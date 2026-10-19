#!/usr/bin/env bash
# Remove the demo workloads and the monitoring stack.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[[ -f "$ROOT/.env" ]] && { set -a; source "$ROOT/.env"; set +a; }
: "${RELEASE_NAME:=kps}" "${MONITORING_NAMESPACE:=monitoring}"

kubectl delete -f "$ROOT/apps/demo-scenarios.yaml" --ignore-not-found
kubectl delete -f "$ROOT/monitoring/servicemonitor-api.yaml" --ignore-not-found
kubectl delete -f "$ROOT/apps/demo-app.yaml" --ignore-not-found
helm uninstall "$RELEASE_NAME" -n "$MONITORING_NAMESPACE" || true
kubectl delete namespace "$MONITORING_NAMESPACE" --ignore-not-found

# CRDs are not removed by helm uninstall; delete them only if nothing else uses them:
#   kubectl get crd -o name | grep monitoring.coreos.com | xargs kubectl delete
