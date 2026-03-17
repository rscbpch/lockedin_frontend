# Jitsi iOS Deterministic Validation Runbook

Use this every time Jitsi behavior changes on iOS.

## 1) Rebuild iOS state

Run from project root:

```bash
flutter clean
flutter pub get
rm -rf ios/Pods ios/Podfile.lock
cd ios && pod install && cd ..
```

## 2) Build compile-check

```bash
flutter build ios --no-codesign
```

Expected: build completes successfully.

## 3) Device test flow (physical iPhone)

1. Stop any existing `flutter run` session with `q`.
2. Uninstall app from device.
3. Run app from Xcode or Flutter on physical iPhone using a fresh process start (do not rely on hot restart for plugin validation).
4. Login and open Study Room.
5. Tap Join on an active room.
6. Repeat from clean launch 3 times.

## 4) Success criteria

All must pass:

1. Jitsi screen opens from Join on 3 consecutive fresh launches.
2. No infinite "Connecting to room..." state.
3. Same behavior verified on at least one second iOS device.

## 5) Debug markers to watch in logs

From `MeetingScreen`:

- `[Jitsi] join:start ...`
- `[Jitsi] token:received ...`
- `[Jitsi] join:roomName=...`
- `[Jitsi] join:calling-native`
- `[Jitsi] event:conferenceWillJoin`
- `[Jitsi] event:conferenceJoined`
- Timeout path: `[Jitsi] error:timeout ...`

If logs stop after `join:calling-native` and no event appears, focus on iOS plugin registration/runtime environment.
