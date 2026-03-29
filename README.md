# LockedIn Frontend

## What This Project Is

LockedIn is a Flutter mobile client for student productivity. It combines authentication, personal productivity tools, social features, and real-time communication in one app.

The core product flow is:

1. Authenticate (email/password or Google).
2. Set and track daily productivity goals (streaks).
3. Use tools such as Pomodoro, to-do list, flashcards, and AI task breakdown.
4. Join social features (follow users, private chat, group chat, study rooms).

This frontend is tightly coupled to the LockedIn backend API and a few external platforms (Firebase, Stream Chat, Jitsi/JaaS). Most setup issues come from missing config for those services.

## Core Features

This app is built as one connected experience. These are the core feature areas that are currently wired in code.

### Authentication and Session

- Email/password sign up and login.
- Google sign-in.
- Forgot password flow with OTP and reset.
- Token persistence in secure storage.
- Centralized logout cleanup (chat disconnect, provider resets, notification token cleanup).

### Productivity Hub

- Daily goal selection and streak tracking.
- Pomodoro timer with session prompts and ranking/stat endpoints.
- To-do list management.
- Flashcard deck creation, editing, studying, and test mode with result screen.
- AI task breakdown screen for turning larger tasks into actionable steps.

### Chat and Collaboration

- Private one-to-one chat.
- Group chat creation and management (add/remove members, transfer ownership, rename, leave, delete).
- Study room lobby and room participation.
- Jitsi/JaaS-backed video sessions from study room flow.

### Social and Profile

- Search users.
- Follow/unfollow users.
- Followers/following lists with mutual-follow state.
- Own profile and other-user profile views.
- Profile updates (name, username, bio, avatar upload).

### Content and Discovery

- Book summary list and related book feature routes.
- Book favorites and reviews API integration.

### Notifications

- Firebase Cloud Messaging setup.
- Foreground local notifications.
- Device token registration/removal against backend on login/logout.

## Tech Stack

This is a Flutter app (Dart SDK ^3.9.0) with a Provider state layer and `go_router` navigation.

Major dependencies and why they matter during setup:

- `flutter_dotenv`: runtime config from `.env`.
- `firebase_core` and `firebase_messaging`: push notifications and Firebase bootstrap.
- `google_sign_in`: Google authentication flow.
- `stream_chat_flutter`: private and group chat UI + client.
- `jitsi_meet_flutter_sdk`: video rooms for study sessions.
- `flutter_secure_storage`: persistent auth token storage.

Platform/build constraints visible in the repo:

- Android: Java 17 toolchain, `minSdk = 26`, Google Services plugin enabled.
- iOS: deployment target 15.1 in Podfile.

There is no `package.json` in this repository. Dependency management is fully Flutter/Dart via `pubspec.yaml`.

## Running Locally

### Prerequisites

- Flutter SDK with Dart 3.9+.
- Xcode and CocoaPods for iOS builds.
- Android Studio (or Android SDK + emulator) for Android builds.

### 1) Install dependencies

```bash
flutter pub get
```

### 2) Create local environment file

Create `.env` in the project root (or copy from your team secret manager values).

Minimum keys you should define:

- `API_BASE_URL`
- `STREAM_API_KEY`
- `JAAS_APP_ID`
- `GOOGLE_CLIENT_ID_IOS`
- `GOOGLE_CLIENT_ID_ANDROID`
- `GOOGLE_CLIENT_ID_WEB`

Notes:

- The app loads `.env` in `main.dart` before providers are created.
- If `API_BASE_URL` does not include `/api`, `lib/config/env.dart` appends it automatically.

### 3) Configure Firebase and Google Sign-In

- Android: place `google-services.json` in `android/app/`.
- iOS: place `GoogleService-Info.plist` in `ios/Runner/`.
- Confirm iOS URL scheme is set in `ios/Runner/Info.plist`.

The repository includes `GOOGLE_SIGNIN_SETUP.md` with the expected Firebase/Google Console flow.

### 4) Run app

```bash
# Android
flutter run -d android

# iOS
flutter run -d iphone
```

## Project Structure

The codebase is organized by feature and layer.

- `lib/main.dart`: app bootstrap, provider wiring, router setup, session cleanup hooks.
- `lib/config/`: environment and API endpoint configuration.
- `lib/models/`: typed data models by feature (user, chat, streak, productivity tools).
- `lib/services/`: HTTP/service integrations (auth, chat, follow, streak, study room, etc.).
- `lib/provider/`: state management with Provider/ChangeNotifier.
- `lib/ui/`: screens, reusable widgets, theme, and responsive helpers.
- `lib/utils/`: utility modules (validation, networking helpers, tracking).

Platform folders:

- `android/`: Gradle/Kotlin Android app config.
- `ios/`: Xcode/CocoaPods iOS app config.
- `assets/`: app images, media, and fonts.

## Environment and Configuration

This project depends on runtime config and third-party platform config files.

Runtime values from `.env`:

- `API_BASE_URL`: backend base URL used by all API services.
- `STREAM_API_KEY`: key for Stream Chat client initialization.
- `JAAS_APP_ID`: Jitsi as a Service app ID for study-room calls.
- `GOOGLE_CLIENT_ID_IOS`, `GOOGLE_CLIENT_ID_ANDROID`, `GOOGLE_CLIENT_ID_WEB`: OAuth client IDs used in Google sign-in flow.

Platform config files:

- Firebase options are read from `lib/firebase_options.dart`.
- Android Firebase uses `android/app/google-services.json`.
- iOS Firebase/Google uses `ios/Runner/GoogleService-Info.plist` and URL schemes in `Info.plist`.

## Build, Test, and Useful Commands

Use standard Flutter commands. There are no custom script runners in this repo.

```bash
# Static analysis
flutter analyze

# Run tests (if/when test files are present)
flutter test

# Build artifacts
flutter build apk
flutter build ios

# Clean and reinstall deps when native/tooling state gets out of sync
flutter clean
flutter pub get
```

If app icons are changed, regenerate launcher icons:

```bash
flutter pub run flutter_launcher_icons
```

## Known Gotchas

1. Logout needs full session cleanup.
   The app intentionally disconnects chat and clears provider state on logout. Keep this behavior if you modify auth flow, otherwise users can see stale chat/session data after account switching.

2. iOS Jitsi registration is patched in Podfile.
   The `post_install` hook patches `jitsi_meet_flutter_sdk` plugin code. Do not remove this unless you verify Jitsi event channel registration still works.

3. Android Jitsi dependency conflict is explicitly excluded.
   `android/app/build.gradle.kts` excludes one Media3 module to avoid duplicate class errors. Keep this exclusion when updating Jitsi or Android dependencies.

4. Release signing is not production-ready.
   Android release currently uses debug signing config. Set up proper signing before shipping builds.

5. Folder name casing is inconsistent in one area.
   The repository has `lib/ui/screens/User/` (capital `U`) while some imports reference `ui/screens/user/...`. This works on default macOS file systems but can fail on case-sensitive environments or CI.

6. `.env.example` is minimal.
   It does not include all keys currently used by the app. Use it only as a starting point and populate the full set listed above.
