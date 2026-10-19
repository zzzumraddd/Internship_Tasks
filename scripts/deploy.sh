#!/usr/bin/env bash
# Deploy kube-prometheus-stack and the demo workloads.
# Usage: scripts/deploy.sh [--with-scenarios]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$ROOT/.env" ]]; then
  echo "Missing .env - run: cp .env.example .env  and set GRAFANA_ADMIN_PASSWORD" >&2
  exit 1
fi
set -a; source "$ROOT/.env"; set +a

: "${RELEASE_NAME:=kps}" "${MONITORING_NAMESPACE:=monitoring}" "${CHART_VERSION:=92.10.1}"
: "${GRAFANA_ADMIN_USER:?set in .env}" "${GRAFANA_ADMIN_PASSWORD:?set in .env}"
if [[ "$GRAFANA_ADMIN_PASSWORD" == change-me* ]]; then
  echo "Set a real GRAFANA_ADMIN_PASSWORD in .env first" >&2
  exit 1
fi

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update prometheus-community

kubectl create namespace "$MONITORING_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Idempotent create/update of the Grafana admin secret (value never hits disk)
kubectl -n "$MONITORING_NAMESPACE" create secret generic grafana-admin \
  --from-literal=admin-user="$GRAFANA_ADMIN_USER" \
  --from-literal=admin-password="$GRAFANA_ADMIN_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install "$RELEASE_NAME" prometheus-community/kube-prometheus-stack \
  --namespace "$MONITORING_NAMESPACE" \
  --version "$CHART_VERSION" \
  -f "$ROOT/monitoring/values.yaml" \
  --wait --timeout 10m

kubectl apply -f "$ROOT/apps/demo-app.yaml"
kubectl apply -f "$ROOT/monitoring/servicemonitor-api.yaml"

if [[ "${1:-}" == "--with-scenarios" ]]; then
  kubectl apply -f "$ROOT/apps/demo-scenarios.yaml"
fi

echo
echo "Done. Endpoints (replace <NODE_IP> with any node's IP):"
echo "  Grafana      http://<NODE_IP>:30300"
echo "  Prometheus   http://<NODE_IP>:30090"
echo "  Alertmanager http://<NODE_IP>:30903"
echo "  Demo app     http://<NODE_IP>:30080"
