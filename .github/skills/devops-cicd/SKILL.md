---
name: devops-cicd
description: >
  DevOps and CI/CD for the Baskit project. Use this skill when creating or
  modifying GitHub Actions workflows, Dockerfiles, docker-compose configuration,
  or deployment automation. Covers quality gates, security scanning, Docker
  build patterns, secrets management, and environment configuration.
---

## Project Infrastructure

| Layer      | Technology               | Notes                        |
| ---------- | ------------------------ | ---------------------------- |
| Frontend   | Flutter `sdk: ^3.10.0`   | iOS, Android, Web            |
| Backend    | Node.js 18 microservices | Express, CommonJS            |
| Database   | PostgreSQL 15            | `database/init.sql`          |
| Cache      | Redis 7                  | Used by list-service         |
| Containers | Docker + Compose         | `docker-compose.yml` at root |
| CI/CD      | GitHub Actions           | `.github/workflows/`         |

Services: `user-service` (3001), `product-service` (3002), `list-service` (3003).

---

## Workflow File Naming

| File                | Trigger                   | Purpose                  |
| ------------------- | ------------------------- | ------------------------ |
| `ci.yml`            | `push`, `pull_request`    | Quality + security gate  |
| `cd-staging.yml`    | push to `main` (after CI) | Deploy to staging        |
| `cd-production.yml` | Manual / release tag      | Deploy to production     |
| `security-scan.yml` | Schedule + push           | Dedicated security scans |

---

## Required Settings on Every Workflow

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
  # Add only what each job needs:
  # packages: write        → GHCR push
  # security-events: write → CodeQL

jobs:
  example:
    timeout-minutes: 20 # 20 for tests, 30 for builds
```

Always use **pinned action versions** — never floating `@main`:

```yaml
- uses: actions/checkout@v4 # ✅
- uses: actions/checkout@main # ❌
```

---

## Docker Build — always context `./backend`

All Dockerfiles copy `shared/` explicitly — the build context must be `./backend`:

```yaml
- uses: docker/build-push-action@v5
  with:
    context: ./backend
    file: ./backend/${{ matrix.service }}/Dockerfile
    tags: ghcr.io/${{ github.repository }}/${{ matrix.service }}:${{ github.sha }}
    cache-from: type=gha
    cache-to: type=gha,mode=max

- uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

---

## Quality Gates

### Flutter

```yaml
- run: dart format --output=none --set-exit-if-changed .
- run: flutter analyze --fatal-infos --fatal-warnings
- run: flutter test --coverage
```

### Node.js (matrix per service)

Use a `services: postgres` container for integration tests:

```yaml
services:
  postgres:
    image: postgres:15-alpine
    env:
      POSTGRES_DB: baskit_test
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports: ["5432:5432"]
    options: >-
      --health-cmd pg_isready --health-interval 10s
      --health-timeout 5s --health-retries 5
```

Test step:

```yaml
- run: npm test -- --ci --coverage
  working-directory: backend/${{ matrix.service }}
  env:
    NODE_ENV: test
    DB_HOST: localhost
    DB_PORT: 5432
    DB_NAME: baskit_test
    DB_USER: postgres
    DB_PASSWORD: postgres
```

---

## Security Gates (all required, block builds on failure)

1. `npm audit --audit-level=high` per service
2. `flutter pub audit`
3. CodeQL: `github/codeql-action/init@v3` → `autobuild@v3` → `analyze@v3` (languages: `javascript, dart`)
4. Trivy image scan: `aquasecurity/trivy-action@master` with `exit-code: 1`, severity `CRITICAL,HIGH`

Build/deploy jobs must declare:

```yaml
needs: [test-flutter, test-backend, security-scan]
```

---

## Secrets

- Never hard-code — always `${{ secrets.NAME }}`.
- `GITHUB_TOKEN` is automatic — no extra secret needed for GHCR.
- Mask dynamically constructed sensitive values: `echo "::add-mask::$VALUE"`.

---

## Environments

| Name         | Deployment             | Approval          |
| ------------ | ---------------------- | ----------------- |
| `staging`    | Auto on push to `main` | None required     |
| `production` | Manual or release tag  | Required reviewer |
