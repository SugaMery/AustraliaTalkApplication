# talk_ami_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
3AM3&2S1@FFZ@uqn



Restarted application in 839ms.
flutter: [Splash] initState - starting animations and connectivity check
flutter: [Splash] _checkAndNavigateIfOnline - performing check
flutter: [Splash] _hasInternet - checking DNS for talk.ami-intelligente.com
flutter: [Splash] _hasInternet - result: true
flutter: [Splash] _checkAndNavigateIfOnline - online, navigate to WebViewPage
flutter: [Splash] cancelling timers
flutter: [WebView] initState - initializing WebView and FCM
flutter: [WebView] _initWebView - creating controller and loading /connexion
flutter: [FCM] requesting permission
flutter: [WebView] _startConnectivityPolling - start
flutter: [FCM] permission status: AuthorizationStatus.authorized
flutter: [FCM] getting token from native FCM
[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: [firebase_messaging/apns-token-not-set] APNS token has not been received on the device yet. Please ensure the APNS token is available before calling `getAPNSToken()`.
#0      MethodChannelFirebaseMessaging._APNSTokenCheck (package:firebase_messaging_platform_interface/src/method_channel/method_channel_messaging.dart:138:9)
method_channel_messaging.dart:138
<asynchronous suspension>
