# Architecture

Module map of Baskit (app, server, deployment). `CLAUDE.md` holds the rules and commands; this file is read on demand.
Update the section of a module when you add, remove or rename it, or when its responsibility changes.

## App (`lib/`)

- Two backends, neither database is read by the app directly:
  - **supermarket-scraper** (`shelly-nas/supermarket-scraper`): offers, catalog prices and list price
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
  token, `onUnauthorized` when the server rejects it, `BaskitApiException` with a user-facing
  message), `RemoteShoppingListDataSource` (server lists + sharing), `LocalShoppingListDataSource`
  (lists as JSON in a `KeyValueStore`; only used by tests as a list backend without a server),
  `AuthRepository` (sign-in, token storage in `SharedPreferencesStore` / `InMemoryStore`, delete
  account, admin calls), DTO parsing in `models/`.
- `lib/backend/` - domain models (`offer.dart`, `shopping_list.dart` incl. `ListItemOffer`,
  `ListPerson`, `isOwner`; `price_comparison.dart`; `user_account.dart`) and services
  (`OfferSearchService`, `ShoppingListService` + use cases, `PriceComparisonService`).
- An account is required: there is no signed-out mode. The token stays on the device until sign-out
  or until the server rejects it, so users stay signed in between visits (FR-001).
- `lib/frontend/presentation/controllers/` - `ShoppingListController` (one instance for all tabs,
  server lists; `reset` on sign-out; failures go to `messages`, shown as a snack bar by
  `MainScreen`) and `AuthController` (`AuthStatus` restoring / signedOut / unreachable / signedIn;
  restore, sign in/up/out, delete account, `handleUnauthorized`; loads the lists on sign-in).
- Screens: `AuthGate` (home: loader while restoring, retry when unreachable, `SignInScreen`
  (sign in / create account) or `MainScreen` keyed by user), `SearchScreen`, `ListsScreen`,
  `ListDetailScreen` (share sheet, leave, compare), `PriceComparisonScreen`, `ProfileScreen`
  (account, delete account), `AdminScreen` (admins only), tabbed in `MainScreen` with an
  `IndexedStack`.
- List item IDs and list IDs are client generated UUIDs, also on the server.

### Server (`server/`)

Express + TypeScript + pg, FinanceApp layout. `src/app.ts` (`createApp`), `src/index.ts` (runs
migrations, listens on `SERVER_PORT`), `src/config.ts` (`JWT_SECRET` required in production,
`ADMIN_EMAILS`, `TOKEN_TTL` default `365d`), `src/context/` (`dbContext`, `migrations.runMigrations` for
`server/migrations/NNN_*.sql`), `src/middleware/` (`requireAuth` re-reads the user per request,
`requireAdmin`, `rateLimit` on password endpoints, `HttpError` + `errorHandler`),
`src/managers/` (SQL: `userManager` incl. account lockout after 10 failed sign-ins for 15 minutes
and `deleteMe`, `listManager` with owner/editor access checks),
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
`${DISCOUNT_API_UPSTREAM}/api/public/v1/`, resolved per request through Docker DNS so the web container
starts while the supermarket-scraper is down; `deploy/05-discount-upstream.envsh` swaps an `/etc/hosts`-only
host such as `host.docker.internal` for its IP, `/api/` to `${BASKIT_API_UPSTREAM}/api/`),
`server/Dockerfile`, `database/Dockerfile`, `docker-compose.yml` (dev: db, server, web) and
`docker-compose.prod.yml` (NAS: db bind mount `./data/postgres`, `shelly-network`, Traefik host
`baskit.shelly-nas.nl`).
