# CLAUDE.md

Baskit: a Flutter shopping-list app (web build behind nginx) with its own server (`server/`, Express +
TypeScript + Postgres) for accounts, synced lists and sharing. Offers and prices come from
supermarket-scraper. Follows the shelly-nas standards (plugin `shelly-fundamentals`).

Module map of the app, the server and the deployment: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Read only the section you need.

## Rules

- **No emojis** in code, UI or responses. Use icons (CupertinoIcons / Material icons) or text. UI copy is English.
- Follow the atomic design structure (`atoms`, `molecules`, `organisms`) and use `DesignTokens` /
  `AppColors` instead of hard-coded sizes and colors.
- **The app never reads a database directly.** Offers, catalog prices and price comparison come from the
  supermarket-scraper public API `/api/public/v1`; when data is missing, extend that API first (in
  `shelly-nas/supermarket-scraper`). Accounts and lists come from the Baskit server under `/api`.
- **Schema:** `database/init.sql` is the first schema; every later change is a new
  `server/migrations/NNN_*.sql`.
- `flutter analyze` must be clean, infos included. Flutter 3.44.0, the same as the Dockerfile build image.
- **After adding, removing or renaming a module, or moving a responsibility**, update its section of
  `docs/ARCHITECTURE.md` (and `README.md` when it describes it). Change this file only when a rule or command changes.

## Reading code

- Locate first, then read narrowly: search with grep or glob (with line numbers), then read only the relevant
  range with an offset and limit. Read a whole file only when you are going to edit it or it is short.
- Do not re-read a file you already read in this session unless it changed since.

## Commands

```bash
flutter pub get && flutter analyze && flutter test
flutter run -d chrome --dart-define=DISCOUNT_API_URL=http://localhost:3001/api/public/v1 \
  --dart-define=BASKIT_API_URL=http://localhost:3002/api
flutter build web --release --no-web-resources-cdn
docker compose up --build -d          # db + server (:3002) + web (nginx :8080)

cd server && npm ci && npm run build
npm test                               # needs DB_* env of a test database (it is reset)
```

## Where things are

| Path | Role |
|---|---|
| `lib/config/app_config.dart` | API base URLs (dart-defines) |
| `lib/di/dependency_injection.dart` | Wires services; tests inject fakes here |
| `lib/database/` | API clients and local storage (data sources, DTOs) |
| `lib/backend/` | Domain models and services |
| `lib/frontend/presentation/` | Controllers and screens |
| `server/src/` | `routes/`, `managers/` (SQL), `middleware/`, `context/` (db, migrations) |
| `deploy/`, `docker-compose*.yml`, `.github/workflows/` | nginx, compose and CI/acc/deploy |
