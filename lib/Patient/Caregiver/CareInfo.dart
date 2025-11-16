// lib/screens/CaregiverInfoScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../shared/message.dart';
import '../../models/caregiver_profile.dart';

class CaregiverInfoScreen extends StatefulWidget {
  final String? caregiverId;

  const CaregiverInfoScreen({super.key, this.caregiverId});

  @override
  State<CaregiverInfoScreen> createState() => _CaregiverInfoScreenState();
}

class _CaregiverInfoScreenState extends State<CaregiverInfoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final String _currentUserId;
  String _currentUserName = 'Patient';
  String _currentUserPhoto = '';

  CaregiverProfile? _caregiver;
  bool _isLoading = true;
  bool _isExpanded = false;
  String? _caregiverId;

  static const Color pink = Color(0xFFE91E63);
  static const Color green = Color(0xFF00B894);
  static const Color blue = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    _currentUserId = user.uid;
    _loadPatientInfo();
    _loadCaregiverAssignment();
  }

  Future<void> _loadPatientInfo() async {
    try {
      final doc = await _firestore.collection('patient_profiles').doc(_currentUserId).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _currentUserName = doc.data()!['fullName'] ?? 'Patient';
          _currentUserPhoto = doc.data()!['profilePhotoUrl'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading patient info: $e');
    }
  }

  Future<void> _loadCaregiverAssignment() async {
    try {
      // If caregiverId is provided directly, use it
      if (widget.caregiverId != null) {
        _caregiverId = widget.caregiverId;
        await _loadCaregiverInfo();
        return;
      }

      // Otherwise, look up the caregiver assignment for this patient
      final assignmentQuery = await _firestore
          .collection('caregiver_assignments')
          .where('patientId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'active')
          .where('removedAt', isEqualTo: null)
          .limit(1)
          .get();

      if (assignmentQuery.docs.isNotEmpty) {
        final assignment = assignmentQuery.docs.first.data();
        _caregiverId = assignment['caregiverId'];
        await _loadCaregiverInfo();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No active caregiver assigned'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading caregiver assignment: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading caregiver assignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCaregiverInfo() async {
    if (_caregiverId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Query caregiver_profile collection where caregiverId field matches
      final querySnapshot = await _firestore
          .collection('caregiver_profile')
          .where('caregiverId', isEqualTo: _caregiverId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        
        // Create CaregiverProfile from the document data
        final caregiver = CaregiverProfile(
          id: doc.id,
          caregiverId: data['caregiverId'] ?? '',
          firstName: data['firstName'] ?? '',
          lastName: data['lastName'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          bio: data['bio'] ?? '',
          experienceYears: (data['experienceYears'] as num?)?.toInt() ?? 0,
          hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? 0.0,
          availableHoursPerWeek: (data['avaiLabLeHoursPerWeek'] as num?)?.toInt() ?? 0,
          licenseNumber: data['licenseNumber'] ?? '',
          education: data['education'] ?? '',
          employmentHistory: data['employmentHistory'] ?? '',
          otherExperience: data['otherExperience'] ?? '',
          skills: List<String>.from(data['skills'] ?? []),
          languages: List<String>.from(data['languages'] ?? []),
          certifications: List<Map<String, dynamic>>.from(data['certifications'] ?? []).map((cert) => Certification(
            name: cert['name'] ?? '',
            imageUrl: cert['imageUrl'] ?? '',
          )).toList(),
          profilePhotoUrl: data['profilePhotoUrl'] ?? '',
          verificationIdUrl: data['verificationIdUrl'] ?? '',
          createdAt: data['createdAt']?.toDate(),
        );

        setState(() {
          _caregiver = caregiver;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Caregiver profile not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading caregiver info: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading caregiver: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall() async {
    if (_caregiver?.phone == null || _caregiver!.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final url = Uri.parse('tel:${_caregiver!.phone}');
    if (await url_launcher.canLaunchUrl(url)) {
      await url_launcher.launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not make phone call'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendMessage() {
    if (_caregiver == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageScreen(
          patientName: _currentUserName,
          patientPhoto: _currentUserPhoto,
          patientId: _currentUserId,
          caregiverId: _caregiver!.caregiverId,
          caregiverName: '${_caregiver!.firstName} ${_caregiver!.lastName}',
          caregiverPhoto: _caregiver!.profilePhotoUrl ?? '',
        ),
      ),
    );
  }

  void _showCertificationImage(String imageUrl, String name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.6,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.6,
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('Failed to load image', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEC407A), Color(0xFFF8BBD0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Profile Photo and Basic Info
          Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: _caregiver?.profilePhotoUrl != null && _caregiver!.profilePhotoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Image.network(
                          _caregiver!.profilePhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              _caregiver != null ? '${_caregiver!.firstName[0]}${_caregiver!.lastName[0]}' : 'CG',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          _caregiver != null ? '${_caregiver!.firstName[0]}${_caregiver!.lastName[0]}' : 'CG',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _caregiver != null ? '${_caregiver!.firstName} ${_caregiver!.lastName}' : 'Loading...',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_caregiver?.experienceYears ?? 0}+ years experience',
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '\$${_caregiver?.hourlyRate ?? 0}/hour',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _makePhoneCall,
                  icon: const Icon(Icons.phone, size: 20),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: pink,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.message, size: 20),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Not provided',
                  style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkills() {
    if (_caregiver?.skills.isEmpty ?? true) {
      return const Text('No skills listed', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _caregiver!.skills.map((skill) => Chip(
        label: Text(skill, style: const TextStyle(fontSize: 12)),
        backgroundColor: pink.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      )).toList(),
    );
  }

  Widget _buildLanguages() {
    if (_caregiver?.languages.isEmpty ?? true) {
      return const Text('No languages listed', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _caregiver!.languages.map((language) => Chip(
        label: Text(language, style: const TextStyle(fontSize: 12)),
        backgroundColor: blue.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      )).toList(),
    );
  }

  Widget _buildCertifications() {
    if (_caregiver?.certifications.isEmpty ?? true) {
      return const Text('No certifications listed', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
    }

    return Column(
      children: _caregiver!.certifications.map((cert) => ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.verified, color: green, size: 20),
        ),
        title: Text(cert.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: cert.imageUrl.isNotEmpty 
            ? IconButton(
                onPressed: () => _showCertificationImage(cert.imageUrl, cert.name),
                icon: Icon(Icons.visibility, color: blue),
              )
            : null,
        onTap: cert.imageUrl.isNotEmpty ? () => _showCertificationImage(cert.imageUrl, cert.name) : null,
      )).toList(),
    );
  }

  Widget _buildBio() {
    if (_caregiver?.bio.isEmpty ?? true) {
      return const Text('No bio provided', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _caregiver!.bio,
          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          maxLines: _isExpanded ? null : 3,
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
        ),
        if (_caregiver!.bio.length > 150)
          TextButton(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            child: Text(
              _isExpanded ? 'Show less' : 'Read more',
              style: TextStyle(color: pink, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: pink))
          : _caregiver == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No caregiver assigned', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pink,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Fixed Header - NOT SCROLLABLE
                    Container(
                      height: 300, 
                      child: Stack(
                        children: [
                          _buildHeader(),
                          Positioned(
                            top: MediaQuery.of(context).padding.top,
                            left: 0,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Contact Information
                            _buildInfoSection(
                              'Contact Information',
                              Column(
                                children: [
                                  _buildInfoRow('Email', _caregiver!.email, icon: Icons.email),
                                  _buildInfoRow('Phone', _caregiver!.phone, icon: Icons.phone),
                                ],
                              ),
                            ),

                            // Professional Information
                            _buildInfoSection(
                              'Professional Information',
                              Column(
                                children: [
                                  _buildInfoRow('License Number', _caregiver!.licenseNumber, icon: Icons.badge),
                                  _buildInfoRow('Available Hours/Week', '${_caregiver!.availableHoursPerWeek} hours', icon: Icons.access_time),
                                  _buildInfoRow('Experience', '${_caregiver!.experienceYears} years', icon: Icons.work),
                                ],
                              ),
                            ),

                            // Bio
                            _buildInfoSection(
                              'About Me',
                              _buildBio(),
                            ),

                            // Skills
                            _buildInfoSection(
                              'Skills & Specialties',
                              _buildSkills(),
                            ),

                            // Languages
                            _buildInfoSection(
                              'Languages',
                              _buildLanguages(),
                            ),

                            // Education
                            if (_caregiver!.education.isNotEmpty)
                              _buildInfoSection(
                                'Education',
                                Text(_caregiver!.education, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
                              ),

                            // Employment History
                            if (_caregiver!.employmentHistory.isNotEmpty)
                              _buildInfoSection(
                                'Employment History',
                                Text(_caregiver!.employmentHistory, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
                              ),

                            // Other Experience
                            if (_caregiver!.otherExperience.isNotEmpty)
                              _buildInfoSection(
                                'Other Experience',
                                Text(_caregiver!.otherExperience, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
                              ),

                            // Certifications
                            _buildInfoSection(
                              'Certifications',
                              _buildCertifications(),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}