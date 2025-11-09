import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({Key? key}) : super(key: key);

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _availableHoursController = TextEditingController();
  final _languageController = TextEditingController();
  final _experienceController = TextEditingController();
  final _licenseController = TextEditingController();
  final _educationController = TextEditingController();
  final _employmentController = TextEditingController();
  final _otherExpController = TextEditingController();

  // Selected Skills & Certifications
  List<String> _selectedSkills = [];
  List<Map<String, dynamic>> _selectedCerts = []; // {name, image}

  // Verification ID
  File? _idImage;

  // All options
  final List<String> _allSkills = [
    'Medication Management',
    'Mobility Assistance',
    'Meal Preparation',
    'Companionship',
    'Personal Hygiene',
    'Light Housekeeping',
    'Dementia Care',
    'Post-Surgery Care',
    'Wound Care',
    'Palliative Care',
  ];

  final List<String> _allCerts = [
    'CPR Certified',
    'First Aid',
    'Dementia Care',
    'Medication Admin',
    'Palliative Care',
    'Wound Care',
    'Nursing Assistant',
    'Home Health Aide',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _hourlyRateController.dispose();
    _availableHoursController.dispose();
    _languageController.dispose();
    _experienceController.dispose();
    _licenseController.dispose();
    _educationController.dispose();
    _employmentController.dispose();
    _otherExpController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      if (_idImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a valid ID for verification')),
        );
        return;
      }

      final profileData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'hourlyRate': _hourlyRateController.text.trim(),
        'availableHours': _availableHoursController.text.trim(),
        'language': _languageController.text.trim(),
        'experienceYears': _experienceController.text.trim(),
        'license': _licenseController.text.trim(),
        'education': _educationController.text.trim(),
        'employmentHistory': _employmentController.text.trim(),
        'otherExperience': _otherExpController.text.trim(),
        'skills': _selectedSkills,
        'certifications': _selectedCerts,
        'verificationId': _idImage!.path,
      };

      Navigator.pop(context, profileData);
    }
  }

  Future<void> _pickIdImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _idImage = File(image.path);
      });
    }
  }

  Future<void> _pickCertImage(String certName) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedCerts.removeWhere((c) => c['name'] == certName);
        _selectedCerts.add({'name': certName, 'image': File(image.path)});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // === Profile Photo ===
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(radius: 50, backgroundColor: Colors.grey[200], child: const Icon(Icons.person, size: 50, color: Colors.grey)),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo upload soon!'))),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Color(0xFF6C5CE7), shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // === Personal Info ===
                    const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(controller: _firstNameController, label: 'First Name', icon: Icons.person, validator: (v) => v!.isEmpty ? 'Required' : null)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(controller: _lastNameController, label: 'Last Name', icon: Icons.person_outline, validator: (v) => v!.isEmpty ? 'Required' : null)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _bioController, label: 'Bio', icon: Icons.description, maxLines: 4, validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email, keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty || !v!.contains('@') ? 'Valid email required' : null),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 24),

                    // === Freelance Details ===
                    const Text('Freelance Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(controller: _hourlyRateController, label: 'Hourly Rate (\$)', icon: Icons.attach_money, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty || double.tryParse(v!) == null ? 'Valid number' : null)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(controller: _availableHoursController, label: 'Available Hours/Week', icon: Icons.access_time, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _languageController, label: 'Languages Spoken', icon: Icons.language, validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 24),

                    // === Professional Info ===
                    const Text('Professional Background', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    _buildTextField(controller: _experienceController, label: 'Years of Experience', icon: Icons.work, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty || int.tryParse(v!) == null ? 'Valid number' : null),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _licenseController, label: 'License Number', icon: Icons.badge, validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _educationController, label: 'Education', icon: Icons.school, maxLines: 3),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _employmentController, label: 'Employment History', icon: Icons.business, maxLines: 4),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _otherExpController, label: 'Other Experience', icon: Icons.more_horiz, maxLines: 3),
                    const SizedBox(height: 24),

                    // === Skills (GREEN, NO CHECKMARK) ===
                    const Text('Skills & Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allSkills.map((skill) {
                        final isSelected = _selectedSkills.contains(skill);
                        return FilterChip(
                          label: Text(skill),
                          selected: isSelected,
                          selectedColor: const Color(0xFF4CAF50), // GREEN
                          checkmarkColor: Colors.transparent, // NO CHECKMARK
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[300]!),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              selected ? _selectedSkills.add(skill) : _selectedSkills.remove(skill);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // === Certifications with Photo ===
                    const Text('Certifications (Upload Proof)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    ..._allCerts.map((cert) {
                      final certData = _selectedCerts.firstWhere((c) => c['name'] == cert, orElse: () => {'name': cert, 'image': null});
                      final isSelected = _selectedCerts.any((c) => c['name'] == cert);
                      final File? image = certData['image'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF4CAF50),
                              onChanged: (val) => setState(() {
                                val! ? _selectedCerts.add({'name': cert, 'image': null}) : _selectedCerts.removeWhere((c) => c['name'] == cert);
                              }),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(cert, style: const TextStyle(fontSize: 15))),
                            if (image != null)
                              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(image, width: 40, height: 40, fit: BoxFit.cover))
                            else if (isSelected)
                              ElevatedButton.icon(
                                onPressed: () => _pickCertImage(cert),
                                icon: const Icon(Icons.upload, size: 16),
                                label: const Text('Upload', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), padding: const EdgeInsets.symmetric(horizontal: 12)),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),

                    // === VERIFICATION: Upload Valid ID ===
                    const Text('Verification (Required)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _idImage != null ? const Color(0xFF4CAF50) : Colors.redAccent.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.badge, color: Colors.redAccent, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Upload Valid ID', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Driver’s License, Passport, or National ID', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          if (_idImage != null)
                            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_idImage!, width: 50, height: 50, fit: BoxFit.cover))
                          else
                            ElevatedButton.icon(
                              onPressed: _pickIdImage,
                              icon: const Icon(Icons.upload, size: 16),
                              label: const Text('Upload ID', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 12)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6C5CE7)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }
}