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
flutter run -d chrome --dart-define=DISCOUNT_API_URL=http://localhost:3001/api/public/v1
flutter build web --release --no-web-resources-cdn
docker compose up --build -d          # web only, nginx on :8080
```

## Architecture

- Baskit is the end-user app. All supermarket and offer data comes from the separate
  **discount-scraper** project (`shelly-nas/discount-scraper`) through its read-only public API
  `/api/public/v1` (`/supermarkets`, `/categories`, `/search`, `/products/:id`). Never connect to
  the discount database directly; if data is missing, extend that public API first.
- `lib/config/app_config.dart` - `DISCOUNT_API_URL` dart-define; relative by default
  (`/api/discounts`), which nginx proxies to the discount-scraper API.
- `lib/database/` - data sources (`DiscountApiDataSource` uses `package:http`), DTO parsing
  (`models/offer_dto.dart`) and repositories (`OfferRepository` interface, `ApiOfferRepository`).
- `lib/backend/` - domain models (`models/offer.dart`) and services (`OfferSearchService`).
- `lib/frontend/presentation/` - screens (`SearchScreen`, `ListsScreen`, `ProfileScreen`, tabbed in
  `MainScreen` with an `IndexedStack`) and components. `SearchScreen` gets its service through the
  constructor so tests can inject `test/support/fake_offer_repository.dart`.
- `lib/di/dependency_injection.dart` - wires data sources, repositories and services; initialized
  in `main.dart`.
- Shopping lists and profile still use mock data.
- `backend/` and `database/` hold the planned Node.js microservices; they are incomplete and
  only run with `docker compose --profile backend`.

## Deployment

`Dockerfile` (Flutter build + nginx), `deploy/nginx.conf.template` (proxy `/api/discounts/` to
`${DISCOUNT_API_UPSTREAM}/api/public/v1/`), `docker-compose.yml` (dev) and
`docker-compose.prod.yml` (NAS, `shelly-network`, Traefik host `baskit.shelly-nas.nl`).

## Keeping this file current

After every change, update this file and `README.md` when files, modules or responsibilities change.
