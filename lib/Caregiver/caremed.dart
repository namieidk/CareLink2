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
import '../models/MedicalHistory.dart';

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
  List<MedicationHistory> _medicationHistory = [];
  Map<String, PatientProfile> _patientProfiles = {};
  bool _isLoading = true;
  int _currentTab = 0; // 0 = Today, 1 = History

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

      // Get medication history for today - FIXED: Simplified query to avoid composite index requirement
      final List<MedicationHistory> history = <MedicationHistory>[];
      if (patientIds.isNotEmpty) {
        final DateTime now = DateTime.now();
        final DateTime startOfDay = DateTime(now.year, now.month, now.day);
        
        // Simple query without range filters on multiple fields
        final QuerySnapshot historySnap = await _firestore
            .collection('medication_history')
            .where('patientId', whereIn: patientIds)
            .orderBy('takenAt', descending: true)
            .limit(100) // Limit to reasonable number of records
            .get();

        // Filter client-side for today's records
        history.addAll(historySnap.docs
            .map((doc) => MedicationHistory.fromFirestore(doc))
            .where((historyItem) => 
                historyItem.takenAt.isAfter(startOfDay) && 
                historyItem.takenAt.isBefore(DateTime(now.year, now.month, now.day + 1)))
            .toList());
      }

      if (!mounted) return;
      setState(() {
        _assignments = assignments;
        _patientProfiles = patientProfiles;
        _medications = meds;
        _medicationHistory = history;
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

  List<Map<String, dynamic>> _getTodayMedications() {
    final List<Map<String, dynamic>> todayMeds = [];
    final DateTime now = DateTime.now();
    final String todayStr = DateFormat('hh:mm a').format(now);

    for (var medication in _medications) {
      // Check if medication has any pending doses for today
      final List<String> pendingTimes = _getPendingTimesForToday(medication);
      
      for (var time in pendingTimes) {
        todayMeds.add({
          'medication': medication,
          'time': time,
          'patientId': medication.patientId,
          'isPending': true,
        });
      }
    }

    // Sort by time
    todayMeds.sort((a, b) {
      final timeA = _parseTime(a['time'] as String);
      final timeB = _parseTime(b['time'] as String);
      return timeA.compareTo(timeB);
    });

    return todayMeds;
  }

  List<String> _getPendingTimesForToday(Medication medication) {
    final List<String> pendingTimes = [];
    final DateTime now = DateTime.now();
    final String todayStr = DateFormat('hh:mm a').format(now);

    // Use the times list from the medication model
    for (var time in medication.times) {
      // Check if this dose was already taken today
      final bool isTaken = _medicationHistory.any((history) =>
          history.medicationId == medication.id &&
          history.time == time &&
          history.status == 'taken');

      // Only show pending medications that haven't been taken and are for current/future times
      if (!isTaken && _compareTime(time, todayStr) >= 0) {
        pendingTimes.add(time);
      }
    }

    return pendingTimes;
  }

  DateTime _parseTime(String timeStr) {
    try {
      final format = RegExp(r'(\d{1,2}):(\d{2})\s?(AM|PM)', caseSensitive: false);
      final match = format.firstMatch(timeStr);
      if (match == null) return DateTime.now();

      int hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3)!.toUpperCase();

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return DateTime(2020, 1, 1, hour, minute);
    } catch (e) {
      return DateTime.now();
    }
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

  Future<void> _markAsTaken(Medication medication, String time) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      // Create medication history entry
      final medicationHistory = MedicationHistory(
        id: '${medication.id}_${DateTime.now().millisecondsSinceEpoch}',
        patientId: medication.patientId,
        medicationId: medication.id,
        medicationName: medication.name,
        dose: medication.dose,
        time: time,
        period: medication.period,
        frequency: medication.frequency,
        purpose: medication.purpose,
        instructions: medication.instructions,
        sideEffects: medication.sideEffects,
        prescribedBy: medication.prescribedBy,
        prescribedById: medication.prescribedById,
        doctorSpecialty: medication.doctorSpecialty,
        doctorHospital: medication.doctorHospital,
        status: 'taken',
        takenAt: DateTime.now(),
        scheduledTime: _getScheduledTime(time),
      );

      // Save to Firestore
      await _firestore
          .collection('medication_history')
          .doc(medicationHistory.id)
          .set(medicationHistory.toMap());

      // Reload data to reflect changes
      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${medication.name} marked as taken'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      debugPrint('Error marking medication as taken: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark medication as taken'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  DateTime _getScheduledTime(String time) {
    final now = DateTime.now();
    final scheduledTime = _parseTime(time);
    return DateTime(
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );
  }

  int get _dueToday {
    return _getTodayMedications().length;
  }

  int get _completedToday {
    return _medicationHistory.where((history) => history.status == 'taken').length;
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
                          : _buildContent(),
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
          Expanded(child: _buildTab('Today', _currentTab == 0)),
          Expanded(child: _buildTab('History', _currentTab == 1)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_currentTab == 0) {
      return _buildTodayView();
    } else {
      return _buildHistoryView();
    }
  }

  Widget _buildTodayView() {
    final todayMedications = _getTodayMedications();
    
    if (todayMedications.isEmpty) {
      return _buildEmptyTodayState();
    }

    // Group medications by patient
    final Map<String, List<Map<String, dynamic>>> medicationsByPatient = {};
    for (var medEntry in todayMedications) {
      final String patientId = medEntry['patientId'] as String;
      if (!medicationsByPatient.containsKey(patientId)) {
        medicationsByPatient[patientId] = [];
      }
      medicationsByPatient[patientId]!.add(medEntry);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: medicationsByPatient.length,
      itemBuilder: (context, index) {
        final String patientId = medicationsByPatient.keys.elementAt(index);
        final PatientProfile? patientProfile = _patientProfiles[patientId];
        final List<Map<String, dynamic>> patientMeds = medicationsByPatient[patientId]!;
        
        if (patientProfile == null) return const SizedBox();

        return Column(
          children: [
            _buildPatientSection(
              patientName: patientProfile.fullName.isEmpty ? 'Unknown Patient' : patientProfile.fullName,
              patientAge: patientProfile.age,
              patientCondition: patientProfile.primaryCondition,
              profilePhotoUrl: patientProfile.profilePhotoUrl,
              medications: patientMeds,
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildHistoryView() {
    if (_medicationHistory.isEmpty) {
      return _buildEmptyHistoryState();
    }

    // Group history by patient
    final Map<String, List<MedicationHistory>> historyByPatient = {};
    for (var history in _medicationHistory) {
      if (!historyByPatient.containsKey(history.patientId)) {
        historyByPatient[history.patientId] = [];
      }
      historyByPatient[history.patientId]!.add(history);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: historyByPatient.length,
      itemBuilder: (context, index) {
        final String patientId = historyByPatient.keys.elementAt(index);
        final PatientProfile? patientProfile = _patientProfiles[patientId];
        final List<MedicationHistory> patientHistory = historyByPatient[patientId]!;
        
        if (patientProfile == null) return const SizedBox();

        return Column(
          children: [
            _buildPatientHistorySection(
              patientName: patientProfile.fullName.isEmpty ? 'Unknown Patient' : patientProfile.fullName,
              patientAge: patientProfile.age,
              patientCondition: patientProfile.primaryCondition,
              profilePhotoUrl: patientProfile.profilePhotoUrl,
              history: patientHistory,
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

  Widget _buildEmptyTodayState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline, 
                size: 80, 
                color: Colors.green[400]
              ),
              const SizedBox(height: 16),
              Text(
                'All medications taken!',
                style: TextStyle(
                  fontSize: 18, 
                  color: Colors.grey[600]
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All medications for today have been completed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistoryState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.history_outlined, 
                size: 80, 
                color: Colors.grey[400]
              ),
              const SizedBox(height: 16),
              Text(
                'No medication history',
                style: TextStyle(
                  fontSize: 18, 
                  color: Colors.grey[600]
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Medication history will appear here once medications are taken.',
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
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = label == 'Today' ? 0 : 1;
        });
      },
      child: Container(
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
                final Map<String, dynamic> medicationEntry = entry.value;
                final Medication medication = medicationEntry['medication'] as Medication;
                final String time = medicationEntry['time'] as String;
                
                return Column(
                  children: [
                    if (entryIndex > 0) const SizedBox(height: 12),
                    _buildMedicationItem(
                      medication: medication,
                      time: time,
                      isPending: true,
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

  Widget _buildPatientHistorySection({
    required String patientName,
    required int patientAge,
    required String patientCondition,
    required String? profilePhotoUrl,
    required List<MedicationHistory> history,
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
                    '${history.length} entries', 
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
              children: history.asMap().entries.map((entry) {
                final int entryIndex = entry.key;
                final MedicationHistory historyEntry = entry.value;
                
                return Column(
                  children: [
                    if (entryIndex > 0) const SizedBox(height: 12),
                    _buildHistoryItem(historyEntry),
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
    required Medication medication,
    required String time,
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
                      medication.name, 
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
                'Dosage: ${medication.dose}', 
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
                  medication.instructions, 
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
                    onPressed: () => _markAsTaken(medication, time),
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

  Widget _buildHistoryItem(MedicationHistory history) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE8EAED), 
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
                  color: history.status == 'taken' 
                      ? const Color(0xFF4CAF50).withOpacity(0.1) 
                      : const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  history.status == 'taken' ? Icons.check_circle : Icons.cancel,
                  color: history.status == 'taken' ? const Color(0xFF4CAF50) : const Color(0xFFFF6B6B), 
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
                          history.time, 
                          style: TextStyle(
                            color: Colors.grey[600], 
                            fontSize: 12, 
                            fontWeight: FontWeight.w500
                          )
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: history.status == 'taken' 
                                ? const Color(0xFF4CAF50).withOpacity(0.1)
                                : const Color(0xFFFF6B6B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: Text(
                            history.status == 'taken' ? 'Taken' : 'Missed', 
                            style: TextStyle(
                              color: history.status == 'taken' 
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF6B6B),
                              fontSize: 11, 
                              fontWeight: FontWeight.w600
                            )
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      history.medicationName, 
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
                'Dosage: ${history.dose}', 
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
                Icons.schedule, 
                size: 15, 
                color: Colors.grey[500]
              ),
              const SizedBox(width: 6),
              Text(
                history.formattedTakenAt, 
                style: TextStyle(
                  fontSize: 12, 
                  color: Colors.grey[600]
                )
              ),
            ],
          ),
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