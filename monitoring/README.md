# Loki + Alloy monitoring stack

This directory runs the Docker logging assignment: Alloy collects container
logs, Loki stores them, nginx generates JSON access logs, and Grafana displays
Logs Overview and evaluates the 5xx alert.

See the [assignment README](../README.md) for startup, five LogQL queries, and
Telegram setup, or [LOGS.md](LOGS.md) for the full walkthrough.

## Configuration files

| File | Purpose |
| --- | --- |
| `docker-compose.yml` | Services, ports, volumes, and environment variables |
| `alloy/config.alloy` | Discover Docker containers, parse nginx status/method, send to Loki |
| `loki/config.yml` | Single-node Loki with persistent filesystem storage |
| `nginx/nginx.conf` | JSON access logs and demo 200/404/500 endpoints |
| `grafana/dashboards/logs-overview.json` | 5xx graph, status pie, logs panel, container variable |
| `grafana/provisioning/datasources/loki.yml` | Loki data source |
| `grafana/provisioning/alerting/nginx.json` | 5xx ratio rule and notification policy |
| `grafana/provisioning/alerting/telegram.yml` | Telegram contact point template |
| `grafana/start.sh` | Render the chat ID as a string before Grafana starts |
| `.env` | Local credentials and ports; ignored by Git |

## Operations

Run these commands from this directory:

```bash
docker compose config --quiet
docker compose up -d
docker compose ps
docker compose logs --tail=50 alloy loki nginx grafana
```

After editing Alloy, Loki, or nginx configuration, restart the affected service:

```bash
docker compose restart alloy loki nginx
```

After editing alert provisioning, restart Grafana. After editing `.env`,
recreate Grafana so it receives the new Telegram environment variables:

```bash
docker compose up -d --force-recreate grafana
```

Grafana and nginx are published on loopback only (default ports 3002 and
8088). Alloy uses the Docker socket to discover and read containers, which
requires host-sensitive access. Config mounts are read-only; named volumes
preserve logs and read positions across restarts.

## Earlier metrics exercise

VictoriaMetrics, vmagent, vmalert, and exporters remain in this combined stack.
Their configuration is in `prometheus.yml`, `rules.yml`, and `blackbox.yml`.
The earlier metrics dashboards are also available in Grafana's Monitoring
folder. The separate [VictoriaLogs exercise](../victoria-logs/README.md)
uses its own Compose project.

## Dashboard verification

I checked the Logs Overview dashboard using sample nginx requests:

- The status pie showed two `200` requests (50%), one `404` (25%), and
  one `500` (25%). Each slice displayed its HTTP status label.
- The 5xx graph counted the error in its rolling five-minute window, then
  returned to zero when that request left the window.
- The logs panel displayed logs from Docker containers. With Container set
  to All, application errors such as Python `ConnectTimeout` also appear;
  expand a log row to identify the container, or select it in the dropdown.
- Grafana successfully provisioned the dashboard and Loki-based alert.
  Updating Loki to 3.5.12 stopped the repeated structured-metadata counter
  errors seen with 3.5.0.

Telegram delivery was verified on 15 October 2026: the contact-point test
arrived at 15:39 Tashkent time, and the real nginx alert arrived at 16:00.
The real message showed `A=10` (10% 5xx ratio) and `C=1` (threshold true),
confirming delivery after the two-minute pending period.
See [Telegram alert verification](../README.md#telegram-alert-verification)
for the explanation of both messages.

Grafana 12.2 coerces numeric environment substitutions into numbers. The startup
script renders the chat ID into a temporary copy of provisioning so Telegram
receives a string without literal quote characters. The token stays in `.env`
and is expanded by Grafana; it is not written into the rendered template.
