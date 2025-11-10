import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:simple_textfield_tag/simple_textfield_tag.dart';

class PatientEditProfileScreen extends StatefulWidget {
  const PatientEditProfileScreen({Key? key}) : super(key: key);

  @override
  State<PatientEditProfileScreen> createState() => _PatientEditProfileScreenState();
}

class _PatientEditProfileScreenState extends State<PatientEditProfileScreen> {
  // === MODERN THEME ===
  static const Color primary = Color(0xFFFF6B6B);
  static const Color primaryLight = Color(0xFFFF8A8A);
  static const Color danger = Color(0xFFE53935);
  static const Color bg = Color(0xFFF8FAFC);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x0D000000);

  // Spacing
  static const double p = 16.0;
  static const double p2 = 12.0;
  static const double p3 = 20.0;
  static const double p4 = 24.0;
  static const double radius = 20.0;

  // Form
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'John Doe');
  final _ageController = TextEditingController(text: '70');
  final _emailController = TextEditingController(text: 'john.doe@email.com');
  final _addressController = TextEditingController(text: '123 Main Street, Springfield');
  String _phone = '(555) 123-4567';
  String _bloodType = 'O+';

  // Tags
  List<String> _allergies = ['Penicillin', 'Peanuts', 'Latex'];
  List<String> _conditions = ['Hypertension', 'Type 2 Diabetes', 'High Cholesterol'];

  // Image
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        foregroundColor: text,
        elevation: 0,
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: textLight)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(p3),
          child: Column(
            children: [
              // === PROFILE PHOTO ===
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [primaryLight, primary]),
                        boxShadow: [BoxShadow(color: shadow, blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: CircleAvatar(
                        radius: 62,
                        backgroundColor: card,
                        child: CircleAvatar(
                          radius: 58,
                          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                          child: _profileImage == null
                              ? Text('JD', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: primary.withAlpha(180)))
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: shadow, blurRadius: 12)]),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: p4),

              // === PERSONAL INFO CARD ===
              _buildCard(
                title: 'Personal Information',
                children: [
                  _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                  const SizedBox(height: p2),
                  Row(
                    children: [
                      Expanded(flex: 3, child: _buildTextField(_ageController, 'Age', Icons.cake_outlined, keyboardType: TextInputType.number)),
                      const SizedBox(width: p2),
                      Expanded(
                        flex: 4,
                        child: DropdownButtonFormField<String>(
                          value: _bloodType,
                          decoration: _inputDecoration('Blood Type', Icons.water_drop_outlined),
                          items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w500))))
                              .toList(),
                          onChanged: (val) => setState(() => _bloodType = val!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: p3),

              // === CONTACT INFO CARD ===
              _buildCard(
                title: 'Contact Information',
                children: [
                  _buildTextField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: p2),
                  IntlPhoneField(
                    decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
                    initialCountryCode: 'US',
                    onChanged: (phone) => _phone = phone.completeNumber,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: p2),
                  _buildTextField(_addressController, 'Street Address', Icons.home_outlined),
                ],
              ),
              const SizedBox(height: p3),

              // === ALLERGIES CARD ===
              _buildCard(
                title: 'Allergies',
                icon: Icons.warning_amber_rounded,
                iconColor: danger,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: InputDecorationTheme(
                        hintStyle: const TextStyle(color: textLight),
                        filled: true,
                        fillColor: bg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: danger, width: 2)),
                      ),
                    ),
                    child: SimpleTextFieldTag(
                      initialTags: _allergies,
                      onTagAdded: (tag) => setState(() => _allergies = [..._allergies, tag]),
                      onTagRemoved: (tag) => setState(() => _allergies.remove(tag)),
                      chipBackgroundColor: const Color.fromRGBO(229, 57, 53, 0.12),
                      deleteIconColor: danger,
                      // Only valid parameters
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Tap to add allergy', style: TextStyle(fontSize: 12, color: textLight)),
                ],
              ),
              const SizedBox(height: p3),

              // === CONDITIONS CARD ===
              _buildCard(
                title: 'Medical Conditions',
                icon: Icons.local_hospital_rounded,
                iconColor: primary,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: InputDecorationTheme(
                        hintStyle: const TextStyle(color: textLight),
                        filled: true,
                        fillColor: bg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary, width: 2)),
                      ),
                    ),
                    child: SimpleTextFieldTag(
                      initialTags: _conditions,
                      onTagAdded: (tag) => setState(() => _conditions = [..._conditions, tag]),
                      onTagRemoved: (tag) => setState(() => _conditions.remove(tag)),
                      chipBackgroundColor: const Color.fromRGBO(255, 107, 107, 0.12),
                      deleteIconColor: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Tap to add condition', style: TextStyle(fontSize: 12, color: textLight)),
                ],
              ),
              const SizedBox(height: p4),

              // === SAVE BUTTON ===
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Profile updated!'), backgroundColor: primary),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
                    elevation: 8,
                    shadowColor: primary.withOpacity(0.3),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, IconData? icon, Color? iconColor, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(p3),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: shadow, blurRadius: 20, offset: const Offset(0, 6))],
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, color: iconColor, size: 22), const SizedBox(width: 8)],
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: text)),
            ],
          ),
          const SizedBox(height: p2),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: _inputDecoration(label, icon),
      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textLight, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: primary),
      filled: true,
      fillColor: bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary, width: 2)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}