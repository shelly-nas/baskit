# Baskit

Baskit is your smart shopping companion designed to help you save money on groceries.
It is a Flutter app (web first, also built for iOS and Android) with a Notion style UI.

## How it fits together

```
supermarkets --> discount-scraper (scrapers + Postgres + admin UI)
                        |
                        |  GET /api/public/v1/...   (read-only public API)
                        v
                 Baskit web / mobile app
```

- **[discount-scraper](https://github.com/shelly-nas/discount-scraper)** owns all supermarket
  data. It scrapes the offers, stores them in its own database and has a management UI to
  check whether the scrapers run correctly.
- **Baskit** is purely for end users. It never talks to the discount database directly; it
  reads offers through the discount-scraper public API (`/api/public/v1`).

## Features

| Feature | Status |
| ------- | ------ |
| Search all current supermarket offers (text search, supermarket and category filters, sorting, paging) | Working, live data |
| Offer details with regular price, savings, deal text and link to the supermarket | Working, live data |
| Shopping lists | UI only, mock data |
| Profile | UI only, mock data |

## Project structure

```
lib/
  config/            build-time configuration (API URL)
  backend/           domain models, services and use cases (business logic)
  database/          data sources (HTTP / local), DTO parsing, repositories
  frontend/          theme, design tokens and atomic design components
    presentation/
      components/    atoms, molecules, organisms
      screens/       search, lists, profile
  di/                dependency wiring
backend/, database/  planned Node.js microservices for accounts and lists (work in progress)
```

## Running locally

1. Start the discount-scraper stack (it exposes its API on `http://localhost:3001`):

   ```bash
   cd ../discount-scraper && docker compose up --build -d
   ```

2. Run Baskit against it:

   ```bash
   flutter pub get
   flutter run -d chrome --dart-define=DISCOUNT_API_URL=http://localhost:3001/api/public/v1
   ```

   For Android or iOS use an address the device can reach, for example
   `http://10.0.2.2:3001/api/public/v1` on the Android emulator.

### Tests

```bash
flutter analyze
flutter test
```

## Docker (web)

The `Dockerfile` builds the Flutter web bundle and serves it with nginx. nginx proxies
`/api/discounts/*` to `${DISCOUNT_API_UPSTREAM}/api/public/v1/*`, so the web build uses a
relative API URL and needs no CORS configuration.

```bash
# Development: Baskit on http://localhost:8080, discount-scraper API on the host (port 3001)
docker compose up --build -d

# Production (NAS): image from the registry, joined to shelly-network
docker compose -f docker-compose.prod.yml up -d
```

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `DISCOUNT_API_URL` (build arg / `--dart-define`) | `/api/discounts` | Base URL of the discount API as seen by the app |
| `DISCOUNT_API_UPSTREAM` (runtime, nginx) | `http://host.docker.internal:3001` (dev), `http://discount-scraper-api:3001` (prod) | Where nginx forwards `/api/discounts` |

The planned microservice backend (`backend/`, `database/`) only starts with
`docker compose --profile backend up`; several of its services do not exist yet.
