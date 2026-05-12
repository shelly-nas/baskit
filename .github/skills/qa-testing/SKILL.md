---
name: qa-testing
description: >
  QA and functional test creation for the Baskit app. Use this skill when
  writing, extending, or reviewing Dart test files. Covers requirement
  traceability, file naming conventions, the AAA test pattern, and coverage
  requirements derived from the docs/features/ specification files.
---

## Guiding Principle

Every test must be traceable to a requirement ID in `docs/features/`. No test
without a spec reference; no spec requirement without a test.

---

## File Naming Convention

```
test/<fr-id>/<fr_id>_<section>_<sub>_<description>_test.dart
```

Examples:

- `test/fr-001/fr_001_1_1_registration_test.dart` → FR-001.1.1
- `test/fr-001/fr_001_1_3_password_complexity_test.dart` → FR-001.1.3

Rules:

- Replace hyphens and dots in the requirement ID with underscores.
- Use `snake_case` for the description.
- Always end with `_test.dart`.

---

## Test File Template

```dart
import 'package:flutter_test/flutter_test.dart';

/// <REQUIREMENT_ID>: <Requirement text copied verbatim from the spec>
///
/// This test suite verifies that <brief description>.

// ── Mock / stub layer ──────────────────────────────────────────────────────
// Minimal models and services needed for this requirement only.

void main() {
  group('<REQUIREMENT_ID>: <Short group description>', () {

    test('should <expected happy-path behaviour>', () async {
      // Arrange
      // Act
      // Assert
    });

    test('should <edge case or error scenario>', () async {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

---

## Coverage Requirements per Requirement Type

| Type                              | Must cover                                           |
| --------------------------------- | ---------------------------------------------------- |
| Input validation                  | Valid input, each invalid format, boundary values    |
| Business rules                    | Normal flow, all documented error cases              |
| Security (rate limiting, locking) | Within-limit success, over-limit failure, reset      |
| Multi-step flows                  | Full happy path, each documented failure point       |
| API endpoint                      | Request shape, success response, each error response |
| Data privacy                      | Consent checks, data-at-rest handling                |

---

## Error Message Assertions

When the spec lists a specific error string (e.g., `"Please enter a valid email address"`),
assert the **exact** string — never paraphrase.

---

## Workflow

1. Read the feature spec in `docs/features/FR-XXX.md`.
2. List all requirement IDs in the spec.
3. Compare against existing files in `test/fr-XXX/` to find gaps.
4. Create one test file per missing requirement ID.
5. Run tests and fix any compilation errors before finishing.
6. Report every created/updated file and its requirement ID.

---

## Scope

- Only create or edit files under `test/`.
- Never modify production code (`lib/`, `backend/`, `database/`).
- Do not add speculative test cases not grounded in the spec.
