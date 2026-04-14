# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
# Run the app (Run the app on the offline device)
flutter run 

# Run the app (Run the app in debug mode on the offline device)
flutter run --debug

# Run on a specific device
flutter run -d windows
flutter run -d chrome

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code
flutter analyze

# Format code
dart format lib/

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Build release web
flutter build web
```

## Architecture

This is a Flutter multi-platform app (Android, iOS, Web, Windows, Linux, macOS). Currently a fresh project scaffold with all app logic in `lib/main.dart`.

- **State management:** `StatefulWidget` + `setState` (no external state management library yet)
- **Theming:** Material Design 3 via `ColorScheme.fromSeed`
- **Tests:** Widget tests in `test/` using `flutter_test`

## Flutter Version

Uses Flutter with Dart SDK `^3.10.1`. Run `flutter doctor` to verify the local environment.
