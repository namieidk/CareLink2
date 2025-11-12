// lib/screens/Profile/PatientEditProfileScreen.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:simple_textfield_tag/simple_textfield_tag.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../../models/patient_profile.dart';

class PatientEditProfileScreen extends StatefulWidget {
  const PatientEditProfileScreen({Key? key}) : super(key: key);
  @override
  State<PatientEditProfileScreen> createState() => _PatientEditProfileScreenState();
}

class _PatientEditProfileScreenState extends State<PatientEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Cloudinary
  static const String cloudName = 'duxxwlurg';
  static const String apiKey = '489679362695478';
  static const String apiSecret = '-UKqPTWnXw3LAMj-IbWeIv27HXo';

  // Controllers — EMPTY by default
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String _phone = '';
  String _bloodType = 'O+';

  List<String> _allergies = [];
  List<String> _conditions = [];
  List<EmergencyContact> _emergencyContacts = [];

  File? _profileImage;
  String? _existingPhotoUrl;

  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('patient_profiles')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final profile = PatientProfile.fromMap(doc.data()!, doc.id);

        _nameController.text = profile.fullName;
        _ageController.text = profile.age.toString();
        _emailController.text = profile.email;
        _addressController.text = profile.address;
        _phone = profile.phone;
        _bloodType = profile.bloodType;
        _allergies = List.from(profile.allergies);
        _conditions = List.from(profile.conditions);
        _emergencyContacts = List.from(profile.emergencyContacts);
        _existingPhotoUrl = profile.profilePhotoUrl;
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _uploadToCloudinary(File file, String folder) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri);

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final params = 'folder=$folder&timestamp=$timestamp$apiSecret';
    final signature = sha1.convert(utf8.encode(params)).toString();

    request.fields.addAll({
      'folder': folder,
      'timestamp': timestamp,
      'api_key': apiKey,
      'signature': signature,
    });

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    final json = jsonDecode(respStr);
    if (response.statusCode != 200) throw Exception(json['error']['message']);
    return json['secure_url'];
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  void _addEmergencyContact() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EmergencyContactForm(
        onSave: (contact) {
          setState(() => _emergencyContacts.add(contact));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _editEmergencyContact(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EmergencyContactForm(
        contact: _emergencyContacts[index],
        onSave: (contact) {
          setState(() => _emergencyContacts[index] = contact);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _removeEmergencyContact(int index) {
    setState(() => _emergencyContacts.removeAt(index));
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String? photoUrl = _existingPhotoUrl;

      if (_profileImage != null) {
        photoUrl = await _uploadToCloudinary(_profileImage!, 'carelink/patient_photos');
      }

      final profile = PatientProfile(
        id: user.uid,
        patientId: user.uid,
        fullName: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        email: _emailController.text.trim(),
        phone: _phone,
        address: _addressController.text.trim(),
        bloodType: _bloodType,
        allergies: _allergies,
        conditions: _conditions,
        emergencyContacts: _emergencyContacts,
        profilePhotoUrl: photoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('patient_profiles')
          .doc(user.uid)
          .set(profile.toMap(), SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!'), backgroundColor: Color(0xFFFF6B6B)),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // PROFILE PHOTO
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFFFF8A8A), Color(0xFFFF6B6B)]),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: CircleAvatar(
                        radius: 62,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 58,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (_existingPhotoUrl != null ? NetworkImage(_existingPhotoUrl!) : null),
                          child: _profileImage == null && _existingPhotoUrl == null
                              ? Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                      : '??',
                                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B)),
                                )
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8, right: 8,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // PERSONAL INFO
              _buildCard(title: 'Personal Information', children: [
                _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(flex: 3, child: _buildTextField(_ageController, 'Age', Icons.cake_outlined, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(flex: 4, child: _bloodTypeDropdown()),
                  ],
                ),
              ]),
              const SizedBox(height: 20),

              // CONTACT INFO
              _buildCard(title: 'Contact Information', children: [
                _buildTextField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                IntlPhoneField(
                  initialValue: _phone,
                  initialCountryCode: 'US',
                  onChanged: (p) => _phone = p.completeNumber,
                  decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
                ),
                const SizedBox(height: 12),
                _buildTextField(_addressController, 'Street Address', Icons.home_outlined),
              ]),
              const SizedBox(height: 20),

              // ALLERGIES
              _buildCard(
                title: 'Allergies',
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFE53935),
                children: [
                  SimpleTextFieldTag(
                    initialTags: _allergies,
                    onTagAdded: (t) => setState(() => _allergies = [..._allergies, t]),
                    onTagRemoved: (t) => setState(() => _allergies.remove(t)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap to add allergy', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 20),

              // CONDITIONS
              _buildCard(
                title: 'Medical Conditions',
                icon: Icons.local_hospital_rounded,
                iconColor: const Color(0xFFFF6B6B),
                children: [
                  SimpleTextFieldTag(
                    initialTags: _conditions,
                    onTagAdded: (t) => setState(() => _conditions = [..._conditions, t]),
                    onTagRemoved: (t) => setState(() => _conditions.remove(t)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap to add condition', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 20),

              // EMERGENCY CONTACTS
              _buildCard(
                title: 'Emergency Contacts',
                icon: Icons.phone_in_talk,
                iconColor: const Color(0xFFE53935),
                children: [
                  ..._emergencyContacts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final contact = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFFF6B6B),
                            child: Text(contact.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(contact.relation, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                Text(contact.phone, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFFFF6B6B)),
                            onPressed: () => _editEmergencyContact(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Color(0xFFE53935)),
                            onPressed: () => _removeEmergencyContact(index),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addEmergencyContact,
                      icon: const Icon(Icons.add, color: Color(0xFFFF6B6B)),
                      label: const Text('Add Contact', style: TextStyle(color: Color(0xFFFF6B6B))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF6B6B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // BLOOD TYPE DROPDOWN
  Widget _bloodTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _bloodType,
      decoration: _inputDecoration('Blood Type', Icons.water_drop_outlined),
      items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (v) => setState(() => _bloodType = v!),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  // CARD WRAPPER
  Widget _buildCard({required String title, IconData? icon, Color? iconColor, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, color: iconColor, size: 22), const SizedBox(width: 8)],
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // TEXT FIELD
  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: _inputDecoration(label, icon),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        if (label == 'Age') {
          final age = int.tryParse(v);
          if (age == null || age < 1 || age > 120) return 'Valid age 1–120';
        }
        return null;
      },
    );
  }

  // INPUT DECORATION
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: const Color(0xFFFF6B6B)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2)),
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

// EMERGENCY CONTACT FORM (BOTTOM SHEET) — WITH DROPDOWN + OTHER
class _EmergencyContactForm extends StatefulWidget {
  final EmergencyContact? contact;
  final Function(EmergencyContact) onSave;

  const _EmergencyContactForm({this.contact, required this.onSave});

  @override
  State<_EmergencyContactForm> createState() => _EmergencyContactFormState();
}

class _EmergencyContactFormState extends State<_EmergencyContactForm> {
  final _nameCtrl = TextEditingController();
  final _otherRelationCtrl = TextEditingController();
  String _phone = '';
  String _selectedRelation = 'Daughter';
  bool _isOther = false;

  final List<String> _relations = [
    'Daughter',
    'Son',
    'Spouse',
    'Sibling',
    'Parent',
    'Friend',
    'Neighbor',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameCtrl.text = widget.contact!.name;
      _phone = widget.contact!.phone;

      final rel = widget.contact!.relation;
      if (_relations.contains(rel)) {
        _selectedRelation = rel;
        _isOther = false;
      } else {
        _selectedRelation = 'Other';
        _isOther = true;
        _otherRelationCtrl.text = rel;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.contact == null ? 'Add Emergency Contact' : 'Edit Contact',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // NAME
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // RELATIONSHIP DROPDOWN
            DropdownButtonFormField<String>(
              value: _selectedRelation,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                prefixIcon: Icon(Icons.family_restroom),
                border: OutlineInputBorder(),
              ),
              items: _relations
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedRelation = v!;
                  _isOther = v == 'Other';
                  if (!_isOther) _otherRelationCtrl.clear();
                });
              },
            ),
            const SizedBox(height: 12),

            // OTHER TEXT FIELD
            if (_isOther)
              TextFormField(
                controller: _otherRelationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Specify Relationship',
                  hintText: 'e.g. Caregiver, Cousin',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _isOther && (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
            if (_isOther) const SizedBox(height: 12),

            // PHONE
            IntlPhoneField(
              initialValue: _phone,
              initialCountryCode: 'US',
              onChanged: (p) => _phone = p.completeNumber,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
                    onPressed: () {
                      final name = _nameCtrl.text.trim();
                      final relation = _isOther ? _otherRelationCtrl.text.trim() : _selectedRelation;
                      if (name.isEmpty || relation.isEmpty || _phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields')),
                        );
                        return;
                      }
                      widget.onSave(EmergencyContact(
                        name: name,
                        relation: relation,
                        phone: _phone,
                      ));
                    },
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _otherRelationCtrl.dispose();
    super.dispose();
  }
}