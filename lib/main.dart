import 'dart:async';
import 'dart:io';

import 'package:animated_background/animated_background.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// ---------------------------------------------------------------------------
///  MAIN – initialise Firebase first
/// ---------------------------------------------------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // reads google-services.json / GoogleService-Info.plist
  runApp(const TalkAmiApp());
}

class TalkAmiApp extends StatelessWidget {
  const TalkAmiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talk AMI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}

/// ==================================================
/// 1. SPLASH SCREEN – animated + polling
/// ==================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  Timer? _pollTimer;
  final Duration _pollInterval = const Duration(seconds: 5);
  final String _hostToCheck = 'talk.ami-intelligente.com';

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();

    // Scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _scaleController.forward();

    // Start checking connectivity
    _checkAndNavigateIfOnline();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkAndNavigateIfOnline());
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup(_hostToCheck)
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkAndNavigateIfOnline() async {
    if (!mounted) return;
    if (await _hasInternet()) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WebViewPage()),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = screenWidth * 0.7;
    final imageHeight = imageWidth * (2 / 3);

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logoausturaliatalk.png',
                      width: imageWidth,
                      height: imageHeight,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(strokeWidth: 3),
                    const SizedBox(height: 12),
                    const Text(
                      'Connexion introuvable • Vérification en cours...',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
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
/// 2. WEBVIEW PAGE – native FCM + injection
/// ==================================================
class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _errorMessage = '';
  String? _fcmToken;
  Timer? _pollTimer;
  final Duration _pollInterval = const Duration(seconds: 5);
  final String _hostToCheck = 'talk.ami-intelligente.com';

  @override
  void initState() {
    super.initState();
    _initWebView();
    _obtainNativeFcmTokenAndInject();
    _startConnectivityPolling();
  }

  // -------------------------------------------------
  // WebView setup
  // -------------------------------------------------
  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterApi',
        onMessageReceived: (msg) {
          debugPrint('JS → Flutter: ${msg.message}');
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (e) => setState(() {
            _isLoading = false;
            _errorMessage = '${e.errorCode}: ${e.description}';
          }),
        ),
      )
      ..loadRequest(Uri.parse('http://192.168.100.4:4200'));
  }

  // -------------------------------------------------
  // 1. Get native FCM token & inject into page
  // -------------------------------------------------
  Future<void> _obtainNativeFcmTokenAndInject() async {
    final messaging = FirebaseMessaging.instance;

    // iOS permission dialog
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('User denied push permission');
      return;
    }

    final token = await messaging.getToken(
      vapidKey:
          'BKDk9gmOpgsUHknZ6DMp1Q6BKgM-nhg5eahQzLAl_SAuxnubjQcML2kB2Hemv1EPjRcvWMOqNO3CdKohOMQY_Ig',
    );

    if (token == null) {
      debugPrint('Failed to get FCM token');
      return;
    }

    setState(() => _fcmToken = token);

    // Wait until JS environment is ready
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 300));
      final ready = await _controller.runJavaScriptReturningResult(
          'typeof window !== "undefined"');
      return ready.toString() != 'true';
    });

    // INJECT TOKEN
    await _controller.runJavaScript('''
      window.flutterFcmToken = "$token";
      // Force Angular change detection if Angular is present
      if (typeof angular !== "undefined") {
        setTimeout(() => {
          const el = document.querySelector('app-login');
          if (el) {
            const scope = angular.element(el).scope();
            if (scope) scope.\$apply();
          }
        }, 0);
      }
    ''');

    debugPrint('Native FCM token injected: $token');
  }

  // -------------------------------------------------
  // 2. Connectivity polling (fallback to splash)
  // -------------------------------------------------
  Future<void> _startConnectivityPolling() async {
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      final online = await _hasInternet();
      if (!mounted) return;
      if (!online) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    });
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup(_hostToCheck)
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------
  // Refresh & external browser
  // -------------------------------------------------
  Future<void> _onRefresh() async => _controller.reload();

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.parse('http://192.168.100.4:4200');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFffffff),
      appBar: AppBar(
        toolbarHeight: 5,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const SizedBox.shrink(),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Stack(
          children: [
            // WebView
            WebViewWidget(controller: _controller),

            // Loading
            if (_isLoading) const Center(child: CircularProgressIndicator()),

            // Error
            if (_errorMessage.isNotEmpty)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(_errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _openInExternalBrowser,
                      child: const Text('Ouvrir dans le navigateur'),
                    ),
                  ],
                ),
              ),

            // DEBUG: show token badge
            if (_fcmToken != null)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black54,
                  child: const Text(
                    'Token OK',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}