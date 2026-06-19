# Incident Response

No pager or on-call tooling is configured. Alerts surface in the Prometheus UI. This runbook defines the response process.

## Severity levels

| Level | Definition | Example |
|---|---|---|
| SEV1 | Complete outage — app is unreachable or returning errors on all requests | AppDown alert firing, 100% 5xx rate |
| SEV2 | Degraded service — partial failure or significant performance impact | High5xxRate or HighP95Latency alert firing |
| SEV3 | Minor issue — no user impact or impact is limited | PodRestartLoop alert firing but app is still serving |

## Response steps

### 1. Detect

- Check Prometheus alerts: `kubectl port-forward svc/prometheus-server -n observability 9090:80` then browse to http://localhost:9090/alerts
- Or notice a failing GitHub Actions deploy or a direct report

### 2. Open a GitHub issue

Create a new issue using the **Incident Report** template:
1. Go to GitHub repo > Issues > New issue > **Incident Report**
2. Fill in severity, detected time, and initial impact assessment
3. Update the issue as the incident progresses

### 3. Investigate

Check Prometheus for active alerts and metrics:
```
http://localhost:9090/alerts
http://localhost:9090/graph
```

Check CloudWatch logs for errors:
```bash
aws logs start-query \
  --log-group-name /eks/svelte-rooms/prod \
  --start-time $(date -d '30 minutes ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /(?i)error/ | sort @timestamp desc | limit 20' \
  --region $AWS_REGION
```

Check pod status:
```bash
kubectl get pods -n prod -l app=svelte-rooms
kubectl describe pod -n prod -l app=svelte-rooms
kubectl logs -n prod -l app=svelte-rooms --tail=100
kubectl logs -n prod -l app=svelte-rooms --previous --tail=100  # if pod restarted
```

Check Jaeger for trace-level errors (if pod is still up):
```bash
kubectl port-forward svc/jaeger-query -n observability 16686:16686
# Browse to http://localhost:16686, filter by http.status_code=500
```

### 4. Rollback if needed

If the incident followed a recent deploy and the root cause is the new version:
1. Go to Actions > **rollback.yml** > Run workflow
2. Select environment and target revision
3. See [rollback.md](rollback.md) for full procedure and DB migration caveats

Manual rollback:
```bash
helm history svelte-rooms -n prod
helm rollback svelte-rooms <revision> -n prod --wait
```

### 5. Resolve and post-mortem

After resolution:
1. Update the GitHub issue with resolved time, root cause, timeline, and actions taken
2. Add follow-up action items as checkboxes in the issue
3. For SEV1/SEV2: create follow-up issues for each preventive action
4. Close the incident issue once all follow-up items are tracked

## Alert-specific response

| Alert | First action |
|---|---|
| AppDown | `kubectl get pods -n prod -l app=svelte-rooms` — check if pods exist and are Running |
| High5xxRate | Check CloudWatch for error messages, check recent deploy history |
| HighP95Latency | Check DB connection count, check for slow queries in CloudWatch |
| PodRestartLoop | `kubectl logs -n prod -l app=svelte-rooms --previous` — check for OOM or crash |
