import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../../models/caregiver_profile.dart';

class AddProfileScreen extends StatefulWidget {
  final String? profileId;
  final Map<String, dynamic>? existingProfile;

  const AddProfileScreen({
    Key? key,
    this.profileId,
    this.existingProfile,
  }) : super(key: key);

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Cloudinary Configuration
  static const String cloudinaryCloudName = 'duxxwlurg';
  static const String cloudinaryApiKey = '489679362695478';
  static const String cloudinaryApiSecret = '-UKqPTWnXw3LAMj-IbWeIv27HXo';

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

  // Tag input
  final _languageInputController = TextEditingController();
  final _skillsInputController = TextEditingController();

  // Tags
  final List<String> _languages = [];
  final List<String> _skills = [];

  // Certifications
  final List<Map<String, dynamic>> _selectedCerts = [];

  // Verification ID
  Uint8List? _idImageBytes;
  String? _existingIdUrl;

  // Profile Photo
  Uint8List? _profilePhotoBytes;
  String? _existingProfilePhotoUrl;

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

  bool get isEditMode => widget.profileId != null;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingProfile == null) return;
    final data = widget.existingProfile!;

    _firstNameController.text = data['firstName'] ?? '';
    _lastNameController.text = data['lastName'] ?? '';
    _bioController.text = data['bio'] ?? '';
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _hourlyRateController.text = data['hourlyRate']?.toString() ?? '';
    _availableHoursController.text = data['availableHoursPerWeek']?.toString() ?? '';
    _experienceController.text = data['experienceYears']?.toString() ?? '';
    _licenseController.text = data['licenseNumber'] ?? '';
    _educationController.text = data['education'] ?? '';
    _employmentController.text = data['employmentHistory'] ?? '';
    _otherExpController.text = data['otherExperience'] ?? '';

    if (data['languages'] != null && data['languages'] is List) {
      _languages.addAll((data['languages'] as List).map((e) => e.toString()));
    }
    if (data['skills'] != null && data['skills'] is List) {
      _skills.addAll((data['skills'] as List).map((e) => e.toString()));
    }
    if (data['certifications'] != null && data['certifications'] is List) {
      for (var cert in data['certifications']) {
        _selectedCerts.add({
          'name': cert['name'],
          'bytes': null,
          'imageUrl': cert['imageUrl'],
        });
      }
    }

    _existingIdUrl = data['verificationIdUrl'];
    _existingProfilePhotoUrl = data['profilePhotoUrl'];
  }

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

  Future<String> _uploadToCloudinary(Uint8List bytes, String folder) async {
    try {
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');

      final request = http.MultipartRequest('POST', uri);

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final paramsToSign = 'folder=$folder&timestamp=$timestamp$cloudinaryApiSecret';
      final signature = _generateSHA1(paramsToSign);

      request.fields['folder'] = folder;
      request.fields['timestamp'] = timestamp;
      request.fields['api_key'] = cloudinaryApiKey;
      request.fields['signature'] = signature;

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = json.decode(responseString);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Upload failed: ${jsonResponse['error']['message']}');
      }
    } catch (e) {
      throw Exception('Error uploading to Cloudinary: $e');
    }
  }

  String _generateSHA1(String input) {
    final bytes = utf8.encode(input);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  void _showSnackBar(String message,
      {Color? backgroundColor, Duration duration = const Duration(seconds: 4)}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  // ---------- Profile Photo ----------
  Future<void> _pickProfilePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _profilePhotoBytes = bytes);
    }
  }

  // ---------- Save ----------
  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idImageBytes == null && _existingIdUrl == null) {
      _showSnackBar('Please upload a valid ID for verification');
      return;
    }
    if (_languages.isEmpty || _skills.isEmpty) {
      _showSnackBar('Add at least one language and skill');
      return;
    }

    final currentContext = context;
    final loadingSnackBar = ScaffoldMessenger.of(currentContext).showSnackBar(
      SnackBar(
        content: Text(isEditMode ? 'Updating profile...' : 'Saving profile...'),
        duration: const Duration(minutes: 2),
      ),
    );

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      final caregiverDoc = await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(currentUser.uid)
          .get();

      if (!caregiverDoc.exists) throw Exception('Caregiver data not found');

      final caregiverId = caregiverDoc.data()?['id'];
      if (caregiverId == null) throw Exception('Caregiver ID not found');

      // ---- Profile Photo ----
      String? profilePhotoUrl;
      if (_profilePhotoBytes != null) {
        profilePhotoUrl = await _uploadToCloudinary(
            _profilePhotoBytes!, 'carelink/profile_photos');
      } else {
        profilePhotoUrl = _existingProfilePhotoUrl;
      }

      // ---- Verification ID ----
      String verificationIdUrl;
      if (_idImageBytes != null) {
        verificationIdUrl = await _uploadToCloudinary(
            _idImageBytes!, 'carelink/verification_ids');
      } else {
        verificationIdUrl = _existingIdUrl!;
      }

      // ---- Certifications ----
      final List<Certification> uploadedCerts = [];
      for (var cert in _selectedCerts) {
        final bytes = cert['bytes'] as Uint8List?;
        final existingUrl = cert['imageUrl'] as String?;

        String imageUrl;
        if (bytes != null && bytes.isNotEmpty) {
          imageUrl = await _uploadToCloudinary(bytes, 'carelink/certifications');
        } else if (existingUrl != null) {
          imageUrl = existingUrl;
        } else {
          continue;
        }
        uploadedCerts.add(Certification(name: cert['name'], imageUrl: imageUrl));
      }

      // ---- createdAt handling ----
      DateTime createdAt = DateTime.now();
      if (widget.existingProfile?['createdAt'] != null) {
        final ca = widget.existingProfile!['createdAt'];
        if (ca is Timestamp) createdAt = ca.toDate();
        if (ca is String) createdAt = DateTime.tryParse(ca) ?? createdAt;
      }

      // ---- Build profile object ----
      final profile = CaregiverProfile(
        id: widget.profileId ?? '',
        caregiverId: caregiverId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        bio: _bioController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        hourlyRate: double.parse(_hourlyRateController.text.trim()),
        availableHoursPerWeek: int.parse(_availableHoursController.text.trim()),
        languages: _languages,
        experienceYears: int.parse(_experienceController.text.trim()),
        licenseNumber: _licenseController.text.trim(),
        education: _educationController.text.trim(),
        employmentHistory: _employmentController.text.trim(),
        otherExperience: _otherExpController.text.trim(),
        skills: _skills,
        certifications: uploadedCerts,
        verificationIdUrl: verificationIdUrl,
        profilePhotoUrl: profilePhotoUrl,
        createdAt: createdAt,
      );

      final profileMap = profile.toMap();

      if (isEditMode) {
        await FirebaseFirestore.instance
            .collection('caregiver_profile')
            .doc(widget.profileId)
            .update(profileMap);
      } else {
        final docRef = await FirebaseFirestore.instance
            .collection('caregiver_profile')
            .add(profileMap);
        await docRef.update({'id': docRef.id});
      }

      loadingSnackBar.close();
      _showSnackBar(
        isEditMode ? 'Profile updated successfully!' : 'Profile saved successfully!',
        backgroundColor: Colors.green,
      );

      if (mounted) {
        Navigator.pop(currentContext, widget.profileId ?? 'updated');
      }
    } catch (e) {
      loadingSnackBar.close();
      _showSnackBar('Error: ${e.toString()}');
      print('Full error: $e');
    }
  }

  // ---------- Tag helpers ----------
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

  void _removeLanguage(String lang) => setState(() => _languages.remove(lang));
  void _removeSkill(String skill) => setState(() => _skills.remove(skill));

  // ---------- Image pickers ----------
  Future<void> _pickIdImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _idImageBytes = bytes);
    }
  }

  Future<void> _pickCertImage(String certName) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedCerts.removeWhere((c) => c['name'] == certName);
        _selectedCerts.add({'name': certName, 'bytes': bytes, 'imageUrl': null});
      });
    }
  }

  // ---------- UI helpers ----------
  Widget _buildImagePreview(Uint8List? bytes,
      {double width = 50, double height = 50, String? url}) {
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes,
            width: width, height: height, fit: BoxFit.cover),
      );
    } else if (url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(url,
            width: width, height: height, fit: BoxFit.cover),
      );
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Profile' : 'Complete Your Profile'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              isEditMode ? 'Update' : 'Save',
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
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
                    // ---------- Profile Photo ----------
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _profilePhotoBytes != null
                                ? MemoryImage(_profilePhotoBytes!)
                                : (_existingProfilePhotoUrl != null
                                    ? NetworkImage(_existingProfilePhotoUrl!)
                                        as ImageProvider
                                    : null),
                            child: (_profilePhotoBytes == null &&
                                    _existingProfilePhotoUrl == null)
                                ? const Icon(Icons.person,
                                    size: 50, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickProfilePhoto,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6C5CE7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ---------- Personal Info ----------
                    const Text('Personal Information',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(
                                _firstNameController, 'First Name', Icons.person,
                                validator: (v) =>
                                    v!.isEmpty ? 'Required' : null)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildTextField(
                                _lastNameController,
                                'Last Name',
                                Icons.person_outline,
                                validator: (v) =>
                                    v!.isEmpty ? 'Required' : null)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_bioController, 'Bio', Icons.description,
                        maxLines: 4,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _buildTextField(_emailController, 'Email', Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty || !v.contains('@')
                            ? 'Valid email required'
                            : null),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, 'Phone Number', Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 24),

                    // ---------- Freelance Details ----------
                    const Text('Freelance Details',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(
                                _hourlyRateController,
                                'Hourly Rate (\$)',
                                Icons.attach_money,
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty ||
                                        double.tryParse(v) == null
                                    ? 'Valid number'
                                    : null)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildTextField(
                                _availableHoursController,
                                'Available Hours/Week',
                                Icons.access_time,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v!.isEmpty ? 'Required' : null)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ---------- Languages ----------
                    const Text('Languages Spoken',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text('Press enter or comma to add',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 12),
                    _buildTagInput(
                      controller: _languageInputController,
                      hint: 'e.g., English, Spanish, Tagalog',
                      icon: Icons.language,
                      color: const Color(0xFF6C5CE7),
                      tags: _languages,
                      onAdd: _addLanguage,
                      onRemove: _removeLanguage,
                    ),
                    const SizedBox(height: 24),

                    // ---------- Professional Background ----------
                    const Text('Professional Background',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                    _buildTextField(_experienceController,
                        'Years of Experience', Icons.work,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty || int.tryParse(v) == null
                            ? 'Valid number'
                            : null),
                    const SizedBox(height: 16),
                    _buildTextField(_licenseController, 'License Number',
                        Icons.badge,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _buildTextField(
                        _educationController, 'Education', Icons.school,
                        maxLines: 3),
                    const SizedBox(height: 16),
                    _buildTextField(_employmentController,
                        'Employment History', Icons.business,
                        maxLines: 4),
                    const SizedBox(height: 16),
                    _buildTextField(
                        _otherExpController, 'Other Experience', Icons.more_horiz,
                        maxLines: 3),
                    const SizedBox(height: 24),

                    // ---------- Skills ----------
                    const Text('Skills & Services',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text('Add the services and skills you can provide',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 12),
                    _buildTagInput(
                      controller: _skillsInputController,
                      hint: 'e.g., Medication Management',
                      icon: Icons.medical_services,
                      color: const Color(0xFF4CAF50),
                      tags: _skills,
                      onAdd: _addSkill,
                      onRemove: _removeSkill,
                    ),
                    const SizedBox(height: 12),
                    Text('Quick add:',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700])),
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
                      ].map((s) => _quickTag(s, () => _addSkill(s))).toList(),
                    ),
                    const SizedBox(height: 24),

                    // ---------- Certifications ----------
                    const Text('Certifications (Upload Proof)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                    ..._allCerts.map((cert) {
                      final certData = _selectedCerts.firstWhere(
                        (c) => c['name'] == cert,
                        orElse: () =>
                            {'name': cert, 'bytes': null, 'imageUrl': null},
                      );
                      final isSelected =
                          _selectedCerts.any((c) => c['name'] == cert);
                      final Uint8List? bytes = certData['bytes'];
                      final String? imageUrl = certData['imageUrl'];
                      return _certTile(cert, isSelected, bytes, imageUrl,
                          () => _pickCertImage(cert));
                    }).toList(),
                    const SizedBox(height: 24),

                    // ---------- Verification ID ----------
                    const Text('Verification (Required)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (_idImageBytes != null || _existingIdUrl != null)
                              ? const Color(0xFF4CAF50)
                              : Colors.redAccent.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge,
                              color: Colors.redAccent, size: 28),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Upload Valid ID',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text(
                                    'Drivers License, Passport, or National ID',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          _buildImagePreview(_idImageBytes,
                              url: _existingIdUrl),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _pickIdImage,
                            icon: const Icon(Icons.upload, size: 16),
                            label: Text(
                              (_idImageBytes != null || _existingIdUrl != null)
                                  ? 'Change'
                                  : 'Upload ID',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
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

  // ---------- TextField ----------
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }

  // ---------- Tag Input ----------
  Widget _buildTagInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
    required List<String> tags,
    required Function(String) onAdd,
    required Function(String) onRemove,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tag,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14)),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => onRemove(tag),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          if (tags.isNotEmpty) const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: color, size: 20),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
            ),
            onChanged: (v) {
              // add on comma or space
              if (v.endsWith(',') || v.endsWith(' ')) {
                final item = v.substring(0, v.length - 1).trim();
                if (item.isNotEmpty) {
                  onAdd(item);
                }
              }
            },
            onSubmitted: (v) {
              final trimmed = v.trim();
              if (trimmed.isNotEmpty) onAdd(trimmed);
            },
          ),
        ],
      ),
    );
  }

  // ---------- Quick Tag ----------
  Widget _quickTag(String text, VoidCallback onTap) {
    final isAlreadyAdded = _skills.contains(text);
    return GestureDetector(
      onTap: isAlreadyAdded ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isAlreadyAdded ? Colors.grey[300] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAlreadyAdded ? Icons.check : Icons.add,
              size: 14,
              color: isAlreadyAdded ? Colors.grey[500] : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isAlreadyAdded ? Colors.grey[500] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Certification Tile ----------
  Widget _certTile(
    String name,
    bool selected,
    Uint8List? bytes,
    String? imageUrl,
    VoidCallback onUpload,
  ) {
    final hasImage = bytes != null || imageUrl != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected ? const Color(0xFF4CAF50) : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            activeColor: const Color(0xFF4CAF50),
            onChanged: (v) => setState(() {
              if (v!) {
                _selectedCerts
                    .add({'name': name, 'bytes': null, 'imageUrl': null});
              } else {
                _selectedCerts.removeWhere((c) => c['name'] == name);
              }
            }),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(name, style: const TextStyle(fontSize: 15))),
          _buildImagePreview(bytes, width: 40, height: 40, url: imageUrl),
          const SizedBox(width: 8),
          if (selected)
            ElevatedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload, size: 16),
              label: Text(
                hasImage ? 'Change' : 'Upload',
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
        ],
      ),
    );
  }
}