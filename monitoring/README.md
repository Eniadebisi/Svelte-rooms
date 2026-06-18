# Monitoring Stack

## What runs where

| Component | Namespace | Pod | Notes |
|---|---|---|---|
| Prometheus | observability | prometheus-server-* | Fargate pod, 24h ephemeral TSDB, no AlertManager |
| Jaeger all-in-one | observability | jaeger-* | Fargate pod, in-memory traces (lost on restart) |
| kube-state-metrics | observability | kube-state-metrics-* | Cluster metrics for Prometheus |
| App metrics | dev / qa / prod | svelte-rooms-* | prom-client at /metrics |
| Logs | AWS CloudWatch | n/a | Fargate native log router — no Fluentd/Fluent Bit pods needed |

## Accessing Prometheus

```bash
kubectl port-forward svc/prometheus-server -n observability 9090:80
```

Browse to http://localhost:9090

- Active alerts: http://localhost:9090/alerts
- Targets (scrape status): http://localhost:9090/targets
- Example query: `rate(http_requests_total[5m])`

## Accessing Jaeger

```bash
kubectl port-forward svc/jaeger-query -n observability 16686:16686
```

Browse to http://localhost:16686

Select service **svelte-rooms** in the dropdown and click Find Traces.

## CloudWatch Logs

Fargate pods stream logs automatically via the built-in Fluent Bit log router.

**Log groups:**
- `/eks/svelte-rooms/dev`
- `/eks/svelte-rooms/qa`
- `/eks/svelte-rooms/prod`

**AWS Console path:** CloudWatch > Log groups > search for `/eks/svelte-rooms`

**CloudWatch Logs Insights sample queries:**

Filter for errors in the last hour:
```
fields @timestamp, @message
| filter @message like /(?i)error/
| sort @timestamp desc
| limit 20
```

Filter for a specific HTTP status:
```
fields @timestamp, @message
| filter @message like "500"
| sort @timestamp desc
| limit 50
```

Request rate by status code (if structured JSON logging):
```
fields @timestamp, status, method, url
| stats count() by status
| sort status asc
```

## Alert Rules

Alert rules are defined in `monitoring/alert-rules.yaml` and mounted into the Prometheus server via a ConfigMap. See [runbooks/observability.md](../runbooks/observability.md) for response steps.

## Ephemeral Data Warning

- **Prometheus:** metrics history is lost when the pod restarts. 24h retention window only. No persistent volume — by design for cost reasons (Fargate EBS is expensive).
- **Jaeger:** traces are stored in memory only. Lost on pod restart.
- **CloudWatch:** durable. Logs are retained per the log group retention policy (default: no expiry unless set in Terraform).
