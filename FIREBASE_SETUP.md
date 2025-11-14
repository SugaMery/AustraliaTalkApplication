# Firebase Integration Guide for Talk AMI App

This document explains how to complete the Firebase integration setup for your Flutter app.

## What Has Been Added

1. **Firebase Core** - Already in your `pubspec.yaml`
2. **Firebase Messaging** - Already in your `pubspec.yaml`
3. **Firebase Initialization** - Added to `main.dart`
4. **Firebase Service** - New service class for managing Firebase features
5. **Firebase Options** - Configuration file for Firebase credentials

## Step 1: Set Up Firebase Project

### On Firebase Console (firebase.google.com)

1. Go to [Firebase Console](https://firebase.google.com/console)
2. Click "Create a project" or select an existing project
3. Enable Google Analytics (optional but recommended)
4. Once created, click on your project

## Step 2: Register Your App

### For Android:
1. In Firebase Console, click the **Android** icon
2. Enter your package name (usually `com.ami.australia.talk`)
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json` (already done in your project)
5. Click "Next" and follow the setup steps

### For iOS:
1. In Firebase Console, click the **iOS** icon
2. Enter your bundle ID (find in Xcode)
3. Download `GoogleService-Info.plist`
4. Open Xcode: `open ios/Runner.xcworkspace`
5. Right-click "Runner" > Add Files > select `GoogleService-Info.plist`
6. Ensure it's added to the Runner target

## Step 3: Update Firebase Credentials

Edit `lib/firebase_options.dart` and replace the placeholder values:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',      // From google-services.json
  appId: 'YOUR_ANDROID_APP_ID',        // From google-services.json
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_STORAGE_BUCKET',
);
```

You can find these values in:
- **Google-services.json** (Android) → Open with text editor
- **GoogleService-Info.plist** (iOS) → Open with Xcode or text editor

## Step 4: Enable Cloud Messaging

In Firebase Console:
1. Go to your project
2. Click **Cloud Messaging** in the left menu
3. Under "iOS app configuration":
   - Upload your **APNs authentication key** or certificate
   - This is required for iOS push notifications

## Step 5: Install Dependencies

Run this command in your project root:

```bash
flutter pub get
```

## Step 6: Build and Test

### Android:
```bash
flutter run -d android
```

### iOS:
```bash
cd ios
pod install
cd ..
flutter run -d ios
```

## Firebase Features Available

### 1. Push Notifications (Cloud Messaging)

The app now automatically:
- Requests notification permissions from users
- Gets and logs the FCM token
- Handles foreground notifications
- Handles background notifications
- Handles notifications when app is terminated

### 2. Firebase Service Methods

Available in `lib/services/firebase_service.dart`:

```dart
// Get FCM token
String? token = await FirebaseService().getFCMToken();

// Subscribe to a topic
await FirebaseService().subscribeToTopic('news');

// Unsubscribe from a topic
await FirebaseService().unsubscribeFromTopic('news');

// Listen to foreground messages
FirebaseService().onMessage.listen((message) {
  print('Message: ${message.notification?.title}');
});
```

### 3. Sending Test Notifications

In Firebase Console:
1. Go to **Cloud Messaging**
2. Click "New campaign"
3. Select "Firebase Notification messages"
4. Create and send a test notification

## Troubleshooting

### FCM Token is null
- Ensure notification permissions are granted
- Check that Firebase is properly initialized
- Restart the app

### Notifications not received on iOS
- Verify APNs certificate is uploaded to Firebase
- Check bundle ID matches Firebase configuration
- Ensure notification permissions are granted

### Notifications not received on Android
- Check notification permission is granted in Android settings
- Verify google-services.json is in the correct location
- Check Firebase project ID and Sender ID

## Files Modified/Created

- `lib/main.dart` - Firebase initialization
- `lib/firebase_options.dart` - Firebase credentials (NEW)
- `lib/services/firebase_service.dart` - Firebase service helper (NEW)
- `pubspec.yaml` - Firebase dependencies already present
- `android/app/google-services.json` - Already present in your project

## Next Steps

1. ✅ Complete the Firebase setup steps above
2. ✅ Update `firebase_options.dart` with your credentials
3. ✅ Test push notifications
4. ✅ Customize notification handling in `firebase_service.dart` as needed

## Support

For more information:
- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Cloud Messaging Setup](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire GitHub](https://github.com/firebase/flutterfire)
