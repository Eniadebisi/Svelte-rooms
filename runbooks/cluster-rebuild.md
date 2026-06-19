# Cluster Rebuild Runbook (destroy-when-idle)

The EKS cluster is torn down when not in use to save cost. This runbook covers the full spin-up and spin-down cycle.

## Spin up

### Via GitHub Actions (preferred)

1. Go to Actions > **infra-up.yml**
2. Click **Run workflow** > **Run workflow**
3. Wait approximately 10 minutes for EKS + Fargate profiles to provision

### Via CLI

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

### Verify the cluster is up

```bash
aws eks describe-cluster --name svelte-rooms --region $AWS_REGION
```

Expected: `"status": "ACTIVE"`

Update your local kubeconfig:
```bash
aws eks update-kubeconfig --name svelte-rooms --region $AWS_REGION
kubectl get nodes  # Fargate: no nodes listed, this is expected
kubectl get namespaces
```

### Redeploy applications after cluster rebuild

The cluster comes up empty — all Helm releases must be redeployed:

```bash
# Re-run via GitHub Actions:
# Actions > deploy-qa.yml > Run workflow
# Actions > deploy-prod.yml > Run workflow (requires approval)

# Or manually:
aws eks update-kubeconfig --name svelte-rooms --region $AWS_REGION
helm upgrade --install svelte-rooms ./helm/svelte-rooms -n qa -f helm/svelte-rooms/values-qa.yaml --create-namespace --wait
helm upgrade --install svelte-rooms ./helm/svelte-rooms -n prod -f helm/svelte-rooms/values-prod.yaml --create-namespace --wait
```

Redeploy observability stack:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

helm upgrade --install prometheus prometheus-community/prometheus \
  -n observability -f monitoring/prometheus-values.yaml --create-namespace --wait

helm upgrade --install jaeger jaegertracing/jaeger \
  -n observability -f monitoring/jaeger-values.yaml --wait
```

### Access UIs after rebuild

```bash
# Prometheus
kubectl port-forward svc/prometheus-server -n observability 9090:80

# Jaeger
kubectl port-forward svc/jaeger-query -n observability 16686:16686
```

## Spin down

### Via GitHub Actions (preferred)

1. Go to Actions > **infra-down.yml**
2. Click **Run workflow** > **Run workflow**

The nightly cron also triggers infra-down at 2:00 AM UTC automatically.

### Via CLI

```bash
cd terraform
terraform destroy -auto-approve
```

### What happens during destroy

- EKS cluster and all Fargate pods are deleted
- RDS final snapshot is automatically created and retained: `cicd-gh-action-test-mysql-final`
- ECR images remain (immutable tags are not deleted)
- SSM parameters remain
- Terraform state in S3 remains (versioned)
- CloudWatch log groups and logs remain (durable)

## Cost while cluster is down

| Resource | Monthly cost |
|---|---|
| RDS db.t3.micro (stopped or retained snapshot) | ~$8-12 |
| ECR image storage | ~$1-2 |
| S3 (Terraform state) | <$1 |
| CloudWatch logs | <$1 |
| **Total while down** | **~$14/month** |

## Cost while cluster is up

| Resource | Monthly cost |
|---|---|
| EKS control plane | $73 |
| Fargate compute (app pods) | ~$10-20 |
| RDS db.t3.micro | ~$15 |
| Everything else | ~$5 |
| **Total while up** | **~$103-113/month** |

Keeping the cluster down when not demoing saves approximately $90/month.
