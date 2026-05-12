# S-Rooms Development

**S-Rooms** is the private development version of the public [Svelte-Rooms](Svelte-Rooms.md) project. This repository contains the codebase for maintaining and extending the room reservation platform.

> For user documentation, features, and learning resources, see [Svelte-Rooms.md](Svelte-Rooms.md).

## Table of Contents

- [Tech Stack](#tech-stack)
- [Developer Setup](#developer-setup)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Database](#database)
- [Development Commands](#development-commands)
- [License](#license)

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Frontend Framework** | Svelte | 4.2.7 |
| **Meta Framework** | SvelteKit | 2.50.1 |
| **Build Tool** | Vite | 5.4.6 |
| **Styling** | SCSS / Bootstrap | 5.3.3 |
| **Backend** | Node.js | 20.x |
| **Database** | MySQL/MariaDB | - |
| **ORM** | Prisma | 7.3.0 (ESM) |
| **DB Adapter** | @prisma/adapter-mariadb | 7.3.0 |
| **DB Driver** | mysql2 | 3.16.1 |
| **Authentication** | jsonwebtoken & bcrypt | 6.0.0 |
| **Email** | Nodemailer | 7.0.12 |
| **Date/Time** | Day.js & rrule | - |
| **Testing** | Vitest | 4.0.18 |
| **Linting** | ESLint | - |
| **Type Checking** | TypeScript | 5.0.0 |

## Developer Setup

### Prerequisites
- Node.js 20.x
- npm (bundled with Node.js)
- MySQL/MariaDB database
- Code editor (VS Code recommended)

### Installation

```bash
git clone https://github.com/Eniadebisi/S-rooms.git
cd S-rooms
npm install
```

## Project Structure

```
src/
├── routes/                          # SvelteKit routes & API endpoints
│   ├── (authenticated)/             # Protected routes (auth required)
│   │   ├── (admin)/                # Admin-only routes
│   │   │   ├── admin/              # Admin dashboard
│   │   │   ├── spaces/             # Room CRUD operations
│   │   │   ├── users/              # User management
│   │   │   └── api/                # Admin API routes
│   │   ├── profile/                # User profile page
│   │   ├── reservations/           # User reservations view
│   │   └── +layout.svelte          # Auth layout wrapper
│   ├── register/                    # Registration page
│   ├── signout/                     # Logout endpoint
│   ├── +error.svelte               # Error boundary
│   └── +page.svelte                # Landing/home page
├── lib/
│   ├── server/
│   │   ├── db.ts                   # Prisma Client singleton - Sets adapter, connection pooling
│   │   ├── user.model.js           # User database queries
│   │   └── rooms.model.js          # Room database queries
│   ├── permissions/
│   │   ├── auth.ts                 # Role-based authorization - hasPermission() checks
│   │   └── hasPermissions.test.ts  # Permission tests
│   ├── settings.ts                 # App config constants
│   └── emails.ts                   # Email template functions
├── scss/
│   └── styles.scss                 # Global SCSS styles
├── auth.js                         # Authentication middleware
├── hooks.server.ts                 # SvelteKit hooks
└── app.d.ts                        # Type definitions
prisma/
├── schema.prisma                   # Database schema - All models defined here
├── config.ts                       # Prisma 7 config - Datasource & settings
├── generated/                      # Auto-generated Prisma Client (do not commit)
└── migrations/                     # Database migration history
```

**Key Files for Developers:**
- [src/lib/server/db.ts](src/lib/server/db.ts) - Connection setup & pooling
- [prisma/schema.prisma](prisma/schema.prisma) - Database schema
- [prisma/config.ts](prisma/config.ts) - Prisma 7 configuration
- [src/lib/permissions/auth.ts](src/lib/permissions/auth.ts) - Authorization logic

## Architecture

### Authentication Flow
1. User registers/logs in via `/register` or form on home page
2. Server hashes password with bcrypt and stores User in database
3. JWT token created and returned to client (stored in cookie)
4. Protected routes check JWT in [src/hooks.server.ts](src/hooks.server.ts)
5. User role determines access to admin features

### API Routes Pattern
All admin API routes follow pattern: `src/routes/(authenticated)/(admin)/api/{action}/+server.ts`
- `+server.ts` handles POST requests
- All requests validated for user permissions
- Database mutations performed via Prisma queries

### Database Queries
Located in `src/lib/server/`:
- **user.model.js** - findUser, createUser, updateRole
- **rooms.model.js** - findRooms, createRoom, deleteRoom

Call these from server routes instead of direct Prisma calls for consistency.

## Database

### Schema (Defined in [prisma/schema.prisma](prisma/schema.prisma))

**Models:**
- `User` - Accounts with roles (Owner, Admin, User, Guest, Restricted)
- `Room` - Bookable spaces with location references
- `Reservation` - Bookings with start/end times and recurrence rules
- `Location` - Building/area groupings for rooms
- `Team` - Team organization (optional, not fully used)

### Configuration
- **Provider:** `mysql` (for MySQL/MariaDB)
- **Client Output:** `prisma/generated` (ESM format)
- **Adapter:** MariaDB adapter for connection pooling
- **Connection Limit:** Set to 1 on shared hosting to preserve connection quota

## Development Commands

```bash
# Start dev server (runs prisma generate first)
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Type & linting checks
npm run check                 # Run TypeScript checks
npm run check:watch          # Watch mode
npm run lint                 # ESLint

# Testing
npm run test                 # Run Vitest

# Database
npx prisma generate          # Generate Prisma Client (auto on npm install)
npx prisma migrate dev       # Create & apply migrations
npx prisma migrate status    # Check migration status
npx prisma studio           # Open visual database browser
npx prisma migrate reset    # Reset database (dev only!)
```

## License

This project is licensed under the MIT License. See the LICENSE file for details.
