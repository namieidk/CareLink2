import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../models/doctor_profile.dart';

class DoctorProfileEditScreen extends StatefulWidget {
  final DoctorProfile? doctorProfile;

  const DoctorProfileEditScreen({super.key, this.doctorProfile});

  @override
  State<DoctorProfileEditScreen> createState() => _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends State<DoctorProfileEditScreen> {
  static const Color primary = Color(0xFF4A90E2);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color background = Color(0xFFF8F9FA);

  // Cloudinary configuration
  static const String _cloudName = 'duxxwlurg';
  static const String _uploadPreset = 'ml_default';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _profileImageUrl;

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _languagesController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _yearsExpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If we are editing an existing profile, populate the controllers
    if (widget.doctorProfile != null) {
      _populateControllers(widget.doctorProfile!);
      _profileImageUrl = widget.doctorProfile!.profileImageUrl;
    }
  }

  void _populateControllers(DoctorProfile profile) {
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
    _specialtyController.text = profile.specialty;
    _hospitalController.text = profile.hospital;
    _addressController.text = profile.address;
    _experienceController.text = profile.experience;
    _educationController.text = profile.education;
    _languagesController.text = profile.languages;
    _bioController.text = profile.bio;
    _licenseController.text = profile.licenseNumber;
    _yearsExpController.text = profile.yearsOfExperience.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _hospitalController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _languagesController.dispose();
    _bioController.dispose();
    _licenseController.dispose();
    _yearsExpController.dispose();
    super.dispose();
  }

  // UPLOAD IMAGE TO CLOUDINARY
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      var request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      print('Uploading to Cloudinary: $_cloudName with preset: $_uploadPreset');
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);
      
      print('Cloudinary response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        print('Cloudinary upload failed with status: ${response.statusCode}');
        print('Error details: $jsonResponse');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  // PICK IMAGE FROM GALLERY
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _uploadSelectedImage(File(pickedFile.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // UPLOAD SELECTED IMAGE TO CLOUDINARY
  Future<void> _uploadSelectedImage(File imageFile) async {
    setState(() => _isUploadingImage = true);

    try {
      final String? imageUrl = await _uploadImageToCloudinary(imageFile);

      if (imageUrl != null) {
        setState(() {
          _profileImageUrl = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload image to Cloudinary'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  // SAVE OR UPDATE PROFILE
  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _specialtyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final now = DateTime.now();
        
        final profileData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'specialty': _specialtyController.text.trim(),
          'hospital': _hospitalController.text.trim(),
          'address': _addressController.text.trim(),
          'experience': _experienceController.text.trim(),
          'education': _educationController.text.trim(),
          'languages': _languagesController.text.trim(),
          'bio': _bioController.text.trim(),
          'licenseNumber': _licenseController.text.trim(),
          'yearsOfExperience': int.tryParse(_yearsExpController.text) ?? 0,
          'patientsTreated': widget.doctorProfile?.patientsTreated ?? 0,
          'patientSatisfaction': widget.doctorProfile?.patientSatisfaction ?? 0.0,
          'joinedDate': widget.doctorProfile?.joinedDate ?? now,
          'updatedAt': Timestamp.fromDate(now),
        };

        // Include profile image URL if available
        if (_profileImageUrl != null) {
          profileData['profileImageUrl'] = _profileImageUrl!;
        }

        if (widget.doctorProfile == null) {
          profileData['createdAt'] = Timestamp.fromDate(now);
        }

        // Use set() instead of update() to create the document if it doesn't exist
        await _firestore
            .collection('doctor_profiles')
            .doc(user.uid)
            .set(profileData, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Pop the screen to go back
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(widget.doctorProfile == null ? 'Create Profile' : 'Edit Profile'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _profileCard(),
                  const SizedBox(height: 20),
                  _personalInfoSection(),
                  const SizedBox(height: 20),
                  _professionalInfoSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // PROFILE CARD
  Widget _profileCard() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // PROFILE AVATAR
              GestureDetector(
                onTap: _pickImageFromGallery,
                child: Stack(
                  children: [
                    _isUploadingImage
                        ? Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: primary, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _profileImageUrl != null
                                  ? Image.network(
                                      _profileImageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildAvatarPlaceholder();
                                      },
                                    )
                                  : _buildAvatarPlaceholder(),
                            ),
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // NAME AND SPECIALTY
              Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name *',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _specialtyController,
                    label: 'Specialty *',
                    icon: Icons.medical_services,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _hospitalController,
                    label: 'Hospital/Clinic',
                    icon: Icons.local_hospital,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _bioController,
                    label: 'Bio',
                    icon: Icons.description,
                    maxLines: 4,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildAvatarPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary.withOpacity(0.8), primary],
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // PERSONAL INFORMATION SECTION
  Widget _personalInfoSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email *',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone *',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _languagesController,
                    label: 'Languages',
                    icon: Icons.language,
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  // PROFESSIONAL INFORMATION SECTION
  Widget _professionalInfoSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Professional Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _yearsExpController,
                    label: 'Years of Experience',
                    icon: Icons.work,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _experienceController,
                    label: 'Experience Details',
                    icon: Icons.work_history,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _educationController,
                    label: 'Education',
                    icon: Icons.school,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _licenseController,
                    label: 'License Number',
                    icon: Icons.card_membership,
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  // MODERN TEXT FIELD
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // HELPER METHODS
  String _getInitials() {
    String name = _nameController.text.isNotEmpty ? _nameController.text : 'Dr';
    final parts = name.split(' ');
    if (parts.length < 2) return name.substring(0, 2).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}