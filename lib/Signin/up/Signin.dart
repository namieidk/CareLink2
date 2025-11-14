import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'Signup.dart';
import '../../auth_service.dart';
import '../../Patient/Home.dart';
import '../../Caregiver/Home.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatingController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    Map<String, dynamic> result;
    try {
      result = await _auth.signInWithEmail(
        email: email,
        password: password,
      );
    } catch (e) {
      result = {'success': false, 'error': 'Unexpected: $e'};
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final role = result['role'];
      
      if (role == 'Caregiver') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CaregiverHomeScreen()),
        );
      } else if (role == 'Patient') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PatientHomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unknown user type')),
        );
      }
    } else {
      final msg = (result['error'] ?? 'Login failed').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.mediumImpact();
    setState(() => _isGoogleLoading = true);

    Map<String, dynamic> result;
    try {
      result = await _auth.signInWithGoogle();
    } catch (e) {
      result = {'success': false, 'error': 'Unexpected: $e'};
    }

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result['success'] == true) {
      final role = result['role'];
      
      if (role == 'Caregiver') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CaregiverHomeScreen()),
        );
      } else if (role == 'Patient') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PatientHomePage()),
        );
      }
    } else if (result['error'] == 'account_not_found') {
      // Show dialog to choose role
      _showRoleSelectionDialog(
        uid: result['userId'],
        email: result['email'],
        displayName: result['displayName'],
        photoUrl: result['photoUrl'],
      );
    } else {
      final msg = (result['error'] ?? 'Login failed').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  void _showRoleSelectionDialog({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Choose Account Type',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This is your first time signing in with Google.\nPlease select your account type:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildRoleButton(
              title: 'Patient',
              icon: Icons.person,
              color: const Color(0xFFFF8383),
              onTap: () async {
                Navigator.pop(context);
                await _createGoogleAccount(
                  uid: uid,
                  email: email,
                  role: 'Patient',
                  displayName: displayName,
                  photoUrl: photoUrl,
                );
              },
            ),
            const SizedBox(height: 12),
            _buildRoleButton(
              title: 'Caregiver',
              icon: Icons.favorite,
              color: const Color(0xFF64B5F6),
              onTap: () async {
                Navigator.pop(context);
                await _createGoogleAccount(
                  uid: uid,
                  email: email,
                  role: 'Caregiver',
                  displayName: displayName,
                  photoUrl: photoUrl,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createGoogleAccount({
    required String uid,
    required String email,
    required String role,
    String? displayName,
    String? photoUrl,
  }) async {
    setState(() => _isGoogleLoading = true);

    final result = await _auth.createGoogleAccount(
      uid: uid,
      email: email,
      role: role,
      displayName: displayName,
      photoUrl: photoUrl,
    );

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result['success'] == true) {
      final accountRole = result['role'];
      
      if (accountRole == 'Caregiver') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CaregiverHomeScreen()),
        );
      } else if (accountRole == 'Patient') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PatientHomePage()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to create account')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isWeb = size.width > 600;

    final double horizontalPadding = isWeb ? size.width * 0.08 : 42.0;
    final double panelTopPosition = size.height * 0.30;
    final double logoTopPosition = size.height * 0.08;
    final double logoSize = isWeb ? 160 : 140;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ModernBackgroundPainter(_floatingController.value),
                );
              },
            ),
          ),

          // Logo
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: logoTopPosition,
            height: logoSize + 40,
            child: Center(
              child: Image.asset(
                'assets/logo.png',
                height: logoSize,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // White curved panel
          Positioned(
            left: 0,
            right: 0,
            top: panelTopPosition,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isWeb ? 60 : 50),
                  topRight: Radius.circular(isWeb ? 60 : 50),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 25,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isWeb ? size.height * 0.07 : 44,
                horizontalPadding,
                isWeb ? size.height * 0.05 : 40,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: isWeb ? 42 : 36,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF424242),
                            ),
                          ),
                          Container(
                            width: 60,
                            height: 4,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8383),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Email Field
                          _buildTextField(
                            label: 'Email',
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            validator: _validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            isWeb: isWeb,
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          _buildTextField(
                            label: 'Password',
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            validator: _validatePassword,
                            isWeb: isWeb,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFFBDBDBD),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                                HapticFeedback.selectionClick();
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Remember Me + Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (val) {
                                        setState(() => _rememberMe = val!);
                                        HapticFeedback.selectionClick();
                                      },
                                      activeColor: const Color(0xFFFF8383),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember Me',
                                    style: TextStyle(
                                      fontSize: isWeb ? 16 : 14,
                                      color: const Color(0xFF424242),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Forgot Password clicked')),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: isWeb ? 16 : 14,
                                    color: const Color(0xFFFF8383),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading || _isGoogleLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF8383),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 8,
                                shadowColor: const Color(0xFFFF8383).withOpacity(0.4),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: isWeb ? 20 : 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Divider with "OR"
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFFBDBDBD))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: const Color(0xFF9E9E9E),
                                    fontSize: isWeb ? 14 : 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFBDBDBD))),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Google Sign-In Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading || _isGoogleLoading ? null : _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFBDBDBD), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: _isGoogleLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    )
                                  : Image.asset(
                                      'assets/google_logo.png', // Make sure to add Google logo to assets
                                      height: 24,
                                      width: 24,
                                    ),
                              label: Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: isWeb ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF424242),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sign Up Link
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: isWeb ? 16 : 14,
                                  color: const Color(0xFF9E9E9E),
                                ),
                                children: [
                                  const TextSpan(text: "Don't have an Account? "),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const SignUpScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Sign up',
                                        style: TextStyle(
                                          color: Color(0xFFFF8383),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    required bool isWeb,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isWeb ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: isWeb ? 16 : 14,
            color: const Color(0xFF424242),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFFBDBDBD), size: 20),
            suffixIcon: suffixIcon,
            hintText: isPassword ? 'Enter your password' : null,
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFFBDBDBD).withOpacity(0.5)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFF8383), width: 2),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            focusedErrorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            errorStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ===================================================================
// BACKGROUND PAINTERS - UNCHANGED
// ===================================================================
class ModernBackgroundPainter extends CustomPainter {
  final double animation;
  ModernBackgroundPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFCCCC),
          Color(0xFFFFB5B5),
          Color(0xFFFF9999),
          Color(0xFFFF8383),
        ],
        stops: [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.75));

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.75), gradientPaint);

    _drawFloatingBlob(
      canvas,
      Offset(size.width * 0.15,
          size.height * 0.15 + math.sin(animation * math.pi * 2) * 20),
      80,
      Colors.white.withOpacity(0.15),
    );
    _drawFloatingBlob(
      canvas,
      Offset(size.width * 0.85,
          size.height * 0.25 + math.cos(animation * math.pi * 2 + 1) * 25),
      100,
      Colors.white.withOpacity(0.12),
    );
    _drawFloatingBlob(
      canvas,
      Offset(size.width * 0.5,
          size.height * 0.08 + math.sin(animation * math.pi * 2 + 2) * 15),
      60,
      Colors.white.withOpacity(0.18),
    );
    _drawFloatingBlob(
      canvas,
      Offset(size.width * 0.2,
          size.height * 0.4 + math.cos(animation * math.pi * 2 + 3) * 18),
      90,
      Colors.white.withOpacity(0.1),
    );
    _drawFloatingBlob(
      canvas,
      Offset(size.width * 0.75,
          size.height * 0.45 + math.sin(animation * math.pi * 2 + 4) * 22),
      110,
      Colors.white.withOpacity(0.08),
    );

    _drawDecorativeCurves(canvas, size, animation);
    _drawTopographicLines(canvas, size);
  }

  void _drawFloatingBlob(
      Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, radius, paint);

    final innerPaint = Paint()
      ..color = color.withOpacity(color.opacity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius * 0.6, innerPaint);
  }

  void _drawDecorativeCurves(
      Canvas canvas, Size size, double animation) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path1 = Path();
    path1.moveTo(size.width * 0.1, size.height * 0.2);
    path1.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.15 + math.sin(animation * math.pi * 2) * 10,
      size.width * 0.5,
      size.height * 0.25,
    );
    path1.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.35,
      size.width * 0.9,
      size.height * 0.3,
    );
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(size.width * 0.05, size.height * 0.5);
    path2.cubicTo(
      size.width * 0.25,
      size.height * 0.48 + math.cos(animation * math.pi * 2 + 1) * 8,
      size.width * 0.5,
      size.height * 0.52,
      size.width * 0.75,
      size.height * 0.5,
    );
    canvas.drawPath(path2, paint);
  }

  void _drawTopographicLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _drawOrganicCircle(
        canvas, paint, Offset(size.width * 0.15, size.height * 0.12), 35);
    _drawOrganicCircle(
        canvas, paint, Offset(size.width * 0.15, size.height * 0.12), 50);
    _drawOrganicCircle(
        canvas, paint, Offset(size.width * 0.15, size.height * 0.12), 65);

    _drawOrganicCircle(
        canvas, paint, Offset(size.width * 0.85, size.height * 0.2), 40);
    _drawOrganicCircle(
        canvas, paint, Offset(size.width * 0.85, size.height * 0.2), 60);
    _drawOrganicCircle(
        canvas, paint, Offset(size.width * 0.85, size.height * 0.2), 80);

    _drawOrganicCircle(
        canvas, paint, Offset(size.width * 0.2, size.height * 0.42), 45);
    _drawOrganicCircle(
        canvas, paint, Offset(size.width * 0.2, size.height * 0.42), 65);

    _drawOrganicCircle(
        canvas, paint, Offset(size.width * 0.75, size.height * 0.5), 50);
    _drawOrganicCircle(
        canvas, paint, Offset(size.width * 0.75, size.height * 0.5), 75);
  }

  void _drawOrganicCircle(
      Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ModernBackgroundPainter oldDelegate) =>
      animation != oldDelegate.animation;
}