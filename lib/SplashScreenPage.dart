import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';

class ScribblrSplashPage extends StatefulWidget {
  const ScribblrSplashPage({super.key});

  @override
  State<ScribblrSplashPage> createState() => _ScribblrSplashPageState();
}

class _ScribblrSplashPageState extends State<ScribblrSplashPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize Fade Animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
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

    // Navigate to OnboardingScreen1 after 30 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive image size (e.g., 50% of screen width and scale height accordingly)
    final imageWidth = screenWidth * 0.7;
    final imageHeight = imageWidth * (2 / 3); // Maintain aspect ratio

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
            image: Image.asset('assets/images/icone-green.png'), // Ensure this asset exists
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