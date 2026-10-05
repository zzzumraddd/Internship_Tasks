# Prometheus Monitoring Stack

This Docker Compose setup runs a complete monitoring stack with:
- **Prometheus**: Metrics collection and storage
- **Grafana**: Provisioned dashboards and visualization
- **Node Exporter**: Hardware and OS metrics
- **cAdvisor**: Container metrics
- **Blackbox Exporter**: Endpoint/service monitoring

## Prerequisites

- Docker
- Docker Compose

## Quick Start

1. **Start all services:**
   ```bash
   docker-compose up -d
   ```

2. **Access the services:**
   - Prometheus: http://localhost:9091
   - Grafana: http://localhost:3000 (default login: `admin` / `admin`)
   - cAdvisor: http://localhost:8080
   - Node Exporter: http://localhost:9100/metrics
   - Blackbox Exporter: http://localhost:9115

## Service Ports

| Service | Port | Purpose |
|---------|------|---------|
| Prometheus | 9091 | Web UI & API (container port 9090) |
| Grafana | 3000 | Provisioned monitoring dashboards |
| Node Exporter | 9100 | Node metrics |
| cAdvisor | 8080 | Container metrics |
| Blackbox Exporter | 9115 | Endpoint monitoring |

## Configuration Files

- `prometheus.yml` - Prometheus configuration with scrape configs
- `rules.yml` - Prometheus recording rules
- `blackbox.yml` - Blackbox exporter probing modules
- `grafana/provisioning/datasources/prometheus.yml` - Provisioned Prometheus data source
- `grafana/provisioning/dashboards/dashboards.yml` - Dashboard provider configuration
- `grafana/dashboards/stage1-overview.json` - Provisioned Stage 1 overview dashboard
- `grafana/dashboards/infra-overview.json` - Custom provisioned infrastructure overview dashboard
- `grafana/dashboards/node-exporter-full.json` - Provisioned Node Exporter Full dashboard (Grafana dashboard 1860)

## Grafana

Grafana is configured entirely through provisioning. The Prometheus data source
and all dashboards are loaded automatically when the container starts; no manual
data-source or dashboard import is required.

Open Grafana at <http://localhost:3000> and sign in with the initial credentials:

- Username: `admin`
- Password: `admin`

Grafana may ask you to replace the default password after the first login. If
port 3000 is unavailable, choose another host port before starting the service:

```bash
GRAFANA_PORT=3001 docker-compose up -d grafana
```

### Provisioned data source

The default Prometheus data source is provisioned with UID `prometheus` and
connects to `http://prometheus:9090` over the internal Docker network. It is
marked read-only so its configuration remains controlled by
`grafana/provisioning/datasources/prometheus.yml`.

### Provisioned dashboards

All dashboards are placed in the **Stage 1** folder.

| Dashboard | UID | Purpose |
|-----------|-----|---------|
| Infra Overview | `infra-overview` | Custom high-level infrastructure and endpoint health dashboard |
| Stage 1 Overview | `stage1-overview` | Compact overview of target, node, container, and Blackbox metrics |
| Node Exporter Full | `rYdddlPWk` | Detailed Node Exporter dashboard imported from Grafana dashboard 1860 |

The **Infra Overview** dashboard contains eight panels:

- CPU usage
- RAM usage
- Disk usage
- One-minute system load
- Network receive and transmit throughput
- Top containers by CPU usage
- Top containers by RAM usage
- Blackbox endpoint status

Use `$instance` to select one or more Node Exporter targets and `$interval` to
control the rate-calculation window. CPU, RAM, disk, load, and Blackbox stat
panels use green, yellow, and red thresholds to highlight health conditions.

The dashboard also includes an enabled **Deployments** annotation stream. To
record a deployment manually, add a dashboard annotation and assign it the
`deploy` tag.

Provisioned dashboards are intentionally read-only. Make lasting changes in the
JSON files under `grafana/dashboards/`; UI edits made through **Make editable**
are not the source of truth and can be replaced by provisioning.

## Common Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f prometheus

# Restart all services
docker-compose restart

# Remove volumes (WARNING: deletes data)
docker-compose down -v
```

## Metrics Available

See [PromQL Queries](queries.md) for five example monitoring queries, explanations,
and Prometheus UI results.

### Node Exporter
- CPU, memory, disk, network usage
- System uptime and load averages
- Filesystem utilization

### cAdvisor
- Container CPU, memory usage
- Container network I/O
- Container filesystem metrics

### Blackbox Exporter
- HTTP endpoint probes (success/latency)
- TCP connectivity checks
- DNS resolution checks
- ICMP ping checks

## Customization

Edit `prometheus.yml` to:
- Add more scrape targets
- Change scrape intervals
- Add alerting rules

Edit `blackbox.yml` to:
- Add more probing modules
- Modify timeout/retry settings
- Add SNMP or other protocol checks

## Troubleshooting

**Containers not starting:**
```bash
docker-compose logs
```

**Connection refused between services:**
- Services must use service names (not localhost)
- Example: `http://prometheus:9090` instead of `http://localhost:9090`

**Grafana data source or dashboard missing:**
- Both are managed through files under `grafana/`; do not configure them in the UI
- Restart Grafana after changing provisioning files: `docker-compose restart grafana`
- If port 3000 is already in use, start with another host port, for example:
  `GRAFANA_PORT=3001 docker-compose up -d grafana`

**Permission denied errors (especially cAdvisor):**
- cAdvisor requires privileged access to read container metrics
- This is configured in docker-compose.yml

**Prometheus not scraping targets:**
- Check Prometheus UI at http://localhost:9091/targets
- Verify service names in prometheus.yml match docker-compose.yml service names
