# Svelte Rooms

**Svelte Rooms** is a full-stack room reservation system that demonstrates enterprise-grade patterns in authentication, authorization, database design, and security scanning within a containerized AWS deployment. The project showcases a production-ready CI/CD pipeline with comprehensive security gates and infrastructure-as-code best practices.
** Note that AI was used extensively for commenting, readmes and documentation to improve reusability and understanding of code.

## Architecture

### Project Overview

* **Security-first CI/CD:** Every change is gate-checked for code vulnerabilities, image security, and infrastructure compliance.
* **Build-once promotion:** A single Docker image flows through dev → qa → prod without rebuilds.
* **Infrastructure-as-code:** Terraform-managed AWS resources with manual control over production changes.
* **Role-based access control:** Five-tier permission system with granular authorization checks.
* **Encrypted secrets management:** No plaintext credentials in logs, images, or code.

### Design Principles

| Principle | Implementation |
|---|---|
| **Fail fast** | Security gates run early (SAST, Trivy pre-push); failures block the pipeline. |
| **Immutability** | Docker images tagged by commit SHA; ECR immutability enabled. |
| **Single source of truth** | Git commits → images → Terraform state; no manual image tags. |
| **Audit trail** | Intentional decisions logged (`.trivyignore`); all changes reviewable in GitHub. |
| **Least privilege** | Five-tier RBAC; IAM roles grant the minimum needed permissions. |
| **Manual control on risk** | Terraform apply requires a human operator; prod changes require approval. |

## Architecture & Design

### High-Level Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│                          GitHub & CI/CD                         │
│                         (GitHub Actions)                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │     SAST     │  │  Image Scan  │  │  IaC Policy  │           │
│  │  (Semgrep)   │  │   (Trivy)    │  │   (Trivy)    │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│        │                  │                 │                   │
│        └──────────────────┴─────────────────┘                   │
│                           │                                     │
│                   ┌─────────────────┐                           │
│                   │   Build & Push  │                           │
│                   │  (Docker/ECR)   │                           │
│                   └─────────────────┘                           │
└─────────────────────────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
        ┌───────────────┐       ┌───────────────┐
        │ ECR Registry  │       │  State Store  │
        │  (immutable)  │       │  (S3 + lock)  │
        └───────────────┘       └───────────────┘
                │                       │
        ┌───────┴─────────┐             │
        │                 │             │
   ┌─────────┐    ┌──────────────┐      │
   │  Deploy │    │  Terraform   │◄─────┘
   │  (ECS)  │    │    (IaC)     │
   └────┬────┘    └──────────────┘
        │
    ┌───┴──────────────────┬──────────┐
    │                      │          │
┌──────────┐      ┌──────────────┐  ┌───────┐
│   Dev    │      │      QA      │  │ Prod  │
│ Cluster  │      │   Cluster    │  │Cluster│
└──────────┘      └──────────────┘  └───────┘
(FARGATE_SPOT)     (FARGATE_SPOT)   (FARGATE)
```

### Application Architecture

**Svelte Rooms** follows a modern full-stack pattern:

```text
┌─────────────────────────────────────────────────────────────┐
│                 Frontend (Svelte/SvelteKit)                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Pages (authentication, reservations, admin panel)    │   │
│  │ Forms, real-time updates, Bootstrap 5 UI             │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                  (Server-side rendering)
                            │
┌─────────────────────────────────────────────────────────────┐
│                 Backend (SvelteKit Server)                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Hooks (JWT validation, session checks)               │   │
│  │ API routes (reservations, users, spaces)             │   │
│  │ Authentication (bcrypt, JWT, role-based access)      │   │
│  │ Email notifications (Nodemailer)                     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                       (Prisma ORM)
                            │
┌─────────────────────────────────────────────────────────────┐
│                     Database (MariaDB)                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Users, Spaces, Reservations, Roles                   │   │
│  │ Connection pooling (optimized for shared hosting)    │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Authentication & Authorization Flow

1. **Login:** User submits credentials → bcrypt verification → JWT token issued.
2. **Session:** JWT stored in HTTP-only cookie (SvelteKit `cookies`).
3. **Protection:** `hooks.server.ts` validates JWT on every request.
4. **Authorization:** Role-based access control (RBAC) checked per route/API.

**Five-tier role hierarchy:**
* **Owner:** Full system access (user management, space management, all reservations).
* **Admin:** User role assignment, space CRUD, view/delete all reservations.
* **User:** Create/view/delete own reservations.
* **Guest:** View own reservations (read-only).
* **Restricted:** No access.

> **Note:** See `src/lib/permissions/auth.ts` for enforcement logic.

### Data Model

**Core entities:**
* **User:** Authentication identity, role, email, password hash.
* **Space:** Rooms/areas available for reservation.
* **Reservation:** Booking entry (date, time, space, user, recurring pattern via rrule).
* **Role:** RBAC definition (Owner, Admin, User, Guest, Restricted).

Prisma schema enforces relationships and constraints. MariaDB handles persistence and connection pooling.

## Technologies & Stack

### Frontend

| Component | Technology | Version | Purpose |
|---|---|---|---|
| Framework | Svelte | 4.2.7 | Reactive components, minimal runtime |
| Meta-framework | SvelteKit | 2.50.1 | SSR, routing, form handling |
| Build tool | Vite | 5.4.6 | ESM-native bundling |
| Styling | Bootstrap 5 + SCSS | 5.3.3 | Component library + custom styles |
| Type safety | TypeScript | 5.0.0 | Full static typing |

### Backend

| Component | Technology | Version | Purpose |
|---|---|---|---|
| Runtime | Node.js | 20.x | JavaScript server environment |
| ORM | Prisma | 7.3.0 | Type-safe database access, ESM client |
| DB adapter | @prisma/adapter-mariadb | 7.3.0 | MariaDB native connection pooling |
| DB driver | mysql2 | 3.16.1 | MySQL protocol implementation |
| Auth | jsonwebtoken + bcrypt | 6.0.0 | JWT sessions, password hashing |
| Email | Nodemailer | 7.0.12 | SMTP-based email notifications |
| Utilities | Day.js + rrule | N/A | Date handling, recurring patterns |
| Testing | Vitest | 4.0.18 | Unit tests, ESM-native |

### Infrastructure & Deployment

| Component | Technology | Purpose |
|---|---|---|
| Container orchestration | AWS ECS Fargate | Serverless container management |
| Container registry | AWS ECR | Docker image repository with immutability |
| Container image | Docker (node:20-alpine) | Multi-stage build, minimal footprint |
| CI/CD | GitHub Actions | Workflow orchestration, reusable workflows |
| Infrastructure-as-code | Terraform 1.10.0 | AWS resource provisioning |
| State management | S3 + lockfile | Terraform state backend with locking |
| Secrets at rest | AWS SSM Parameter Store | Encrypted secure string storage |
| Logging | AWS CloudWatch | Application and infrastructure logs |
| Monitoring | CloudWatch alarms | Task count and service health checks |
| Load balancer | (Fargate public IP) | Direct public IP for testing (not production-grade) |

### Security Tooling

| Tool | Purpose | Stage |
|---|---|---|
| Semgrep | SAST — scan application code for vulnerabilities | Pre-build |
| Trivy | Image scanning (secrets + CVE), IaC compliance | Pre-push + scheduled |
| Gitleaks | Secrets scanning (hardcoded credentials) | Pre-build + scheduled |
| npm audit | Dependency vulnerability scanning | Pre-build |
| Docker BuildKit | Secrets handling in build (no plaintext in image) | Build |

## Security Implementation

### Security Architecture

#### 1. Secrets Management (At Rest)
* Database credentials, JWT secret, and email passwords are stored in **AWS SSM Parameter Store** as `SecureString` type.
* Encryption via AWS-managed KMS key (`aws/ssm`, no extra cost).
* Task execution role is granted `ssm:GetParameters` and `kms:Decrypt` permissions.
* ECS task fetches credentials at startup and injects them as container environment variables (decrypted in memory only).

#### 2. Image Security (Pre-Push)
* Build image locally → **Trivy scans** (vulnerabilities + secrets) → if clean, push to ECR → if fails, pipeline stops.
* Trivy is configured to fail on HIGH/CRITICAL severity (exit-code: 1).
* `.trivyignore` documents intentional findings (e.g., unrestricted egress for Fargate networking).

#### 3. Code Quality & Vulnerability Detection (SAST)
* **Semgrep** (`p/default` ruleset) scans JavaScript/TypeScript for XSS, SQL injection, and insecure patterns.
* Runs in `_validate.yml` as a parallel job (prevents pipeline bottlenecks).
* Fails pipeline on high-confidence security findings.

#### 4. Infrastructure Security (IaC Policy)
* **Trivy config scan** validates Terraform against CIS benchmarks.
* Checks: IAM least-privilege, security groups, encryption, resource limits.
* Runs in `_validate.yml` before `terraform init`.
* *Niche detail: Can be escalated to **Checkov** for stronger, customized policy packs.*
* **Result:** Misconfigurations caught before apply.

#### 5. Secrets Scanning
* **Gitleaks** scans commit history for patterns (AWS keys, private keys, database passwords).
* Runs on every push and via weekly scheduled scans.
* Results uploaded to GitHub's Security tab (if Advanced Security is enabled).
* **Result:** Accidental commits blocked before reaching the main branch.

#### 6. Application Authentication
* JWT-based session tokens leverage HTTP-only cookies and the secure flag.
* bcrypt password hashing (cost factor 10).
* Role-based access control (5-tier hierarchy).
* `hooks.server.ts` validates JWT on every request.
* Protected routes (`(authenticated)`) require a valid token.
* Admin routes (`(authenticated)/(admin)`) require Owner/Admin roles.

## CI/CD Pipeline

This project uses a reusable multi-environment GitHub Actions pipeline deploying to AWS ECS Fargate via Docker and ECR.

### Branching Strategy

```text
feature/* ──► dev ──► qa ──► main
               │       │       │
             dev      qa      prod
           cluster  cluster cluster
```

* **`feature/*`** — Cut from `dev`, opened as PR back to `dev`.
* **`dev`** — Auto-deploys to dev ECS cluster on every merge.
* **`qa`** — Auto-deploys to qa ECS cluster on every merge.
* **`main`** — Deploys to prod ECS cluster after required reviewer approval.

### Pipeline Flow

```text
1. Developer cuts feature branch off dev
        │
2. PR opened → dev (code review)
        │
3. Merge to dev triggers build.yml
   - Authenticates to AWS via access token
   - Runs: npm ci → npx prisma generate → npm run build
   - Builds Docker image with build-time env vars
   - Tags image as dev-<git-sha> and dev-latest
   - Pushes to ECR
        │
4. deploy-dev.yml triggers automatically
   - Downloads current ECS task definition
   - Swaps image tag to dev-<git-sha>
   - Registers new task definition revision
   - Updates ECS dev service
   - Waits for stability (ECS circuit breaker auto-rolls back on failure)
        │
5. PR: dev → qa (tested in dev first)
   - Merge triggers deploy-qa.yml automatically
   - Same image SHA promoted — no rebuild
        │
6. PR: qa → main
   - GitHub Environment approval gate pauses workflow
   - Required reviewer approves in GitHub UI
   - Deploys to prod — zero-downtime (new task starts before old stops)
```

### Rollback Strategy

Manual trigger via `rollback.yml` in the Actions tab:
1. Select environment (dev / qa / prod).
2. Optionally specify a task definition revision number.
3. Leave blank to automatically roll back to revision N-1.
4. ECS circuit breaker independently handles auto-rollback on failed deployments.

### CI/CD Stage Breakdown

```text
Dev Branch Push
    ↓
┌─────────────────────────────────────┐
│ 1. VALIDATE (runs on every push)    │
├─────────────────────────────────────┤
│ ✓ Lint & format (Prettier, ESLint)  │
│ ✓ SAST (Semgrep code analysis)      │
│ ✓ Secrets scan (Gitleaks)           │
│ ✓ Dependency audit (npm audit)      │
│ ✓ Terraform validate & format check │
│ ✓ IaC compliance (Trivy config)     │
│ ✓ Prisma schema validation          │
└─────────────────────────────────────┘
    ↓ (fail on high severity findings)
┌─────────────────────────────────────┐
│ 2. BUILD (Docker image)             │
├─────────────────────────────────────┤
│ ✓ Multi-stage build (node:20-alpine)│
│ ✓ Image tag: env-{commit_sha:7}     │
│ ✓ Push to ECR (immutable tags)      │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 3. SCAN (Trivy pre-push)            │
├─────────────────────────────────────┤
│ ✓ Container image (vuln + secret)   │
│ ✓ Exit on CRITICAL/HIGH             │
└─────────────────────────────────────┘
    ↓ (only clean images in ECR)
┌─────────────────────────────────────┐
│ 4. DEPLOY DEV                       │
├─────────────────────────────────────┤
│ ✓ Update ECS task def (new image)   │
│ ✓ Deploy to dev cluster (Fargate)   │
│ ✓ Health check (wait for stability) │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 5. PROMOTE QA (GitHub PR)           │
├─────────────────────────────────────┤
│ ✓ Auto-create PR: dev → qa branch   │
│ ✓ Await manual approval             │
└─────────────────────────────────────┘
    ↓ (manual merge in GitHub)
┌─────────────────────────────────────┐
│ 6. VALIDATE & BUILD (qa push)       │
├─────────────────────────────────────┤
│ ✓ Same as step 1 (re-validate)      │
│ ✓ Build image (same SHA as dev)     │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 7. TEST (QA Cluster)                │
├─────────────────────────────────────┤
│ ✓ Run unit tests                    │
│ ✓ Container health check (HTTP)     │
│ ✓ Deploy to qa cluster              │
└─────────────────────────────────────┘
    ↓ (after all tests pass)
┌─────────────────────────────────────┐
│ 8. TAG (Git semantic version)       │
├─────────────────────────────────────┤
│ ✓ Commit message → semver bump      │
│   - breaking/feat! → major          │
│   - feat → minor                    │
│   - else → patch                    │
│ ✓ Tag: v{major}.{minor}.{patch}     │
│ ✓ Push to main (implicit)           │
└─────────────────────────────────────┘
    ↓ (tag push triggers prod workflow)
┌─────────────────────────────────────┐
│ 9. PROMOTE PROD (GitHub PR)         │
├─────────────────────────────────────┤
│ ✓ Auto-create PR: qa → main         │
│ ✓ Await manual approval             │
└─────────────────────────────────────┘
    ↓ (manual merge in GitHub)
┌─────────────────────────────────────┐
│ 10. RETAG & DEPLOY PROD             │
├─────────────────────────────────────┤
│ ✓ Pull qa image (same SHA)          │
│ ✓ Retag as prod-{version}           │
│ ✓ Push to ECR                       │
│ ✓ Deploy to prod cluster (FARGATE)  │
│ ✓ Create GitHub Release             │
└─────────────────────────────────────┘
```

### Key Pipeline Decisions

| Decision | Rationale |
|---|---|
| **Build once** | Same image moves from dev → qa → prod; no re-builds per env. Reduces risk of configuration drift. |
| **SHA-based tags** | `dev-{sha:7}`, `qa-{sha:7}`, `prod-v1.2.3` — guarantees uniqueness, easy to trace back to commits. |
| **No `-latest` tag** | Prevents accidental overwrites; immutability enforced natively by ECR. |
| **Manual terraform apply** | Full control retained over infrastructure changes; CI only runs `plan` and posts output. |
| **Pre-push image scan** | Trivy runs before `docker push`; ECR never contains vulnerable images. |
| **Parallel SAST job** | Semgrep runs in parallel with other validation steps; doesn't block independent checks. |
| **Semver on success only** | Git tags created only after full test suite passes; avoids tagging broken commits. |
| **FARGATE_SPOT for non-prod** | Cost optimization; dev/qa can handle interruptions; prod uses standard FARGATE. |
| **Deployment circuit breaker** | ECS auto-rollback if new version fails health checks (default 100 failed tasks = rollback). |

## Standards & Compliance

| Standard | Area | Implementation |
|---|---|---|
| **OWASP Top 10** | Web Application Security | Input validation, CSRF protection (SvelteKit), secure session handling |
| **NIST Cybersecurity Framework** | Risk Management | Risk-based security gates (SAST → Image Scan → Deploy) |
| **CIS Controls** | Infrastructure Security | Trivy scans against CIS benchmarks (IAM, encryption, network segmentation) |
| **AWS Well-Architected Framework** | Cloud Architecture | Least privilege (IAM), encryption (KMS), separation of concerns (dev/qa/prod) |
| **12 Factor App** | Application Design | Secrets pulled from environment, stateless containers, logging routed to stdout |
| **Container Security Best Practices** | Image Security | Alpine base image, multi-stage builds, secrets excluded from image layers, immutable tags |
