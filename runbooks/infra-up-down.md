# Infrastructure Up/Down Guide

Use this guide on demo day or when you need the environment running.

## Demo day procedure

### 1. Spin up infrastructure (~10 min)

**Via GitHub Actions:**
1. Go to Actions > **infra-up.yml**
2. Click **Run workflow** > **Run workflow**
3. Monitor the run — EKS + Fargate profiles take ~10 minutes

**Via CLI:**
```bash
cd terraform
terraform init
terraform apply -auto-approve
aws eks update-kubeconfig --name svelte-rooms --region $AWS_REGION
```

Verify:
```bash
aws eks describe-cluster --name svelte-rooms --region $AWS_REGION --query 'cluster.status'
# Expected: "ACTIVE"
```

### 2. Deploy applications (once cluster is green)

**Via GitHub Actions:**
- Actions > **deploy-qa.yml** > Run workflow
- Actions > **deploy-prod.yml** > Run workflow (requires prod approval)

**Via CLI:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --name svelte-rooms --region $AWS_REGION

# Deploy app to qa
helm upgrade --install svelte-rooms ./helm/svelte-rooms \
  -n qa \
  -f helm/svelte-rooms/values-qa.yaml \
  --create-namespace \
  --wait

# Deploy app to prod
helm upgrade --install svelte-rooms ./helm/svelte-rooms \
  -n prod \
  -f helm/svelte-rooms/values-prod.yaml \
  --create-namespace \
  --wait

# Deploy observability stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

helm upgrade --install prometheus prometheus-community/prometheus \
  -n observability \
  -f monitoring/prometheus-values.yaml \
  --create-namespace \
  --wait

helm upgrade --install jaeger jaegertracing/jaeger \
  -n observability \
  -f monitoring/jaeger-values.yaml \
  --wait
```

### 3. Port-forward UIs

Open separate terminal tabs for each:

```bash
# Application (prod)
kubectl port-forward svc/svelte-rooms 3000:80 -n prod

# Application (qa)
kubectl port-forward svc/svelte-rooms 3001:80 -n qa

# Prometheus
kubectl port-forward svc/prometheus-server -n observability 9090:80

# Jaeger
kubectl port-forward svc/jaeger-query -n observability 16686:16686
```

Or use the Makefile:
```bash
make pf-app        # port-forward app on :3000
make pf-prometheus # port-forward Prometheus on :9090
make pf-jaeger     # port-forward Jaeger on :16686
```

URLs:
- App: http://localhost:3000
- Prometheus: http://localhost:9090
- Jaeger: http://localhost:16686

### 4. Spin down when done (~5 min)

**Via GitHub Actions:**
1. Go to Actions > **infra-down.yml**
2. Click **Run workflow** > **Run workflow**

**Via CLI:**
```bash
cd terraform
terraform destroy -auto-approve
```

The nightly cron at **2:00 AM UTC** also triggers infra-down automatically, so you don't need to remember to do this after a late demo.

## What is retained after spin-down

- RDS snapshot: `cicd-gh-action-test-mysql-final` (auto-created on destroy)
- ECR images (all tags, immutable)
- SSM parameters (all secrets intact)
- Terraform state (S3, versioned)
- CloudWatch logs (durable, no expiry by default)
- Git history and GitHub Actions logs

## Cost reference

- **While down:** ~$14/month (RDS snapshot storage + ECR + S3)
- **While up:** ~$103-113/month
- **Savings per idle day:** ~$3
