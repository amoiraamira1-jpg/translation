# Screen Translator (Flutter + native Android overlay)

A floating screen-translator scaffold like "Tap Translate Screen":
tap a draggable icon over any app → it screenshots, OCRs, and shows the
translation on top of the original text — using only **free, on-device**
engines (Google ML Kit Text Recognition + ML Kit Translate). No paid API,
no API key.

## Architecture (why it's split Flutter + Kotlin)

The floating icon has to keep working while your Flutter UI is closed —
Flutter's engine doesn't run in the background on Android. So:

- **Flutter (`lib/`)** — Home/Translate/Camera/More screens, settings UI,
  exactly the sections in your screenshots (Text Style, Floating Icon,
  Other Settings, More menu). Writes every toggle to `SharedPreferences`.
- **Kotlin (`android/app/.../*.kt`)** — a `Foreground Service`
  (`OverlayService.kt`) that draws the icon, captures the screen via
  `MediaProjection`, runs OCR (`OcrEngine.kt`) and translation
  (`TranslateEngine.kt`), and draws the result overlay. It reads the same
  `SharedPreferences` (`Prefs.kt`) the Flutter side writes to, so a setting
  change applies immediately without restarting the service.
- `MainActivity.kt` is the bridge: a `MethodChannel` lets Flutter ask for
  the overlay permission, start/stop the service, and read/write settings.

## What's implemented vs. what's a starting point

Implemented: floating draggable icon, tap-to-capture full screen,
drag-then-hold to start region selection, `MediaProjection` capture,
on-device OCR with per-block bounding boxes, on-device translation,
overlay rendering with upcase/center-align/vertical-text options, hide
close/settings icon, one-touch-close, auto-move-to-edge-and-dim.

Left as clearly-marked TODOs because they need a real device to iterate on:
fine-tuning the region-selection UX, a custom icon asset, wiring the
Camera and Translate tabs to the same native engines, and a proper
in-app language picker beyond the 6 example pairs.

## Building it in Termux

Termux can build a real Flutter APK — people do this regularly — but the
toolchain is heavy (Flutter SDK + Android SDK + a JDK), so budget real
disk space (3–5 GB) and patience on the first build.

```bash
pkg update && pkg upgrade -y
pkg install -y git wget unzip openjdk-17

# Get a Termux-packaged Flutter SDK (prebuilt for aarch64, avoids
# building Flutter's own engine from source on-device):
curl -s https://raw.githubusercontent.com/Hax4us/flutter_in_termux/master/install.sh | bash -s

# restart Termux, then:
flutter doctor
flutter config --android-sdk $PREFIX/share/android-sdk
```

Then bring this scaffold into a real Flutter project (this repo is
missing the boilerplate files `flutter create` normally generates —
`android/settings.gradle`, `gradle-wrapper`, launcher icons, etc.):

```bash
flutter create screen_translator
cd screen_translator
# copy this repo's lib/, android/app/src/main/AndroidManifest.xml,
# and android/app/src/main/kotlin/ over the generated ones, then:
# paste android/app/build.gradle.snippet's dependencies block into
# the generated android/app/build.gradle
flutter pub get
flutter build apk --release --target-platform android-arm64
```

The APK lands at `build/app/outputs/flutter-apk/app-release.apk`.
Install it with `pkg install android-tools && adb install <path>`, or
just copy the file to your phone and open it.

## Known rough edges to test on-device

- `MediaProjection` requires a one-time user consent dialog per app
  launch (Android security requirement) — `ScreenCaptureActivity.kt`
  handles this, but the first tap after opening the app will always show
  it.
- Some OEMs (Xiaomi, Huawei, Samsung's aggressive battery saver) kill
  background services; the Home screen already shows the same warning
  banner your reference app does.
- `SYSTEM_ALERT_WINDOW` is a "special app access" permission — it can't
  be requested with a normal runtime-permission dialog, which is why
  `requestOverlayPermission()` opens Android's settings screen instead.
