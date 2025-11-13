# Firebase Integration Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Flutter App (Talk AMI)                       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      main.dart (Entry Point)                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ 1. Initialize Firebase                                  │   │
│  │ 2. Set Background Message Handler                       │   │
│  │ 3. Initialize FirebaseService                           │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                  FirebaseService (Singleton)                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ • Request Notification Permissions                      │   │
│  │ • Get/Delete FCM Token                                 │   │
│  │ • Subscribe/Unsubscribe Topics                         │   │
│  │ • Listen to Messages (Foreground & App Open)          │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────┬──────────────────────────────────────────┐
│                      ↓                                           ↓
│      ┌─────────────────────────┐        ┌──────────────────────┐
│      │   Firebase Core         │        │ Firebase Messaging   │
│      │  (Initialization)       │        │  (Push Notifications)│
│      └─────────────────────────┘        └──────────────────────┘
│                                                   ↓
│                                    ┌──────────────────────────────┐
│                                    │ Firebase Cloud Messaging     │
│                                    │ (FCM - Backend Service)      │
│                                    └──────────────────────────────┘
│
└──────────────────────────────────────────────────────────────────┘

```

## Data Flow for Push Notifications

```
┌─────────────────────────────────────────────────────────┐
│         Firebase Cloud Console                          │
│  (Create Campaign & Send Notification)                 │
└──────────────────────────┬──────────────────────────────┘
                           │
                           ↓
                ┌──────────────────────┐
                │  Firebase Servers    │
                │  (Google Cloud)      │
                └──────────────┬───────┘
                               │
                ┌──────────────┴──────────────┐
                │                             │
                ↓                             ↓
        ┌──────────────┐          ┌──────────────────┐
        │  Android     │          │  iOS Device      │
        │  Device      │          │  (APNs)          │
        │  (FCM)       │          │                  │
        └──────────────┘          └──────────────────┘
                │                            │
                └──────────────┬─────────────┘
                               │
                               ↓
                    ┌──────────────────────┐
                    │  Flutter App         │
                    │  (Your Talk AMI App) │
                    │                      │
                    │  Notification       │
                    │  Handler Triggered  │
                    └──────────────────────┘

```

## Firebase Configuration Flow

```
1. Create Firebase Project
   └─→ firebase.google.com

2. Register Apps
   ├─→ Android App
   │   └─→ Download: google-services.json
   │       (Place in: android/app/)
   │
   └─→ iOS App
       └─→ Download: GoogleService-Info.plist
           (Add to Xcode Runner target)

3. Get Credentials
   └─→ Update lib/firebase_options.dart
       ├─→ apiKey
       ├─→ appId
       ├─→ messagingSenderId
       ├─→ projectId
       └─→ storageBucket

4. Enable Cloud Messaging
   └─→ Upload iOS APNs Certificate/Key
       (For iOS push notifications)

5. Flutter Integration
   ├─→ main.dart (Init Firebase)
   ├─→ FirebaseService (Manage features)
   └─→ Your Pages (Use Firebase features)
```

## File Dependencies

```
main.dart
  ├─→ firebase_options.dart
  ├─→ services/firebase_service.dart
  └─→ flutter packages
      ├─→ firebase_core
      ├─→ firebase_messaging
      └─→ others...

services/firebase_service.dart
  ├─→ firebase_messaging
  ├─→ flutter
  └─→ (No internal dependencies)

firebase_options.dart
  └─→ firebase_core
```

## Message Types Handled

```
┌─────────────────────────────────────────────┐
│     Firebase Message Types                  │
├─────────────────────────────────────────────┤
│                                             │
│  1. Notification Messages (Display)        │
│     ├─→ Title                              │
│     ├─→ Body                               │
│     └─→ Image                              │
│                                             │
│  2. Data Messages (Background)             │
│     ├─→ Custom key-value pairs             │
│     └─→ Handled by your code               │
│                                             │
│  3. Combined Messages                      │
│     ├─→ Notification + Data                │
│     └─→ Full rich experience               │
│                                             │
└─────────────────────────────────────────────┘
```

## State Handling

```
App States → Message Handler

1. FOREGROUND (App Visible)
   └─→ FirebaseService.onMessage listener
       └─→ Show dialog/snackbar

2. BACKGROUND (App Minimized)
   └─→ Background handler
       └─→ OS notification tray

3. TERMINATED (App Closed)
   └─→ Background handler
       └─→ OS notification tray
       └─→ User taps → App opens
           └─→ FirebaseService.onMessageOpenedApp
               └─→ Navigate to specific screen

4. APP OPENED FROM NOTIFICATION
   └─→ FirebaseService.onMessageOpenedApp
       └─→ Handle navigation/action
```

---

This architecture ensures:
✅ Reliable message delivery
✅ Proper permission handling
✅ Background execution support
✅ Clean separation of concerns
✅ Easy to extend and customize
