import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Home.dart';
import 'doctor.dart';
import 'Caregiver.dart';
import 'Profile.dart';
import 'Medication/AddMed.dart';
import '../models/medication.dart';
import '../models/MedicalHistory.dart';

class PatientMedicationScreen extends StatefulWidget {
  const PatientMedicationScreen({Key? key}) : super(key: key);

  @override
  State<PatientMedicationScreen> createState() => _PatientMedicationScreenState();

  static const Color primary = Color(0xFFE91E63);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFE53935);
  static const Color bg = Color(0xFFFAFAFA);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const double p = 16.0, p2 = 8.0, p3 = 12.0, p4 = 20.0, p6 = 24.0;
}

class _PatientMedicationScreenState extends State<PatientMedicationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Medication> _medications = [];
  List<MedicationHistory> _medicationHistory = [];
  Set<String> _completedTodayIds = {};
  bool _isLoading = true;
  int _completedCount = 0;
  int _missedCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMedications();
    _loadMedicationHistory();
  }

  Future<void> _loadMedications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('medications')
          .where('patientId', isEqualTo: user.uid)
          .get();

      setState(() {
        _medications = snapshot.docs
            .map((doc) => Medication.fromFirestore(doc))
            .where((med) => med.isActive)
            .toList()
          ..sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) return 0;
            return b.createdAt!.compareTo(a.createdAt!);
          });
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading medications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMedicationHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('medication_history')
          .where('patientId', isEqualTo: user.uid)
          .get();

      int completed = 0;
      int missed = 0;
      List<MedicationHistory> history = [];
      Set<String> completedToday = {};

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      for (var doc in snapshot.docs) {
        try {
          final medHistory = MedicationHistory.fromFirestore(doc);
          history.add(medHistory);
          
          if (medHistory.status.toLowerCase() == 'taken') {
            completed++;
            // Check if this medication was completed today
            if (medHistory.takenAt.isAfter(todayStart) && medHistory.takenAt.isBefore(todayEnd)) {
              completedToday.add(medHistory.medicationId);
            }
          } else if (medHistory.status.toLowerCase() == 'missed') {
            missed++;
          }
        } catch (e) {
          print('Error parsing medication history document ${doc.id}: $e');
          continue;
        }
      }

      // Sort by takenAt date (newest first)
      history.sort((a, b) => b.takenAt.compareTo(a.takenAt));

      setState(() {
        _medicationHistory = history.take(20).toList();
        _completedCount = completed;
        _missedCount = missed;
        _completedTodayIds = completedToday;
      });
    } catch (e) {
      print('Error loading medication history: $e');
    }
  }

  Future<void> _completeMedication(Medication medication) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final history = MedicationHistory(
        id: '',
        patientId: user.uid,
        medicationId: medication.id,
        medicationName: medication.name,
        dose: medication.dose,
        time: medication.time,
        period: medication.period,
        frequency: medication.frequency,
        purpose: medication.purpose,
        instructions: medication.instructions,
        sideEffects: medication.sideEffects,
        prescribedBy: medication.prescribedBy,
        prescribedById: medication.prescribedById,
        doctorSpecialty: medication.doctorSpecialty,
        doctorHospital: medication.doctorHospital,
        status: 'Taken',
        takenAt: DateTime.now(),
        scheduledTime: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('medication_history').add(history.toMap());

      // Add to completed today set
      setState(() {
        _completedTodayIds.add(medication.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medication.name} marked as taken!'),
            backgroundColor: PatientMedicationScreen.success,
            duration: const Duration(seconds: 2),
          ),
        );
        await _loadMedicationHistory();
      }
    } catch (e) {
      print('Error completing medication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark medication as taken'),
            backgroundColor: PatientMedicationScreen.danger,
          ),
        );
      }
    }
  }

  List<Medication> get _activeMedications => _medications.where((m) => !_completedTodayIds.contains(m.id)).toList();
  int get _todayMedicationsCount => _activeMedications.length;
  int get _upcomingCount => _activeMedications.where((m) => m.period == 'Evening' || m.period == 'Night').length;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildBottomNav(BuildContext context, int activeIndex) {
    return Container(
      decoration: BoxDecoration(
        color: PatientMedicationScreen.card,
        border: const Border(top: BorderSide(color: PatientMedicationScreen.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: PatientMedicationScreen.p2),
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
      child: InkWell(
        onTap: active ? null : () {
          switch (index) {
            case 0: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientHomePage())); break;
            case 1: break;
            case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientCaregiverScreen())); break;
            case 3: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DoctorPage())); break;
            case 4: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProfileScreen())); break;
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: active ? PatientMedicationScreen.primary : PatientMedicationScreen.textMuted),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: active ? PatientMedicationScreen.primary : PatientMedicationScreen.textMuted, fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientMedicationScreen.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(PatientMedicationScreen.p4),
              decoration: BoxDecoration(
                color: PatientMedicationScreen.card,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientHomePage())),
                        child: Container(
                          padding: const EdgeInsets.all(PatientMedicationScreen.p2),
                          decoration: BoxDecoration(color: PatientMedicationScreen.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.arrow_back, color: PatientMedicationScreen.primary, size: 24),
                        ),
                      ),
                      const SizedBox(width: PatientMedicationScreen.p3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('My Medications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: PatientMedicationScreen.text)),
                            Text('${_medications.length} Active Prescriptions', style: const TextStyle(fontSize: 14, color: PatientMedicationScreen.textMuted)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.search, size: 24, color: PatientMedicationScreen.textMuted), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.refresh, size: 24, color: PatientMedicationScreen.textMuted), onPressed: () { _loadMedications(); _loadMedicationHistory(); }),
                    ],
                  ),
                  const SizedBox(height: PatientMedicationScreen.p6),
                  Row(
                    children: [
                      Expanded(child: _statCard(Icons.alarm, '$_todayMedicationsCount', 'Due Today', PatientMedicationScreen.primary)),
                      const SizedBox(width: PatientMedicationScreen.p3),
                      Expanded(child: _statCard(Icons.schedule, '$_upcomingCount', 'Upcoming', PatientMedicationScreen.warning)),
                      const SizedBox(width: PatientMedicationScreen.p3),
                      Expanded(child: _statCard(Icons.check_circle, '$_completedCount', 'Completed', PatientMedicationScreen.success)),
                    ],
                  ),
                  const SizedBox(height: PatientMedicationScreen.p6),
                  Container(
                    decoration: BoxDecoration(color: PatientMedicationScreen.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: PatientMedicationScreen.border)),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(color: PatientMedicationScreen.primary, borderRadius: BorderRadius.circular(14)),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: PatientMedicationScreen.textMuted,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      tabs: const [Tab(text: 'Today'), Tab(text: 'Schedule'), Tab(text: 'History')],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: PatientMedicationScreen.primary))
                  : TabBarView(controller: _tabController, children: [_todayTab(), _scheduleTab(), _historyTab()]),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMedicationScreen()));
          if (result == true || mounted) _loadMedications();
        },
        backgroundColor: PatientMedicationScreen.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Medication', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(PatientMedicationScreen.p3),
      decoration: BoxDecoration(
        color: PatientMedicationScreen.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientMedicationScreen.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 24, color: color)),
          const SizedBox(height: PatientMedicationScreen.p2),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: PatientMedicationScreen.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _todayTab() {
    final activeMeds = _activeMedications;
    
    if (activeMeds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 80, color: PatientMedicationScreen.textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _medications.isEmpty ? 'No medications yet' : 'All medications completed!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: PatientMedicationScreen.text)
            ),
            const SizedBox(height: 8),
            Text(
              _medications.isEmpty ? 'Add your first medication to get started' : 'Great job staying on track today!',
              style: const TextStyle(fontSize: 14, color: PatientMedicationScreen.textMuted)
            ),
          ],
        ),
      );
    }

    final nextMed = activeMeds.first;

    return ListView(
      padding: const EdgeInsets.all(PatientMedicationScreen.p4),
      children: [
        Container(
          padding: const EdgeInsets.all(PatientMedicationScreen.p),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [PatientMedicationScreen.primary.withOpacity(0.1), PatientMedicationScreen.primary.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PatientMedicationScreen.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(PatientMedicationScreen.p2), decoration: BoxDecoration(color: PatientMedicationScreen.card, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.alarm, color: PatientMedicationScreen.primary, size: 28)),
              const SizedBox(width: PatientMedicationScreen.p),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Next Dose', style: TextStyle(fontWeight: FontWeight.bold, color: PatientMedicationScreen.text)),
                    Text('${nextMed.name} ${nextMed.dose} - ${nextMed.time}', style: const TextStyle(color: PatientMedicationScreen.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: PatientMedicationScreen.primary),
            ],
          ),
        ),
        const SizedBox(height: PatientMedicationScreen.p6),
        const Text("Today's Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PatientMedicationScreen.text)),
        const SizedBox(height: PatientMedicationScreen.p3),
        ...activeMeds.map((medication) => Padding(padding: const EdgeInsets.only(bottom: PatientMedicationScreen.p2), child: _medCard(medication))),
      ],
    );
  }

  Widget _medCard(Medication medication) {
    Color periodColor;
    switch (medication.period) {
      case 'Morning': periodColor = PatientMedicationScreen.warning; break;
      case 'Afternoon': periodColor = Colors.orange; break;
      case 'Evening': periodColor = Colors.purple; break;
      case 'Night': periodColor = Colors.indigo; break;
      default: periodColor = PatientMedicationScreen.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: PatientMedicationScreen.p2),
      decoration: BoxDecoration(
        color: PatientMedicationScreen.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientMedicationScreen.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(PatientMedicationScreen.p),
            decoration: const BoxDecoration(color: PatientMedicationScreen.card, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(PatientMedicationScreen.p2), decoration: BoxDecoration(color: periodColor.withOpacity(0.1), borderRadius: const BorderRadius.all(Radius.circular(12))), child: Icon(Icons.medication, color: periodColor, size: 28)),
                const SizedBox(width: PatientMedicationScreen.p),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medication.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: PatientMedicationScreen.text)),
                      Text(medication.dose, style: const TextStyle(color: PatientMedicationScreen.textMuted)),
                    ],
                  ),
                ),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: periodColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(medication.period, style: TextStyle(color: periodColor, fontWeight: FontWeight.w600, fontSize: 11))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(PatientMedicationScreen.p),
            child: Column(
              children: [
                _detailRow(Icons.access_time, 'Time', medication.time, PatientMedicationScreen.primary),
                _detailRow(Icons.repeat, 'Frequency', medication.frequency, PatientMedicationScreen.warning),
                _detailRow(Icons.healing, 'Purpose', medication.purpose, PatientMedicationScreen.success),
                _detailRow(Icons.info_outline, 'Instructions', medication.instructions, Colors.orange),
                _detailRow(Icons.warning_amber_outlined, 'Side Effects', medication.sideEffects, PatientMedicationScreen.danger),
                _detailRow(Icons.local_hospital, 'Prescribed by', '${medication.prescribedBy} (${medication.doctorSpecialty})', Colors.purple),
                const SizedBox(height: PatientMedicationScreen.p),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder snoozed for 30 minutes'), duration: Duration(seconds: 2))),
                        icon: const Icon(Icons.snooze, size: 16),
                        label: const Text('Remind Later'),
                        style: OutlinedButton.styleFrom(foregroundColor: PatientMedicationScreen.textMuted, side: const BorderSide(color: PatientMedicationScreen.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(width: PatientMedicationScreen.p2),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _completeMedication(medication),
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: const Text('Complete', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: PatientMedicationScreen.success, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)),
          const SizedBox(width: PatientMedicationScreen.p2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: PatientMedicationScreen.textMuted)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PatientMedicationScreen.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleTab() {
    final activeMeds = _activeMedications;
    
    if (activeMeds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: PatientMedicationScreen.textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _medications.isEmpty ? 'No medications scheduled' : 'All medications completed!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: PatientMedicationScreen.text)
            ),
            const SizedBox(height: 8),
            Text(
              _medications.isEmpty ? 'Add medications to see your schedule' : 'Check back tomorrow for your next doses',
              style: const TextStyle(fontSize: 14, color: PatientMedicationScreen.textMuted)
            ),
          ],
        ),
      );
    }

    final morningMeds = activeMeds.where((m) => m.period == 'Morning').toList();
    final afternoonMeds = activeMeds.where((m) => m.period == 'Afternoon').toList();
    final eveningMeds = activeMeds.where((m) => m.period == 'Evening').toList();
    final nightMeds = activeMeds.where((m) => m.period == 'Night').toList();

    return ListView(
      padding: const EdgeInsets.all(PatientMedicationScreen.p4),
      children: [
        if (morningMeds.isNotEmpty) ...[_scheduleSection('Morning (6AM - 12PM)', Icons.wb_sunny_outlined, PatientMedicationScreen.warning, morningMeds), const SizedBox(height: PatientMedicationScreen.p4)],
        if (afternoonMeds.isNotEmpty) ...[_scheduleSection('Afternoon (12PM - 6PM)', Icons.wb_sunny, Colors.orange, afternoonMeds), const SizedBox(height: PatientMedicationScreen.p4)],
        if (eveningMeds.isNotEmpty) ...[_scheduleSection('Evening (6PM - 9PM)', Icons.wb_twilight, Colors.purple, eveningMeds), const SizedBox(height: PatientMedicationScreen.p4)],
        if (nightMeds.isNotEmpty) ...[_scheduleSection('Night (9PM - 12AM)', Icons.nightlight_outlined, Colors.indigo, nightMeds)],
      ],
    );
  }

  Widget _scheduleSection(String title, IconData icon, Color color, List<Medication> meds) {
    return Container(
      decoration: BoxDecoration(color: PatientMedicationScreen.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: PatientMedicationScreen.border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(PatientMedicationScreen.p), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))), child: Row(children: [Icon(icon, color: color, size: 22), const SizedBox(width: PatientMedicationScreen.p2), Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: PatientMedicationScreen.text))])),
          ...meds.map((m) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: PatientMedicationScreen.p, vertical: 4),
                leading: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.medication, color: color, size: 18)),
                title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(m.dose),
                trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: PatientMedicationScreen.border, borderRadius: BorderRadius.circular(8)), child: Text(m.time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              )),
        ],
      ),
    );
  }

  Widget _historyTab() {
    final totalCount = _completedCount + _missedCount;
    final adherenceRate = totalCount > 0 ? (_completedCount / totalCount * 100).toInt() : 0;

    return ListView(
      padding: const EdgeInsets.all(PatientMedicationScreen.p4),
      children: [
        Container(
          padding: const EdgeInsets.all(PatientMedicationScreen.p4),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [PatientMedicationScreen.success.withOpacity(0.15), PatientMedicationScreen.success.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16), border: Border.all(color: PatientMedicationScreen.success.withOpacity(0.2))),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Adherence Rate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PatientMedicationScreen.text)), Text('$adherenceRate%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: PatientMedicationScreen.success))]),
              const SizedBox(height: PatientMedicationScreen.p3),
              ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: totalCount > 0 ? _completedCount / totalCount : 0.0, minHeight: 10, backgroundColor: PatientMedicationScreen.border, valueColor: const AlwaysStoppedAnimation(PatientMedicationScreen.success))),
              const SizedBox(height: PatientMedicationScreen.p3),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_StatItem(label: 'Taken', value: '$_completedCount', color: PatientMedicationScreen.success), _StatItem(label: 'Missed', value: '$_missedCount', color: PatientMedicationScreen.danger), _StatItem(label: 'Total', value: '$totalCount', color: PatientMedicationScreen.primary)]),
            ],
          ),
        ),
        const SizedBox(height: PatientMedicationScreen.p6),
        const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PatientMedicationScreen.text)),
        const SizedBox(height: PatientMedicationScreen.p3),
        if (_medicationHistory.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(PatientMedicationScreen.p6), child: Column(children: [Icon(Icons.history, size: 60, color: PatientMedicationScreen.textMuted.withOpacity(0.5)), const SizedBox(height: 12), const Text('No medication history yet', style: TextStyle(fontSize: 16, color: PatientMedicationScreen.textMuted))])))
        else
          ..._medicationHistory.map((history) {
            final color = history.status.toLowerCase() == 'taken' ? PatientMedicationScreen.success : PatientMedicationScreen.danger;
            final icon = history.status.toLowerCase() == 'taken' ? Icons.check_circle : Icons.cancel;
            return _historyItem(history.formattedTakenAt, '${history.medicationName} ${history.dose}', history.status, color, icon);
          }).toList(),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: PatientMedicationScreen.textMuted)),
      ],
    );
  }
}

Widget _historyItem(String date, String med, String status, Color color, IconData icon) {
  return Container(
    margin: const EdgeInsets.only(bottom: PatientMedicationScreen.p2),
    padding: const EdgeInsets.all(PatientMedicationScreen.p),
    decoration: BoxDecoration(
      color: PatientMedicationScreen.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: PatientMedicationScreen.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        )
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: PatientMedicationScreen.p),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(med, style: const TextStyle(fontWeight: FontWeight.w600, color: PatientMedicationScreen.text)),
              Text(date, style: const TextStyle(fontSize: 12, color: PatientMedicationScreen.textMuted)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
        ),
      ],
    ),
  );
}