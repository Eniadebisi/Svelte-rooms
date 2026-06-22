# Observability Runbook

## Prometheus

### Access

```bash
kubectl port-forward svc/prometheus-server -n observability 9090:80
```

Browse to http://localhost:9090

### Key pages

- **Alerts:** http://localhost:9090/alerts — shows firing and pending alerts
- **Targets:** http://localhost:9090/targets — shows scrape status for each job; confirm `svelte-rooms` job is UP
- **Graph:** http://localhost:9090/graph — ad-hoc PromQL queries

### Useful queries

Request rate per route (last 5 min):
```promql
rate(http_requests_total[5m])
```

5xx error rate:
```promql
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])
```

P95 latency:
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[10m]))
```

Pod restart count (last 1h):
```promql
increase(kube_pod_container_status_restarts_total{namespace=~"qa|prod"}[1h])
```

### Alert response

Active alerts appear at http://localhost:9090/alerts. For each alert see:

| Alert | Runbook |
|---|---|
| AppDown | Check pod status: `kubectl get pods -n <env> -l app=svelte-rooms`. Check events: `kubectl describe pod -n <env> -l app=svelte-rooms`. Check CloudWatch logs. |
| High5xxRate | Check CloudWatch for error messages. Check recent deploy (may need rollback — see rollback.md). |
| HighP95Latency | Check CloudWatch for slow query logs. Check DB connections. May indicate DB overload. |
| PodRestartLoop | Check pod logs: `kubectl logs -n <env> -l app=svelte-rooms --previous`. Check OOM: `kubectl describe pod -n <env> -l app=svelte-rooms` and look for OOMKilled. |

## Jaeger

### Access

```bash
kubectl port-forward svc/jaeger-query -n observability 16686:16686
```

Browse to http://localhost:16686

### Finding traces

1. Select service **svelte-rooms** from the Service dropdown
2. Optionally filter by Operation (HTTP route), Tags (e.g. `http.status_code=500`), or time range
3. Click **Find Traces**
4. Click any trace to see the full span tree

### Notes

- Traces are in-memory only. All traces are lost when the Jaeger pod restarts (cluster rebuild, OOM, etc.).
- The OTLP endpoint is `http://jaeger-collector:4318/v1/traces` inside the cluster.
- Traces are sent from the app via the OTel SDK configured in `app/otel.cjs`.

## CloudWatch Logs

### AWS Console

1. Open AWS Console > CloudWatch > Log groups
2. Search for `/eks/svelte-rooms`
3. Select the environment log group (`/eks/svelte-rooms/qa`, `/eks/svelte-rooms/prod`)
4. Click a log stream (named after the Fargate task)
5. Use **Logs Insights** for structured queries

### AWS CLI — tail recent logs

```bash
# Get the most recent log streams
aws logs describe-log-streams \
  --log-group-name /eks/svelte-rooms/prod \
  --order-by LastEventTime \
  --descending \
  --max-items 3 \
  --region $AWS_REGION

# Fetch events from a stream
aws logs get-log-events \
  --log-group-name /eks/svelte-rooms/prod \
  --log-stream-name <stream-name> \
  --limit 100 \
  --region $AWS_REGION
```

### Logs Insights queries

Errors in the last hour:
```
fields @timestamp, @message
| filter @message like /(?i)error/
| sort @timestamp desc
| limit 20
```

All 5xx responses:
```
fields @timestamp, @message
| filter @message like "5[0-9][0-9]"
| sort @timestamp desc
| limit 50
```

Slow requests (if duration is logged):
```
fields @timestamp, @message, duration
| filter duration > 1000
| sort duration desc
| limit 20
```
