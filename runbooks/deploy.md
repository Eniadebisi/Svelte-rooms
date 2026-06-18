# Deploy Runbook

## Prerequisites

- EKS cluster `svelte-rooms` is running: `aws eks describe-cluster --name svelte-rooms --region $AWS_REGION`
- AWS credentials available (GitHub Actions uses OIDC; local use requires `aws sso login` or equivalent)
- `kubectl` context set: `aws eks update-kubeconfig --name svelte-rooms --region $AWS_REGION`

## Deploying via GitHub Actions (preferred)

### Deploy to dev

Triggered automatically on every push to the `dev` branch via `_deploy-eks.yml`.

To trigger manually:
1. Go to Actions > Deploy to EKS (dev)
2. Click **Run workflow** > select branch `dev` > **Run workflow**

### Deploy to QA

1. Go to Actions > **deploy-qa.yml**
2. Click **Run workflow** > **Run workflow**
3. A semver tag is created automatically by the `gittag` job if tests pass.

### Deploy to prod

1. Go to Actions > **deploy-prod.yml**
2. Click **Run workflow** > **Run workflow**
3. Approval required from the `prod` GitHub environment before the deploy job runs.

## Verifying a deployment

Check rollout status:
```bash
kubectl rollout status deployment/svelte-rooms -n <env> --timeout=120s
```

Check running pods:
```bash
kubectl get pods -n <env> -l app=svelte-rooms
```

Check pod events (useful if pods are crashing):
```bash
kubectl describe pod -n <env> -l app=svelte-rooms
```

Hit the health endpoint (requires port-forward or cluster access):
```bash
kubectl port-forward svc/svelte-rooms 3000:80 -n <env>
curl http://localhost:3000/health
```

## Checking logs in CloudWatch

**AWS Console:** CloudWatch > Log groups > `/eks/svelte-rooms/<env>`

**AWS CLI:**
```bash
# List log streams for an environment
aws logs describe-log-streams \
  --log-group-name /eks/svelte-rooms/prod \
  --order-by LastEventTime \
  --descending \
  --max-items 5

# Tail recent log events from a specific stream
aws logs get-log-events \
  --log-group-name /eks/svelte-rooms/prod \
  --log-stream-name <stream-name> \
  --limit 50
```

**Logs Insights query (last 30 min errors):**
```
fields @timestamp, @message
| filter @message like /(?i)error/
| sort @timestamp desc
| limit 20
```

## SSM parameters are re-read on every deploy

The deploy workflow reads all `/cicd-gh-action-test/*` SSM SecureString parameters at deploy time and injects them as Kubernetes Secrets. No pod restart is required after updating SSM — re-running the deploy workflow is sufficient.
