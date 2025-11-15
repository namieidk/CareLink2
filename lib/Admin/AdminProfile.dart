import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'AdminHome.dart';
import 'AdminDoctor.dart';
import 'AdminCaregiver.dart';
import 'AdminPatient.dart';
import '../auth_service.dart';
import '../Signin/up/Signin.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  // ──────────────────────────────────────────────────────────────
  // Colors
  // ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFF8BA0);
  static const Color muted = Colors.grey;

  final AuthService _auth = AuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  // Change Password Controllers
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Eye toggle states
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _notificationsEnabled = true;
  bool _isChangingPassword = false;

  Map<String, dynamic>? _adminData;
  Map<String, dynamic>? _profileData;

  late SharedPreferences _prefs;

  // ──────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initPreferences();
    _loadAdminData();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final savedNotif = _prefs.getBool('notifications') ?? true;
    setState(() {
      _notificationsEnabled = savedNotif;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  // Load admin + profile
  // ──────────────────────────────────────────────────────────────
  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _goToSignIn();
        return;
      }

      final uid = user.uid;

      final adminSnap = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      if (!adminSnap.exists) {
        _showSnack('Error loading profile: Account not found.');
        _goToSignIn();
        return;
      }

      _adminData = adminSnap.data()!;

      _nameController.text = _adminData!['fullName']?.toString() ?? '';
      _emailController.text = _adminData!['email']?.toString() ?? '';

      final profileSnap = await FirebaseFirestore.instance
          .collection('admin_profiles')
          .doc(uid)
          .get();

      if (profileSnap.exists) {
        _profileData = profileSnap.data()!;
        _phoneController.text = _profileData!['phoneNumber']?.toString() ?? '';
        _locationController.text = _profileData!['location']?.toString() ?? '';
        _bioController.text = _profileData!['bio']?.toString() ?? '';
      } else {
        _phoneController.clear();
        _locationController.clear();
        _bioController.clear();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error loading profile: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Save profile
  // ──────────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      _showSnack('Name and email are required');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final uid = user.uid;
      final now = Timestamp.now();

      await FirebaseFirestore.instance.collection('admins').doc(uid).update({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'email_lower': _emailController.text.trim().toLowerCase(),
        'updatedAt': now,
      });

      final profileData = {
        'adminId': uid,
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'location': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        'updatedAt': now,
      };

      final profileRef = FirebaseFirestore.instance.collection('admin_profiles').doc(uid);
      final profileSnap = await profileRef.get();

      if (profileSnap.exists) {
        await profileRef.update(profileData);
      } else {
        profileData['createdAt'] = now;
        await profileRef.set(profileData);
      }

      setState(() {
        _isSaving = false;
        _isEditing = false;
      });

      _showSnack('Profile saved successfully!', background: Colors.green);
      _loadAdminData();
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnack('Failed to save: $e', background: Colors.red);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Change Password (Fully Functional with Eye Toggle)
  // ──────────────────────────────────────────────────────────────
  Future<void> _changePassword() async {
    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showSnack('All password fields are required', background: Colors.red);
      return;
    }

    if (newPass != confirmPass) {
      _showSnack('New passwords do not match', background: Colors.red);
      return;
    }

    if (newPass.length < 6) {
      _showSnack('New password must be at least 6 characters', background: Colors.red);
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        _showSnack('User not logged in', background: Colors.red);
        setState(() => _isChangingPassword = false);
        return;
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPass,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password in Firebase Auth
      await user.updatePassword(newPass);

      // Update Firestore 'admins' collection (remove if not storing plain passwords)
      await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .update({'password': newPass});

      // Clear fields and reset toggles
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _isChangingPassword = false;
        _showOldPassword = false;
        _showNewPassword = false;
        _showConfirmPassword = false;
      });

      Navigator.pop(context);
      _showSnack('Password changed successfully!', background: Colors.green);
    } on FirebaseAuthException catch (e) {
      setState(() => _isChangingPassword = false);
      String message = 'Error: ${e.message}';
      switch (e.code) {
        case 'wrong-password':
          message = 'Old password is incorrect';
          break;
        case 'weak-password':
          message = 'New password is too weak';
          break;
        case 'requires-recent-login':
          message = 'Please log in again to change your password';
          break;
      }
      _showSnack(message, background: Colors.red);
    } catch (e) {
      setState(() => _isChangingPassword = false);
      _showSnack('Failed to change password: $e', background: Colors.red);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Toggle Notifications
  // ──────────────────────────────────────────────────────────────
  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _prefs.setBool('notifications', value);
    _showSnack(
      value ? 'Notifications enabled' : 'Notifications disabled',
      background: value ? Colors.green : Colors.orange,
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Sign out
  // ──────────────────────────────────────────────────────────────
  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Sign out of your admin account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignInScreen()));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────
  void _goToSignIn() {
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignInScreen()));
    }
  }

  void _showSnack(String msg, {Color? background}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: background),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Bottom Navigation
  // ──────────────────────────────────────────────────────────────
  Widget _bottomNav(BuildContext ctx) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -1))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home, 'Home', false, 0, ctx),
              _navItem(Icons.local_hospital, 'Doctor', false, 1, ctx),
              _navItem(Icons.supervisor_account, 'Caregiver', false, 2, ctx),
              _navItem(Icons.people_alt, 'Patient', false, 3, ctx),
              _navItem(Icons.person_outline, 'Profile', true, 4, ctx),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, int index, BuildContext ctx) {
    return Expanded(
      child: GestureDetector(
        onTap: active
            ? null
            : () {
                switch (index) {
                  case 0:
                    Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => const AdminHomePage()));
                    break;
                  case 1:
                    Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => const AdminDoctorsScreen()));
                    break;
                  case 2:
                    Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => const AdminCaregiversScreen()));
                    break;
                  case 3:
                    Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => const AdminPatientsScreen()));
                    break;
                }
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? primary : muted, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active ? primary : muted,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: _bottomNav(context),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Admin Profile',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () => _isEditing ? _saveProfile() : setState(() => _isEditing = true),
                          icon: _isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Icon(_isEditing ? Icons.check : Icons.edit, size: 18),
                          label: Text(_isSaving
                              ? 'Saving...'
                              : (_isEditing ? 'Save' : 'Edit')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isEditing ? const Color(0xFF4CAF50) : primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Profile Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          _field('Full Name', _nameController, Icons.person, _isEditing),
                          const SizedBox(height: 16),
                          _field('Email Address', _emailController, Icons.email_outlined, _isEditing, keyboard: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _field('Phone Number', _phoneController, Icons.phone_outlined, _isEditing, keyboard: TextInputType.phone),
                          const SizedBox(height: 16),
                          _field('Location', _locationController, Icons.location_on_outlined, _isEditing),
                          const SizedBox(height: 24),
                          const Text('Bio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _bioController,
                            enabled: _isEditing,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: _isEditing ? 'Tell us about yourself...' : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              filled: true,
                              fillColor: _isEditing ? Colors.white : Colors.grey[50],
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      ),
                   ),

                    const SizedBox(height: 32),

                    // Settings
                    const Text('Account Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 16),
                    _tile(
                      Icons.security,
                      'Change Password',
                      'Update your password regularly',
                      () => _showChangePasswordDialog(),
                    ),
                    _tile(
                      Icons.notifications_outlined,
                      'Notification Preferences',
                      _notificationsEnabled ? 'Push notifications are ON' : 'Push notifications are OFF',
                      () => _toggleNotifications(!_notificationsEnabled),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeColor: primary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sign Out
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red.shade600, size: 28),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sign Out', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.red)),
                                SizedBox(height: 4),
                                Text('Sign out of your admin account.', style: TextStyle(fontSize: 14, color: Colors.red)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _signOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(context),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Change Password Dialog with Eye Toggle
  // ──────────────────────────────────────────────────────────────
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Change Password'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _passwordField(
                  label: 'Old Password',
                  controller: _oldPasswordController,
                  obscureText: !_showOldPassword,
                  onToggle: () => setStateDialog(() => _showOldPassword = !_showOldPassword),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  label: 'New Password',
                  controller: _newPasswordController,
                  obscureText: !_showNewPassword,
                  onToggle: () => setStateDialog(() => _showNewPassword = !_showNewPassword),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  label: 'Confirm New Password',
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  onToggle: () => setStateDialog(() => _showConfirmPassword = !_showConfirmPassword),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _showOldPassword = false;
                  _showNewPassword = false;
                  _showConfirmPassword = false;
                });
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isChangingPassword ? null : _changePassword,
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              child: _isChangingPassword
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock, color: primary),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: primary),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Reusable Widgets
  // ──────────────────────────────────────────────────────────────
  Widget _field(String label, TextEditingController controller, IconData icon, bool enabled, {TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboard,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap, {Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: ListTile(
        leading: Icon(icon, color: primary, size: 26),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: muted),
        onTap: onTap,
      ),
    );
  }
}