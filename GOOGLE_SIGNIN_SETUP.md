# Google Sign-In Setup Guide

## ✅ What Has Been Implemented

1. ✅ Added `google_sign_in` dependency to `pubspec.yaml`
2. ✅ Implemented `signInWithGoogle()` method in `AuthService`
3. ✅ Added Google sign-in method to `AuthProvider`
4. ✅ Connected Google buttons in Login and Sign-Up screens
5. ✅ Configured iOS `Info.plist` with URL scheme placeholder
6. ✅ Added internet permission to Android `AndroidManifest.xml`
7. ✅ Updated `.env` with Google config placeholders

## 🔧 What You Need to Do

### Step 1: Install Dependencies

```bash
flutter pub get
```

### Step 2: Set Up Google OAuth Credentials

#### Option A: Using Firebase (Recommended)

1. **Go to Firebase Console**: https://console.firebase.google.com
2. **Create/Select Project**: Create a new project or select existing
3. **Add iOS App**:
   - Click "Add app" → iOS
   - Register bundle ID (check `ios/Runner.xcodeproj`)
   - Download `GoogleService-Info.plist`
   - Add file to `ios/Runner/` in Xcode (drag & drop, ensure "Copy items if needed" is checked)
   - Open the plist file and find `REVERSED_CLIENT_ID` value

4. **Add Android App**:
   - Click "Add app" → Android
   - Register package name (check `android/app/build.gradle.kts` → `applicationId`)
   - Download `google-services.json`
   - Place in `android/app/` folder

5. **Enable Google Sign-In**:
   - Go to Firebase Console → Authentication
   - Click "Get Started" → Sign-in method
   - Enable "Google" provider
   - Add support email

#### Option B: Using Google Cloud Console (Advanced)

1. Go to https://console.cloud.google.com
2. Create OAuth 2.0 credentials for:
   - iOS (OAuth client ID)
   - Android (OAuth client ID)
   - Web (for backend verification)

### Step 3: Configure iOS

1. **Update Info.plist**: Open [`ios/Runner/Info.plist`](ios/Runner/Info.plist) and replace:

   ```xml
   <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
   ```

   With your actual reversed client ID from `GoogleService-Info.plist`:

   ```xml
   <string>com.googleusercontent.apps.123456789-abcdefgh</string>
   ```

2. **Verify Bundle ID**: Ensure your iOS bundle ID matches what you registered in Firebase/Google Cloud

### Step 4: Configure Android

1. **Add google-services plugin** (if using Firebase):

   Edit `android/build.gradle.kts`:

   ```kotlin
   dependencies {
       classpath("com.android.tools.build:gradle:8.5.0")
       classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
       classpath("com.google.gms:google-services:4.4.0")  // Add this
   }
   ```

   Edit `android/app/build.gradle.kts` (at the bottom):

   ```kotlin
   // At the very bottom of the file
   apply(plugin = "com.google.gms.google-services")
   ```

2. **Verify package name**: Ensure your Android package name matches Firebase/Google Cloud registration

### Step 5: Backend Implementation

Your backend needs to verify the Google ID token. Here's an example for Node.js:

```javascript
const { OAuth2Client } = require("google-auth-library");
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

app.post("/api/auth/google", async (req, res) => {
  try {
    const { idToken } = req.body;

    // Verify the token
    const ticket = await client.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    const { email, sub: googleId, name, picture } = payload;

    // Check if user exists or create new user
    let user = await User.findOne({ email });

    if (!user) {
      user = await User.create({
        email,
        username: email.split("@")[0],
        googleId,
        displayName: name,
        avatar: picture,
        isVerified: true, // Google accounts are pre-verified
      });
    }

    // Generate your app's JWT token
    const token = generateJWT(user);

    res.json({
      success: true,
      data: {
        token,
        user: {
          id: user._id,
          email: user.email,
          username: user.username,
        },
      },
    });
  } catch (error) {
    res.status(401).json({ success: false, message: "Invalid token" });
  }
});
```

### Step 6: Update Environment Variables (Optional)

If you want to add client IDs to `.env` for documentation:

```env
# Already added as comments in .env file
GOOGLE_CLIENT_ID_IOS=your-ios-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_ID_ANDROID=your-android-client-id.apps.googleusercontent.com
GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps.your-reversed-id
```

### Step 7: Test the Implementation

1. **Clean and rebuild**:

   ```bash
   flutter clean
   flutter pub get
   ```

2. **iOS**:

   ```bash
   flutter run -d iphone
   ```

3. **Android**:

   ```bash
   flutter run -d android
   ```

4. **Test the flow**:
   - Tap "Continue with Google" button
   - Sign in with Google account
   - Verify redirect to productivity hub
   - Check backend receives and verifies token

## 🔍 Troubleshooting

### iOS Issues

**Error: "Unable to open URL"**

- Verify `CFBundleURLSchemes` in Info.plist matches your reversed client ID
- Check `GoogleService-Info.plist` is added to Xcode project

**Error: "No application found"**

- Ensure URL scheme exactly matches reversed client ID (no typos)
- Rebuild the app after changing Info.plist

### Android Issues

**Error: "Developer Error" / "Error 10"**

- Verify SHA-1 fingerprint is added to Firebase Console
- Get SHA-1: `cd android && ./gradlew signingReport`
- Add both debug and release SHA-1 to Firebase

**Error: "INTERNAL_ERROR"**

- Check `google-services.json` is in correct location
- Verify package name matches Firebase registration

### Backend Issues

**Token verification fails**

- Ensure you're using the correct Web Client ID for backend verification
- Check token is being sent correctly in request body
- Verify Google Auth library is installed: `npm install google-auth-library`

## 📱 Testing on Physical Device

For iOS physical device:

- Ensure your Mac and iPhone are on same Wi-Fi
- Update API_BASE_URL in `.env` to use your Mac's IP:
  ```env
  API_BASE_URL=http://192.168.1.x:3000/api
  ```
- Rebuild the app

## 📚 Additional Resources

- [google_sign_in package](https://pub.dev/packages/google_sign_in)
- [Firebase Console](https://console.firebase.google.com)
- [Google Cloud Console](https://console.cloud.google.com)
- [Google Sign-In for iOS](https://developers.google.com/identity/sign-in/ios/start)
- [Google Sign-In for Android](https://developers.google.com/identity/sign-in/android/start)

## 🎉 Summary

The Google Sign-In flow is now implemented:

1. User taps "Continue with Google"
2. Google sign-in dialog opens
3. User authenticates with Google
4. App receives ID token
5. Token sent to your backend at `/api/auth/google`
6. Backend verifies token and returns app JWT
7. User logged in and redirected to productivity hub

Complete the configuration steps above to enable full functionality!
