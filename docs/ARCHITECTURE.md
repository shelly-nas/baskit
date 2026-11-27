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
  message), `RemoteShoppingListDataSource` (server lists + sharing), `OfflineShoppingListDataSource`
  (FR-007, wraps the remote source: keeps a copy of the lists on the device, applies changes made
  without a connection (status 0 or 5xx) to that copy and queues them in `baskit.lists.outbox.v1`;
  the queue is sent in order before the next fetch, a change the server refuses is dropped and
  reported through `onRejected`; `status` is a `SyncStatus` (offline, pending); `clear` on
  sign-out), `LocalShoppingListDataSource` (lists as JSON in a `KeyValueStore`: the device copy for
  the offline source, and a list backend without a server in tests), `AuthRepository` (sign-in,
  token and the last user JSON in `SharedPreferencesStore` / `InMemoryStore`, so `restore` works
  without a connection; delete account, admin calls), DTO parsing in `models/`.
- `lib/backend/` - domain models (`offer.dart`, `shopping_list.dart` incl. `ListItemOffer`,
  `ListPerson`, `isOwner`; `price_comparison.dart`; `user_account.dart`) and services
  (`OfferSearchService`, `ShoppingListService` + use cases, `PriceComparisonService`,
  `ItemSuggestionService`: while typing an item, the user's history from `ItemSuggestionDataSource`
  (`GET /api/items/suggestions`; offline: names on the lists) plus up to 3 matching offers; items
  still open on the list are left out; failures give fewer suggestions, not an error).
- An account is required: there is no signed-out mode. The token stays on the device until sign-out
  or until the server rejects it, so users stay signed in between visits (FR-001).
- `lib/frontend/presentation/controllers/` - `ShoppingListController` (one instance for all tabs,
  server lists; `reset` on sign-out, also clears the device copy; `syncStatus` and
  `reportRejected` for offline changes; failures go to `messages`, shown as a snack bar by
  `MainScreen`; `refresh` fetches the lists in the background without loader or message and
  drops its answer when a change was saved meanwhile; `startAutoRefresh` / `stopAutoRefresh`
  run it every 10 seconds) and `AuthController` (`AuthStatus` restoring / signedOut / unreachable / signedIn;
  restore, sign in/up/out, delete account, `handleUnauthorized`; loads the lists on sign-in).
- Screens: `AuthGate` (home: loader while restoring, retry when unreachable, `SignInScreen`
  (sign in / create account) or `MainScreen` keyed by user), `SearchScreen`, `ListsScreen`,
  `ListDetailScreen` (share sheet, leave, compare; `ItemSuggestionsPanel` under the add field,
  asked 250 ms after typing stops), `PriceComparisonScreen`, `ProfileScreen`
  (account, delete account), `AdminScreen` (admins only), tabbed in `MainScreen` with an
  `IndexedStack`. `MainScreen` runs the auto refresh while the app is in the foreground (app
  lifecycle; stopped when hidden or paused, refreshed at once on resume); `ListsScreen` and
  `ListDetailScreen` also refresh on pull-down. `BaskitApp` (`main.dart`) shows the
  `OfflineBanner` (offline, or changes waiting) above every screen through `MaterialApp.builder`.
- List item IDs and list IDs are client generated UUIDs, also on the server.

### Server (`server/`)

Express + TypeScript + pg, FinanceApp layout. `src/app.ts` (`createApp`), `src/index.ts` (runs
migrations, listens on `SERVER_PORT`), `src/config.ts` (`JWT_SECRET` required in production,
`ADMIN_EMAILS`, `TOKEN_TTL` default `365d`, `AUTH_RATE_LIMIT` sign-in attempts per IP per 15 minutes,
default 20), `src/context/` (`dbContext`, `migrations.runMigrations` for
`server/migrations/NNN_*.sql`), `src/middleware/` (`requireAuth` re-reads the user per request,
`requireAdmin`, `rateLimit` on password endpoints, `HttpError` + `errorHandler`),
`src/managers/` (SQL: `itemManager` (item history per user in `item_history`, recorded in the
same transaction as `listManager.addItem`; suggestions: starts-with first, then most added, then
most recent), `userManager` incl. account lockout after 10 failed sign-ins for 15 minutes
and `deleteMe`, `listManager` with owner/editor access checks),
`src/routes/` (`/api/auth`, `/api/lists`, `/api/items`, `/api/admin`). Lists JSON is snake_case, the same shape
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

## E2E and UAT scenarios (`e2e/`)

Gherkin scenarios in `e2e/features/*.feature` (English, one file per feature, tagged `@FR-00x`), steps
in `e2e/steps/` (`fixtures.ts`: the `Baskit` page driver and a `World` per scenario; `account.steps.ts`,
`lists.steps.ts`), run by playwright-bdd 9.2.1 and Playwright 1.63.0 against `BASE_URL` (default acc).
The steps switch on Flutter's accessibility tree (`flt-semantics-placeholder`) and find widgets by role
and label; Flutter ignores synthetic key presses, so `Baskit.type` sets the field and sends an `input`
event. Scenarios create their own `e2e-*@baskit.test` accounts through the API. Reports:
`e2e/reports/scenarios.html` (readable) and `e2e/reports/playwright`. The `acc.yml` job `e2e-acc`
runs them after every acc deploy in a Playwright container on `shelly-network`
(`http://baskit-acc-web`) and uploads the reports as artifact `e2e-reports`; acc sets
`AUTH_RATE_LIMIT` high for that run.
