# Takhti Grow — notes for Claude Code

Flutter Android app (package `com.homilabs.takhtigrow`), pilot of 4 daily neuroscience lessons from the Takhti YouTube channel. Design: `docs/takhti-grow-pilot-design-v1.md` (v1.0; D1–D10 accepted as recommended on 10 Oct 2026, package changed to `com.homilabs.*`).

## Code map
- `lib/main.dart` — Firebase init, Crashlytics, `USE_EMULATOR` switch for test builds.
- `lib/app/` — `router.dart` (go_router + auth/profile redirect), `providers.dart`, `theme.dart`, `config.dart` (`kAppBuild` must equal pubspec `+N`; URLs).
- `lib/shared/journey_logic.dart` — unlock, Today state, streak (pure Dart, unit-tested).
- `lib/features/<feature>/` — screens + repositories (auth, lesson, reminders, profile, reflections, journey, today, onboarding, home).
- `assets/lessons.json` — lesson content; bundled fallback **and** source for `tool/seed_lessons.js`. Placeholder `[TODO …]` text until Content Pack v0.1 arrives.
- `firestore.rules` / `firestore.indexes.json` — deployed with `firebase deploy --only firestore`.
- `tool/` — `seed_lessons.js` (Admin SDK), `rules.test.mjs` (emulator rules tests), `emulator-test-account.env` (emulator-only).
- `web/grow/` — privacy, terms, delete-account pages for takhti.homilabs.org/grow/ (Homi uploads to Hostinger).

## Commands
```bash
flutter analyze && flutter test
# Rules tests (firebase-tools needs Java 21):
cd tool && JAVA_HOME=~/jdks/jdk-21.0.12.1+1 PATH=~/jdks/jdk-21.0.12.1+1/bin:$PATH npm run test:rules
# Emulator test build on a USB phone:
firebase emulators:start --only auth,firestore --project takhti-grow-homilabs   # with Java 21
adb reverse tcp:9099 tcp:9099 && adb reverse tcp:8085 tcp:8085
(cd tool && FIRESTORE_EMULATOR_HOST=127.0.0.1:8085 GOOGLE_CLOUD_PROJECT=takhti-grow-homilabs node seed_lessons.js)
flutter build apk --release --target-platform android-arm64,android-arm --dart-define=USE_EMULATOR=true
# Release bundle for Play (live Firebase):
flutter build appbundle --release
```

## Gotchas
- Firebase: project `takhti-grow-homilabs`, Firestore `(default)` in **nam5** (auto-created by the first deploy).
- FlutterFire maps `127.0.0.1` → `10.0.2.2` on Android; emulator calls pass `automaticHostMapping: false` for real phones via `adb reverse`.
- `res/raw/keep.xml` keeps `@drawable/ic_stat_takhti` (used only from Dart) from release resource shrinking — without it notification setup throws.
- Firestore writes from lesson steps are fire-and-forget (offline-first); UI reads snapshots.
- Account deletion closes its progress dialog before deleting the auth user (the router replaces the stack).
- Signing: `android/key.properties` + `android/app/takhtigrow-upload.jks` (gitignored; backup in `../takhti_grow-secrets/`). Public repo — never commit them.
- RAM: Gradle capped at 3 GB in `android/gradle.properties`; don't build while another project (e.g. Stock Guru) builds; `cd android && ./gradlew --stop` when done.
