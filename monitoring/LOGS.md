# Loki and Alloy assignment

I added logging to the existing stack:

```text
All Docker containers -> Alloy -> Loki -> Grafana
nginx JSON access logs -----^               -> Telegram alert
```

## Run

From `monitoring`, keep your existing `.env` (or copy `.env.example`
if you do not have one). Add `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` to
`.env` for notifications. Get a bot token from Telegram's @BotFather, start
a chat with the bot, and obtain your chat ID using the Telegram Bot API
`getUpdates` method. For a group, add the bot and use the group's chat ID.
Do not commit the token.

```bash
docker compose config --quiet
docker compose up -d
```

Open [Logs Overview](http://127.0.0.1:3002/d/logs-overview) in Grafana.
It has a rolling five-minute 5xx count graph, a pie chart of status counts
for the selected time range, a logs panel, and a multi-select `$container`
variable. The logs panel shows all selected containers; the charts use nginx
access logs. Alloy discovers all running containers on this Docker daemon,
including other Compose projects. Containers need a logging driver readable
through Docker's logs API. Alloy persists its read positions in a volume.

nginx writes JSON access logs to stdout. Alloy parses only `status` and
`method` into labels. `job` and `container` are source labels. URI stays in
the log body; IP, URI, request IDs, and user IDs are not indexed labels.
nginx error logs are also collected but have no status/method labels, so
request charts and the alert exclude them. The Docker socket gives Alloy
host-sensitive access even though the mount is read-only.

## Five LogQL queries

Paste these into Grafana Explore with the Loki data source. These standalone
queries do not need dashboard variables.

1. All nginx access logs:

```logql
{job="nginx",status=~"[1-5][0-9][0-9]"}
```

2. 5xx requests per second, averaged over five minutes:

```logql
sum(rate({job="nginx",status=~"5.."}[5m])) or vector(0)
```

3. Request count grouped by status over five minutes:

```logql
sum by (status) (count_over_time({job="nginx",status=~"[1-5][0-9][0-9]"}[5m]))
```

4. Request count grouped by method over five minutes:

```logql
sum by (method) (count_over_time({job="nginx",status=~"[1-5][0-9][0-9]"}[5m]))
```

5. 5xx percentage over five minutes (also used by the alert):

```logql
100 * (sum(count_over_time({job="nginx",status=~"5.."}[5m])) or vector(0)) / sum(count_over_time({job="nginx",status=~"[1-5][0-9][0-9]"}[5m]))
```

The zero fallback handles traffic with no errors. With no requests the ratio
has no usable value; the rule uses `noDataState: OK`. A ratio equal to 5%
does not fire: the threshold is strictly greater than 5%.

## Check the dashboard and alert

Wait around 10 seconds for Docker discovery, then make sample requests:

```bash
curl http://127.0.0.1:8088/
curl -X POST http://127.0.0.1:8088/
curl http://127.0.0.1:8088/missing
curl http://127.0.0.1:8088/error
```

For a sustained 10% error ratio, run this for three minutes. It deliberately
creates HTTP 500 responses, so curl is used without `--fail`:

```bash
for round in $(seq 1 18); do
  for request in $(seq 1 9); do
    curl -s -o /dev/null http://127.0.0.1:8088/
  done
  curl -s -o /dev/null http://127.0.0.1:8088/error
  sleep 10
done
```

In Grafana, open **Alerting -> Alert rules -> Nginx 5xx ratio above 5%**.
Grafana evaluates the Loki query every minute. It becomes Pending above 5%
and Alerting after two minutes. The nginx notification route sends it to
Telegram after a 30-second group wait, then repeats every four hours if it
remains firing. Recovery notifications are enabled. Dashboard selection does
not change the alert: it covers all nginx containers.

The Telegram contact point is provisioned with environment variables. Without
valid credentials, Telegram delivery will fail; the local dashboard and rule
can still be inspected. After updating `.env`, recreate Grafana:

```bash
docker compose up -d --force-recreate grafana
```

Use **Alerting -> Contact points -> telegram -> View -> Test** to verify delivery.
The configuration also provisions a notification policy for `service=nginx`;
this lab file owns Grafana's notification policy tree.

## Files

- `alloy/config.alloy`: Docker discovery, parsing, label allowlist, Loki push.
- `loki/config.yml`: single-node filesystem storage with TSDB schema v13.
- `nginx/nginx.conf`: JSON logs and demo 200/404/500 endpoints.
- `grafana/dashboards/logs-overview.json`: dashboard.
- `grafana/provisioning/datasources/loki.yml`: Loki data source.
- `grafana/provisioning/alerting/nginx.json`: Loki-based Grafana alert and Telegram route.

References: [Alloy Docker source](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.source.docker/),
[Alloy log processing](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.process/),
and [Grafana alert provisioning](https://grafana.com/docs/grafana/latest/alerting/set-up/provision-alerting-resources/file-provisioning/).

The status pie uses All values on the instant query, so each status row
becomes its own slice. Loki is pinned to 3.5.12 to avoid the 3.5.0
structured-metadata counter error that repeatedly logs for zero-byte metadata.

## Verified Telegram delivery

On 15 October 2026, the contact-point test arrived at 15:39 Tashkent time.
The actual nginx alert arrived at 16:00 with `A=10` and `C=1`: the Loki query
returned a 10% 5xx ratio, and the greater-than-5% condition was true for two
minutes. See [the root README](../README.md#proof-telegram-notifications-received)
for the distinction between the test message and real alert.
