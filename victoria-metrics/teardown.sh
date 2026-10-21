#!/usr/bin/env bash
# Remove the VictoriaMetrics stack. Leaves kps, its PVCs and the local-path StorageClass in place.
# Usage: victoria-metrics/teardown.sh
set -euo pipefail

helm uninstall vmks --namespace victoria --wait || true
kubectl delete namespace victoria --ignore-not-found
# CRDs are installed as plain manifests (crds.plain: true), so helm leaves them behind
kubectl get crd -o name | grep victoriametrics.com | xargs -r kubectl delete
