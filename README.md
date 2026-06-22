# Svelte Rooms

> A room reservation system with a full 21-stage DevSecOps CI/CD pipeline on AWS EKS.

![CI](https://github.com/Eniadebisi/Svelte-rooms/actions/workflows/01_code-commit.yml/badge.svg?branch=dev)
![License](https://img.shields.io/badge/license-MIT-blue)
![Node](https://img.shields.io/badge/node-22.x-brightgreen)
![Terraform](https://img.shields.io/badge/terraform-1.10-7B42BC)
![Svelte](https://img.shields.io/badge/svelte-4-FF3E00)
![EKS](https://img.shields.io/badge/AWS-EKS-FF9900)

---

## What is this?

A full-stack room booking application used as a real-world platform for practising DevSecOps. The app handles authenticated reservations, role-based access control, and email notifications. The infrastructure and pipeline are the primary learning surface.

**App:** SvelteKit · Prisma 7 · MariaDB · Bootstrap 5  
**Pipeline:** GitHub Actions · Docker · ECR · Helm · EKS Fargate  
**IaC:** Terraform · AWS VPC · RDS · fck-nat · SSM  

---

## CI/CD Pipeline — 21 Stages

```
push dev
   │
   ▼
┌─────────────────────────────────────────────────────────┐
│  01. Code Commit       push to dev branch               │
│  02. PR Validation     PR opened to any branch          │
└─────────────────────────────────────────────────────────┘
   │ merge dev → qa (auto PR)
   ▼
┌─────────────────────────────────────────────────────────┐
│  03-13. QA Pipeline    push to qa branch                │
│                                                         │
│   03. Unit Testing         npm test (vitest)            │
│   04. SAST Scan            ESLint / static analysis     │
│   05. Dependency Scan      npm audit                    │
│   06. Secret Detection     Gitleaks                     │
│   07. Terraform Validation tf validate (global+platform)│
│   08. Checkov Scan         Helm lint / config check     │
│   09. Container Build      docker build                 │
│   10. Container Scan       Trivy image scan             │
│   11. Push to ECR          docker push                  │
│   12. Deploy to QA         helm upgrade --install       │
│   13. Integration Testing  container health check       │
└─────────────────────────────────────────────────────────┘
   │ approval gate: auto PR qa → main opened
   ▼
┌─────────────────────────────────────────────────────────┐
│  14-20. Production Pipeline   push to main              │
│                                                         │
│   15. Approval Gate        manual PR merge required     │
│   19. Production Deploy    retag ECR + helm upgrade     │
│   20. Post-Deploy          GitHub Release created       │
└─────────────────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────────────────┐
│  21. Rollback Automation   manual workflow_dispatch      │
└─────────────────────────────────────────────────────────┘
```

### Workflow Files

| File | Trigger | Stage |
|------|---------|-------|
| [`01_code-commit.yml`](.github/workflows/01_code-commit.yml) | push → `dev` | 1 |
| [`02_pr-validation.yml`](.github/workflows/02_pr-validation.yml) | PR opened | 2 |
| [`03-13_qa-pipeline.yml`](.github/workflows/03-13_qa-pipeline.yml) | push → `qa` | 3–13 |
| [`14-20_prod-pipeline.yml`](.github/workflows/14-20_prod-pipeline.yml) | push → `main` | 14–20 |
| [`20_post-deploy-validation.yml`](.github/workflows/20_post-deploy-validation.yml) | weekly cron | 20 |
| [`21_rollback-automation.yml`](.github/workflows/21_rollback-automation.yml) | manual | 21 |
| [`_03-08_validate.yml`](.github/workflows/_03-08_validate.yml) | reusable | 3–8 |
| [`_09-11_build.yml`](.github/workflows/_09-11_build.yml) | reusable | 9–11 |
| [`_13_integration-test.yml`](.github/workflows/_13_integration-test.yml) | reusable | 13 |
| [`_deploy-eks.yml`](.github/workflows/_deploy-eks.yml) | reusable | 12 / 16 / 19 |

---

## Architecture

### Branching Strategy

```text
feature/* ──► dev ──► qa ──► main
                │      │       │
             (auto)  (auto)  (manual
              PR      PR     approval)
```

### AWS Infrastructure

```
AWS Account
│
├── Global Stack  (terraform/global)
│     ├── VPC — 2 public + 2 private subnets
│     ├── fck-nat — t4g.nano NAT instance (~$4/mo vs $32 NAT Gateway)
│     ├── ECR — Docker image registry
│     ├── S3 — Terraform remote state
│     └── IAM — OIDC provider + gha-deploy role (GitHub Actions → AWS, no static keys)
│
└── Platform Stack  (terraform/platform)
      ├── EKS Fargate cluster  (Kubernetes 1.31, no EC2 nodes)
      │     ├── Fargate profile: kube-system  (CoreDNS, kube-proxy, vpc-cni)
      │     └── Fargate profile: apps  (dev / qa / prod / observability)
      ├── RDS MariaDB — encrypted, final snapshot on destroy
      ├── SSM Parameter Store — runtime secrets per environment
      └── Observability  (observability namespace)
            ├── Prometheus
            └── Jaeger
```

> **Cost design:** EKS control plane costs ~$0.10/hr. [`infra-down.yml`](.github/workflows/infra-down.yml) runs a nightly `terraform destroy` at 2am UTC. [`infra-up.yml`](.github/workflows/infra-up.yml) re-provisions on demand before deploys.

### Application

```
Browser
  └── SvelteKit (SSR + server routes)
        ├── hooks.server.ts        JWT validation on every request
        ├── routes/
        │     ├── (authenticated)/           JWT required
        │     └── (authenticated)/(admin)/   Admin/Owner role only
        └── lib/server/
              ├── db.ts            PrismaClient with MariaDB adapter
              ├── user.model.js    User queries
              └── rooms.model.js   Room queries
```

---

## Tech Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Frontend | Svelte / SvelteKit | 4 / 2.x |
| Build | Vite | 5.4 |
| ORM | Prisma ESM client | 7.3 |
| Database | MariaDB (`@prisma/adapter-mariadb`) | — |
| Auth | JWT + bcrypt | — |
| Email | Nodemailer | 9.x |
| Styling | Bootstrap 5 + SCSS | 5.3 |
| Testing | Vitest | 4.x |
| Container | Docker / AWS ECR | — |
| Orchestration | EKS Fargate + Helm | K8s 1.31 |
| IaC | Terraform | 1.10 |
| Observability | OpenTelemetry + Prometheus + Jaeger | — |
| CI/CD | GitHub Actions (OIDC → AWS) | — |

---

## Local Development

### Prerequisites

- Node.js 22.x
- Docker Desktop
- MariaDB or MySQL

### Setup

```bash
git clone https://github.com/Eniadebisi/Svelte-rooms.git
cd Svelte-rooms

npm install
npx prisma generate
npx prisma migrate dev
npm run dev
```

Create `.env` at repo root (never commit):

```env
DATABASE_URL=mysql://user:pass@localhost:3306/svelte_rooms
JWT_ACCESS_SECRET=your-local-secret
AUTH_EMAIL=your@email.com
AUTH_EMAIL_PW=your-email-password
```

### Run tests

```bash
npm test
```

### Build Docker image locally

```bash
docker build -t svelte-rooms .
docker run -p 3000:3000 -e NODE_ENV=production svelte-rooms
```

---

## Infrastructure

### GitHub Secrets Required

| Secret | Purpose |
|--------|---------|
| `GHA_DEPLOY_ROLE_ARN` | OIDC role ARN — no static AWS keys needed |
| `AWS_REGION` | e.g. `us-east-1` |
| `ECR_REPOSITORY` | Short ECR repo name |

### Provision Infrastructure (local only)

```bash
# One-time global resources (VPC, ECR, IAM OIDC)
terraform -chdir=terraform/global init
terraform -chdir=terraform/global apply

# Per-deploy platform resources (EKS, RDS, SSM)
terraform -chdir=terraform/platform init
terraform -chdir=terraform/platform apply
```

> `terraform apply` is intentionally not in the pipeline — run it locally before triggering a deploy.

---

## User Roles

| Role | User Mgmt | Space Mgmt | Reservations | Admin UI |
|------|-----------|------------|--------------|----------|
| Owner | Full | Full | Full | ✅ |
| Admin | Assign roles | CRUD | View all / delete | ✅ |
| User | — | — | Own only | — |
| Guest | — | — | View own | — |
| Restricted | No access | — | — | — |

See [`src/lib/permissions/auth.ts`](src/lib/permissions/auth.ts) for enforcement.

---

## Security Controls

| Control | Tool | Pipeline Stage |
|---------|------|----------------|
| SAST | ESLint / static analysis | 04 |
| Dependency scan | npm audit | 05 |
| Secret detection | Gitleaks | 06 |
| IaC misconfiguration | Trivy config + Helm lint | 07–08 |
| Container vulnerabilities | Trivy image scan | 10 |
| Secrets at rest | AWS SSM Parameter Store | runtime |
| AWS authentication | OIDC federation (no static keys) | all stages |

---

## License

MIT
