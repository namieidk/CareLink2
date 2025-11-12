import 'package:flutter/material.dart';
import 'Home.dart';
import 'Appointment.dart';
import 'Caregiver.dart';
import 'Profile.dart';
import 'Medication/AddMed.dart'; // AddMed.dart

class PatientMedicationScreen extends StatefulWidget {
  const PatientMedicationScreen({Key? key}) : super(key: key);

  @override
  State<PatientMedicationScreen> createState() => _PatientMedicationScreenState();

  static const Color primary = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFE53935);
  static const Color bg = Colors.white;
  static const Color card = Colors.white;
  static const Color text = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const double p = 16.0, p2 = 8.0, p3 = 12.0, p4 = 20.0, p6 = 24.0;
}

class _PatientMedicationScreenState extends State<PatientMedicationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

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
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -1))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: PatientMedicationScreen.p2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home, 'Home', activeIndex == 0, 0, context),
              _navItem(Icons.medication, 'Meds', activeIndex == 1, 1, context),
              _navItem(Icons.local_hospital, 'Caregiver', activeIndex == 2, 2, context),
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
        onTap: active
            ? null
            : () {
                switch (index) {
                  case 0:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientHomePage()));
                    break;
                  case 1:
                    break;
                  case 2:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientCaregiverScreen()));
                    break;
                  case 3:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppointmentPage()));
                    break;
                  case 4:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProfileScreen()));
                    break;
                }
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: active ? PatientMedicationScreen.primary : PatientMedicationScreen.textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active ? PatientMedicationScreen.primary : PatientMedicationScreen.textMuted,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
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
      backgroundColor: PatientMedicationScreen.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(PatientMedicationScreen.p4),
              decoration: const BoxDecoration(
                color: PatientMedicationScreen.card,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientHomePage())),
                        child: Container(
                          padding: const EdgeInsets.all(PatientMedicationScreen.p2),
                          decoration: BoxDecoration(
                            color: PatientMedicationScreen.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back, color: PatientMedicationScreen.primary, size: 24),
                        ),
                      ),
                      const SizedBox(width: PatientMedicationScreen.p3),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Medications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: PatientMedicationScreen.text)),
                            Text('8 Active Prescriptions', style: TextStyle(fontSize: 14, color: PatientMedicationScreen.textMuted)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.search, size: 24, color: PatientMedicationScreen.textMuted), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.filter_list, size: 24, color: PatientMedicationScreen.textMuted), onPressed: () {}),
                    ],
                  ),
                  const SizedBox(height: PatientMedicationScreen.p6),
                  Row(
                    children: [
                      Expanded(child: _statCard(Icons.alarm, '3', 'Due Today', PatientMedicationScreen.primary)),
                      const SizedBox(width: PatientMedicationScreen.p3),
                      Expanded(child: _statCard(Icons.schedule, '2', 'Upcoming', PatientMedicationScreen.warning)),
                      const SizedBox(width: PatientMedicationScreen.p3),
                      Expanded(child: _statCard(Icons.check_circle, '12', 'Completed', PatientMedicationScreen.success)),
                    ],
                  ),
                  const SizedBox(height: PatientMedicationScreen.p6),
                  Container(
                    decoration: BoxDecoration(
                      color: PatientMedicationScreen.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PatientMedicationScreen.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: PatientMedicationScreen.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: PatientMedicationScreen.primary,
                      unselectedLabelColor: PatientMedicationScreen.textMuted,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Today'),
                        Tab(text: 'Schedule'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_todayTab(), _scheduleTab(), _historyTab()],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
          );
        },
        backgroundColor: PatientMedicationScreen.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Medication', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  // === REST OF YOUR ORIGINAL CODE (unchanged) ===
  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(PatientMedicationScreen.p3),
      decoration: BoxDecoration(
        color: PatientMedicationScreen.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientMedicationScreen.border),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 1))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: color),
          const SizedBox(height: PatientMedicationScreen.p2),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: PatientMedicationScreen.text)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: PatientMedicationScreen.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _todayTab() {
    return ListView(
      padding: const EdgeInsets.all(PatientMedicationScreen.p4),
      children: [
        Container(
          padding: const EdgeInsets.all(PatientMedicationScreen.p),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFE4E1), Color(0xFFFFC1CC)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PatientMedicationScreen.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(PatientMedicationScreen.p2),
                decoration: const BoxDecoration(color: PatientMedicationScreen.card, borderRadius: BorderRadius.all(Radius.circular(12))),
                child: const Icon(Icons.alarm, color: PatientMedicationScreen.primary, size: 28),
              ),
              const SizedBox(width: PatientMedicationScreen.p),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next Dose in 15 min', style: TextStyle(fontWeight: FontWeight.bold, color: PatientMedicationScreen.text)),
                    Text('Metformin 500mg - 2:00 PM', style: TextStyle(color: PatientMedicationScreen.textMuted)),
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
        _medCard(
          name: 'Metformin', dose: '500mg', time: '08:00 AM', freq: 'Twice daily', purpose: 'Diabetes',
          taken: true, instr: 'With breakfast', side: 'Nausea', color: PatientMedicationScreen.success, doctor: 'Dr. Martinez',
        ),
        const SizedBox(height: PatientMedicationScreen.p2),
        _medCard(
          name: 'Lisinopril', dose: '10mg', time: '12:00 PM', freq: 'Once daily', purpose: 'Blood pressure',
          taken: false, instr: 'With lunch', side: 'Dizziness', color: PatientMedicationScreen.primary, doctor: 'Dr. Martinez',
        ),
        const SizedBox(height: PatientMedicationScreen.p2),
        _medCard(
          name: 'Atorvastatin', dose: '20mg', time: '08:00 PM', freq: 'Once daily', purpose: 'Cholesterol',
          taken: false, instr: 'With dinner', side: 'Muscle pain', color: PatientMedicationScreen.warning, doctor: 'Dr. Santos',
        ),
      ],
    );
  }

  Widget _medCard({
    required String name,
    required String dose,
    required String time,
    required String freq,
    required String purpose,
    required bool taken,
    required String instr,
    required String side,
    required Color color,
    required String doctor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: PatientMedicationScreen.p2),
      decoration: BoxDecoration(
        color: PatientMedicationScreen.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientMedicationScreen.border),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 1))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(PatientMedicationScreen.p),
            decoration: BoxDecoration(
              color: taken ? PatientMedicationScreen.success.withOpacity(0.08) : PatientMedicationScreen.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(PatientMedicationScreen.p2),
                  decoration: const BoxDecoration(color: PatientMedicationScreen.card, borderRadius: BorderRadius.all(Radius.circular(12))),
                  child: Icon(Icons.medication, color: color, size: 28),
                ),
                const SizedBox(width: PatientMedicationScreen.p),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: PatientMedicationScreen.text)),
                      Text(dose, style: const TextStyle(color: PatientMedicationScreen.textMuted)),
                    ],
                  ),
                ),
                if (taken)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: PatientMedicationScreen.success, borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Taken', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(PatientMedicationScreen.p),
            child: Column(
              children: [
                _detailRow(Icons.access_time, 'Time', time, PatientMedicationScreen.primary),
                _detailRow(Icons.repeat, 'Frequency', freq, PatientMedicationScreen.warning),
                _detailRow(Icons.healing, 'Purpose', purpose, PatientMedicationScreen.success),
                _detailRow(Icons.info_outline, 'Instructions', instr, Colors.orange),
                _detailRow(Icons.warning_amber_outlined, 'Side Effects', side, PatientMedicationScreen.danger),
                _detailRow(Icons.local_hospital, 'Prescribed by', doctor, Colors.purple),
                if (!taken) ...[
                  const SizedBox(height: PatientMedicationScreen.p),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.snooze, size: 16),
                          label: const Text('Remind Later'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PatientMedicationScreen.textMuted,
                            side: const BorderSide(color: PatientMedicationScreen.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: PatientMedicationScreen.p2),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Mark as Taken'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PatientMedicationScreen.success,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
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
    return ListView(
      padding: const EdgeInsets.all(PatientMedicationScreen.p4),
      children: [
        _scheduleSection('Morning (6AM - 12PM)', Icons.wb_sunny_outlined, PatientMedicationScreen.warning, [
          {'name': 'Metformin', 'dose': '500mg', 'time': '08:00 AM'},
          {'name': 'Levothyroxine', 'dose': '50mcg', 'time': '07:00 AM'},
        ]),
        const SizedBox(height: PatientMedicationScreen.p4),
        _scheduleSection('Afternoon (12PM - 6PM)', Icons.wb_sunny, Colors.orange, [
          {'name': 'Lisinopril', 'dose': '10mg', 'time': '12:00 PM'},
          {'name': 'Vitamin D3', 'dose': '1000 IU', 'time': '02:00 PM'},
        ]),
        const SizedBox(height: PatientMedicationScreen.p4),
        _scheduleSection('Evening (6PM - 12AM)', Icons.nightlight_outlined, Colors.purple, [
          {'name': 'Atorvastatin', 'dose': '20mg', 'time': '08:00 PM'},
          {'name': 'Omeprazole', 'dose': '40mg', 'time': '09:00 PM'},
        ]),
      ],
    );
  }

  Widget _scheduleSection(String title, IconData icon, Color color, List<Map<String, String>> meds) {
    return Container(
      decoration: BoxDecoration(
        color: PatientMedicationScreen.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientMedicationScreen.border),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(PatientMedicationScreen.p),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: PatientMedicationScreen.p2),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: PatientMedicationScreen.text)),
              ],
            ),
          ),
          ...meds.map((m) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: PatientMedicationScreen.p, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.medication, color: color, size: 18),
                ),
                title: Text(m['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(m['dose']!),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: PatientMedicationScreen.border, borderRadius: BorderRadius.circular(8)),
                  child: Text(m['time']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _historyTab() {
    return ListView(
      padding: const EdgeInsets.all(PatientMedicationScreen.p4),
      children: [
        Container(
          padding: const EdgeInsets.all(PatientMedicationScreen.p4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PatientMedicationScreen.success.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Adherence Rate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PatientMedicationScreen.text)),
                  Text('94%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: PatientMedicationScreen.success)),
                ],
              ),
              const SizedBox(height: PatientMedicationScreen.p3),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  value: 0.94,
                  minHeight: 10,
                  backgroundColor: PatientMedicationScreen.border,
                  valueColor: AlwaysStoppedAnimation(PatientMedicationScreen.success),
                ),
              ),
              const SizedBox(height: PatientMedicationScreen.p3),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(label: 'Taken', value: '142', color: PatientMedicationScreen.success),
                  _StatItem(label: 'Missed', value: '9', color: PatientMedicationScreen.danger),
                  _StatItem(label: 'Total', value: '151', color: PatientMedicationScreen.primary),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: PatientMedicationScreen.p6),
        const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PatientMedicationScreen.text)),
        const SizedBox(height: PatientMedicationScreen.p3),
        _historyItem('Today, 08:00 AM', 'Metformin 500mg', 'Taken', PatientMedicationScreen.success, Icons.check_circle),
        _historyItem('Today, 07:00 AM', 'Levothyroxine 50mcg', 'Taken', PatientMedicationScreen.success, Icons.check_circle),
        _historyItem('Yesterday, 08:00 PM', 'Atorvastatin 20mg', 'Missed', PatientMedicationScreen.danger, Icons.cancel),
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
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 1))],
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