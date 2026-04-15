# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Global Rules

You are a senior software engineer.

## Workflow Rules
1. Always create a clear step-by-step plan before coding
2. Do NOT directly jump to code unless explicitly asked
3. Keep responses concise and production-ready

## Code Rules
- Follow clean architecture (MVVM where applicable)
- Write modular and maintainable code
- Optimize for performance

## Communication Rules
- Be direct and avoid unnecessary explanations
- Ask for clarification if requirements are unclear

## Common Commands

```bash
# Run the app on a connected Android device
flutter run

# Analyze for errors/warnings
flutter analyze --no-fatal-infos

# Regenerate Hive TypeAdapters after changing any model
flutter pub run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Get/refresh dependencies
flutter pub get
```

## Architecture

**InvoGen** — offline-first GST invoice generator for Indian businesses.

- **State management:** GetX everywhere — `GetxController` per module, `Obx()` for reactive UI. No `setState`, no Provider, no BLoC.
- **Local DB:** Hive (4 boxes: `clients`, `invoices`, `userProfile`, `appSettings`). `GetStorage` for boolean flags only (`isLoggedIn`, `isFirstLaunch`, `tutorialShown`).
- **Navigation:** GetX named routes via `AppRoutes`/`AppPages`. `ShellScreen` holds `IndexedStack` for the bottom nav (Dashboard / Clients / Invoices / Profile).
- **Services (static):** `HiveService` (all CRUD + invoice counter), `PdfService` (A4 PDF generation), `EmailService` (flutter_email_sender), `GeminiService` (Gemini API HTTP).

## Folder Layout

```
lib/app/
  bindings/        # AppBindings (initial) + per-route Bindings
  core/
    constants/     # AppColors, AppTextStyles, AppStrings
    theme/         # AppTheme.lightTheme
    utils/         # CurrencyFormatter (Indian rupee), DateFormatter, NumberToWords
  data/
    models/        # ClientModel, InvoiceModel, InvoiceItemModel, UserProfileModel (.g.dart adapters auto-generated)
    services/      # HiveService, PdfService, EmailService, GeminiService
  modules/         # One controller per feature (auth, splash, onboarding, dashboard, clients, invoices, profile, reports, shell, tutorial)
  routes/          # AppRoutes (constants), AppPages (GetPage list)
  screens/         # One folder per feature, mirrors modules/
assets/
  fonts/           # NotoSans-Regular/Bold/Italic.ttf (required for PDF rupee symbol rendering)
  animations/      # Lottie JSON files
```

## Key Implementation Notes

- **Hive models** use `@HiveType`/`@HiveField`. Run `build_runner` after any model change.
- **Invoice number** auto-increments via `HiveService.generateInvoiceNumber()` producing `INV-000001` format.
- **GST calculation**: `InvoiceModel.isInterState` field toggles between CGST+SGST (intra-state, each half) and IGST (inter-state, full rate).
- **PDF fonts**: NotoSans TTF loaded via `rootBundle` in `PdfService` — required for rupee symbol support.
- **Dev autofill buttons**: Every form screen has an orange `[Dev Fill]` button wrapped in `if (kDebugMode)`.
- **Tutorial overlay**: `TutorialController` + `TutorialOverlay` widget uses `GlobalKey` + `CustomPainter` spotlight. Triggered once from `DashboardController.onReady()`.
- **Gemini API key**: Set `AppStrings.geminiApiKey` in `lib/app/core/constants/app_strings.dart`.
- **Mock data seeding**: `AuthController._seedMockData()` runs on first sign-in, creating 2 clients + 3 invoices.

## Flutter Version

Dart SDK `^3.10.1`. Run `flutter doctor` to verify environment.
