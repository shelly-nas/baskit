# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Baskit is a smart grocery shopping app targeting the Dutch market. It consists of a Flutter mobile/web frontend and a Node.js microservices backend, all orchestrated via Docker Compose.

## Development Commands

### Flutter Frontend

```bash
flutter pub get          # Install dependencies
flutter analyze          # Lint
flutter test             # All tests
flutter test test/path/to_test.dart  # Single test file
flutter build apk        # Android
flutter build web        # Web
```

### Backend (Node.js Microservices)

```bash
# From /backend
npm run install:all           # Install all service dependencies
npm run test:all              # Test all services
npm run test:user-service     # Test a specific service
npm run dev:user-service      # Run a service in dev/hot-reload mode

# From an individual service directory (e.g., backend/user-service)
npm run dev                   # Hot-reload via nodemon
npm test                      # Jest with coverage
npm run test:unit             # Unit tests only
npm run test:integration      # Integration tests only
npm run test:watch            # Watch mode
```

### Infrastructure

```bash
docker-compose up -d     # Start full backend stack (Postgres, Redis, active services)
docker-compose down      # Stop all services
```

Test users (password: `TestPassword123!`) are defined in `database/seeds/`.

## Architecture

### Frontend (Flutter/Dart) — `lib/`

Uses clean architecture with dependency injection:

- `lib/frontend/` — Presentation layer: screens, widgets, theming, BLoC
- `lib/backend/` — Domain layer: use cases, services
- `lib/database/` — Data layer: repositories, data sources, local storage
- `lib/di/` — Dependency injection wiring
- `lib/main.dart` — App entry point

### Backend (Node.js) — `backend/`

Microservices architecture; each service is independent with its own Express app, Dockerfile, and `.env.example`:

| Service | Port | Status |
|---|---|---|
| user-service | 3001 | Active — JWT auth, registration, login |
| product-service | 3002 | Active — Product catalog |
| list-service | 3003 | Active — Shopping lists, real-time via Socket.IO |
| price-service | 3004 | Planned |
| store-service | 3005 | Planned |
| route-service | 3006 | Planned |
| notification-service | 3007 | Planned |

`backend/shared/` contains cross-service utilities: database pool, logger (Winston), custom error classes, and auth middleware.

All active services expose health check endpoints at `/api/health`, `/api/health/ready`, and `/api/health/live`.

### Database — `database/`

PostgreSQL 15. The full schema (including tables for future services) is in `database/init.sql`. Seed data is in `database/seeds/`.

## Documentation

- [docs/Architecture_Diagram.md](docs/Architecture_Diagram.md) — Full clean architecture diagram: DI → Services → Use Cases → Repositories → Data Sources → Storage
- [docs/Functional_Design.md](docs/Functional_Design.md) — Feature requirements and user stories
- [docs/Business_Case.md](docs/Business_Case.md) — Business model and target market analysis
- [docs/features/FR-001.md](docs/features/FR-001.md) — Feature requirement: FR-001

## Key Patterns

- **Backend service tests** are split into `unit/` and `integration/` subdirectories within each service's `test/` folder. Jest enforces 80% coverage thresholds.
- **Shared backend utilities** live in `backend/shared/` — always use these (db pool, logger, error types) rather than service-local equivalents.
- **Environment config**: each service has its own `.env.example`. Copy to `.env` and fill in values before running locally.
- **Real-time sync** on list-service uses Socket.IO — relevant when modifying list operations.
