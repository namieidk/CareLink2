import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;

import 'Signin.dart';   // <-- your real sign-in page

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _floatController;
  late AnimationController _loadController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  bool _showLoading = false;

  @override
  void initState() {
    super.initState();

    // Logo fade-in / slide-in
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _logoController.forward();

    // Floating background
    _floatController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    // Loading pulse
    _loadController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _loadController, curve: Curves.easeInOut),
    );
    _opacityAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _loadController, curve: const Interval(0.0, 0.5)),
    );

    // 1. Show welcome for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showLoading = true);
      _loadController.forward().then((_) {
        // 2. After loading animation, go to sign-in
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, __, ___) => const SignInScreen(),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _floatController.dispose();
    _loadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isWeb = size.width > 600;

    final double logoSize = isWeb ? size.width * 0.3 : 240;
    final double topPadding = isWeb ? size.height * 0.25 : size.height * 0.3;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ---------- Pink animated background ----------
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (_, __) => CustomPaint(
                painter: PinkBackgroundPainter(_floatController.value),
              ),
            ),
          ),

          // ---------- Logo (only Image.asset) ----------
          Positioned(
            top: topPadding,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: Image.asset(
                    'assets/logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // ---------- Optional tagline ----------
          Positioned(
            bottom: size.height * 0.18,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: const Text(
                'CareLink',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // ---------- Loading overlay (same file) ----------
          if (_showLoading)
            Container(
              color: const Color(0xCCFF69B4), // semi-transparent hot-pink
              child: Center(
                child: AnimatedBuilder(
                  animation: _loadController,
                  builder: (_, __) => Opacity(
                    opacity: _opacityAnim.value,
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            width: 100,
                            height: 100,
                          ),
                          const SizedBox(height: 32),
                          const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// PINK BACKGROUND PAINTER
// ──────────────────────────────────────────────────────────────
class PinkBackgroundPainter extends CustomPainter {
  final double animation;
  PinkBackgroundPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final grad = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFB6C1), // Light Pink
          Color(0xFFFF69B4), // Hot Pink
          Color(0xFFE91E63), // Deep Pink
          Color(0xFFC2185B), // Darker Pink
        ],
        stops: [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grad);

    // floating blobs
    _blob(canvas, Offset(size.width * 0.2, size.height * 0.2 + math.sin(animation * math.pi * 2) * 30), 90);
    _blob(canvas, Offset(size.width * 0.8, size.height * 0.3 + math.cos(animation * math.pi * 2 + 1) * 35), 110);
    _blob(canvas, Offset(size.width * 0.5, size.height * 0.15 + math.sin(animation * math.pi * 2 + 2) * 25), 70);
  }

  void _blob(Canvas canvas, Offset c, double r, [double o = 0.12]) {
    final p = Paint()
      ..color = Colors.white.withOpacity(o)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(covariant PinkBackgroundPainter old) =>
      animation != old.animation;
}