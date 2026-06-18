# Secret Rotation Runbook

All application secrets are stored as SSM SecureString parameters under the prefix `/cicd-gh-action-test/`.
The deploy workflow reads these at deploy time and injects them as Kubernetes Secrets. There are no static secrets in the repo or in GitHub Actions secrets for application config.

## Rotation procedure

### Step 1 — Update the SSM parameter

```bash
aws ssm put-parameter \
  --name /cicd-gh-action-test/<param-name> \
  --value "NEW_VALUE" \
  --type SecureString \
  --overwrite \
  --region $AWS_REGION
```

### Step 2 — Trigger redeployment

Re-run the deploy workflow for the target environment. The workflow re-reads SSM on every run.

- **dev:** Actions > Deploy to EKS (dev) > Run workflow
- **qa:** Actions > deploy-qa.yml > Run workflow
- **prod:** Actions > deploy-prod.yml > Run workflow (requires prod environment approval)

### Step 3 — Verify

Check pod logs for authentication errors after the new pod starts:
```bash
kubectl logs -n <env> -l app=svelte-rooms --tail=50
```

Check CloudWatch for any auth-related errors:
```
fields @timestamp, @message
| filter @message like /(?i)(auth|credentials|password|forbidden|unauthorized)/
| sort @timestamp desc
| limit 20
```

Hit the health endpoint to confirm the app is up:
```bash
kubectl port-forward svc/svelte-rooms 3000:80 -n <env>
curl http://localhost:3000/health
```

## SSM parameter inventory

| Parameter name | Purpose | Rotation trigger |
|---|---|---|
| `/cicd-gh-action-test/db-password` | RDS MySQL database password | If DB credentials are compromised or per policy |
| `/cicd-gh-action-test/db-host` | RDS endpoint hostname | After cluster rebuild if RDS endpoint changes |
| `/cicd-gh-action-test/db-name` | Database name | Rarely changes |
| `/cicd-gh-action-test/db-user` | Database username | If DB user credentials are rotated |
| `/cicd-gh-action-test/session-secret` | Express session signing secret | If session token compromise suspected |
| `/cicd-gh-action-test/jwt-secret` | JWT signing secret (if used) | If JWT compromise suspected |

> Note: Update this table if new parameters are added in `terraform/modules/secrets`.

## GitHub OIDC (GHA_DEPLOY_ROLE_ARN)

The GitHub Actions deploy role uses OIDC — there are no static AWS access keys to rotate. If the IAM role or OIDC trust policy needs to change, update the Terraform in `terraform/modules/iam-oidc` and apply.

If `GHA_DEPLOY_ROLE_ARN` or `AWS_REGION` in GitHub repository secrets need updating:
1. Go to GitHub repo > Settings > Secrets and variables > Actions
2. Update the secret value
3. Re-run the affected workflow to pick up the new value
