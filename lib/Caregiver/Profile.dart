// lib/screens/Profile.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
  static const Color primary = Color(0xFF6C5CE7);
  static const Color success = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFE53935);
  static const Color text = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  Map<String, dynamic>? caregiverData;
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  String? currentUserId;

  double averageRating = 0.0;
  int totalReviews = 0;
  List<Map<String, dynamic>> reviews = [];

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

      final caregiverDoc = await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(currentUserId)
          .get();

      if (caregiverDoc.exists) {
        caregiverData = caregiverDoc.data();
      }

      final caregiverId = caregiverData?['id'];
      final profileQuery = await FirebaseFirestore.instance
          .collection('caregiver_profile')
          .where('caregiverId', isEqualTo: caregiverId)
          .limit(1)
          .get();

      if (profileQuery.docs.isNotEmpty) {
        profileData = profileQuery.docs.first.data();
        profileData!['id'] = profileQuery.docs.first.id;
      } else if (caregiverData?['email'] != null) {
        final emailQuery = await FirebaseFirestore.instance
            .collection('caregiver_profile')
            .where('email', isEqualTo: caregiverData!['email'])
            .limit(1)
            .get();
        if (emailQuery.docs.isNotEmpty) {
          profileData = emailQuery.docs.first.data();
          profileData!['id'] = emailQuery.docs.first.id;
        }
      }

      // Load ratings from the correct collection
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('toUserId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      totalReviews = ratingsSnapshot.docs.length;

      if (totalReviews > 0) {
        double sum = 0.0;
        reviews = ratingsSnapshot.docs.map((doc) {
          final data = doc.data();
          final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
          sum += rating;
          return {
            'id': doc.id,
            'patientName': data['fromUserName'] ?? 'Anonymous',
            'rating': rating,
            'comment': data['comment'] ?? '',
            'createdAt': data['createdAt'] as Timestamp?,
            'fromUserPhotoUrl': data['fromUserPhotoUrl'],
          };
        }).toList();
        averageRating = sum / totalReviews;
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

    if (result != null) {
      setState(() => isLoading = true);
      await _loadUserData();
    }
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (i < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
    );
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

    if (profileData == null) {
      // === NO PROFILE UI (unchanged) ===
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: Column(
            children: [
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
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caregiverData?['email'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
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
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4))],
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text('Complete Your Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text('Add your professional details, certifications,\nand experience to get started',
                                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _goToAddProfile,
                                icon: const Icon(Icons.edit, color: Colors.white),
                                label: const Text('Complete Profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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

    // === FULL PROFILE - FIXED HEADER NO OVERFLOW ===
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF8B7FE8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Photo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                        child: ClipOval(
                          child: profileData!['profilePhotoUrl'] != null
                              ? Image.network(profileData!['profilePhotoUrl'], fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: Colors.white))
                              : const Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Name, Rating, Verified, Edit - FULLY RESPONSIVE
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name
                                Text(
                                  '${profileData!['firstName']} ${profileData!['lastName']}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const Text('Freelance Caregiver', style: TextStyle(fontSize: 14, color: Colors.white70)),
                                const SizedBox(height: 8),

                                // Rating Row - NOW 100% SAFE
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      _buildStars(averageRating),
                                      const SizedBox(width: 6),
                                      Text(
                                        averageRating.toStringAsFixed(1),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '($totalReviews ${totalReviews == 1 ? 'review' : 'reviews'})',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // Verified Badge + Edit Button (aligned top)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: success.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Verified', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: _goToAddProfile),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text(profileData!['bio'] ?? '', textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 20),
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

            // === REST OF THE PROFILE (unchanged) ===
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
                      const Text('No certifications added yet', style: TextStyle(color: textMuted))
                    else
                      ...(profileData!['certifications'] as List<dynamic>).map((cert) => _certificationCard(cert['name'], cert['imageUrl'])),

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

                    const SizedBox(height: 32),
                    _sectionHeader(Icons.star_outline, 'Patient Ratings & Reviews'),
                    const SizedBox(height: 16),

                    if (totalReviews == 0)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No reviews yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textMuted)),
                              SizedBox(height: 8),
                              Text('Your first patient reviews will appear here.'),
                            ],
                          ),
                        ),
                      )
                    else
                      ...reviews.map((review) {
                        final date = review['createdAt'] != null
                            ? DateFormat('MMM d, yyyy').format((review['createdAt'] as Timestamp).toDate())
                            : 'Unknown date';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: border),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: primary.withOpacity(0.15),
                                    backgroundImage: review['fromUserPhotoUrl'] != null 
                                        ? NetworkImage(review['fromUserPhotoUrl'] as String)
                                        : null,
                                    child: review['fromUserPhotoUrl'] == null
                                        ? Text(
                                            (review['patientName'] as String).isEmpty ? 'A' : (review['patientName'] as String)[0].toUpperCase(),
                                            style: const TextStyle(color: primary, fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(review['patientName'] as String? ?? 'Anonymous',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  ),
                                  Text(date, style: const TextStyle(color: textMuted, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildStars(review['rating'] as double),
                              if ((review['comment'] as String).isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(review['comment'], style: const TextStyle(color: textMuted, height: 1.5, fontSize: 14)),
                              ],
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const SignInScreen()),
                              (_) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout, color: danger),
                        label: const Text('Sign Out', style: TextStyle(color: danger, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: danger),
                          padding: const EdgeInsets.symmetric(vertical: 16),
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

  // === ALL UI HELPERS (unchanged) ===
  Widget _statCard(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70), textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Widget _sectionHeader(IconData icon, String title) => Row(
        children: [
          Icon(icon, color: text, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: text)),
        ],
      );

  Widget _contactItem(IconData icon, String label, String value, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(color: textMuted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
          ],
        ),
      );

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      );

  Widget _serviceChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      );

  Widget _certificationCard(String name, String? imageUrl) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: success.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: success.withOpacity(0.3))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: success.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.verified, color: success, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
            if (imageUrl != null) const Icon(Icons.image, color: success, size: 18),
          ],
        ),
      );

  Widget _infoCard(IconData icon, String title, String content, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: text))]),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 13, color: textMuted, height: 1.5)),
          ],
        ),
      );

  Widget _buildBottomNav(BuildContext context, int currentIndex) => Container(
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: border)), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))]),
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

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isActive, int index) => Expanded(
        child: InkWell(
          onTap: isActive ? null : () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => [const CaregiverHomeScreen(), const PatientsScreen(), const MedicationScreen(), const CalendarScreen(), const ProfileScreen()][index])),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? primary : Colors.grey[400], size: 26),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: isActive ? primary : Colors.grey[400], fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
            ],
          ),
        ),
      );
}