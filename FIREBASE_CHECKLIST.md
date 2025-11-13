# Firebase Setup Checklist

## ✅ Code Changes Completed

- [x] Updated `main.dart` with Firebase initialization
- [x] Created `firebase_options.dart` with platform-specific configs
- [x] Created `services/firebase_service.dart` singleton service
- [x] Created example usage file
- [x] Created setup documentation
- [x] Created architecture documentation

## 📋 Your Action Items

### Phase 1: Firebase Console Setup (5-10 minutes)

- [ ] Go to https://firebase.google.com
- [ ] Create a new Firebase project or select existing one
- [ ] Enable Google Analytics (recommended)
- [ ] Name: `talk-ami-app` (or your preference)

### Phase 2: Android Setup (10-15 minutes)

- [ ] In Firebase Console, click "Add app" → Android
- [ ] Package name: `com.example.talk_ami_app` (check your build.gradle)
- [ ] Download `google-services.json`
- [ ] Place in: `android/app/google-services.json` ✓ (Already exists)
- [ ] SHA-1 fingerprint (run: `./gradlew signingReport` in android folder)
- [ ] Enter SHA-1 in Firebase Console
- [ ] Confirm registration

### Phase 3: iOS Setup (10-15 minutes)

- [ ] In Firebase Console, click "Add app" → iOS
- [ ] Bundle ID: Find in Xcode (usually `com.example.talkAmiApp`)
- [ ] Download `GoogleService-Info.plist`
- [ ] Open: `open ios/Runner.xcworkspace` (NOT .xcodeproj)
- [ ] Drag `GoogleService-Info.plist` into Xcode
- [ ] Select: "Copy items if needed" + "Runner" target
- [ ] Build number and version (optional)
- [ ] Confirm registration

### Phase 4: Configure Credentials (10 minutes)

- [ ] Open `lib/firebase_options.dart`
- [ ] For Android, fill in:
  - [ ] `apiKey` - from google-services.json
  - [ ] `appId` - from google-services.json
  - [ ] `messagingSenderId` - from google-services.json
  - [ ] `projectId` - from Firebase Console
  - [ ] `storageBucket` - from Firebase Console
- [ ] For iOS, fill in same values (get from GoogleService-Info.plist)

### Phase 5: Enable Cloud Messaging (5 minutes)

- [ ] Go to Firebase Console → Cloud Messaging
- [ ] For iOS:
  - [ ] Generate APNs Certificate or Key
  - [ ] Upload to Firebase Console
- [ ] For Android:
  - [ ] Should work automatically

### Phase 6: Build & Test (10-15 minutes)

- [ ] Run: `flutter pub get`
- [ ] On Android: `flutter run -d android`
  - [ ] Check for FCM token in console log
  - [ ] Check notification permission request
  - [ ] Accept permissions
- [ ] On iOS: 
  - [ ] `cd ios && pod install && cd ..`
  - [ ] `flutter run -d ios`
  - [ ] Check for FCM token in console log
  - [ ] Check notification permission request
  - [ ] Accept permissions

### Phase 7: Send Test Notification (5 minutes)

- [ ] Go to Firebase Console → Cloud Messaging
- [ ] Click "Create campaign"
- [ ] Type "Firebase Notification messages"
- [ ] Write test notification (title + body)
- [ ] Select target: "Single device"
- [ ] Paste your FCM token from console log
- [ ] Send
- [ ] Check if notification appears on your device

### Phase 8: Integration (Optional - 15 minutes)

- [ ] Open `lib/examples_firebase_usage.dart`
- [ ] Copy example code as needed
- [ ] Add to `SplashScreen` or `WebViewPage`:
  ```dart
  // In initState()
  final token = await FirebaseService().getFCMToken();
  print('FCM Token: $token');
  
  // Subscribe to topics
  await FirebaseService().subscribeToTopic('general');
  ```
- [ ] Customize notification handling in `FirebaseService`

## 🔍 Verification Steps

After each phase, verify:

- [ ] No build errors: `flutter analyze`
- [ ] Can run on device/emulator: `flutter run`
- [ ] FCM token appears in console (flutter run output)
- [ ] Notification permissions are requested
- [ ] Test notifications arrive

## 📱 Device/Emulator Requirements

### Android
- [ ] Emulator with Google Play Services
- [ ] Minimum API level 21+
- [ ] Physical device recommended for testing

### iOS
- [ ] Physical iPhone recommended (simulator may not receive notifications)
- [ ] iOS 11+
- [ ] Development certificate installed

## 🐛 Troubleshooting Quick Fixes

### "FCM Token is null"
```dart
// Check these in order:
1. Firebase.initializeApp() completed?
2. Notification permissions granted?
3. Internet connection available?
4. Run: flutter clean && flutter pub get
5. Rebuild app
```

### "google-services.json not found"
```
Ensure file is in: android/app/google-services.json
(Already present in your project)
```

### "GoogleService-Info.plist not added"
```
1. Open Xcode: open ios/Runner.xcworkspace
2. Right-click "Runner" folder
3. Add Files → select GoogleService-Info.plist
4. Check "Copy items if needed"
5. Check "Runner" target is selected
```

### "iOS notifications not working"
```
1. Ensure APNs certificate/key uploaded to Firebase
2. Physical device required (not simulator)
3. Check: Settings → Notifications → Talk AMI (enabled)
4. Internet connection required
```

## 📚 Documentation Files

- [x] `FIREBASE_SETUP.md` - Detailed setup guide
- [x] `FIREBASE_ARCHITECTURE.md` - How it works
- [x] `FIREBASE_INTEGRATION_SUMMARY.md` - Quick overview
- [x] `lib/examples_firebase_usage.dart` - Code examples
- [x] This file - Complete checklist

## 🎯 Success Criteria

Your Firebase setup is complete when:

1. ✅ App builds without errors
2. ✅ App runs on Android/iOS device
3. ✅ FCM token appears in console log on app startup
4. ✅ Notification permission dialog appears
5. ✅ Test notification received successfully
6. ✅ Tapping notification opens app/specific screen

## 📞 Quick Support

| Issue | Solution |
|-------|----------|
| Build fails | Run `flutter clean && flutter pub get` |
| No FCM token | Check Firebase initialization, device internet |
| No notifications | Upload iOS APNs cert, verify permissions |
| Emulator issues | Use physical device, ensure Play Services |
| Token keeps changing | Normal - each new install gets new token |

---

**Estimated Total Time: 45-60 minutes** ⏱️

**Next Step: Start with Phase 1 - Firebase Console Setup** 🚀
