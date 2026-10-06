# VictoriaMetrics monitoring stack

This is a separate replacement for the repository's Prometheus Compose stack.
It collects the same Node Exporter, cAdvisor, and Blackbox metrics and loads the
same Grafana dashboards. The original stack is unchanged.

## Architecture (plain English)

```text
exporters -> vmagent -> VictoriaMetrics <- Grafana
                          ^
                          |
                       vmalert
```

- **vmagent** scrapes targets. Its on-disk queue prevents short storage outages
  from immediately losing samples.
- **VictoriaMetrics** stores metrics and serves Prometheus-compatible queries.
- **vmalert** evaluates the existing recording rules.
- **Grafana** uses its Prometheus data-source plugin because VictoriaMetrics
  supports that query API.

## Start it

From this directory:

```bash
cp .env.example .env
# Edit .env and set a long, unique GRAFANA_ADMIN_PASSWORD.
docker compose config --quiet
docker compose up -d
docker compose ps
```

Open <http://127.0.0.1:3002>. The username and password are in your untracked
`.env` file. The existing dashboards are provisioned into the VictoriaMetrics
folder. To inspect scrape health without publishing vmagent, run:

```bash
docker compose exec vmagent wget -qO- http://localhost:8429/targets
```

Stop without deleting metrics:

```bash
docker compose down
```

`docker compose down -v` also deletes all stored metrics and Grafana data.

## Why these defaults are safer

- Only Grafana is published, and only on loopback (`127.0.0.1`). VictoriaMetrics
  and exporters accept no host connections. The bridge still permits outbound
  traffic because Blackbox must probe public HTTPS endpoints.
- Anonymous Grafana access and user sign-up are disabled; the password is not
  committed to Git.
- Images use explicit versions instead of moving `latest` tags.
- Services drop Linux capabilities and enable `no-new-privileges` where their
  function permits it. cAdvisor remains privileged because it must inspect the
  Docker host; treat that container as host-sensitive.
- Config and dashboard mounts are read-only.

For access from another machine, do not change the bind address to `0.0.0.0`
on an Internet-facing host. Put Grafana behind an HTTPS reverse proxy or VPN,
then set `GF_SECURITY_COOKIE_SECURE=true`.

## Scaling path

This Compose file is a secure learning/small-host deployment, not high
availability. Scale in stages:

1. Run one `vmagent` per host or failure domain and point all of them at storage.
2. Move storage to VictoriaMetrics cluster (`vminsert`, `vmstorage`, `vmselect`)
   when one node no longer meets ingestion, retention, or availability needs.
3. Put `vmauth` or a trusted authenticated TLS proxy in front of cluster read
   and write endpoints. Never expose component ports directly.
4. Use at least two `vmstorage` replicas across failure domains, durable disks,
   tested backups, resource limits, and monitoring for the monitoring stack.
5. For Kubernetes, use the VictoriaMetrics Operator rather than translating
   this Compose file literally.

Single-node VictoriaMetrics has no application-level replication, so adding a
second single-node container does not make this deployment HA.

## Files an intern will edit most often

- `prometheus.yml`: scrape targets and intervals (vmagent understands Prometheus
  scrape configuration).
- `rules.yml`: MetricsQL/PromQL recording and alert rules.
- `blackbox.yml`: endpoint probe behavior.
- `.env`: local port, Grafana credentials, and retention.

After a scrape-config change, validate and restart vmagent:

```bash
docker compose config --quiet
docker compose restart vmagent
docker compose logs --tail=100 vmagent
```
