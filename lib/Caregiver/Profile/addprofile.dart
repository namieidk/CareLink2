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
  final _experienceController = TextEditingController();
  final _licenseController = TextEditingController();
  final _educationController = TextEditingController();
  final _employmentController = TextEditingController();
  final _otherExpController = TextEditingController();

  // Tag input controllers
  final _languageInputController = TextEditingController();
  final _skillsInputController = TextEditingController();

  // Tags lists
  final List<String> _languages = [];
  final List<String> _skills = [];

  // Selected Certifications
  final List<Map<String, dynamic>> _selectedCerts = []; // {name, image}

  // Verification ID
  File? _idImage;

  // All certifications options
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
    _experienceController.dispose();
    _licenseController.dispose();
    _educationController.dispose();
    _employmentController.dispose();
    _otherExpController.dispose();
    _languageInputController.dispose();
    _skillsInputController.dispose();
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

      if (_languages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one language')),
        );
        return;
      }

      if (_skills.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one skill/service')),
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
        'languages': _languages,
        'experienceYears': _experienceController.text.trim(),
        'license': _licenseController.text.trim(),
        'education': _educationController.text.trim(),
        'employmentHistory': _employmentController.text.trim(),
        'otherExperience': _otherExpController.text.trim(),
        'skills': _skills,
        'certifications': _selectedCerts,
        'verificationId': _idImage!.path,
      };

      Navigator.pop(context, profileData);
    }
  }

  void _addLanguage(String language) {
    final trimmed = language.trim();
    if (trimmed.isNotEmpty && !_languages.contains(trimmed)) {
      setState(() {
        _languages.add(trimmed);
        _languageInputController.clear();
      });
    }
  }

  void _addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isNotEmpty && !_skills.contains(trimmed)) {
      setState(() {
        _skills.add(trimmed);
        _skillsInputController.clear();
      });
    }
  }

  void _removeLanguage(String language) {
    setState(() {
      _languages.remove(language);
    });
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
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
                    const SizedBox(height: 24),

                    // === Languages Spoken ===
                    const Text('Languages Spoken', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text('Press enter or comma to add', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_languages.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _languages.map((lang) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C5CE7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(lang, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => _removeLanguage(lang),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          if (_languages.isNotEmpty) const SizedBox(height: 8),
                          TextField(
                            controller: _languageInputController,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'e.g., English, Spanish, Tagalog',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.language, color: Color(0xFF6C5CE7), size: 20),
                              prefixIconConstraints: const BoxConstraints(minWidth: 40),
                            ),
                            onChanged: (value) {
                              if (value.endsWith(',') || value.endsWith(' ')) {
                                final lang = value.substring(0, value.length - 1).trim();
                                if (lang.isNotEmpty) {
                                  _addLanguage(lang);
                                }
                              }
                            },
                            onSubmitted: (value) => _addLanguage(value),
                          ),
                        ],
                      ),
                    ),
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

                    // === Skills & Services ===
                    const Text('Skills & Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text('Add the services and skills you can provide', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_skills.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _skills.map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(skill, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => _removeSkill(skill),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          if (_skills.isNotEmpty) const SizedBox(height: 8),
                          TextField(
                            controller: _skillsInputController,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'e.g., Medication Management, Mobility Assistance',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.medical_services, color: Color(0xFF4CAF50), size: 20),
                              prefixIconConstraints: const BoxConstraints(minWidth: 40),
                            ),
                            onChanged: (value) {
                              if (value.endsWith(',') || value.endsWith(' ')) {
                                final skill = value.substring(0, value.length - 1).trim();
                                if (skill.isNotEmpty) {
                                  _addSkill(skill);
                                }
                              }
                            },
                            onSubmitted: (value) => _addSkill(value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Quick add:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
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
                      ].map((suggestion) => GestureDetector(
                        onTap: () => _addSkill(suggestion),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(suggestion, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                            ],
                          ),
                        ),
                      )).toList(),
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
                                Text('Drivers License, Passport, or National ID', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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