# VictoriaLogs: standalone first run

This example runs only VictoriaLogs: one container, one persistent volume, and
one loopback-only port. It does not depend on the repository's VictoriaMetrics
or Grafana stacks.

## Start

From the repository root:

```bash
cd victoria-logs
docker compose up -d
docker compose ps
docker compose logs --tail=20 victoria-logs
```

VictoriaLogs listens at <http://127.0.0.1:9428>. Its built-in query UI is at
<http://127.0.0.1:9428/select/vmui>.

## Insert three JSON log lines

Run this from the `victoria-logs` directory:

```bash
curl --fail-with-body \
  -H 'Content-Type: application/stream+json' \
  --data-binary @sample.jsonl \
  'http://127.0.0.1:9428/insert/jsonline?_stream_fields=service,level&_time_field=timestamp&_msg_field=message'
```

`timestamp: "0"` asks VictoriaLogs to assign the ingestion time. The URL
parameters map `service` and `level` to stream fields, `timestamp` to `_time`,
and `message` to the searchable `_msg` field.

The `checkout`, `payment declined`, and order ID values in `sample.jsonl` are
synthetic tutorial data. They are not logs collected from another application
in this repository and do not represent real orders or payments.

## Query in VMUI

Open <http://127.0.0.1:9428/select/vmui>, enter a LogsQL query in the **Query**
field, and click **Execute**. Set the time picker to a range that includes the
time when the sample was inserted, such as **Last 5 minutes**.

Use `*` to display every stored log:

```logsql
*
```

Use a word search to find the sample error message:

```logsql
error
```

Filter by a stream field:

```logsql
{service="checkout"}
```

Filter by multiple stream fields:

```logsql
{service="checkout",level="error"}
```

Count logs by level:

```logsql
* | stats by (level) count() logs
```

The VMUI result for `{service="checkout",level="error"}` contains the
synthetic `payment declined` entry from `sample.jsonl`. Expand a result row to
inspect `_time`, `_msg`, `_stream`, `level`, `service`, and `order_id`.

## Query from the terminal

Return up to ten recent checkout logs:

```bash
curl --silent --show-error --fail-with-body \
  'http://127.0.0.1:9428/select/logsql/query' \
  --data-urlencode 'query={service="checkout"}' \
  -d 'limit=10'
```

Count logs by level:

```bash
curl --silent --show-error --fail-with-body \
  'http://127.0.0.1:9428/select/logsql/query' \
  --data-urlencode 'query=* | stats by (level) count() logs'
```

Each time the insert command is run, another copy of all three sample events is
stored. VictoriaLogs does not deduplicate repeated uploads. To remove the demo
events and start with empty storage, run:

```bash
docker compose down -v
docker compose up -d
```

## Stop or reset

```bash
docker compose down       # keep the stored logs
docker compose down -v    # delete the stored logs
```

The service is intentionally bound to `127.0.0.1`; VictoriaLogs does not add
authentication or TLS by itself, so do not publish port 9428 directly to the
Internet.
