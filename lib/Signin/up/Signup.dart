// signup.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'Signin.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedUserType;

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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _fakeSignUp() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select user type')),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created as $_selectedUserType! (demo)')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isWeb = size.width > 600;

    final double horizontalPadding = isWeb ? size.width * 0.08 : 42.0;
    final double panelTopPosition = size.height * 0.25;
    final double logoTopPosition = size.height * 0.08;
    final double logoSize = isWeb ? 160 : 140;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
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
                  BoxShadow(color: Colors.black12, blurRadius: 25, offset: Offset(0, -8)),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isWeb ? size.height * 0.05 : 32,
                horizontalPadding,
                isWeb ? size.height * 0.04 : 32,
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
                          Text('Sign up',
                              style: TextStyle(
                                  fontSize: isWeb ? 42 : 36,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF424242))),
                          Container(
                            width: 60,
                            height: 4,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8383),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Username
                          _buildTextField(
                            label: 'Username',
                            controller: _usernameController,
                            icon: Icons.person_outline,
                            validator: _validateUsername,
                            hintText: 'Choose a username',
                            isWeb: isWeb,
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _buildTextField(
                            label: 'Email',
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            validator: _validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            hintText: 'Enter your email address',
                            isWeb: isWeb,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _buildTextField(
                            label: 'Password',
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            validator: _validatePassword,
                            hintText: 'Create a strong password',
                            isWeb: isWeb,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFFBDBDBD),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                                HapticFeedback.selectionClick();
                              },
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              'Must be 6+ characters with uppercase and number',
                              style: TextStyle(
                                fontSize: isWeb ? 13 : 12,
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          _buildTextField(
                            label: 'Confirm Password',
                            controller: _confirmPasswordController,
                            icon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            validator: _validateConfirmPassword,
                            hintText: 'Re-enter your password',
                            isWeb: isWeb,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFFBDBDBD),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                HapticFeedback.selectionClick();
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // User Type Dropdown
                          Text(
                            'User Type',
                            style: TextStyle(
                              fontSize: isWeb ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF424242),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedUserType,
                            hint: const Text('Select your role'),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFBDBDBD)),
                            elevation: 2,
                            dropdownColor: Colors.white,
                            style: TextStyle(
                              fontSize: isWeb ? 16 : 14,
                              color: const Color(0xFF424242),
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.account_circle_outlined, color: Color(0xFFBDBDBD), size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFBDBDBD), width: 0.5),
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
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Patient', child: Text('Patient')),
                              DropdownMenuItem(value: 'Caregiver', child: Text('Caregiver')),
                            ],
                            onChanged: _isLoading ? null : (val) => setState(() => _selectedUserType = val),
                            validator: (val) => val == null ? 'Please select a user type' : null,
                          ),
                          const SizedBox(height: 28),

                          // Create Account Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _fakeSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF8383),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: _isLoading ? 0 : 8,
                                shadowColor: const Color(0xFFFF8383).withOpacity(0.4),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : Text('Create Account',
                                      style: TextStyle(
                                          fontSize: isWeb ? 20 : 18,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Login Link
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: isWeb ? 16 : 14, color: const Color(0xFF9E9E9E)),
                                children: [
                                  const TextSpan(text: "Already have an Account? "),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: _isLoading
                                          ? null
                                          : () {
                                              HapticFeedback.lightImpact();
                                              Navigator.of(context).pushReplacement(
                                                PageRouteBuilder(
                                                  transitionDuration: const Duration(milliseconds: 600),
                                                  pageBuilder: (_, __, ___) => const SignInScreen(),
                                                  transitionsBuilder: (_, animation, __, child) {
                                                    return SlideTransition(
                                                      position: Tween<Offset>(
                                                        begin: const Offset(-1, 0),
                                                        end: Offset.zero,
                                                      ).animate(CurvedAnimation(
                                                        parent: animation,
                                                        curve: Curves.easeOutCubic,
                                                      )),
                                                      child: child,
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                      child: Text('Login',
                                          style: TextStyle(
                                              color: _isLoading
                                                  ? const Color(0xFFBDBDBD)
                                                  : const Color(0xFFFF8383),
                                              fontWeight: FontWeight.w600)),
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

          // Loading Overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black12,
                child: const Center(
                  child: Card(
                    elevation: 8,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFFFF8383)),
                          SizedBox(height: 16),
                          Text('Creating your account...',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? hintText,
    Widget? suffixIcon,
    required bool isWeb,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF424242))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          enabled: !_isLoading,
          style: TextStyle(fontSize: isWeb ? 16 : 14, color: const Color(0xFF424242)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFFBDBDBD), size: 20),
            suffixIcon: suffixIcon,
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFBDBDBD), width: 0.5)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF8383), width: 2)),
            errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red.shade300)),
            focusedErrorBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: Colors.red.shade400, width: 2)),
            errorStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // Validation Functions
  String? _validateUsername(String? v) {
    if (v == null || v.isEmpty) return 'Please enter a username';
    if (v.length < 3) return 'Username must be at least 3 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) return 'Only letters, numbers, and _ allowed';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Please enter a password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Password must contain at least one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Password must contain at least one number';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }
}

// PAINTERS (unchanged)
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

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.75), gradientPaint);

    _drawFloatingBlob(canvas, Offset(size.width * 0.15, size.height * 0.15 + math.sin(animation * math.pi * 2) * 20), 80, Colors.white.withOpacity(0.15));
    _drawFloatingBlob(canvas, Offset(size.width * 0.85, size.height * 0.25 + math.cos(animation * math.pi * 2 + 1) * 25), 100, Colors.white.withOpacity(0.12));
    _drawFloatingBlob(canvas, Offset(size.width * 0.5, size.height * 0.08 + math.sin(animation * math.pi * 2 + 2) * 15), 60, Colors.white.withOpacity(0.18));
    _drawFloatingBlob(canvas, Offset(size.width * 0.2, size.height * 0.4 + math.cos(animation * math.pi * 2 + 3) * 18), 90, Colors.white.withOpacity(0.1));
    _drawFloatingBlob(canvas, Offset(size.width * 0.75, size.height * 0.45 + math.sin(animation * math.pi * 2 + 4) * 22), 110, Colors.white.withOpacity(0.08));

    _drawDecorativeCurves(canvas, size, animation);
    _drawTopographicLines(canvas, size);
  }

  void _drawFloatingBlob(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, radius, paint);
    final innerPaint = Paint()..color = color.withOpacity(color.opacity * 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius * 0.6, innerPaint);
  }

  void _drawDecorativeCurves(Canvas canvas, Size size, double animation) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path1 = Path();
    path1.moveTo(size.width * 0.1, size.height * 0.2);
    path1.quadraticBezierTo(size.width * 0.3, size.height * 0.15 + math.sin(animation * math.pi * 2) * 10, size.width * 0.5, size.height * 0.25);
    path1.quadraticBezierTo(size.width * 0.7, size.height * 0.35, size.width * 0.9, size.height * 0.3);
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(size.width * 0.05, size.height * 0.5);
    path2.cubicTo(size.width * 0.25, size.height * 0.48 + math.cos(animation * math.pi * 2 + 1) * 8, size.width * 0.5, size.height * 0.52, size.width * 0.75, size.height * 0.5);
    canvas.drawPath(path2, paint);
  }

  void _drawTopographicLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _drawOrganicCircle(canvas, paint, Offset(size.width * 0.15, size.height * 0.12), 35);
    _drawOrganicCircle(canvas, paint, Offset(size.width * 0.15, size.height * 0.12), 50);
    _drawOrganicCircle(canvas, paint, Offset(size.width * 0.15, size.height * 0.12), 65);
    _drawOrganicCircle(canvas, paint, Offset(size.width * 0.85, size.height * 0.2), 40);
    _drawOrganicCircle(canvas, paint, Offset(size.width * 0.85, size.height * 0.2), 60);
    _drawOrganicCircle(canvas, paint, Offset(size.width * 0.85, size.height * 0.2), 80);
    _drawOrganicCircle(canvas, paint, Offset(size.width * 0.2, size.height * 0.42), 45);
    _drawOrganicCircle(canvas, paint, Offset(size.width * 0.2, size.height * 0.42), 65);
    _drawOrganicCircle(canvas, paint, Offset(size.width * 0.75, size.height * 0.5), 50);
    _drawOrganicCircle(canvas, paint, Offset(size.width * 0.75, size.height * 0.5), 75);
  }

  void _drawOrganicCircle(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ModernBackgroundPainter old) => animation != old.animation;
}