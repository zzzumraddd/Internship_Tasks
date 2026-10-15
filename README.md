# Loki + Alloy: Docker logs assignment

This branch contains my Docker logging assignment. I added Loki, Grafana Alloy,
and nginx to the existing monitoring stack, built a Logs Overview dashboard,
and configured a Loki-based alert with a Telegram contact point.

## Proof: Telegram notifications received

I verified delivery in two stages on 15 October 2026 (Tashkent time).

### Contact-point test — 15:39

The notification received in Telegram contained:

```text
Firing
Value: B=22, C=1
Labels:
 - alertname = TestAlert
 - grafana_folder = Test Folder
 - instance = Grafana
Annotations:
 - summary = Notification test
```

The first Telegram message had `alertname = TestAlert`,
`summary = Notification test`, and `Value: B=22, C=1`. I sent it from
Grafana's contact-point test dialog. Receiving this message confirmed that
Grafana could use the configured bot token and chat ID to send to Telegram.
The values are sample test data; they do not describe nginx traffic.

### Real nginx alert — 16:00

The actual alert received in Telegram contained:

```text
Firing
Value: A=10, C=1
Labels:
 - alertname = Nginx 5xx ratio above 5%
 - grafana_folder = Logs
 - service = nginx
 - severity = warning
Annotations:
 - description = More than 5% of nginx access logs were 5xx during the last 5 minutes, for 2 minutes.
 - summary = Nginx 5xx ratio exceeds 5%
```

The second message had `alertname = Nginx 5xx ratio above 5%`,
`service = nginx`, `severity = warning`, and `Value: A=10, C=1`.

| Field in the notification | Meaning |
| --- | --- |
| `Firing` | The condition stayed true for the configured two-minute pending period. |
| `A=10` | The Loki query calculated a 10% 5xx ratio over the last five minutes. |
| `C=1` | The threshold expression was true: 10% is strictly greater than 5%. |
| `service = nginx` | The notification policy routed the alert to Telegram. |
| `grafana_folder = Logs` | The folder containing the alert rule in Grafana. |

I generated nine successful requests and one HTTP 500 response per batch.
The real notification confirms the complete path: nginx access logs -> Alloy
parsing -> Loki query -> Grafana alert evaluation -> Telegram delivery.
Grafana's alert history also showed the rule moving from Pending to Alerting.

The captured messages contain links to `http://localhost:3000`. This lab
publishes Grafana at `http://127.0.0.1:3002`, so use port 3002 when opening
those links locally. The contact-point test's `dashboard_uid` link is sample
data; the real alert links to `logs-overview`.

## What I implemented

1. **Docker log collection:** Alloy discovers all running containers on the
   Docker host and sends their logs to Loki, including other Compose projects.
2. **nginx access log parsing:** nginx writes JSON to stdout. Alloy extracts
   only `status` and `method` as access-log labels. `job` and `container`
   identify the source; request URLs stay in the log body to limit cardinality.
3. **Logs Overview dashboard:** a rolling five-minute 5xx count graph, a pie
   chart by status, a logs panel, and a multi-select `$container` variable.
4. **Five LogQL queries:** examples below cover access logs, error rate,
   status counts, method counts, and the 5xx ratio.
5. **Telegram alert:** Grafana evaluates a Loki query every minute and fires
   when the five-minute 5xx ratio stays strictly above 5% for two minutes.

```text
Docker containers -> Alloy -> Loki -> Grafana Logs Overview
nginx JSON logs -------^                 |
                                        +-> Loki-based alert -> Telegram
```

## Start the stack

Requirements: Docker, Docker Compose v2, and curl.

```bash
cd monitoring
# Copy only on first setup; keep an existing .env.
cp .env.example .env
# Set GRAFANA_ADMIN_PASSWORD in .env.
docker compose config --quiet
docker compose up -d
docker compose ps
```

Open [Logs Overview](http://127.0.0.1:3002/d/logs-overview) and sign in using
`GRAFANA_ADMIN_USER` and `GRAFANA_ADMIN_PASSWORD` from `.env`. The dashboard
is provisioned into the **Monitoring** folder, and Loki is already configured
as a data source. The default Grafana port is 3002; nginx listens on 8088.

Wait about 10 seconds for Docker discovery, then generate sample traffic:

```bash
curl http://127.0.0.1:8088/
curl -X POST http://127.0.0.1:8088/
curl http://127.0.0.1:8088/missing
curl http://127.0.0.1:8088/error
```

The endpoints return 200, 200, 404, and 500 respectively. The pie should show
50% for 200 and 25% each for 404 and 500 when these are the only requests in
the selected time range. Select nginx in `$container` to inspect its logs.
With All selected, the logs panel also displays the other containers.

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

## Telegram setup and alert

Add your real credentials to `monitoring/.env`:

```dotenv
TELEGRAM_BOT_TOKEN=<your bot token>
TELEGRAM_CHAT_ID=<your chat ID>
```

Create a bot using Telegram's @BotFather, start a chat with it, and get the
chat ID using the Bot API `getUpdates` method. Keep these credentials out of
Git. From `monitoring`, apply the environment changes:

```bash
docker compose up -d --force-recreate grafana
```

Test **Alerting -> Contact points -> telegram -> View -> Test** in Grafana, then open
**Alerting -> Alert rules -> Nginx 5xx ratio above 5%**. The rule covers all
nginx containers independently of dashboard selection. Recovery messages
are enabled. See [the walkthrough](monitoring/LOGS.md#check-the-dashboard-and-alert)
for sustained test traffic.

Telegram delivery was verified with both a contact-point test and the real
nginx 5xx alert on 15 October 2026. See the proof section at the top.

## Verification

- Docker Compose configuration validated and the services started.
- nginx access logs reached Loki with status and method labels.
- Grafana provisioned the data source, dashboard, and alert.
- The dashboard showed two 200 responses, one 404, and one 500 with separate
  status slices. The rolling 5xx count returned to zero after five minutes.
- The alert ratio query returned the expected percentage for the test traffic.
- Loki 3.5.12 stopped the repeated metadata-counter errors seen with 3.5.0.

## Repository layout

- [`monitoring/`](monitoring/): Compose stack, Alloy/Loki/nginx configuration,
  Grafana dashboard, and alert provisioning.
- [`monitoring/README.md`](monitoring/README.md): configuration files and operations.
- [`monitoring/LOGS.md`](monitoring/LOGS.md): detailed logging walkthrough.
- [`victoria-logs/`](victoria-logs/): earlier standalone VictoriaLogs exercise.

The existing VictoriaMetrics services and metrics dashboards remain in the
combined stack from the earlier assignment. Loki stores the Docker logs for
this assignment; the standalone VictoriaLogs exercise runs separately.

## Stop

From `monitoring`:

```bash
docker compose down
```

Stored data is preserved. Add `-v` only to delete the stack's persistent data.
