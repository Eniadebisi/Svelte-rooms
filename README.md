# Svelte Rooms Reservations

A full-stack room reservation system built with **Svelte + SvelteKit**, **Prisma 7**, and **MariaDB**. Handles user authentication, role-based access control, space management, recurring reservations, and admin operations.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Setup](#setup)
- [API Surface](#api-surface)
- [Data Models](#data-models)
- [Key Patterns](#key-patterns)

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

## Architecture

### Authentication & Authorization

- **Session Flow:** Login form → JWT token stored in cookie → Checked via [src/hooks.server.ts](src/hooks.server.ts) on protected routes
- **Permission System:** `hasPermission(user.role, requiredRole)` in [src/lib/permissions/auth.ts](src/lib/permissions/auth.ts)
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

- **[src/lib/server/user.model.js](src/lib/server/user.model.js)** - User queries (findUser, createUser, updateRole)
- **[src/lib/server/rooms.model.js](src/lib/server/rooms.model.js)** - Room queries (findRooms, createRoom, deleteRoom)
- **Prisma Client** - Instantiated in [src/lib/server/db.ts](src/lib/server/db.ts) with MariaDB adapter

### Data Flow

```
SvelteKit Route (+page.server.ts)
  → Server Load Function or Form Action
    → Calls Model (user.model.js, rooms.model.js)
      → Uses PrismaClient
        → Returns data/result to component
```

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
| Node               | -                       | 20.x    | Required version                      |

## API Surface

### Server Routes (API Endpoints)

**Admin Routes** - All under `src/routes/(authenticated)/(admin)/api/`

| Endpoint                 | Method | Purpose                   |
| ------------------------ | ------ | ------------------------- |
| `/api/newReservation`    | POST   | Create reservation        |
| `/api/deleteReservation` | POST   | Delete reservation        |
| `/api/reservationData`   | POST   | Fetch reservation details |
| `/api/deleteRoom`        | POST   | Delete space/room         |
| `/api/editUserRole`      | POST   | Update user role          |

All routes validate user permissions before executing.

See [prisma/schema.prisma](prisma/schema.prisma) for full schema.

## User Roles & Permissions

| Role       | User Mgmt       | Space Mgmt | Reservations        | Admin Access |
| ---------- | --------------- | ---------- | ------------------- | ------------ |
| Owner      | ✅ Full         | ✅ Full    | ✅ Full             | ✅ Yes       |
| Admin      | ✅ Assign roles | ✅ CRUD    | ✅ View all, delete | ✅ Yes       |
| User       | ❌              | ❌         | ✅ Own only         | ❌           |
| Guest      | ❌              | ❌         | ✅ View own         | ❌           |
| Restricted | No access       |

Check [src/lib/permissions/auth.ts](src/lib/permissions/auth.ts) for enforcement.

## License

MIT License. See LICENSE file for details.
