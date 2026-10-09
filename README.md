# VictoriaMetrics and VictoriaLogs lab

This branch demonstrates a complete metrics stack and a separate, minimal logs
example. It does not run a Prometheus server.

## What is included

- **VictoriaMetrics** stores metrics.
- **vmagent** scrapes Node Exporter, cAdvisor, and Blackbox Exporter.
- **vmalert** evaluates the recording rules.
- **Grafana** is automatically configured with the VictoriaMetrics data source
  and three dashboards.
- **VictoriaLogs** runs independently for JSON log ingestion and LogsQL queries.

```text
Node Exporter -----\
cAdvisor -----------+--> vmagent --> VictoriaMetrics --> Grafana
Blackbox Exporter --/                       ^
                                            |
                                         vmalert

JSON logs -----------------------------> VictoriaLogs --> VMUI
```

## Requirements

- Docker
- Docker Compose v2 (`docker compose`)
- `curl` for the VictoriaLogs example

## Run the metrics stack with Grafana

From the repository root:

```bash
cd victoria-metrics
cp .env.example .env
docker compose config --quiet
docker compose up -d
docker compose ps
```

The example credentials are suitable only for this loopback-only local lab:

- URL: <http://127.0.0.1:3002>
- Username: `admin`
- Password: `change-me-to-a-long-random-password`

For anything beyond local evaluation, change `GRAFANA_ADMIN_PASSWORD` in
`victoria-metrics/.env` before starting the stack.

Grafana provisions the VictoriaMetrics data source and dashboards without any
manual import. After signing in, open **Dashboards** and select the
**VictoriaMetrics** folder, or use these direct links:

- [Infra Overview](http://127.0.0.1:3002/d/infra-overview)
- [Stage 1 Overview](http://127.0.0.1:3002/d/stage1-overview)
- [Node Exporter Full](http://127.0.0.1:3002/d/rYdddlPWk)

Allow roughly 30 seconds after startup for vmagent to collect the first samples.
Confirm that the services and scrape targets are healthy with:

```bash
docker compose ps
docker compose exec vmagent wget -qO- http://localhost:8429/targets
```

Detailed configuration and troubleshooting are in
[`victoria-metrics/README.md`](victoria-metrics/README.md).

## Run the standalone logs example

VictoriaLogs is intentionally a separate Compose project. From the repository
root, open another terminal and run:

```bash
cd victoria-logs
docker compose up -d
docker compose ps

curl --fail-with-body \
  -H 'Content-Type: application/stream+json' \
  --data-binary @sample.jsonl \
  'http://127.0.0.1:9428/insert/jsonline?_stream_fields=service,level&_time_field=timestamp&_msg_field=message'
```

Open the built-in VMUI at <http://127.0.0.1:9428/select/vmui> and execute:

```logsql
*
```

The checkout and payment messages are synthetic tutorial data from
`victoria-logs/sample.jsonl`, not real application events. See
[`victoria-logs/README.md`](victoria-logs/README.md) for more queries.

## Stop the lab

Run the following command once in each project directory:

```bash
docker compose down
```

Add `-v` only when you also want to delete stored metrics, logs, and Grafana
state:

```bash
docker compose down -v
```
