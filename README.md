# Baskit

Baskit is your smart shopping companion designed to help you save money on groceries.

---

## Running locally on macOS

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install/macos) (SDK in path, or use the full path below)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) — required to run the backend
- Node.js 18+ — required if running backend services outside Docker
- Xcode — required for iOS Simulator
- Chrome — required for web

Make sure `flutter` is in your PATH. If `flutter doctor` gives "command not found", add your Flutter SDK's `bin/` directory to `~/.zshrc`:

```bash
export PATH="$HOME/path/to/flutter/bin:$PATH"
source ~/.zshrc
```

See the [Flutter macOS install guide](https://docs.flutter.dev/get-started/install/macos) for details.

Verify your Flutter setup:

```bash
flutter doctor
```

---

### 1. Start the backend

The app requires the backend services and Postgres to be running.

```bash
docker-compose up -d
```

This starts Postgres, Redis, and all active microservices. To stop:

```bash
docker-compose down
```

---

### 2. Install Flutter dependencies

```bash
flutter pub get
```

---

### 3. Run on iOS Simulator (macOS)

Open Simulator first (Xcode → Open Developer Tool → Simulator, or run `open -a Simulator`), then:

```bash
flutter run
```

Flutter will detect the running simulator automatically. To target a specific device:

```bash
flutter devices          # list available devices
flutter run -d <device-id>
```

---

### 4. Run as a web app

```bash
flutter run -d chrome
```

Or to run on any available browser:

```bash
flutter run -d web-server --web-port 8080
```

Then open [http://localhost:8080](http://localhost:8080) in your browser.

---

### 5. Run tests

```bash
# All Flutter tests
flutter test

# FR-001 tests only
flutter test test/fr-001/

# Backend unit tests (from backend/user-service)
cd backend/user-service && npm test
```

---

## Test users

Seeded test users (password: `TestPassword123!`) are defined in `database/seeds/`.
