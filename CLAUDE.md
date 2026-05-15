# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter run -d windows   # Run on Windows desktop
flutter build android    # Build Android APK/AAB
flutter build ios        # Build iOS app
flutter build windows    # Build Windows MSIX package
flutter test             # Run tests
flutter analyze          # Static analysis
```

## Architecture

Linklado is a special character keyboard utility (ʉ, ɨ, ñ, ç, etc.) for Android, iOS, and Windows.

**Platform routing** happens in `main.dart`: a top-level `platform` variable drives `MyApp.build()` to return one of three StatefulWidget classes — `LinkladoWindows`, `LinkladoAndroid`, or `LinkladoIOS`. No routing library is used.

**Windows** (`lib/linklado_windows.dart`): A floating 400×250px always-on-top grid of character buttons. Uses `win32` + `ffi` to call `SendInput()` with `KEYEVENTF_UNICODE` to inject keystrokes into whichever window was in the foreground. `window_manager` handles the window lifecycle.

**Android** (`lib/linklado_android.dart`): A 4-screen onboarding flow using `IndexedStack` (no Navigator). Bridges to native Android via MethodChannel `com.linklado.tuklado.tuklado_flutter/channelTuklado` to open system Settings and InputMethodManager. Progress persists to `SharedPreferences` via a global `prefs` variable initialized in `main()`. The actual keyboard is implemented as `Tuklado.java` extending `InputMethodService`.

**iOS** (`lib/linklado_ios.dart`): A 3-screen onboarding flow (IndexedStack), read-only UI — no native calls, user configures the keyboard manually in iOS Settings.

**Styles** (`lib/styles.dart`): Centralized color constants — `roxoLinklado` (purple) and `verdeLinklado` (green).

## Known Issues

- `test/widget_test.dart` imports `package:tuklado_flutter/main.dart` (old project name); the current `pubspec.yaml` declares `name: Linklado` — tests will fail until fixed.
- The MSIX config in `pubspec.yaml` contains hardcoded local paths and certificate credentials — not suitable for CI.
- UI text is in Portuguese throughout; no i18n setup.
