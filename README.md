# Prometheus Monitoring Stack

This Docker Compose setup runs a complete monitoring stack with:
- **Prometheus**: Metrics collection and storage
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
   - cAdvisor: http://localhost:8080
   - Node Exporter: http://localhost:9100/metrics
   - Blackbox Exporter: http://localhost:9115

## Service Ports

| Service | Port | Purpose |
|---------|------|---------|
| Prometheus | 9091 | Web UI & API (container port 9090) |
| Node Exporter | 9100 | Node metrics |
| cAdvisor | 8080 | Container metrics |
| Blackbox Exporter | 9115 | Endpoint monitoring |

## Configuration Files

- `prometheus.yml` - Prometheus configuration with scrape configs
- `rules.yml` - Prometheus recording rules
- `blackbox.yml` - Blackbox exporter probing modules

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

**Permission denied errors (especially cAdvisor):**
- cAdvisor requires privileged access to read container metrics
- This is configured in docker-compose.yml

**Prometheus not scraping targets:**
- Check Prometheus UI at http://localhost:9091/targets
- Verify service names in prometheus.yml match docker-compose.yml service names
