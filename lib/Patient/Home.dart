import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'Medication.dart';
import 'Caregiver.dart';
import 'Caregiver/Careinfo.dart';
import 'doctor.dart';
import 'Profile.dart';
import '../models/patient_profile.dart';
import '../models/medication.dart';
import '../models/caregiver_profile.dart';
import '../models/caregiverAssign.dart';
import '../models/MedicalHistory.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({Key? key}) : super(key: key);

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  static const Color primary = Color(0xFFFF6B6B);
  static const Color muted = Colors.grey;

  PatientProfile? _patientProfile;
  CaregiverProfile? _assignedCaregiver;
  CaregiverAssign? _caregiverAssign;
  List<Medication> _medications = [];
  List<Medication> _todayMedications = [];
  Set<String> _completedTodayIds = {};
  bool _isLoading = true;
  String _greeting = 'Hello';
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadPatientProfile();
    await _loadMedicationHistoryData();
    await _loadMedications();
    await _loadAssignedCaregiver();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _loadPatientProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('patient_profiles')
          .where('patientId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _patientProfile = PatientProfile.fromMap(
            snapshot.docs.first.data() as Map<String, dynamic>,
            snapshot.docs.first.id,
          );
        });
      }
    } catch (e) {
      print('Error loading patient profile: $e');
    }
  }

  Future<void> _loadMedicationHistoryData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('medication_history')
          .where('patientId', isEqualTo: user.uid)
          .get();

      int completed = 0;
      Set<String> completedToday = {};

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      for (var doc in snapshot.docs) {
        try {
          final medHistory = MedicationHistory.fromFirestore(doc);
          
          if (medHistory.status.toLowerCase() == 'taken') {
            completed++;
            if (medHistory.takenAt.isAfter(todayStart) && medHistory.takenAt.isBefore(todayEnd)) {
              completedToday.add(medHistory.medicationId);
            }
          }
        } catch (e) {
          print('Error parsing medication history document ${doc.id}: $e');
          continue;
        }
      }

      setState(() {
        _completedTodayIds = completedToday;
        _completedCount = completed;
      });
    } catch (e) {
      print('Error loading medication history: $e');
    }
  }

  Future<void> _loadMedications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('medications')
          .where('patientId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .get();

      List<Medication> allMeds = snapshot.docs
          .map((doc) => Medication.fromFirestore(doc))
          .toList();

      allMeds.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      List<Medication> activeMeds = allMeds
          .where((med) => !_completedTodayIds.contains(med.id))
          .toList();

      List<Medication> todayMeds = activeMeds.take(2).toList();

      setState(() {
        _medications = activeMeds;
        _todayMedications = todayMeds;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading medications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssignedCaregiver() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Step 1: Find active caregiver assignment for this patient
      final QuerySnapshot assignmentSnapshot = await FirebaseFirestore.instance
          .collection('caregiver_assignments')
          .where('patientId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (assignmentSnapshot.docs.isEmpty) {
        print('No active caregiver assignment found');
        setState(() {
          _assignedCaregiver = null;
          _caregiverAssign = null;
        });
        return;
      }

      // Step 2: Get the assignment details
      final assignmentDoc = assignmentSnapshot.docs.first;
      final assignment = CaregiverAssign.fromFirestore(assignmentDoc);
      
      print('Found caregiver assignment: ${assignment.caregiverId}');

      // Step 3: Load the caregiver profile using caregiverId
      final QuerySnapshot profileSnapshot = await FirebaseFirestore.instance
          .collection('caregiver_profile')
          .where('caregiverId', isEqualTo: assignment.caregiverId)
          .limit(1)
          .get();

      if (profileSnapshot.docs.isNotEmpty) {
        final caregiverProfile = CaregiverProfile.fromMap(
          profileSnapshot.docs.first.data() as Map<String, dynamic>,
          profileSnapshot.docs.first.id,
        );
        
        print('Loaded caregiver profile: ${caregiverProfile.firstName} ${caregiverProfile.lastName}');
        
        setState(() {
          _assignedCaregiver = caregiverProfile;
          _caregiverAssign = assignment;
        });
      } else {
        print('Caregiver profile not found for caregiverId: ${assignment.caregiverId}');
        setState(() {
          _assignedCaregiver = null;
          _caregiverAssign = assignment;
        });
      }
    } catch (e) {
      print('Error loading assigned caregiver: $e');
      setState(() {
        _assignedCaregiver = null;
        _caregiverAssign = null;
      });
    }
  }

  String _getInitials(String fullName) {
    if (fullName.isEmpty) return 'U';
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName[0].toUpperCase();
  }

  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'User';
    final parts = fullName.trim().split(' ');
    return parts[0];
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return DateFormat('EEEE, MMMM d, yyyy').format(now);
  }

  // === REUSABLE BOTTOM NAVIGATION ===
  Widget _buildBottomNav(BuildContext context, int activeIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -1))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_outlined, 'Home', activeIndex == 0, 0, context),
              _navItem(Icons.medical_services_outlined, 'Meds', activeIndex == 1, 1, context),
              _navItem(Icons.people_alt_outlined, 'Caregiver', activeIndex == 2, 2, context),
              _navItem(Icons.calendar_today, 'Schedule', activeIndex == 3, 3, context),
              _navItem(Icons.person_outline, 'Profile', activeIndex == 4, 4, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, int index, BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: active
            ? null
            : () {
                switch (index) {
                  case 0:
                    break;
                  case 1:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientMedicationScreen()),
                    );
                    break;
                  case 2:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientCaregiverScreen()),
                    );
                    break;
                  case 3:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const DoctorPage()),
                    );
                    break;
                  case 4:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientProfileScreen()),
                    );
                    break;
                }
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? primary : muted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? primary : muted,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primary),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildProgressCard(),
                            const SizedBox(height: 24),
                            _buildSectionHeader(Icons.access_time, "Today's Medications"),
                            const SizedBox(height: 16),
                            if (_todayMedications.isEmpty)
                              _emptyMedicationsCard()
                            else
                              ..._todayMedications.map((med) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _medicationCard(medication: med),
                                  )),
                            const SizedBox(height: 24),
                            _buildSectionHeader(Icons.people, 'Your Caregiver'),
                            const SizedBox(height: 16),
                            _buildCaregiverCard(),
                            const SizedBox(height: 24),
                            _buildSectionHeader(Icons.medication, 'All Medications'),
                            const SizedBox(height: 16),
                            if (_medications.isEmpty)
                              _emptyAllMedicationsCard()
                            else
                              ..._medications.take(3).map((med) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _medicationListItem(medication: med),
                                  )),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const PatientMedicationScreen()),
                                  );
                                },
                                icon: const Icon(Icons.medication, size: 20),
                                label: const Text('All Medications', style: TextStyle(fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  // === HEADER ===
  Widget _buildHeader() {
    final fullName = _patientProfile?.fullName ?? 'User';
    final firstName = _getFirstName(fullName);
    final initials = _getInitials(fullName);
    final photoUrl = _patientProfile?.profilePhotoUrl;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          photoUrl != null && photoUrl.isNotEmpty
              ? CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(photoUrl),
                  backgroundColor: primary,
                  onBackgroundImageError: (_, __) {},
                  child: photoUrl.isEmpty
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                )
              : CircleAvatar(
                  radius: 28,
                  backgroundColor: primary,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting, $firstName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  _getFormattedDate(),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 28),
                onPressed: () {},
              ),
              const Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === PROGRESS CARD ===
  Widget _buildProgressCard() {
    final totalMeds = _medications.length + _completedTodayIds.length;
    final completedToday = _completedTodayIds.length;
    final progressPercent = totalMeds > 0 ? (completedToday / totalMeds * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Today's Progress", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Chip(
                backgroundColor: const Color(0xFF4CAF50),
                label: Text('$progressPercent%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$completedToday of $totalMeds doses taken', style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  // === SECTION HEADER ===
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.black87, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // === CAREGIVER CARD ===
  Widget _buildCaregiverCard() {
    if (_assignedCaregiver == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.person_add_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No caregiver assigned yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const PatientCaregiverScreen()),
                  );
                },
                child: const Text('Find a Caregiver'),
              ),
            ],
          ),
        ),
      );
    }

    final caregiver = _assignedCaregiver!;
    final caregiverName = '${caregiver.firstName} ${caregiver.lastName}';
    final caregiverInitials = _getInitials(caregiverName);

    return GestureDetector(
      onTap: () {
        // Navigate to CaregiverInfoScreen with the caregiverId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CaregiverInfoScreen(caregiverId: caregiver.caregiverId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                caregiver.profilePhotoUrl != null && caregiver.profilePhotoUrl!.isNotEmpty
                    ? CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(caregiver.profilePhotoUrl!),
                        backgroundColor: const Color(0xFFFF9800),
                        onBackgroundImageError: (_, __) {},
                      )
                    : CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFFFF9800),
                        child: Text(
                          caregiverInitials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caregiverName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _patientProfile?.address ?? 'Location not set',
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${caregiver.experienceYears} years experience',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Color(0xFFFF9800), size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(
                    caregiver.phone,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(Icons.email, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      caregiver.email,
                      style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
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

  // === TODAY'S MED CARD ===
  Widget _medicationCard({required Medication medication}) {
    final isTaken = false;
    final status = isTaken ? 'Taken' : 'Take Now';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTaken ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isTaken ? const Color(0xFF4CAF50) : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isTaken ? const Color(0xFF4CAF50) : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isTaken ? Icons.check : Icons.access_time,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${medication.dose} • ${medication.time}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isTaken ? const Color(0xFF4CAF50) : primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMedicationsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.medication_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No medications for today',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              'Add your medications to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // === MED LIST ITEM ===
  Widget _medicationListItem({required Medication medication}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(medication.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(medication.dose, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(medication.purpose, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text('${medication.frequency} • ${medication.time}', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _emptyAllMedicationsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.medication, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No medications added yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              'Start adding your medications',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}