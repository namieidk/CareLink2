import 'package:flutter/material.dart';
import 'Medication.dart';
import 'Caregiver.dart';
import 'Appointment.dart';
import 'Profile.dart';

class PatientHomePage extends StatelessWidget {
  const PatientHomePage({Key? key}) : super(key: key);

  // === COLORS DEFINED TO FIX 'Undefined name' ERROR ===
  static const Color primary = Color(0xFFFF6B6B);
  static const Color muted = Colors.grey;

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
                      MaterialPageRoute(builder: (_) => const AppointmentPage()),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildProgressCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(Icons.access_time, "Today's Medications"),
                    const SizedBox(height: 16),
                    _medicationCard(
                      name: 'Lisinopril',
                      dose: '10 mg',
                      time: '09:00 AM',
                      status: 'Taken',
                      isTaken: true,
                    ),
                    const SizedBox(height: 12),
                    _medicationCard(
                      name: 'Metformin',
                      dose: '500 mg',
                      time: '09:00 AM, 09:00 PM',
                      status: 'Take Now',
                      isTaken: false,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(Icons.show_chart, 'Health Readings'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _healthMetric(
                          icon: Icons.favorite,
                          label: 'Blood\nPressure',
                          value: '120/80',
                          unit: 'mmHg',
                          color: const Color(0xFFFF9B9B),
                        ),
                        const SizedBox(width: 12),
                        _healthMetric(
                          icon: Icons.water_drop,
                          label: 'Blood\nSugar',
                          value: '95',
                          unit: 'mg/dL',
                          color: const Color(0xFF6EC1E4),
                        ),
                        const SizedBox(width: 12),
                        _healthMetric(
                          icon: Icons.monitor_heart,
                          label: 'Heart Rate',
                          value: '72',
                          unit: 'bpm',
                          color: const Color(0xFFD0A9F5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildAdherenceCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(Icons.medication, 'All Medications'),
                    const SizedBox(height: 16),
                    _medicationListItem(
                      name: 'Lisinopril',
                      dose: '10 mg',
                      purpose: 'Blood pressure control',
                      schedule: 'Once daily • 09:00 AM',
                    ),
                    const SizedBox(height: 12),
                    _medicationListItem(
                      name: 'Metformin',
                      dose: '500 mg',
                      purpose: 'Blood sugar management',
                      schedule: 'Twice daily • 09:00 AM, 09:00 PM',
                    ),
                    const SizedBox(height: 12),
                    _medicationListItem(
                      name: 'Atorvastatin',
                      dose: '20 mg',
                      purpose: 'Cholesterol management जै',
                      schedule: 'Once daily • 08:00 PM',
                    ),
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
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 0), // Home active
    );
  }

  // === HEADER ===
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: primary,
            child: Text(
              'JD',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Hello, John',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  'Tuesday, November 11, 2025',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
            children: const [
              Text("Today's Progress", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Spacer(),
              Chip(
                backgroundColor: Color(0xFF4CAF50),
                label: Text('33%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('1 of 3 doses taken', style: TextStyle(color: Colors.black54)),
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

  // === TODAY'S MED CARD ===
  Widget _medicationCard({
    required String name,
    required String dose,
    required String time,
    required String status,
    required bool isTaken,
  }) {
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
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$dose • $time', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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

  // === MED LIST ITEM ===
  Widget _medicationListItem({
    required String name,
    required String dose,
    required String purpose,
    required String schedule,
  }) {
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
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(dose, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(purpose, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(schedule, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  // === HEALTH METRIC BOX ===
  Widget _healthMetric({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  // === ADHERENCE CARD ===
  Widget _buildAdherenceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Taking Meds Regularly', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('87%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.87,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Excellent! Keep it up', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 14)),
        ],
      ),
    );
  }
}