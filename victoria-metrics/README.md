# VictoriaMetrics vs. kube-prometheus-stack

A **VictoriaMetrics** stack runs in its own namespace (`victoria`) next to the
existing kube-prometheus-stack (`kps` in `monitoring`). Both stacks scrape the
same targets and evaluate the same alert rules, so you can compare them
directly. This folder also adds persistent storage for both stacks.

Everything here is additive. The main setup in the repository root is unchanged.

## What was added

| Step | What | Why |
|------|------|-----|
| 1 | **StorageClass `local-path`** ([rancher/local-path-provisioner](https://github.com/rancher/local-path-provisioner) v0.0.31), set as default | The cluster had no StorageClass, so every component ran on `emptyDir` and lost its data on restart |
| 2 | **Prometheus** → 2Gi PVC, **Alertmanager** → 256Mi PVC | Data survives pod restarts |
| 3 | **victoria-metrics-k8s-stack** 0.96.0 (VM v1.154.0) in namespace `victoria` | The side-by-side comparison |

## How the comparison is set up

```
                 ServiceMonitors / PrometheusRules (created by kps)
                    │                                │
                    ▼                                ▼ converted by VM operator
  monitoring ns:  Prometheus ── Alertmanager       VMServiceScrape / VMRule
                    ▲                                │
                    │                                ▼
                 Grafana ◄──── datasource ──── victoria ns:
                                                VMAgent → VMSingle ← VMAlert → VMAlertmanager
```

- **Same targets.** The VM operator converts every existing ServiceMonitor,
  PodMonitor and PrometheusRule into its own CRDs and keeps them in sync. New
  scrape configs only need to be added once, for Prometheus.
- **Same settings.** Both use a 30s scrape interval and 2d retention.
- **No duplicate exporters.** The chart's own node-exporter, kube-state-metrics,
  default rules, dashboards and Grafana are disabled. A second node-exporter
  would clash on hostPort 9100.
- **Shared Grafana.** A ConfigMap with the label `grafana_datasource: "1"` adds
  a `VictoriaMetrics` datasource to the existing Grafana. The same dashboard can
  then be pointed at either backend.
- **Silent alerts.** VMAlertmanager sends to a `blackhole` receiver. Alerts show
  up in its UI, but nobody gets notified twice.

## Storage notes

- **Node-bound volumes.** `local-path` volumes are directories under
  `/opt/local-path-provisioner` on one node. A pod with a PVC is pinned to that
  node and can't move if the node goes down.
- **No size limit.** `local-path` doesn't enforce PVC size, and the nodes have
  only about 3 GB free disk, so each stack has its own guard:
  - Prometheus: `retentionSize: 1500MB`
  - VMSingle: `storage.minFreeDiskSpaceBytes: 500MB` (it switches to read-only
    before the node disk fills up)

## Files

```
victoria-metrics/
├── deploy.sh                 # steps 1–3, idempotent
├── teardown.sh               # removes the VM stack only
├── local-path-storage.yaml   # upstream local-path-provisioner v0.0.31 manifest
├── kps-storage-values.yaml   # overlay on ../monitoring/values.yaml: PVCs + retentionSize
└── values.yaml               # victoria-metrics-k8s-stack Helm values
```

## Deploy

```bash
./scripts/deploy.sh               # base stack first (creates kps + grafana-admin secret)
./victoria-metrics/deploy.sh      # storage + VictoriaMetrics
```

Check:

```bash
kubectl get pvc -A
kubectl -n victoria get pods
kubectl -n victoria get vmservicescrapes,vmrules | wc -l   # converted objects
```

## Comparing

Run these queries in Grafana (either datasource):

```promql
# memory
sum by (pod)(container_memory_working_set_bytes{container!="",namespace=~"monitoring|victoria",
  pod=~"prometheus-kps.*|alertmanager-kps.*|vm.*"})
# CPU
sum by (pod)(rate(container_cpu_usage_seconds_total{container!="",namespace=~"monitoring|victoria",
  pod=~"prometheus-kps.*|alertmanager-kps.*|vm.*"}[10m]))
```

The two stacks are split up differently. Prometheus does scraping, storage and
rule evaluation in one pod. VictoriaMetrics splits the same work across
VMAgent, VMSingle and VMAlert. Compare **Prometheus** with
**VMAgent + VMSingle + VMAlert**.

### First snapshot (2026-10-21)

These numbers are from about 1 h after the VM install and about 20 min after
Prometheus restarted on its new PVC. Treat them as a starting point, not a
result. A fair comparison needs both stacks running for at least a full
retention window (2d).

| | Memory (MiB) | CPU (mcores) |
|---|---|---|
| Prometheus | 308 | 54 |
| VMAgent + VMSingle + VMAlert | 104 + 233 + 56 = **393** | 57 + 92 + 23 = **172** |
| Alertmanager / VMAlertmanager | 33 / 45 | 6 / 7 |
| Operators (prometheus-operator / vm-operator) | 24 / 73 | 13 / 23 |

## Teardown

```bash
./victoria-metrics/teardown.sh
```

This removes the VM stack and its CRDs. kps, its PVCs and the StorageClass
stay in place.
