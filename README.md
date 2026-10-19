# Kubernetes Monitoring

Cluster and application monitoring on a kubeadm Kubernetes cluster with
**kube-prometheus-stack** (Prometheus Operator, Prometheus, Alertmanager,
Grafana, node-exporter, kube-state-metrics), plus demo workloads that expose
custom Prometheus metrics and simulate common failures.

## Environment

| Component | Version / value |
|-----------|-----------------|
| Nodes | 3 × Ubuntu 26.04 LTS VMs: `vm1` (control-plane), `vm2`, `vm3` (workers) |
| Kubernetes | v1.31.14, bootstrapped with `kubeadm` |
| Container runtime | containerd 2.2.2 |
| CNI | Flannel (pod CIDR `10.244.0.0/16`) |
| Helm | v3.22 |
| Chart | `prometheus-community/kube-prometheus-stack` 92.10.1 (operator v0.94.1) |
| Helm release / namespace | `kps` / `monitoring` |

## Repository layout

```
.
├── .env.example                      # template for local settings & credentials
├── .gitignore                        # keeps .env, kubeconfigs and keys out of git
├── monitoring/
│   ├── values.yaml                   # kube-prometheus-stack Helm values (no secrets)
│   └── servicemonitor-api.yaml       # scrapes the demo API's /metrics
├── apps/
│   ├── demo-app.yaml                 # namespace demo-app: frontend + Flask API + Redis
│   └── demo-scenarios.yaml           # namespace demo: failure scenarios (optional)
└── scripts/
    ├── deploy.sh                     # one-command install / upgrade
    └── teardown.sh                   # removes everything again
```

## Security

- **No credentials in git.** The Grafana admin user and password live only in a
  local `.env` file, which is git-ignored. `deploy.sh` turns them into the
  Kubernetes Secret `monitoring/grafana-admin`, and the Helm values point at it
  through `grafana.admin.existingSecret`.
- No kubeconfig, certificates or join tokens are committed. Node IPs are left
  as `<NODE_IP>` placeholders.
- The chart version is pinned, so each deploy is reproducible.
- The UIs are exposed through **NodePorts** for lab convenience. On anything
  shared, switch the services to `ClusterIP` and use `kubectl port-forward` or
  an Ingress with TLS and authentication.

## Quick start

Prerequisites: a working cluster, plus `kubectl` and `helm` on a machine with
cluster-admin access.

```bash
git clone -b kubernetes-monitoring https://github.com/zzzumraddd/Internship_Tasks.git
cd Internship_Tasks

cp .env.example .env
# edit .env and set GRAFANA_ADMIN_PASSWORD (e.g. `openssl rand -base64 24`)

./scripts/deploy.sh                    # monitoring stack + demo-app
./scripts/deploy.sh --with-scenarios   # also deploys the failure scenarios
```

`deploy.sh` is idempotent, so you can re-run it to apply changes. To remove
everything, run `./scripts/teardown.sh`.

### Endpoints

| Service | URL |
|---------|-----|
| Grafana | `http://<NODE_IP>:30300` (credentials from `.env`) |
| Prometheus | `http://<NODE_IP>:30090` |
| Alertmanager | `http://<NODE_IP>:30903` |
| Demo app | `http://<NODE_IP>:30080` |

## Demo workloads

### `demo-app` (namespace `demo-app`)

- **frontend**: nginx serving a page with buttons that call the API (normal,
  slow, error, and a burst of 50 requests). It proxies `/api/` to the API.
- **api**: a Flask app (2 replicas) that counts visits in Redis. It exposes
  `app_requests_total{endpoint,status}` and
  `app_request_duration_seconds` on `/metrics`.
- **redis**: the backing store.

`monitoring/servicemonitor-api.yaml` tells Prometheus to scrape the API every
15 seconds.

### `demo-scenarios` (namespace `demo`, optional)

| Deployment | What it shows |
|------------|---------------|
| `metrics-app` | Custom metrics: `demo_jobs_processed_total`, `demo_job_duration_seconds`, `demo_queue_size` (includes its own ServiceMonitor) |
| `web` + `loadgen` | Continuous network traffic |
| `cpu-burner` | High CPU usage and CPU throttling |
| `memory-leak` | Memory growth until the container is OOMKilled |
| `crash-loop` | `CrashLoopBackOff` and restart alerts |
| `too-big` | A pod stuck in `Pending` because of an unsatisfiable memory request |

Many of the stack's built-in alerts fire for these scenarios, for example
`KubePodCrashLooping`, `KubePodNotReady` and `CPUThrottlingHigh`. You can see
them in Alertmanager.

## Useful PromQL

```promql
# Request rate per endpoint / status
sum by (endpoint, status) (rate(app_requests_total[5m]))

# Error ratio
sum(rate(app_requests_total{status=~"5.."}[5m])) / sum(rate(app_requests_total[5m]))

# p95 latency per endpoint
histogram_quantile(0.95, sum by (le, endpoint) (rate(app_request_duration_seconds_bucket[5m])))

# CPU usage per pod in the demo namespaces
sum by (namespace, pod) (rate(container_cpu_usage_seconds_total{namespace=~"demo|demo-app", container!=""}[5m]))

# Container restarts in the last hour
increase(kube_pod_container_status_restarts_total[1h]) > 0

# OOMKilled containers
kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}
```

## Grafana

The chart provisions the Prometheus data source and the standard Kubernetes
dashboards automatically. These are useful starting points:

- *Kubernetes / Compute Resources / Namespace (Pods)*: choose `demo` or `demo-app`
- *Kubernetes / Compute Resources / Node (Pods)*
- *Node Exporter / Nodes*

To build an app dashboard, start a new dashboard from the PromQL queries above.

## Customising

- **Credentials and release settings:** edit `.env`.
- **Ports, retention and other stack options:** edit `monitoring/values.yaml`,
  then re-run `deploy.sh`.
- **Scraping your own app:** add a `ServiceMonitor` whose selector matches your
  Service's labels and whose `port` names a Service port. Prometheus picks up
  ServiceMonitors from every namespace, so no release label is needed.
