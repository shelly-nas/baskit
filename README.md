# Baskit

Baskit is your smart shopping companion designed to help you save money on groceries.
It is a Flutter app (web first, also built for iOS and Android) with a Notion style UI.

## How it fits together

```
supermarkets --> discount-scraper (scrapers + Postgres + admin UI)
                        |
                        |  /api/public/v1   (read-only: offers, catalog, compare)
                        v
   Baskit web / mobile app  <-- /api -->  Baskit server (accounts, lists) --> Postgres
```

- **[discount-scraper](https://github.com/shelly-nas/discount-scraper)** owns all supermarket
  data: weekly offers and the full catalog at regular prices, with its own management UI.
- **Baskit server** (`server/`) owns accounts and synced, shared shopping lists.
- **Baskit app** (`lib/`) talks to both. It never reads either database directly.

## Features

| Feature | Status |
| ------- | ------ |
| Search all current supermarket offers (text search, supermarket and category filters, sorting, paging) | Working, live data |
| Offer details with regular price, savings, deal text and link to the supermarket | Working, live data |
| Shopping lists: create, rename, delete; add, check off and remove items; quantities | Working |
| Add an offer from search to a list (keeps supermarket, price and end date) | Working |
| Compare what a list costs at each supermarket (offers and regular catalog prices) | Working, live data |
| Accounts: register, sign in, change name and password | Working |
| Lists on the device when signed out; synced to the account when signed in (device lists are uploaded once) | Working |
| Share a list with other accounts by email; members edit, the owner manages sharing | Working |
| Admin: usage numbers, make admin, disable accounts | Working |

## Project structure

```
lib/
  config/            build-time configuration (API URLs)
  backend/           domain models and services (business logic)
  database/          data sources (HTTP / device), DTO parsing, repositories
  frontend/          theme, design tokens and atomic design components
    presentation/
      controllers/   ChangeNotifiers shared by screens (lists, auth)
      components/    atoms, molecules, organisms
      screens/       search, lists, list detail, compare, profile, admin
  di/                dependency wiring (AppDependencies)
server/              Baskit server: Express + TypeScript + Postgres
  src/               routes, managers (SQL), middleware (auth, errors, rate limit)
  migrations/        NNN_*.sql schema changes, applied on startup
database/            init.sql (first schema) and the database image
```

## Running locally

1. Start the discount-scraper stack (API on `http://localhost:3001`):

   ```bash
   cd ../discount-scraper && docker compose up --build -d
   ```

2. Start the Baskit server and database:

   ```bash
   cp .env.example .env    # set ADMIN_EMAILS to your email to become admin
   docker compose up --build -d db server   # a fresh volume gets the demo accounts (password baskit-demo)
   ```

3. Run the app against both:

   ```bash
   flutter pub get
   flutter run -d chrome \
     --dart-define=DISCOUNT_API_URL=http://localhost:3001/api/public/v1 \
     --dart-define=BASKIT_API_URL=http://localhost:3002/api
   ```

   Or run everything including the web build behind nginx: `docker compose up --build -d`
   (http://localhost:8080). For Android or iOS use addresses the device can reach, for example
   `http://10.0.2.2:3001` on the Android emulator.

### Tests

```bash
flutter analyze && flutter test

cd server && npm ci
DB_HOST=localhost DB_PORT=5434 DB_NAME=baskit DB_USER=baskit DB_PASSWORD=baskit npm test
```

The server tests reset the database they run against; use a test database.

## Docker and deployment

The root `Dockerfile` builds the Flutter web bundle and serves it with nginx. nginx proxies
`/api/discounts/*` to `${DISCOUNT_API_UPSTREAM}/api/public/v1/*` and `/api/*` to
`${BASKIT_API_UPSTREAM}/api/*`, so the web build uses relative API URLs and needs no CORS.

| Variable | Where | Description |
| -------- | ----- | ----------- |
| `DISCOUNT_API_URL`, `BASKIT_API_URL` | build (`--dart-define`) | API base URLs as seen by the app; default `/api/discounts` and `/api` |
| `DISCOUNT_API_UPSTREAM`, `BASKIT_API_UPSTREAM` | web container | Where nginx forwards |
| `DB_NAME`, `DB_USER`, `DB_PASSWORD` | db, server | Database |
| `JWT_SECRET` | server | Signs sign-in tokens; required (32+ characters) in production |
| `ADMIN_EMAILS` | server | Comma separated; these accounts get the admin role |
| `TOKEN_TTL` | server | How long a sign-in lasts, default `30d` |

### CI and deployment

- `.github/workflows/ci.yml`: `flutter analyze` and `flutter test`, plus the shared shelly-nas
  Node + Postgres CI for `server/` (typecheck, `database/init.sql`, migrations twice, server tests).
- `.github/workflows/acc.yml` deploys every pull request to the acceptance environment
  `baskit-acc.shelly-nas.nl` (`docker-compose.acc.yml`, `/volume1/docker/baskit-acc`) with images
  tagged `acc-<commit>`. Its database is rebuilt on every deploy from `database/init.sql` plus the
  demo data in `database/seed-demo.sql`, and torn down when the pull request closes. Demo
  accounts: `admin@baskit.demo` (admin), `anna@baskit.demo`, `bram@baskit.demo` (shares a list with
  Anna), `cees@baskit.demo` (disabled); password `baskit-demo`. Offers come from the discount-scraper acc stack (`discount-scraper-acc-api`, override with the
  variable `DISCOUNT_API_UPSTREAM_ACC`). Production never gets demo data:
  the database image only contains `init.sql`, and its data directory is persistent.
- `.github/workflows/deploy.yml` runs on every push to `main`: builds `baskit-web`, `baskit-server`
  and `baskit-db` on the NAS runner, pushes them and redeploys `docker-compose.prod.yml` into
  `/volume1/docker/baskit`.

Required repository settings (Settings, Secrets and variables, Actions):

| Name | Kind | Value |
| ---- | ---- | ----- |
| `REGISTRY_URL`, `REGISTRY_USERNAME` | variables | NAS registry |
| `REGISTRY_PASSWORD` | secret | registry password |
| `DB_PASSWORD` | secret | Baskit database password |
| `JWT_SECRET` | secret | 32+ random characters |
| `ADMIN_EMAILS` | variable | admin account emails |
| `JWT_SECRET_ACC` | secret, optional | separate token secret for acc (falls back to `JWT_SECRET`) |
| `DB_NAME`, `DB_USER`, `TZ` | variables, optional | default `baskit`, `baskit`, `Europe/Amsterdam` |

On the NAS, `/volume1/docker/baskit/data/postgres` must exist and be owned by uid 70. The
discount-scraper API must be deployed with its `shelly-network` change, otherwise nginx cannot
resolve `discount-scraper-api`.
