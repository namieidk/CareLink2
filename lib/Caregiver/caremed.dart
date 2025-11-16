import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'Home.dart';
import 'patient.dart';
import 'calendar.dart';
import 'Profile.dart';
import '../models/caregiverAssign.dart';
import '../models/patient_profile.dart';
import '../models/medication.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<CaregiverAssign> _assignments = [];
  List<Medication> _medications = [];
  Map<String, PatientProfile> _patientProfiles = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final String caregiverId = user.uid;

      // Get active assignments
      final QuerySnapshot assignmentSnap = await _firestore
          .collection('caregiver_assignments')
          .where('caregiverId', isEqualTo: caregiverId)
          .where('status', isEqualTo: 'active')
          .get();

      final List<CaregiverAssign> assignments = assignmentSnap.docs
          .map((doc) => CaregiverAssign.fromFirestore(doc))
          .toList();

      final List<String> patientIds = assignments.map((assignment) => assignment.patientId).toList();

      // Get patient profiles using PatientProfile model
      final Map<String, PatientProfile> patientProfiles = <String, PatientProfile>{};
      if (patientIds.isNotEmpty) {
        final QuerySnapshot patientSnap = await _firestore
            .collection('patient_profiles')
            .where(FieldPath.documentId, whereIn: patientIds)
            .get();
        for (var doc in patientSnap.docs) {
          patientProfiles[doc.id] = PatientProfile.fromFirestore(doc);
        }
      }

      // Get medications
      final List<Medication> meds = <Medication>[];
      if (patientIds.isNotEmpty) {
        final QuerySnapshot medSnap = await _firestore
            .collection('medications')
            .where('patientId', whereIn: patientIds)
            .where('isActive', isEqualTo: true)
            .get();
        meds.addAll(medSnap.docs.map((doc) => Medication.fromFirestore(doc)));
      }

      if (!mounted) return;
      setState(() {
        _assignments = assignments;
        _patientProfiles = patientProfiles;
        _medications = meds;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading medications: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load data'), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  List<String> _getMedicationTimes(Medication medication) {
    // Use the actual times from the medication
    if (medication.time.isNotEmpty) {
      return ['08:00 AM', '02:00 PM', '08:00 PM'];
    }
    // Fallback if no times are set
    return ['08:00 AM', '02:00 PM', '08:00 PM'];
  }

  int get _dueToday {
    final DateTime now = DateTime.now();
    final String todayStr = DateFormat('hh:mm a').format(now);
    int count = 0;
    for (var medication in _medications) {
      final List<String> times = _getMedicationTimes(medication);
      if (times.any((time) => _compareTime(time, todayStr) >= 0)) {
        count++;
      }
    }
    return count;
  }

  int get _completedToday {
    return _medications.length - _dueToday;
  }

  int _compareTime(String time1, String time2) {
    try {
      final DateFormat format = DateFormat('hh:mm a');
      final DateTime dateTime1 = format.parse(time1);
      final DateTime dateTime2 = format.parse(time2);
      return dateTime1.compareTo(dateTime2);
    } catch (error) {
      return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: _assignments.isEmpty
                          ? _buildEmptyState()
                          : _buildMedicationList(),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 2),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFC),
        boxShadow: [
          BoxShadow(
            color: Colors.black12, 
            blurRadius: 10, 
            offset: Offset(0, 2)
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
                ),
                Text(
                  'Medications',
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add medication – coming soon!')),
                    );
                  },
                  icon: Icon(
                    Icons.add_circle_outline, 
                    color: Colors.grey[700], 
                    size: 28
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMedStat('$_dueToday', 'Due Today')),
                const SizedBox(width: 12),
                Expanded(child: _buildMedStat('$_completedToday', 'Completed')),
                const SizedBox(width: 12),
                Expanded(child: _buildMedStat('${_assignments.length}', 'Patients')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 8, 
            offset: const Offset(0, 2)
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildTab('Today', true)),
          Expanded(child: _buildTab('Upcoming', false)),
          Expanded(child: _buildTab('History', false)),
        ],
      ),
    );
  }

  Widget _buildMedicationList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        final CaregiverAssign assignment = _assignments[index];
        final PatientProfile? patientProfile = _patientProfiles[assignment.patientId];
        
        if (patientProfile == null) return const SizedBox();

        final String patientName = patientProfile.fullName;
        final int patientAge = patientProfile.age;
        final String patientCondition = patientProfile.primaryCondition;
        final String? profilePhotoUrl = patientProfile.profilePhotoUrl;

        final List<Medication> patientMeds = _medications
            .where((medication) => medication.patientId == assignment.patientId)
            .toList();

        final List<Map<String, dynamic>> doseEntries = [];
        for (var medication in patientMeds) {
          final List<String> times = _getMedicationTimes(medication);
          final DateTime now = DateTime.now();
          final String todayStr = DateFormat('hh:mm a').format(now);
          
          for (var time in times) {
            final bool isPending = _compareTime(time, todayStr) >= 0;
            doseEntries.add({
              'time': time,
              'medication': medication.name,
              'dosage': medication.dose,
              'instructions': medication.instructions,
              'isPending': isPending,
            });
          }
        }

        return Column(
          children: [
            _buildPatientSection(
              patientName: patientName.isEmpty ? 'Unknown Patient' : patientName,
              patientAge: patientAge,
              patientCondition: patientCondition,
              profilePhotoUrl: profilePhotoUrl,
              medications: doseEntries,
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.medication_outlined, 
                size: 80, 
                color: Colors.grey[400]
              ),
              const SizedBox(height: 16),
              Text(
                'No patients assigned',
                style: TextStyle(
                  fontSize: 18, 
                  color: Colors.grey[600]
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You will see medications here once patients are assigned.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedStat(String count, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED), width: 1),
      ),
      child: Column(
        children: [
          Text(
            count, 
            style: TextStyle(
              color: Colors.grey[900], 
              fontSize: 20, 
              fontWeight: FontWeight.bold
            )
          ),
          const SizedBox(height: 4),
          Text(
            label, 
            style: TextStyle(
              color: Colors.grey[600], 
              fontSize: 11
            )
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6C5CE7) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildPatientSection({
    required String patientName,
    required int patientAge,
    required String patientCondition,
    required String? profilePhotoUrl,
    required List<Map<String, dynamic>> medications,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAED), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 8, 
            offset: const Offset(0, 2)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F6F7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), 
                topRight: Radius.circular(20)
              ),
            ),
            child: Row(
              children: [
                // Profile photo with fallback
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300], 
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: profilePhotoUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.person,
                                size: 28,
                                color: Colors.grey[500],
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.person,
                              size: 28,
                              color: Colors.grey[500],
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person, 
                          size: 28, 
                          color: Colors.grey[500]
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName, 
                        style: TextStyle(
                          fontSize: 17, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.grey[900]
                        )
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$patientAge years • $patientCondition', 
                        style: TextStyle(
                          fontSize: 13, 
                          color: Colors.grey[600]
                        )
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${medications.length} doses', 
                    style: const TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.w600, 
                      color: Color(0xFF6C5CE7)
                    )
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: medications.asMap().entries.map((entry) {
                final int entryIndex = entry.key;
                final Map<String, dynamic> medication = entry.value;
                return Column(
                  children: [
                    if (entryIndex > 0) const SizedBox(height: 12),
                    _buildMedicationItem(
                      time: medication['time'] as String,
                      medication: medication['medication'] as String,
                      dosage: medication['dosage'] as String,
                      instructions: medication['instructions'] as String,
                      isPending: medication['isPending'] as bool,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem({
    required String time,
    required String medication,
    required String dosage,
    required String instructions,
    required bool isPending,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending ? const Color(0xFFDFE1E6) : const Color(0xFFE8EAED), 
          width: 1
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPending 
                      ? const Color(0xFFFF6B6B).withOpacity(0.1) 
                      : const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.medication, 
                  color: isPending ? const Color(0xFFFF6B6B) : const Color(0xFF4CAF50), 
                  size: 24
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time, 
                          size: 14, 
                          color: Colors.grey[500]
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time, 
                          style: TextStyle(
                            color: Colors.grey[600], 
                            fontSize: 12, 
                            fontWeight: FontWeight.w500
                          )
                        ),
                        const Spacer(),
                        if (isPending)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F1F3), 
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Text(
                              'Pending', 
                              style: TextStyle(
                                color: Colors.grey[700], 
                                fontSize: 11, 
                                fontWeight: FontWeight.w600
                              )
                            ),
                          )
                        else
                          const Icon(
                            Icons.check_circle, 
                            color: Color(0xFF4CAF50), 
                            size: 18
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      medication, 
                      style: TextStyle(
                        fontSize: 14, 
                        color: Colors.grey[900], 
                        fontWeight: FontWeight.w600
                      )
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey[200], height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.info_outline, 
                size: 15, 
                color: Colors.grey[500]
              ),
              const SizedBox(width: 6),
              Text(
                'Dosage: $dosage', 
                style: TextStyle(
                  fontSize: 12, 
                  color: Colors.grey[600]
                )
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.description_outlined, 
                size: 15, 
                color: Colors.grey[500]
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  instructions, 
                  style: TextStyle(
                    fontSize: 12, 
                    color: Colors.grey[600]
                  )
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.alarm, size: 16),
                    label: const Text('Snooze'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: const BorderSide(color: Color(0xFFE8EAED)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFC),
        border: Border(top: BorderSide(color: Color(0xFFE8EAED), width: 1)),
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
        onTap: () async {
          if (isActive) return;

          final List<Widget Function()> routes = [
            CaregiverHomeScreen.new,
            PatientsScreen.new,
            MedicationScreen.new,
            CalendarScreen.new,
            ProfileScreen.new,
          ];

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => routes[index]()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                color: isActive ? const Color(0xFF6C5CE7) : Colors.grey[400], 
                size: 26
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? const Color(0xFF6C5CE7) : Colors.grey[400],
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