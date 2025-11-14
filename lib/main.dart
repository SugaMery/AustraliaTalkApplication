import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:animated_background/animated_background.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

/// ---------------------------------------------------------------------------
///  MAIN – initialise Firebase (reads android/app/google-services.json)
/// ---------------------------------------------------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TalkAmiApp());
}

class TalkAmiApp extends StatelessWidget {
  const TalkAmiApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
        title: 'Talk AMI',
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      );
}

/// ==================================================
/// 1. SPLASH SCREEN – animated + polling with timeout
/// ==================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  Timer? _pollTimer;
  Timer? _timeoutTimer;
  bool _showOfflineError = false;
  static const int _timeoutSeconds = 30; // max wait time for internet

  @override
  void initState() {
    super.initState();
    debugPrint('[Splash] initState - starting animations and connectivity check');

    // Initialize Fade Animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();

    // Initialize Scale Animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _scaleController.forward();

    // Start connectivity check
    _checkAndNavigateIfOnline();

    // Poll every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        debugPrint('[Splash] periodic connectivity poll tick');
        _checkAndNavigateIfOnline();
      }
    });

    // Timeout after 30 seconds: if still not online, show error
    _timeoutTimer = Timer(const Duration(seconds: _timeoutSeconds), () {
      if (mounted && _fcmToken == null) {
        // Still not online and haven't navigated away
        debugPrint('[Splash] timeout reached, showing offline error');
        setState(() => _showOfflineError = true);
      }
    });
  }

  bool _navigated = false; // flag to prevent multiple navigations

  Future<bool> _hasInternet() async {
    debugPrint('[Splash] _hasInternet - checking DNS for talk.ami-intelligente.com');
    try {
      final result = await InternetAddress.lookup('talk.ami-intelligente.com')
          .timeout(const Duration(seconds: 5));
      final ok = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      debugPrint('[Splash] _hasInternet - result: $ok');
      return ok;
    } catch (e) {
      debugPrint('[Splash] _hasInternet - error: $e');
      return false;
    }
  }

  // Just a flag to track if we've navigated (used by timeout)
  bool? _fcmToken;

  Future<void> _checkAndNavigateIfOnline() async {
    if (!mounted || _navigated) {
      debugPrint('[Splash] _checkAndNavigateIfOnline - not mounted or already navigated, abort');
      return;
    }
    debugPrint('[Splash] _checkAndNavigateIfOnline - performing check');
    if (await _hasInternet()) {
      debugPrint('[Splash] _checkAndNavigateIfOnline - online, navigate to WebViewPage');
      _navigated = true;
      _cancelTimers();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WebViewPage()),
      );
    } else {
      debugPrint('[Splash] _checkAndNavigateIfOnline - still offline');
    }
  }

  void _cancelTimers() {
    debugPrint('[Splash] cancelling timers');
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
  }

  void _retryConnection() {
    debugPrint('[Splash] user tapped retry');
    setState(() => _showOfflineError = false);
    _checkAndNavigateIfOnline();
  }

  @override
  void dispose() {
    debugPrint('[Splash] dispose - cancelling animations and timers');
    _fadeController.dispose();
    _scaleController.dispose();
    _cancelTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = screenWidth * 0.7;
    final imageHeight = imageWidth * (2 / 3);


    // Show animated splash while checking internet
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBackground(
        vsync: this,
        behaviour: RandomParticleBehaviour(
          options: ParticleOptions(
            baseColor: const Color(0xFF54A651).withOpacity(0.15),
            spawnMinSpeed: 8.0,
            spawnMaxSpeed: 25.0,
            particleCount: 50,
            spawnOpacity: 0.3,
            image: Image.asset('assets/images/icone-green.png'),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/images/logoausturaliatalk.png',
                  width: imageWidth,
                  height: imageHeight,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ==================================================
/// 2. WEBVIEW PAGE – login → home + auto-device-token
/// ==================================================
class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});
  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  String? _fcmToken;
  Timer? _pollTimer;

  // Keep last time we logged a "skip because already registered" per user
  final Map<String, DateTime> _lastSkipLog = {};

  // --- NEW: track registered tokens per user and in-progress registrations
  final Map<String, String> _registeredUserTokens = {}; // userId -> fcmToken
  final Set<String> _registeringUsers = {}; // userIds currently being registered

  // --- NEW fields to avoid repeated heavy work
  String? _lastLocalStorageJson;
  String? _lastPath;
  bool _processingStorage = false;

  // --- NEW: prefs + key to persist last known FCM token
  SharedPreferences? _prefs;
  static const String _prefFcmKey = 'fcm_token';

  @override
  void initState() {
    super.initState();
    debugPrint('[WebView] initState - initializing WebView and FCM');
    _initWebView();
    _initAsync(); // init prefs & token refresh listener
    _obtainNativeFcmTokenAndInject();
    _startConnectivityPolling();
  }

  // --- NEW helper to init SharedPreferences & token refresh listener
  Future<void> _initAsync() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      // listen for FCM token refresh events
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] onTokenRefresh received: ${newToken != null ? "<redacted>" : null}');
        if (newToken != null) _handleNewFcmToken(newToken);
      });
    } catch (e) {
      debugPrint('[WebView] _initAsync error: $e');
    }
  }

  // -------------------------------------------------
  // WebView setup – start on **/connexion**
  // -------------------------------------------------
  void _initWebView() {
    debugPrint('[WebView] _initWebView - creating controller and loading /connexion');
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('FlutterApi',
          onMessageReceived: (msg) {
            debugPrint('[WebView][JS→Flutter] raw: ${msg.message}');
            try {
              final payload = jsonDecode(msg.message);
              if (payload is Map<String, dynamic> || payload is Map) {
                final userId = payload['user_id']?.toString();
                final siteToken = payload['token']?.toString();
                debugPrint('[WebView][JS→Flutter] parsed payload user_id:$userId token:${siteToken != null ? "<redacted>" : null}');
                if (userId != null && siteToken != null) {
                  // If we already have native FCM token -> register immediately,
                  // otherwise store and let _obtainNativeFcmTokenAndInject/other logic handle it.
                  if (_fcmToken != null) {
                    _registerDeviceToken(userId, siteToken);
                  } else {
                    debugPrint('[WebView][JS→Flutter] received site creds but native FCM not ready yet; will register once available');
                    // store temporary retry via a short delayed waiter
                    Future<void>(() async {
                      const maxAttempts = 20;
                      for (int i = 0; i < maxAttempts; i++) {
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (_fcmToken != null) {
                          debugPrint('[WebView][JS→Flutter] native FCM now available, registering device token');
                          await _registerDeviceToken(userId, siteToken);
                          return;
                        }
                      }
                      debugPrint('[WebView][JS→Flutter] timed out waiting for native FCM token');
                    });
                  }
                }
              }
            } catch (e) {
              debugPrint('[WebView][JS→Flutter] failed to parse message: $e');
            }
          })
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          // track simple path to avoid repeated navigations later
          final path = Uri.tryParse(url)?.path ?? url;
          if (_lastPath != path) _lastPath = path;
          debugPrint('[WebView] onPageStarted: $url (path=$_lastPath)');
          setState(() {});
        },
        onPageFinished: (url) {
          debugPrint('[WebView] onPageFinished: $url');
          _onPageFinished();
        },
        onWebResourceError: (e) => debugPrint('[WebView] WebError: $e'),
      ))
      // <<< START ON LOGIN PAGE >>>
      ..loadRequest(Uri.parse('https://talk.ami-intelligente.com/connexion'));
  }

  // -------------------------------------------------
  // 1. Get native FCM token & inject
  // -------------------------------------------------
  Future<void> _obtainNativeFcmTokenAndInject() async {
    debugPrint('[FCM] requesting permission');
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] permission status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] permission denied - aborting token retrieval');
      return;
    }

    debugPrint('[FCM] getting token from native FCM');
    final token = await messaging.getToken();
    if (token == null) {
      debugPrint('[FCM] no token received from FCM');
      return;
    }

    // Delegate handling to the shared handler (persist, inject, register)
    await _handleNewFcmToken(token);
  }

  // --- NEW: central handler for any new native token
  Future<void> _handleNewFcmToken(String token) async {
    try {
      final prevStored = _prefs?.getString(_prefFcmKey);
      final changed = prevStored == null || prevStored != token;

      // update in-memory token
      setState(() => _fcmToken = token);

      // persist token
      try {
        await _prefs?.setString(_prefFcmKey, token);
      } catch (e) {
        debugPrint('[FCM] failed to persist token: $e');
      }

      // inject into WebView (ensure DOM ready)
      try {
        await _waitForDomReady();
        await _controller.runJavaScript('''
          (function(){
            window.flutterFcmToken = "$token";
            console.log("[Flutter] FCM token injected:", "$token");
            if(typeof ng!=="undefined"){
              setTimeout(()=>{ 
                const appRef = ng.getInjector(document.body).get(ng.coreTokens.ApplicationRef);
                if(appRef) appRef.tick();
              },50);
            }
          })();
        ''');
        debugPrint('[FCM] injection complete (newToken=${changed ? "yes" : "no"})');
      } catch (e) {
        debugPrint('[FCM] injection error: $e');
      }

      // If token actually changed, clear previous "registered" markers so we'll re-register for any logged-in user
      if (changed) {
        debugPrint('[FCM] token changed; clearing _registeredUserTokens to force re-registration');
        _registeredUserTokens.clear();
        // Attempt to read current site localStorage and register (if logged-in)
        await _attemptRegisterFromLocalStorage();
      } else {
        debugPrint('[FCM] token unchanged; no re-registration needed');
      }
    } catch (e) {
      debugPrint('[FCM] _handleNewFcmToken error: $e');
    }
  }

  // --- NEW: read localStorage and call _registerDeviceToken if site logged-in
  Future<void> _attemptRegisterFromLocalStorage() async {
    if (_fcmToken == null) return;
    try {
      // Run JS to get token and user_id from localStorage
      final raw = await _controller.runJavaScriptReturningResult(
          'JSON.stringify({ token: window.localStorage.token, user_id: window.localStorage.user_id })');
      final jsonStr = raw?.toString() ?? '';
      if (jsonStr.isEmpty) return;
      Map<String, dynamic>? obj;
      try {
        // handle quoted result
        String s = jsonStr;
        if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
          s = jsonDecode(s).toString();
        }
        obj = jsonDecode(s) as Map<String, dynamic>?;
      } catch (e) {
        debugPrint('[WebView] _attemptRegisterFromLocalStorage parse error: $e');
        return;
      }
      final siteJwt = obj?['token']?.toString();
      final userId = obj?['user_id']?.toString();
      if (siteJwt != null && userId != null) {
        debugPrint('[WebView] _attemptRegisterFromLocalStorage found user:$userId → registering new native token');
        await _registerDeviceToken(userId, siteJwt);
      } else {
        debugPrint('[WebView] _attemptRegisterFromLocalStorage - no site login found');
      }
    } catch (e) {
      debugPrint('[WebView] _attemptRegisterFromLocalStorage error: $e');
    }
  }

  Future<void> _waitForDomReady() async {
    const max = 30;
    debugPrint('[WebView] _waitForDomReady - start (max $max attempts)');
    for (int i = 0; i < max; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      final ok = await _controller.runJavaScriptReturningResult(
          'document.readyState==="complete"');
      debugPrint('[WebView] _waitForDomReady - attempt ${i + 1}: ready=${ok.toString()}');
      if (ok.toString() == 'true') {
        debugPrint('[WebView] _waitForDomReady - DOM ready');
        return;
      }
    }
    debugPrint('[WebView] _waitForDomReady - timed out');
  }

  // -------------------------------------------------
  // 2. After page load → check localStorage → maybe skip login
  // -------------------------------------------------
  Future<void> _onPageFinished() async {
    // Prevent concurrent runs (many page events can fire quickly)
    if (_processingStorage) {
      debugPrint('[WebView] _onPageFinished - already processing, skipping');
      return;
    }
    _processingStorage = true;
    try {
      debugPrint('[WebView] _onPageFinished - giving Angular time to restore localStorage');
      await Future.delayed(const Duration(milliseconds: 800));

      final rawResult = await _controller.runJavaScriptReturningResult('JSON.stringify(localStorage)');
      final storageJson = rawResult?.toString() ?? '{}';

      // Skip further work if storage hasn't changed since last successful parse.
      if (_lastLocalStorageJson != null && _lastLocalStorageJson == storageJson) {
        debugPrint('[WebView] localStorage unchanged, skipping');
        return;
      }
      _lastLocalStorageJson = storageJson;
      debugPrint('[WebView] localStorage raw JSON: $storageJson');

      // Robust parsing: if the JS returned a quoted string, jsonDecode will unwrap it.
      Map<String, dynamic>? storage;
      try {
        String raw;
        if ((storageJson.startsWith('"') && storageJson.endsWith('"')) ||
            (storageJson.startsWith("'") && storageJson.endsWith("'"))) {
          // jsonDecode on the quoted string yields the inner JSON string
          raw = jsonDecode(storageJson).toString();
        } else {
          raw = storageJson;
        }
        storage = jsonDecode(raw) as Map<String, dynamic>?;
      } catch (e, st) {
        debugPrint('[WebView] failed to parse storage JSON: $e\n$st');
        return; // abort gracefully if parsing fails
      }

      if (storage == null) {
        debugPrint('[WebView] localStorage parse resulted in null, aborting');
        return;
      }

      final token = storage['token']?.toString();
      final userId = storage['user_id']?.toString();

      debugPrint('[WebView] localStorage → token:${token != null ? "<redacted>" : null}  user_id:$userId');

      if (token != null && userId != null) {
        if (_fcmToken != null) {
          debugPrint('[WebView] already logged in and have FCM token → navigate/register');
          // only navigate if we're not already on the home path
          if (_lastPath != '/') {
            await _controller.runJavaScript("window.location.href='/'");
            _lastPath = '/';
          }
          await Future.delayed(const Duration(milliseconds: 600));
          await _registerDeviceToken(userId, token);
        } else {
          debugPrint('[WebView] have site login but native FCM not ready; waiting briefly');
          // wait up to ~10s for native token
          const attempts = 20;
          for (int i = 0; i < attempts; i++) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (_fcmToken != null) {
              if (_lastPath != '/') {
                await _controller.runJavaScript("window.location.href='/'");
                _lastPath = '/';
              }
              await Future.delayed(const Duration(milliseconds: 600));
              await _registerDeviceToken(userId, token);
              break;
            }
          }
          if (_fcmToken == null) {
            debugPrint('[WebView] timeout waiting for native FCM token; registration deferred');
          }
        }
      } else {
        debugPrint('[WebView] not ready to auto-login (missing token/userId/fcm)');
      }
    } finally {
      _processingStorage = false;
    }
  }

  // -------------------------------------------------
  // 3. Call your API to add the device token
  // -------------------------------------------------
  Future<void> _registerDeviceToken(String userId, String jwt) async {
    // Guard: ensure we have a native FCM token
    if (_fcmToken == null) {
      debugPrint('[API] _registerDeviceToken - aborting: native FCM token not available');
      return;
    }

    // If we already successfully registered this exact token for this user -> skip
    final already = _registeredUserTokens[userId];
    if (already != null && already == _fcmToken) {
      // Avoid spamming the logs when the same skip happens repeatedly.
      final now = DateTime.now();
      final last = _lastSkipLog[userId];
      if (last == null || now.difference(last) > const Duration(minutes: 1)) {
        debugPrint('[API] _registerDeviceToken - skipping: token already registered for user $userId');
        _lastSkipLog[userId] = now;
      }
      return;
    }

    // Prevent concurrent registrations for the same user
    if (_registeringUsers.contains(userId)) {
      debugPrint('[API] _registerDeviceToken - skipping: registration already in progress for user $userId');
      return;
    }
    _registeringUsers.add(userId);

    final url = 'https://api-australia.eloommgolfclub.ma/users/$userId';

    debugPrint('[API] _registerDeviceToken - url: $url');
    debugPrint('[API] _registerDeviceToken - body device_tokens: [$_fcmToken]');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'device_tokens': [_fcmToken]   // <-- your backend merges this
        }),
      );

      debugPrint('[API] response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        // mark as registered so future attempts are no-ops (until token changes)
        _registeredUserTokens[userId] = _fcmToken!;
        // Clear any skip-log so a future new token will log immediately.
        _lastSkipLog.remove(userId);
        debugPrint('[API] Device token registered successfully for user $userId');
      } else {
        debugPrint('[API] API error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[API] Network error while registering token: $e');
    } finally {
      _registeringUsers.remove(userId);
    }
  }

  // -------------------------------------------------
  // 4. Connectivity fallback
  // -------------------------------------------------
  Future<void> _startConnectivityPolling() async {
    debugPrint('[WebView] _startConnectivityPolling - start');
    // Lower polling frequency to reduce main-thread pressure
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      debugPrint('[WebView] connectivity poll tick');
      final ok = await InternetAddress.lookup('talk.ami-intelligente.com')
          .then((r) => r.isNotEmpty)
          .catchError((e) {
            debugPrint('[WebView] connectivity poll error: $e');
            return false;
          });
      debugPrint('[WebView] connectivity poll result: $ok');
      if (!ok && mounted) {
        debugPrint('[WebView] offline detected - navigating back to SplashScreen');
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SplashScreen()));
      }
    });
  }

  @override
  void dispose() {
    debugPrint('[WebView] dispose - cancelling poll timer');
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white, // 🔥 BG blanc
    appBar: AppBar(
      toolbarHeight: 0,
      backgroundColor: Colors.white, // (optionnel) AppBar blanc aussi
      elevation: 0, // optionnel : enlever la shadow
    ),
    body: Container(
      color: Colors.white, // 🔥 s'assure que le WebView est sur fond blanc
      child: WebViewWidget(controller: _controller),
    ),
  );
}

}