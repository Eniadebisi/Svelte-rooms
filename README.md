# Svelte Rooms Reservations

A full-stack room reservation system built with **Svelte + SvelteKit**, **Prisma 7**, and **MariaDB**. Handles user authentication, role-based access control, space management, recurring reservations, and admin operations.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [CI/CD Pipeline](#cicd-pipeline)
- [Environment Variables](#environment-variables)
- [Local Development](#local-development)
- [API Surface](#api-surface)
- [Data Models](#data-models)
- [Key Patterns](#key-patterns)

---

## Features

### Core Functionality

- **Authentication** - JWT-based user sessions with bcrypt password hashing
- **Role-Based Access Control** - Five roles (Owner, Admin, User, Guest, Restricted) with permission checks
- **Space Management** - CRUD operations for rooms/spaces with locations
- **Reservations** - Booking system with date/time selection and recurring patterns (via rrule)
- **Admin Operations** - User role assignment, space management, mass reservation viewing/deletion
- **Email Notifications** - Nodemailer integration for confirmations and updates

### Technical Capabilities

- Type-safe database access via Prisma 7 (ESM client)
- Server-side rendering with SvelteKit
- Responsive UI with Bootstrap 5
- Connection pooling optimized for shared hosting (connectionLimit: 1)
- Sass preprocessing with modern API
- Test coverage for authorization logic (Vitest)

---

## Architecture

### Authentication & Authorization

- **Session Flow:** Login form → JWT token stored in cookie → Checked via `src/hooks.server.ts` on protected routes
- **Permission System:** `hasPermission(user.role, requiredRole)` in `src/lib/permissions/auth.ts`
- **Protected Routes:** All routes under `src/routes/(authenticated)/` require valid JWT
- **Admin-Only Routes:** Routes under `src/routes/(authenticated)/(admin)/` check for Admin/Owner role

### API Route Pattern

```
src/routes/(authenticated)/(admin)/api/{action}/+server.ts
├── POST handler accepts request
├── Validates user permissions
├── Calls database model (e.g., user.model.js, rooms.model.js)
└── Returns JSON response
```

### Database Query Organization

- **`src/lib/server/user.model.js`** - User queries (findUser, createUser, updateRole)
- **`src/lib/server/rooms.model.js`** - Room queries (findRooms, createRoom, deleteRoom)
- **Prisma Client** - Instantiated in `src/lib/server/db.ts` with MariaDB adapter

### Data Flow

```
SvelteKit Route (+page.server.ts)
  → Server Load Function or Form Action
    → Calls Model (user.model.js, rooms.model.js)
      → Uses PrismaClient
        → Returns data/result to component
```

---

## Tech Stack

| Layer              | Technology              | Version | Notes                                 |
| ------------------ | ----------------------- | ------- | ------------------------------------- |
| Frontend Framework | Svelte                  | 4.2.7   | Reactive components, minimal overhead |
| Meta Framework     | SvelteKit               | 2.50.1  | SSR, routing, server routes           |
| Build Tool         | Vite                    | 5.4.6   | ESM-based, zero-config                |
| ORM                | Prisma                  | 7.3.0   | ESM client (90% smaller bundle)       |
| DB Adapter         | @prisma/adapter-mariadb | 7.3.0   | Native MariaDB connection pooling     |
| DB Driver          | mysql2                  | 3.16.1  | MySQL protocol implementation         |
| Authentication     | jsonwebtoken + bcrypt   | 6.0.0   | JWT sessions, password hashing        |
| Email              | Nodemailer              | 7.0.12  | SMTP integration                      |
| Utilities          | Day.js + rrule          | -       | Date handling, recurring patterns     |
| Styling            | Bootstrap 5 + SCSS      | 5.3.3   | Component library, modern CSS API     |
| Testing            | Vitest                  | 4.0.18  | Fast unit tests, ESM-native           |
| Type Safety        | TypeScript              | 5.0.0   | Full codebase type checking           |
| Node               | -                       | 2.x    | Required version                      |
| Deployment         | AWS ECS Fargate         | -       | Containerized, serverless             |
| Container Registry | AWS ECR                 | -       | Private Docker image registry         |
| IaC                | Terraform               | 1.5+    | AWS infrastructure as code            |

---

## CI/CD Pipeline

This project uses a reusable multi-environment GitHub Actions pipeline deploying to AWS ECS Fargate via Docker and ECR.

### Branching Strategy

```
feature/* ──► dev ──► qa ──► main
               │       │       │
             dev     qa     prod
            cluster cluster cluster
```

- **`feature/*`** — cut from `dev`, opened as PR back to `dev`
- **`dev`** — auto-deploys to dev ECS cluster on every merge
- **`qa`** — auto-deploys to qa ECS cluster on every merge
- **`main`** — deploys to prod ECS cluster after required reviewer approval

### Pipeline Flow

```
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

### Rollback

Manual trigger via `rollback.yml` in the Actions tab:
- Select environment (dev / qa / prod)
- Optionally specify a task definition revision number
- Leave blank to automatically roll back to revision N-1
- ECS circuit breaker also auto-rolls back on failed deployments independently

### Workflow Files

| File | Trigger | Purpose |
|------|---------|---------|
| `build.yml` | Push to `dev` | Build Docker image, push to ECR |
| `_deploy.yml` | Called by others | Reusable deploy template |
| `deploy-dev.yml` | Push to `dev` | Deploy to dev ECS cluster |
| `deploy-qa.yml` | Push to `qa` | Deploy to qa ECS cluster |
| `deploy-prod.yml` | Push to `main` | Deploy to prod with approval gate |
| `rollback.yml` | Manual | Roll back any environment |

### AWS Infrastructure (Terraform)

Managed via `main.tf` at the repo root. Provisions:

- VPC with public subnets (no NAT Gateway — cost optimized)
- ECR repository with lifecycle policies (auto-expires old images)
- ECS clusters per environment (dev/qa/prod)
- ECS Fargate Spot for dev/qa (~70% cheaper), standard Fargate for prod
- CloudWatch log groups and crash alarms per environment
- ECS services with deployment circuit breakers

**To provision infrastructure:**
```bash
terraform init
terraform plan
terraform apply
```

**Key Terraform considerations:**
- No IAM role creation (restricted permissions) — uses existing `ecsTaskExecutionRole`
- S3 backend for remote state (`svelte-rooms-tf-state` bucket)
- `use_lockfile = false` — avoids `s3:DeleteObject` permission requirement
- Resources already existing in AWS must be imported: `terraform import <resource> <id>`

---

## Environment Variables

### SvelteKit Variable Types

SvelteKit has two categories of private env vars — understanding this is critical for the Docker build:

| Type | Import | Resolved | Where to set |
|------|--------|----------|--------------|
| `$env/static/private` | Build time | During `npm run build` | GitHub Actions secrets (build args) |
| `$env/dynamic/private` | Runtime | When container starts | ECS task definition |

### Build-Time Variables (GitHub Actions Secrets)

These must exist as GitHub repository secrets AND be passed as Docker build args. The build fails without them because SvelteKit resolves them statically during `npm run build`.

| Secret | Purpose |
|--------|---------|
| `AWS_ACCESS_KEY_ID` | AWS authentication |
| `AWS_SECRET_ACCESS_KEY` | AWS authentication |
| `AWS_REGION` | AWS region (us-east-1) |
| `ECR_REPOSITORY` | Full ECR URL (from `terraform output ecr_repository_url`) |
| `JWT_ACCESS_SECRET` | JWT signing secret |
| `CONTACT_EMAIL` | Contact email for notifications |

> To find all build-time variables in the codebase:
> ```bash
> grep -r "from \"\$env/static/private\"" src/ | grep -o '"[A-Z_]*"' | sort -u
> ```

### Runtime Variables (ECS Task Definition)

These are injected into the container at runtime via the ECS task definition `environment` block. They do not need to be in GitHub secrets.

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | MariaDB connection string |
| `SMTP_HOST` | Email server host |
| `SMTP_PORT` | Email server port |
| `SMTP_USER` | Email credentials |
| `SMTP_PASS` | Email credentials |

> To find all runtime variables:
> ```bash
> grep -r "from \"\$env/dynamic/private\"" src/ | grep -o '"[A-Z_]*"' | sort -u
> ```

### Local Development

Create a `.env` file at the repo root (never commit this):
```env
JWT_ACCESS_SECRET=your-secret
CONTACT_EMAIL=your@email.com
DATABASE_URL=mysql://user:pass@localhost:3306/svelte_rooms
```

---

## Local Development

### Prerequisites

- Node.js 22.x
- Docker Desktop (for local container testing)
- MariaDB or MySQL instance

### Setup

```bash
# Install dependencies
npm install

# Generate Prisma client
npx prisma generate

# Run database migrations
npx prisma migrate dev

# Start dev server
npm run dev
```

### Test Docker build locally before pushing

Always test the Docker build locally before pushing to avoid waiting for GitHub Actions to catch errors:

```bash
docker build \
  --build-arg JWT_ACCESS_SECRET=test-secret \
  --build-arg CONTACT_EMAIL=test@test.com \
  -t svelte-rooms-test .
```

If this passes locally it will pass in GitHub Actions.

---

## API Surface

### Server Routes (API Endpoints)

**Admin Routes** - All under `src/routes/(authenticated)/(admin)/api/`

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/newReservation` | POST | Create reservation |
| `/api/deleteReservation` | POST | Delete reservation |
| `/api/reservationData` | POST | Fetch reservation details |
| `/api/deleteRoom` | POST | Delete space/room |
| `/api/editUserRole` | POST | Update user role |

All routes validate user permissions before executing.

See `prisma/schema.prisma` for full schema.

---

## User Roles & Permissions

| Role | User Mgmt | Space Mgmt | Reservations | Admin Access |
|------|-----------|------------|--------------|--------------|
| Owner | ✅ Full | ✅ Full | ✅ Full | ✅ Yes |
| Admin | ✅ Assign roles | ✅ CRUD | ✅ View all, delete | ✅ Yes |
| User | ❌ | ❌ | ✅ Own only | ❌ |
| Guest | ❌ | ❌ | ✅ View own | ❌ |
| Restricted | No access | | | |

Check `src/lib/permissions/auth.ts` for enforcement.

---

## License

MIT License. See LICENSE file for details.
