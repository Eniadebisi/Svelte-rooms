# Rollback Runbook

## Option 1 — Rollback via GitHub Actions (preferred)

1. Go to Actions > **rollback.yml**
2. Click **Run workflow**
3. Select the target environment (`dev`, `qa`, or `prod`) and the Helm revision to roll back to
4. Click **Run workflow**

The workflow runs `helm rollback` with `--wait` and reports success or failure in the Actions log.

## Option 2 — Manual Helm rollback

Set your kubectl context first:
```bash
aws eks update-kubeconfig --name svelte-rooms --region $AWS_REGION
```

View Helm release history to find the revision to roll back to:
```bash
helm history svelte-rooms -n <env>
```

Example output:
```
REVISION  UPDATED                   STATUS     CHART                APP VERSION  DESCRIPTION
1         2026-06-01 12:00:00 UTC   superseded svelte-rooms-1.0.0   1.0.0        Install complete
2         2026-06-10 09:15:00 UTC   deployed   svelte-rooms-1.1.0   1.1.0        Upgrade complete
```

Roll back to a specific revision:
```bash
helm rollback svelte-rooms <revision> -n <env> --wait
```

Example — roll back prod to revision 1:
```bash
helm rollback svelte-rooms 1 -n prod --wait
```

Verify the rollback:
```bash
kubectl rollout status deployment/svelte-rooms -n <env> --timeout=120s
kubectl get pods -n <env> -l app=svelte-rooms
```

## Important: Database migrations are forward-only

Helm rollback reverts Kubernetes manifests (Deployment, Service, ConfigMap, Secret) to the previous state. It does **not** reverse Prisma database migrations.

- Prisma migrations are forward-only by design.
- If the new code version introduced a breaking DB schema change, a Helm rollback will result in the old app code running against the new schema.
- In that case, a forward-fix deploy (new commit that fixes the issue) is safer than a rollback.

**When rollback is safe:** no DB schema changes in the failing release (image-only or config-only change).

**When rollback is risky:** the failing release added or modified DB columns/tables. Assess before rolling back.
