# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Code style

- Never use emojis in code, UI, or responses. Use icons (CupertinoIcons / Material icons) or text.
- Follow the existing atomic design structure (`atoms`, `molecules`, `organisms`) and use
  `DesignTokens` / `AppColors` instead of hard coded sizes and colors.
- UI copy is English.

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --dart-define=DISCOUNT_API_URL=http://localhost:3001/api/public/v1 \
  --dart-define=BASKIT_API_URL=http://localhost:3002/api
flutter build web --release --no-web-resources-cdn
docker compose up --build -d          # db + server (:3002) + web (nginx :8080)

cd server && npm ci && npm run build
npm test                               # needs DB_* env of a test database (it is reset)
```

## Architecture

- Two backends, neither database is read by the app directly:
  - **discount-scraper** (`shelly-nas/discount-scraper`): offers, catalog prices and list price
    comparison through its read-only public API `/api/public/v1` (`/supermarkets`, `/categories`,
    `/search`, `/products/:id`, `POST /compare`). If data is missing, extend that API first.
  - **Baskit server** (`server/`): accounts, synced lists and sharing under `/api`.
- `lib/config/app_config.dart` - `DISCOUNT_API_URL` and `BASKIT_API_URL` dart-defines; relative by
  default (`/api/discounts`, `/api`), which nginx proxies.
- `lib/di/dependency_injection.dart` - `AppDependencies.create({store, baskitApi,
  offerRepository})` wires everything; tests pass an `InMemoryStore`, a `BaskitApiClient` over a
  `MockClient` (`test/support/fake_baskit_server.dart`) and `FakeOfferRepository`.
  `buildShoppingListService(dataSource)` builds the list service stack on any data source.
- `lib/database/` - `DiscountApiDataSource` (discount API), `BaskitApiClient` (Baskit server, bearer
  token, `BaskitApiException` with a user-facing message), `LocalShoppingListDataSource` (device,
  JSON through a `KeyValueStore`: `SharedPreferencesStore` / `InMemoryStore`),
  `RemoteShoppingListDataSource` (server lists + sharing + import), `AuthRepository` (sign-in,
  token storage, admin calls), DTO parsing in `models/`.
- `lib/backend/` - domain models (`offer.dart`, `shopping_list.dart` incl. `ListItemOffer`,
  `ListPerson`, `isOwner`; `price_comparison.dart`; `user_account.dart`) and services
  (`OfferSearchService`, `ShoppingListService` + use cases, `PriceComparisonService`).
- `lib/frontend/presentation/controllers/` - `ShoppingListController` (one instance for all tabs;
  `useService` switches between device and server lists; failures go to `messages`, shown as a
  snack bar by `MainScreen`) and `AuthController` (restore, sign in/up/out; on sign-in uploads device
  lists once via `POST /lists/import`, deletes them from the device and switches to server lists).
- Screens: `SearchScreen`, `ListsScreen`, `ListDetailScreen` (share sheet, leave, compare),
  `PriceComparisonScreen`, `ProfileScreen` (sign-in/register form or account), `AdminScreen`
  (admins only), tabbed in `MainScreen` with an `IndexedStack`.
- List item IDs and list IDs are client generated UUIDs, also on the server.

### Server (`server/`)

Express + TypeScript + pg, FinanceApp layout. `src/app.ts` (`createApp`), `src/index.ts` (runs
migrations, listens on `SERVER_PORT`), `src/config.ts` (`JWT_SECRET` required in production,
`ADMIN_EMAILS`, `TOKEN_TTL`), `src/context/` (`dbContext`, `migrations.runMigrations` for
`server/migrations/NNN_*.sql`), `src/middleware/` (`requireAuth` re-reads the user per request,
`requireAdmin`, `rateLimit` on password endpoints, `HttpError` + `errorHandler`),
`src/managers/` (SQL: `userManager`, `listManager` with owner/editor access checks),
`src/routes/` (`/api/auth`, `/api/lists`, `/api/admin`). Lists JSON is snake_case, the same shape
the app stores on the device. Tests: `src/__tests__/*.test.ts` with `node --test` against a real
Postgres (`helpers.resetDatabase` applies `database/init.sql` + migrations and truncates).
`database/init.sql` is the first schema; every later change is a new migration file.

## Deployment

CI (`.github/workflows/ci.yml`): `flutter analyze` (must be clean, infos included) and `flutter test`
with Flutter 3.44.0 (same as the Dockerfile build image), and the shared `ci-node-postgres.yml` for
`server/` (which also applies `database/seed-demo.sql` twice to check it is idempotent). Acc
(`.github/workflows/acc.yml`): every pull request is deployed to `baskit-acc.shelly-nas.nl`
(`docker-compose.acc.yml`) with a fresh database: `init.sql` + `database/seed-demo.sql` (demo
accounts, password `baskit-demo`; guarded no-op when accounts exist; never in the db image, so never
in production). Deploy (`.github/workflows/deploy.yml`): every push to `main` builds `baskit-web`,
`baskit-server`, `baskit-db` and deploys via `shelly-nas/shared-workflows`. Commit messages follow
Conventional Commits.

`Dockerfile` (Flutter build + nginx), `deploy/nginx.conf.template` (`/api/discounts/` to
`${DISCOUNT_API_UPSTREAM}/api/public/v1/`, `/api/` to `${BASKIT_API_UPSTREAM}/api/`),
`server/Dockerfile`, `database/Dockerfile`, `docker-compose.yml` (dev: db, server, web) and
`docker-compose.prod.yml` (NAS: db bind mount `./data/postgres`, `shelly-network`, Traefik host
`baskit.shelly-nas.nl`).

## Keeping this file current

After every change, update this file and `README.md` when files, modules or responsibilities change.
