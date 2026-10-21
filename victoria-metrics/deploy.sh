#!/usr/bin/env bash
# Add persistent storage and a VictoriaMetrics stack next to kube-prometheus-stack.
# Run ../scripts/deploy.sh first: it creates the "kps" release and the grafana-admin secret.
# Usage: victoria-metrics/deploy.sh
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"

[[ -f "$ROOT/.env" ]] && { set -a; source "$ROOT/.env"; set +a; }
: "${RELEASE_NAME:=kps}" "${MONITORING_NAMESPACE:=monitoring}" "${CHART_VERSION:=92.10.1}"
VM_RELEASE=vmks
VM_NAMESPACE=victoria
VM_CHART_VERSION=0.96.0

# 1. StorageClass: rancher local-path-provisioner v0.0.31, made the default class
kubectl apply -f "$DIR/local-path-storage.yaml"
kubectl patch storageclass local-path \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl -n local-path-storage rollout status deploy/local-path-provisioner --timeout=5m

# 2. Prometheus + Alertmanager onto PVCs (same chart version, only storage changes)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo add vm https://victoriametrics.github.io/helm-charts/ >/dev/null 2>&1 || true
helm repo update prometheus-community vm

helm upgrade --install "$RELEASE_NAME" prometheus-community/kube-prometheus-stack \
  --namespace "$MONITORING_NAMESPACE" \
  --version "$CHART_VERSION" \
  -f "$ROOT/monitoring/values.yaml" \
  -f "$DIR/kps-storage-values.yaml" \
  --wait --timeout 10m

# 3. VictoriaMetrics stack in its own namespace
helm upgrade --install "$VM_RELEASE" vm/victoria-metrics-k8s-stack \
  --namespace "$VM_NAMESPACE" --create-namespace \
  --version "$VM_CHART_VERSION" \
  -f "$DIR/values.yaml" \
  --wait --timeout 10m

kubectl get pvc -A
kubectl -n "$VM_NAMESPACE" get pods
