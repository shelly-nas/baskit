# Graph Report - .  (2026-05-12)

## Corpus Check
- 144 files · ~60,938 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 804 nodes · 979 edges · 61 communities (50 shown, 11 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 53 edges (avg confidence: 0.93)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Flutter Registration Tests|Flutter Registration Tests]]
- [[_COMMUNITY_UI Component Atoms & Molecules|UI Component Atoms & Molecules]]
- [[_COMMUNITY_Shopping List Data Layer|Shopping List Data Layer]]
- [[_COMMUNITY_PostgreSQL Database Schema|PostgreSQL Database Schema]]
- [[_COMMUNITY_Shopping List Features|Shopping List Features]]
- [[_COMMUNITY_Backend Input Validation|Backend Input Validation]]
- [[_COMMUNITY_Auth Controller & Email|Auth Controller & Email]]
- [[_COMMUNITY_Clean Architecture Docs|Clean Architecture Docs]]
- [[_COMMUNITY_Microservice Health & Routes|Microservice Health & Routes]]
- [[_COMMUNITY_Login Integration Tests|Login Integration Tests]]
- [[_COMMUNITY_JWT Token Service|JWT Token Service]]
- [[_COMMUNITY_Mobile App Icon Assets|Mobile App Icon Assets]]
- [[_COMMUNITY_UI Molecules & Icons|UI Molecules & Icons]]
- [[_COMMUNITY_Text & Card Components|Text & Card Components]]
- [[_COMMUNITY_Session Management|Session Management]]
- [[_COMMUNITY_API Client & HTTP|API Client & HTTP]]
- [[_COMMUNITY_Login Flow Script|Login Flow Script]]
- [[_COMMUNITY_Home Screen & Theme|Home Screen & Theme]]
- [[_COMMUNITY_Atom Design System|Atom Design System]]
- [[_COMMUNITY_Shared Error Classes|Shared Error Classes]]
- [[_COMMUNITY_User Profile Controller|User Profile Controller]]
- [[_COMMUNITY_Email Verification Tests|Email Verification Tests]]
- [[_COMMUNITY_Auth Middleware|Auth Middleware]]
- [[_COMMUNITY_Shared Backend Index|Shared Backend Index]]
- [[_COMMUNITY_Bottom Nav Components|Bottom Nav Components]]
- [[_COMMUNITY_Registration Integration Tests|Registration Integration Tests]]
- [[_COMMUNITY_Theme Design Tokens|Theme Design Tokens]]
- [[_COMMUNITY_Profile Header Widgets|Profile Header Widgets]]
- [[_COMMUNITY_Preferences UI Section|Preferences UI Section]]
- [[_COMMUNITY_Auth Screen Flow|Auth Screen Flow]]
- [[_COMMUNITY_Database Connection Pool|Database Connection Pool]]
- [[_COMMUNITY_App Entry Point|App Entry Point]]
- [[_COMMUNITY_Flutter Project Config|Flutter Project Config]]
- [[_COMMUNITY_Shared DB & Logger|Shared DB & Logger]]
- [[_COMMUNITY_Bottom Navigation Bar|Bottom Navigation Bar]]
- [[_COMMUNITY_Divider Components|Divider Components]]
- [[_COMMUNITY_Savings Summary Widget|Savings Summary Widget]]
- [[_COMMUNITY_Web PWA Icons|Web PWA Icons]]
- [[_COMMUNITY_AppText Typography|AppText Typography]]
- [[_COMMUNITY_User Info Section|User Info Section]]
- [[_COMMUNITY_Avatar Atom Widget|Avatar Atom Widget]]
- [[_COMMUNITY_Shopping List Model|Shopping List Model]]
- [[_COMMUNITY_Android Launcher Icons|Android Launcher Icons]]
- [[_COMMUNITY_iOS App Delegate|iOS App Delegate]]
- [[_COMMUNITY_iOS LLDB Debug Helper|iOS LLDB Debug Helper]]
- [[_COMMUNITY_Shopping List Entity|Shopping List Entity]]
- [[_COMMUNITY_AppIcon Atom Widget|AppIcon Atom Widget]]
- [[_COMMUNITY_iOS Plugin Registrant|iOS Plugin Registrant]]
- [[_COMMUNITY_Android Plugin Registrant|Android Plugin Registrant]]
- [[_COMMUNITY_Auth Service Client|Auth Service Client]]
- [[_COMMUNITY_Android Main Activity|Android Main Activity]]
- [[_COMMUNITY_Design Tokens|Design Tokens]]
- [[_COMMUNITY_Project README|Project README]]
- [[_COMMUNITY_Functional Design FR006|Functional Design FR006]]
- [[_COMMUNITY_iOS Launch Image README|iOS Launch Image README]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 35 edges
2. `../../../theme/design_tokens.dart` - 22 edges
3. `../../../theme/colors.dart` - 21 edges
4. `FR-001 Feature Requirements Document` - 18 edges
5. `../atoms/app_text.dart` - 12 edges
6. `runTests()` - 11 edges
7. `package:flutter/cupertino.dart` - 11 edges
8. `apiCall()` - 10 edges
9. `Database README & Schema Docs` - 10 edges
10. `Functional Design Document` - 10 edges

## Surprising Connections (you probably didn't know these)
- `Self-Hosted NAS Infrastructure Strategy` --semantically_similar_to--> `PostgreSQL 15 Service (Docker Compose)`  [INFERRED] [semantically similar]
  docs/Business_Case.md → docker-compose.yml
- `Clean Architecture Pattern (Flutter)` --semantically_similar_to--> `Architecture Diagram Document`  [INFERRED] [semantically similar]
  CLAUDE.md → docs/Architecture_Diagram.md
- `Socket.IO Real-Time Sync (List Service)` --semantically_similar_to--> `WebSocket + Redis Pub/Sub Sync Architecture`  [INFERRED] [semantically similar]
  backend/README.md → docs/Functional_Design.md
- `JWT Configuration (docker-compose env)` --implements--> `JWT Access Token (24h, HS256)`  [INFERRED]
  docker-compose.yml → docs/features/FR-001.md
- `Backend Shared Utilities Pattern` --references--> `backend/shared/src/database.js`  [INFERRED]
  CLAUDE.md → backend/README.md

## Hyperedges (group relationships)
- **JWT Token Management Flow (FR-001 + docker-compose + jwt.service)** — fr001_jwt_access_token, fr001_refresh_token, dockercompose_jwt_config, login_test_jwt_service, fr001_token_blacklist [EXTRACTED 0.95]
- **Login Security Requirements Coverage (FR-001.2.x tests)** — login_test_integration_file, login_test_fr_001_2_2, login_test_fr_001_2_3, login_test_fr_001_2_8, login_test_ratelimit_service [EXTRACTED 1.00]
- **Active Microservices Infrastructure (Docker Compose)** — dockercompose_postgres, dockercompose_redis, dockercompose_user_service, dockercompose_product_service, dockercompose_list_service [EXTRACTED 1.00]
- **All platform app icons and launch images use unmodified default Flutter branding** — ios_appicon_set, android_launcher_set, flutter_default_branding [INFERRED 0.95]
- **iOS launch images and app icons together define iOS app visual identity** — ios_launchimage_set, ios_appicon_set, ios_appicon_1024 [INFERRED 0.85]
- **iOS and Android launcher icons serve same role across platforms** — ios_appicon_set, android_launcher_hdpi, android_launcher_mdpi [INFERRED 0.85]
- **Android Launcher Icon Multi-Density Variants** — ic_launcher_xxxhdpi, ic_launcher_xxhdpi, ic_launcher_xhdpi [INFERRED 0.95]

## Communities (61 total, 11 thin omitted)

### Community 0 - "Flutter Registration Tests"
Cohesion: 0.04
Nodes (43): package:flutter_test/flutter_test.dart, main, MockRegistrationService, RegistrationRequest, RegistrationResult, EmailValidator, isValid, main (+35 more)

### Community 1 - "UI Component Atoms & Molecules"
Cohesion: 0.04
Nodes (43): ../components/atoms/app_text.dart, ../components/atoms/spacing.dart, ../components/molecules/menu_item.dart, ../components/molecules/section_header.dart, ../components/organisms/bottom_navigation.dart, ../components/organisms/logout_button.dart, ../components/organisms/preferences_section.dart, ../components/organisms/savings_summary.dart (+35 more)

### Community 2 - "Shopping List Data Layer"
Cohesion: 0.04
Nodes (41): ../../../backend/models/shopping_list.dart, ../data_sources/shopping_list_data_source.dart, ../mappers/shopping_list_mapper.dart, ../models/shopping_list_entity.dart, ../../theme/app_theme.dart, Exception, LocalShoppingListDataSource, ShoppingListDataSource (+33 more)

### Community 3 - "PostgreSQL Database Schema"
Cohesion: 0.06
Nodes (46): categories Table, database/init.sql Schema File, list_items Table, lists Table, prices Table, products Table, Database README & Schema Docs, database/seeds/01_initial_data.sql (+38 more)

### Community 4 - "Shopping List Features"
Cohesion: 0.05
Nodes (35): ../atoms/app_progress_bar.dart, ../backend/services/shopping_list_service.dart, ../backend/use_cases/shopping_list_use_cases.dart, ../components/molecules/list_header.dart, ../components/organisms/shopping_list_card_component.dart, ../database/data_sources/shopping_list_data_source.dart, ../../database/repositories/shopping_list_repository.dart, ../models/shopping_list.dart (+27 more)

### Community 5 - "Backend Input Validation"
Cohesion: 0.06
Nodes (37): { error }, { error: longError }, { error: shortError }, { error, value }, errors, invalidData, invalidEmails, {
  isValidEmail,
  isValidPassword,
  isValidDisplayName,
  getValidationErrors,
  registrationSchema,
  emailSchema,
  passwordSchema,
  displayNameSchema,
} (+29 more)

### Community 6 - "Auth Controller & Email"
Cohesion: 0.07
Nodes (27): { createVerificationToken }, { database, logger, ValidationError, ConflictError, UnauthorizedError, NotFoundError }, { hashPassword }, { logRegistration }, register(), { registrationSchema }, { sendVerificationEmail }, { asyncHandler } (+19 more)

### Community 7 - "Clean Architecture Docs"
Cohesion: 0.07
Nodes (37): Backend Layer (Business Logic), Database Layer (Data), Dependency Injection Layer, Architecture Diagram Document, Frontend Layer (Presentation), LocalShoppingListDataSource (Flutter Data), ShoppingListMapper (Flutter Data), ShoppingListRepository (Flutter Data) (+29 more)

### Community 8 - "Microservice Health & Routes"
Cohesion: 0.1
Nodes (25): { database, logger }, express, healthCheck, router, { asyncHandler, authenticate }, express, io, router (+17 more)

### Community 9 - "Login Integration Tests"
Cohesion: 0.07
Nodes (24): app, { database }, decoded, expiresAt, jwt, jwtService, lockUntil, now (+16 more)

### Community 10 - "JWT Token Service"
Cohesion: 0.07
Nodes (25): crypto, generateAccessToken(), generateRefreshToken(), generateTokenPair(), getTokenExpirationTime(), isTokenExpired(), jwt, { logger } (+17 more)

### Community 11 - "Mobile App Icon Assets"
Cohesion: 0.09
Nodes (24): Android Launcher Icon (hdpi) — Default Flutter Logo, Android Launcher Icon (mdpi) — Default Flutter Logo, Android Launcher Icon Set (default Flutter branding), Default Flutter Branding (unmodified blue geometric F logo), iOS App Icon 1024x1024 (1x) — Default Flutter Logo, iOS App Icon 20x20 (1x) — Default Flutter Logo, iOS App Icon 20x20 (2x) — Default Flutter Logo, iOS App Icon 20x20 (3x) — Default Flutter Logo (+16 more)

### Community 12 - "UI Molecules & Icons"
Cohesion: 0.12
Nodes (15): ../atoms/app_icon.dart, package:flutter/cupertino.dart, build, ListHeader, Row, AppIcon, build, Container (+7 more)

### Community 13 - "Text & Card Components"
Cohesion: 0.13
Nodes (14): ../atoms/app_text.dart, ../../../theme/colors.dart, AppText, build, ListCardInfo, build, Material, PreferenceItem (+6 more)

### Community 14 - "Session Management"
Cohesion: 0.14
Nodes (7): createSession(), crypto, { database, logger }, hashToken(), parseUserAgent(), tokenBlacklist, verifyRefreshTokenSession()

### Community 15 - "API Client & HTTP"
Cohesion: 0.12
Nodes (15): dart:convert, dart:typed_data, package:http/http.dart, ApiClient, ApiResponse, BcryptConfig, Exception, _generateMockHash (+7 more)

### Community 16 - "Login Flow Script"
Cohesion: 0.28
Nodes (15): apiCall(), axios, colors, log, runTests(), test1_Register(), test2_LoginUnverified(), test3_VerifyEmail() (+7 more)

### Community 17 - "Home Screen & Theme"
Cohesion: 0.12
Nodes (11): package:flutter/material.dart, AppProgressBar, build, ClipRRect, ShoppingList, build, HomeScreen, Scaffold (+3 more)

### Community 18 - "Atom Design System"
Cohesion: 0.13
Nodes (12): app_text.dart, ../../../theme/design_tokens.dart, AppBadge, build, Container, AppContainer, build, Container (+4 more)

### Community 19 - "Shared Error Classes"
Cohesion: 0.15
Nodes (6): AppError, ConflictError, ForbiddenError, logger, NotFoundError, ValidationError

### Community 20 - "User Profile Controller"
Cohesion: 0.17
Nodes (5): { logger, NotFoundError }, { asyncHandler, authenticate }, express, router, userController

### Community 21 - "Email Verification Tests"
Cohesion: 0.17
Nodes (11): buildVerificationLink, clear, EmailContent, EmailSendResult, generateToken, main, MockEmailService, MockTokenService (+3 more)

### Community 22 - "Auth Middleware"
Cohesion: 0.18
Nodes (4): UnauthorizedError, corsOptions, logger, { UnauthorizedError }

### Community 23 - "Shared Backend Index"
Cohesion: 0.2
Nodes (9): actualShared, app, { database }, expiresAt, request, database, errors, logger (+1 more)

### Community 24 - "Bottom Nav Components"
Cohesion: 0.2
Nodes (8): ../atoms/spacing.dart, BottomNavItem, build, Expanded, AppIcon, build, ListCardHeader, Row

### Community 25 - "Registration Integration Tests"
Cohesion: 0.22
Nodes (8): actualShared, app, { database }, displayName, invalidEmails, request, responseStr, userData

### Community 26 - "Theme Design Tokens"
Cohesion: 0.22
Nodes (7): colors.dart, design_tokens.dart, package:google_fonts/google_fonts.dart, typography.dart, AppTheme, ThemeData, AppTypography

### Community 27 - "Profile Header Widgets"
Cohesion: 0.25
Nodes (7): ../atoms/app_avatar.dart, ../atoms/app_badge.dart, AppAvatar, build, ProfileHeader, Row, VerticalSpace

### Community 28 - "Preferences UI Section"
Cohesion: 0.25
Nodes (7): ../atoms/app_divider.dart, ../molecules/preference_item.dart, ../molecules/preference_toggle.dart, AppDivider, build, Container, PreferencesSection

### Community 29 - "Auth Screen Flow"
Cohesion: 0.25
Nodes (7): login_page.dart, registration_page.dart, AuthScreen, _AuthScreenState, build, Scaffold, _toggleAuthMode

### Community 31 - "App Entry Point"
Cohesion: 0.29
Nodes (6): frontend/theme/theme.dart, package:baskit/frontend/presentation/screens/auth_screen.dart, BaskitApp, build, main, MaterialApp

### Community 32 - "Flutter Project Config"
Cohesion: 0.29
Nodes (7): Flutter Lints Analysis Config, Baskit Flutter App (pubspec.yaml), cupertino_icons Package, flutter_lints Dev Dependency, Flutter SDK Dependency, google_fonts Package, http Package

### Community 33 - "Shared DB & Logger"
Cohesion: 0.33
Nodes (4): logger, { Pool }, logger, winston

### Community 34 - "Bottom Navigation Bar"
Cohesion: 0.33
Nodes (5): ../molecules/bottom_nav_item.dart, BottomNavigation, build, Container, Function

### Community 35 - "Divider Components"
Cohesion: 0.33
Nodes (5): AppBorderDivider, AppDivider, build, Container, Divider

### Community 36 - "Savings Summary Widget"
Cohesion: 0.33
Nodes (5): AppText, build, Container, SavingsSummary, VerticalSpace

### Community 37 - "Web PWA Icons"
Cohesion: 0.33
Nodes (6): Baskit Web Favicon (Flutter logo placeholder), Baskit Web App Icon 192px (Flutter logo), Baskit Web App Icon 512px (Flutter logo), Baskit Maskable Icon 192px (Flutter logo, safe-zone cropped), Baskit Maskable Icon 512px (Flutter logo, safe-zone cropped), Web App Entry Point (index.html)

### Community 38 - "AppText Typography"
Cohesion: 0.4
Nodes (4): ../../../theme/typography.dart, AppText, build, Text

### Community 39 - "User Info Section"
Cohesion: 0.4
Nodes (4): ../molecules/profile_header.dart, build, Container, UserInfoSection

### Community 40 - "Avatar Atom Widget"
Cohesion: 0.4
Nodes (4): app_icon.dart, AppAvatar, build, Container

### Community 41 - "Shopping List Model"
Cohesion: 0.4
Nodes (4): copyWith, ListItem, ShoppingList, toggleCompleted

### Community 42 - "Android Launcher Icons"
Cohesion: 0.9
Nodes (5): Android Mipmap Density Set, Flutter Logo Icon Design, Android App Icon (xhdpi 96x96), Android App Icon (xxhdpi 144x144), Android App Icon (xxxhdpi 192x192)

### Community 45 - "Shopping List Entity"
Cohesion: 0.5
Nodes (3): copyWith, ListItemEntity, ShoppingListEntity

### Community 46 - "AppIcon Atom Widget"
Cohesion: 0.5
Nodes (3): AppIcon, build, Icon

## Knowledge Gaps
- **497 isolated node(s):** `User`, `RegistrationResult`, `MockUserRepository`, `clear`, `main` (+492 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Home Screen & Theme` to `UI Component Atoms & Molecules`, `Shopping List Data Layer`, `Divider Components`, `Shopping List Features`, `Savings Summary Widget`, `AppText Typography`, `User Info Section`, `Avatar Atom Widget`, `UI Molecules & Icons`, `Text & Card Components`, `AppIcon Atom Widget`, `Atom Design System`, `Bottom Nav Components`, `Theme Design Tokens`, `Preferences UI Section`, `Auth Screen Flow`, `App Entry Point`?**
  _High betweenness centrality (0.087) - this node is a cross-community bridge._
- **Why does `createVerificationToken` connect `Auth Controller & Email` to `Email Verification Tests`?**
  _High betweenness centrality (0.058) - this node is a cross-community bridge._
- **Are the 18 inferred relationships involving `iOS App Icon Set (default Flutter branding)` (e.g. with `iOS App Icon 1024x1024 (1x) — Default Flutter Logo` and `iOS App Icon 76x76 (2x) — Default Flutter Logo`) actually correct?**
  _`iOS App Icon Set (default Flutter branding)` has 18 INFERRED edges - model-reasoned connections that need verification._
- **What connects `User`, `RegistrationResult`, `MockUserRepository` to the rest of the system?**
  _497 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Flutter Registration Tests` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `UI Component Atoms & Molecules` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Shopping List Data Layer` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._