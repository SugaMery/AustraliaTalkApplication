# 🚀 Firebase Integration - QUICK START

**TL;DR Version** - Get Firebase working in 5 simple phases

---

## ⚡ Phase 1: Firebase Console (10 min)

1. Go to https://firebase.google.com
2. Click "Create Project" → Name it `talk-ami-app`
3. Enable Google Analytics (optional)
4. Wait for project to create

---

## 📱 Phase 2: Register Your Apps (15 min)

### Android
1. In Firebase Console: Click `+` Add app → Android
2. Package name: `com.ami.australia.talk`
3. Download `google-services.json`
4. You already have it at: `android/app/google-services.json` ✓

### iOS
1. In Firebase Console: Click `+` Add app → iOS
2. Bundle ID: Find in Xcode (App settings → Bundle ID)
3. Download `GoogleService-Info.plist`
4. Drag it into Xcode → Runner → Check "Copy if needed"

---

## 🔑 Phase 3: Update Credentials (5 min)

Edit: `lib/firebase_options.dart`

Replace `YOUR_*` with values from Firebase Console:
- `apiKey` - from google-services.json
- `appId` - from google-services.json
- `messagingSenderId` - from Firebase Console
- `projectId` - from Firebase Console
- `storageBucket` - from Firebase Console

**Don't know where?** 
- Android values → Open google-services.json in text editor
- iOS values → Open GoogleService-Info.plist in Xcode

---

## 🔔 Phase 4: Enable Cloud Messaging (5 min)

1. Firebase Console → Cloud Messaging
2. **For iOS only:**
   - Generate APNs certificate or key
   - Upload to Firebase Console
   - (Android auto-works)

---

## ✅ Phase 5: Test (10 min)

```bash
# Get dependencies
flutter pub get

# Run on Android
flutter run -d android

# OR run on iOS
cd ios && pod install && cd ..
flutter run -d ios
```

**Watch console for:** `FCM Token: xxxxxx`

---

## 📤 Send Test Notification

1. Firebase Console → Cloud Messaging
2. Click "Create campaign"
3. "Firebase Notification messages"
4. Type title & body
5. Target: "Single device" → Paste your FCM token
6. Send
7. **Notification should arrive on your device!** ✅

---

## 🎯 That's It!

You're done! Your app now has:
- ✅ Push notifications
- ✅ Topic subscriptions
- ✅ Message handling
- ✅ Token management

---

## 💡 Use in Your Code

```dart
// Get token
String? token = await FirebaseService().getFCMToken();

// Subscribe to topic
await FirebaseService().subscribeToTopic('updates');

// Listen to messages
FirebaseService().onMessage.listen((message) {
  print('Notification: ${message.notification?.title}');
});
```

See `examples_firebase_usage.dart` for more examples.

---

## 🆘 Something Wrong?

| Problem | Fix |
|---------|-----|
| Build fails | `flutter clean && flutter pub get` |
| No FCM token | Check internet, permissions, restart app |
| No notifications on iOS | Upload APNs certificate to Firebase |
| Can't find credentials | See `FIREBASE_SETUP.md` detailed guide |

---

## 📚 Full Documentation

- `FIREBASE_CHECKLIST.md` - Complete step-by-step
- `FIREBASE_SETUP.md` - Detailed with troubleshooting  
- `examples_firebase_usage.dart` - Copy-paste code
- `FIREBASE_ARCHITECTURE.md` - How it works

---

## ⏱️ Total Time: 45-60 minutes

**Start with:** Phase 1 Firebase Console → Follow through Phase 5 → Test

🎉 **You've got this!**
