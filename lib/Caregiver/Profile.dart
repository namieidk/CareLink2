// lib/screens/Profile.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Home.dart';
import 'patient.dart';
import 'caremed.dart';
import 'calendar.dart';
import 'Profile/addprofile.dart';
import '../Signin/up/Signin.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Theme colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFE53935);
  static const Color text = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  Map<String, dynamic>? caregiverData;
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      currentUserId = user.uid;

      // Load caregiver basic info
      final caregiverDoc = await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(currentUserId)
          .get();

      if (caregiverDoc.exists) {
        caregiverData = caregiverDoc.data();
        print('Caregiver data loaded: ${caregiverData?['email']}');
      }

      // Try to load profile from 'caregiver_profile' collection using caregiverId
      final caregiverId = caregiverData?['id'];
      print('Looking for profile with caregiverId: $caregiverId');
      
      final profileQuery = await FirebaseFirestore.instance
          .collection('caregiver_profile')
          .where('caregiverId', isEqualTo: caregiverId)
          .limit(1)
          .get();

      print('Profile query results: ${profileQuery.docs.length}');

      if (profileQuery.docs.isNotEmpty) {
        profileData = profileQuery.docs.first.data();
        profileData!['id'] = profileQuery.docs.first.id;
        print('Profile data loaded: ${profileData!['firstName']} ${profileData!['lastName']}');
      } else {
        // Try searching by email as fallback
        if (caregiverData?['email'] != null) {
          print('Trying email search: ${caregiverData!['email']}');
          final emailQuery = await FirebaseFirestore.instance
              .collection('caregiver_profile')
              .where('email', isEqualTo: caregiverData!['email'])
              .limit(1)
              .get();
          
          print('Email query results: ${emailQuery.docs.length}');
          
          if (emailQuery.docs.isNotEmpty) {
            profileData = emailQuery.docs.first.data();
            profileData!['id'] = emailQuery.docs.first.id;
            print('Profile data loaded by email: ${profileData!['firstName']} ${profileData!['lastName']}');
          } else {
            print('No profile found in database');
          }
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => isLoading = false);
    }
  }

  void _goToAddProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProfileScreen(
          profileId: profileData?['id'],
          existingProfile: profileData,
        ),
      ),
    );

    // Reload data when returning from add/edit profile
    if (result != null) {
      setState(() => isLoading = true);
      await _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: _buildBottomNav(context, 4),
      );
    }

    // === NO COMPLETE PROFILE YET ===
    if (profileData == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: Column(
            children: [
              // Header with basic info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF8B7FE8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: const Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      caregiverData?['username'] ?? 'Caregiver',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caregiverData?['email'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    if (caregiverData?['fullName'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        caregiverData!['fullName'],
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Complete Your Profile',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your professional details, certifications,\nand experience to get started',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _goToAddProfile,
                                icon: const Icon(Icons.edit, color: Colors.white),
                                label: const Text(
                                  'Complete Profile',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context, 4),
      );
    }

    // === FULL PROFILE VIEW ===
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER WITH PROFILE PHOTO =================
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF8B7FE8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Profile Photo with Network Image Support
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          color: Colors.white.withOpacity(0.3),
                        ),
                        child: ClipOval(
                          child: profileData!['profilePhotoUrl'] != null
                              ? Image.network(
                                  profileData!['profilePhotoUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.person, size: 40, color: Colors.white);
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                                )
                              : const Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profileData!['firstName']} ${profileData!['lastName']}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Freelance Caregiver',
                              style: TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: success.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _goToAddProfile,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profileData!['bio'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  // Stats Cards
                  Row(
                    children: [
                      _statCard('Experience', '${profileData!['experienceYears']} yrs'),
                      const SizedBox(width: 12),
                      _statCard('Rate', '\$${profileData!['hourlyRate']}/hr'),
                      const SizedBox(width: 12),
                      _statCard('Hours/Week', '${profileData!['availableHoursPerWeek']}'),
                    ],
                  ),
                ],
              ),
            ),

            // ================= SCROLLABLE CONTENT =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(Icons.person_outline, 'Contact Information'),
                    const SizedBox(height: 12),
                    _contactItem(Icons.email, 'Email', profileData!['email'], Colors.blue),
                    const SizedBox(height: 8),
                    _contactItem(Icons.phone, 'Phone', profileData!['phone'], success),
                    const SizedBox(height: 8),
                    _contactItem(Icons.badge, 'License', profileData!['licenseNumber'], primary),

                    const SizedBox(height: 24),

                    _sectionHeader(Icons.language, 'Languages'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (profileData!['languages'] as List<dynamic>)
                          .map<Widget>((lang) => _chip(lang.toString(), primary))
                          .toList(),
                    ),

                    const SizedBox(height: 24),

                    _sectionHeader(Icons.verified, 'Certifications'),
                    const SizedBox(height: 12),
                    if ((profileData!['certifications'] as List<dynamic>).isEmpty)
                      Text('No certifications added yet', style: TextStyle(color: textMuted))
                    else
                      ...(profileData!['certifications'] as List<dynamic>).map((cert) {
                        return _certificationCard(cert['name'], cert['imageUrl']);
                      }).toList(),

                    const SizedBox(height: 24),

                    _sectionHeader(Icons.medical_services, 'Skills & Services'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (profileData!['skills'] as List<dynamic>)
                          .map<Widget>((skill) => _serviceChip(skill.toString()))
                          .toList(),
                    ),

                    const SizedBox(height: 24),

                    _sectionHeader(Icons.school, 'Professional Background'),
                    const SizedBox(height: 12),

                    if (profileData!['education']?.toString().isNotEmpty ?? false)
                      _infoCard(Icons.school, 'Education', profileData!['education'], Colors.purple),

                    if (profileData!['employmentHistory']?.toString().isNotEmpty ?? false) ...[
                      const SizedBox(height: 12),
                      _infoCard(Icons.work, 'Employment History', profileData!['employmentHistory'], Colors.orange),
                    ],

                    if (profileData!['otherExperience']?.toString().isNotEmpty ?? false) ...[
                      const SizedBox(height: 12),
                      _infoCard(Icons.star, 'Other Experience', profileData!['otherExperience'], Colors.blue),
                    ],

                    const SizedBox(height: 40),

                    // Sign Out Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const SignInScreen()),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout, color: danger),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(color: danger, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: danger),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 4),
    );
  }

  // ================= UI HELPERS =================
  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: text, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: text),
        ),
      ],
    );
  }

  Widget _contactItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: textMuted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _serviceChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
      ),
    );
  }

  Widget _certificationCard(String name, String? imageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified, color: success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          if (imageUrl != null)
            const Icon(Icons.image, color: success, size: 18),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: text),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.home, 'Home', currentIndex == 0, 0),
              _buildNavItem(context, Icons.people, 'Patients', currentIndex == 1, 1),
              _buildNavItem(context, Icons.medication, 'Medications', currentIndex == 2, 2),
              _buildNavItem(context, Icons.calendar_month, 'Calendar', currentIndex == 3, 3),
              _buildNavItem(context, Icons.person, 'Profile', currentIndex == 4, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isActive, int index) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (isActive) return;
          final screens = [
            const CaregiverHomeScreen(),
            const PatientsScreen(),
            const MedicationScreen(),
            const CalendarScreen(),
            const ProfileScreen(),
          ];
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => screens[index]),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? primary : Colors.grey[400],
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? primary : Colors.grey[400],
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}