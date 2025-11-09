import 'package:flutter/material.dart';
import 'Home.dart';
import 'Appointment.dart';
import 'Caregiver.dart';

class PatientMedicationScreen extends StatefulWidget {
  const PatientMedicationScreen({Key? key}) : super(key: key);

  @override
  State<PatientMedicationScreen> createState() => _PatientMedicationScreenState();
}

class _PatientMedicationScreenState extends State<PatientMedicationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

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

  // Bottom Navigation Item
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required int index,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (isActive) return;
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PatientHomePage()),
              );
              break;
            case 1:
              break; // Already on Medication
            case 2:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PatientCaregiverScreen()),
              );
              break;
            case 3:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AppointmentPage()),
              );
              break;
            case 4:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const Placeholder()),
              );
              break;
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFFFF6B6B) : Colors.grey[400],
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? const Color(0xFFFF6B6B) : Colors.grey[400],
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header with Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF9B9B),
                    Color(0xFFFFB5B5),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Top Row: Back, Title, Icons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Row(
                      children: [
                        // Back Button → Home
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const PatientHomePage()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'My Medications',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '8 Active Prescriptions',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.search, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.filter_list, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                  ),

                  // Summary Cards
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.medication,
                            count: '3',
                            label: 'Due Today',
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.schedule,
                            count: '2',
                            label: 'Upcoming',
                            color: const Color(0xFFFFA726),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.check_circle,
                            count: '12',
                            label: 'Completed',
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: const Color(0xFFFF6B6B),
                      unselectedLabelColor: Colors.white,
                      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Today'),
                        Tab(text: 'Schedule'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTodayTab(),
                  _buildScheduleTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFFFF6B6B),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Medication',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home, label: 'Home', isActive: false, index: 0),
                _buildNavItem(icon: Icons.medication, label: 'Medication', isActive: true, index: 1),
                _buildNavItem(icon: Icons.local_hospital, label: 'Caregiver', isActive: false, index: 2),
                _buildNavItem(icon: Icons.calendar_month, label: 'Appointment', isActive: false, index: 3),
                _buildNavItem(icon: Icons.settings, label: 'Settings', isActive: false, index: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Summary Card
  Widget _buildSummaryCard({
    required IconData icon,
    required String count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Today Tab
  Widget _buildTodayTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Next Dose Alert
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFE0E0), Color(0xFFFFF0F0)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF6B6B), width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.alarm, color: Color(0xFFFF6B6B), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Next Dose in 15 minutes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD63031)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Metformin 500mg - 2:00 PM',
                      style: TextStyle(fontSize: 14, color: Color(0xFFD63031)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFFF6B6B)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Today's Schedule",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _buildMedicationCard(
          medicationName: 'Metformin',
          dosage: '500mg',
          time: '08:00 AM',
          frequency: 'Twice daily',
          purpose: 'Diabetes management',
          taken: true,
          instructions: 'Take with breakfast',
          sideEffects: 'May cause nausea',
          iconColor: const Color(0xFF4CAF50),
          doctorName: 'Dr. Martinez',
        ),
        const SizedBox(height: 12),
        _buildMedicationCard(
          medicationName: 'Lisinopril',
          dosage: '10mg',
          time: '12:00 PM',
          frequency: 'Once daily',
          purpose: 'Blood pressure control',
          taken: false,
          instructions: 'Take with lunch',
          sideEffects: 'Dizziness may occur',
          iconColor: const Color(0xFFFF6B6B),
          doctorName: 'Dr. Martinez',
        ),
        const SizedBox(height: 12),
        _buildMedicationCard(
          medicationName: 'Atorvastatin',
          dosage: '20mg',
          time: '08:00 PM',
          frequency: 'Once daily',
          purpose: 'Cholesterol management',
          taken: false,
          instructions: 'Take with dinner',
          sideEffects: 'Muscle pain possible',
          iconColor: const Color(0xFFFFA726),
          doctorName: 'Dr. Santos',
        ),
      ],
    );
  }

  // Schedule Tab
  Widget _buildScheduleTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildScheduleSection(
          title: 'Morning (6:00 AM - 12:00 PM)',
          icon: Icons.wb_sunny_outlined,
          color: const Color(0xFFFFA726),
          medications: [
            {'name': 'Metformin', 'dosage': '500mg', 'time': '08:00 AM'},
            {'name': 'Levothyroxine', 'dosage': '50mcg', 'time': '07:00 AM'},
          ],
        ),
        const SizedBox(height: 20),
        _buildScheduleSection(
          title: 'Afternoon (12:00 PM - 6:00 PM)',
          icon: Icons.wb_sunny,
          color: const Color(0xFFFF9800),
          medications: [
            {'name': 'Lisinopril', 'dosage': '10mg', 'time': '12:00 PM'},
            {'name': 'Vitamin D3', 'dosage': '1000 IU', 'time': '02:00 PM'},
          ],
        ),
        const SizedBox(height: 20),
        _buildScheduleSection(
          title: 'Evening (6:00 PM - 12:00 AM)',
          icon: Icons.nightlight_outlined,
          color: const Color(0xFF6C5CE7),
          medications: [
            {'name': 'Atorvastatin', 'dosage': '20mg', 'time': '08:00 PM'},
            {'name': 'Omeprazole', 'dosage': '40mg', 'time': '09:00 PM'},
            {'name': 'Aspirin', 'dosage': '81mg', 'time': '10:00 PM'},
          ],
        ),
      ],
    );
  }

  // History Tab
  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFD4F8E8), Color(0xFFB8F2D9)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Adherence Rate',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  Text(
                    '94%',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00B894)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  value: 0.94,
                  minHeight: 10,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B894)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Taken', '142', const Color(0xFF4CAF50)),
                  _buildStatItem('Missed', '9', const Color(0xFFFF6B6B)),
                  _buildStatItem('Total', '151', const Color(0xFF42A5F5)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _buildHistoryItem(
          date: 'Today, 08:00 AM',
          medication: 'Metformin 500mg',
          status: 'Taken',
          statusColor: const Color(0xFF4CAF50),
          icon: Icons.check_circle,
        ),
        _buildHistoryItem(
          date: 'Today, 07:00 AM',
          medication: 'Levothyroxine 50mcg',
          status: 'Taken',
          statusColor: const Color(0xFF4CAF50),
          icon: Icons.check_circle,
        ),
        _buildHistoryItem(
          date: 'Yesterday, 08:00 PM',
          medication: 'Atorvastatin 20mg',
          status: 'Missed',
          statusColor: const Color(0xFFFF6B6B),
          icon: Icons.cancel,
        ),
        _buildHistoryItem(
          date: 'Yesterday, 02:00 PM',
          medication: 'Vitamin D3 1000 IU',
          status: 'Taken',
          statusColor: const Color(0xFF4CAF50),
          icon: Icons.check_circle,
        ),
        _buildHistoryItem(
          date: 'Yesterday, 12:00 PM',
          medication: 'Lisinopril 10mg',
          status: 'Taken',
          statusColor: const Color(0xFF4CAF50),
          icon: Icons.check_circle,
        ),
      ],
    );
  }

  // Medication Card
  Widget _buildMedicationCard({
    required String medicationName,
    required String dosage,
    required String time,
    required String frequency,
    required String purpose,
    required bool taken,
    required String instructions,
    required String sideEffects,
    required Color iconColor,
    required String doctorName,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: taken ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.grey[50],
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.medication, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medicationName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                      const SizedBox(height: 4),
                      Text(dosage, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                if (taken)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('Taken', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(Icons.access_time, 'Time', time, const Color(0xFF42A5F5)),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.repeat, 'Frequency', frequency, const Color(0xFF9C27B0)),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.healing, 'Purpose', purpose, const Color(0xFF4CAF50)),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.info_outline, 'Instructions', instructions, const Color(0xFFFFA726)),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.warning_amber_outlined, 'Side Effects', sideEffects, const Color(0xFFFF6B6B)),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.local_hospital, 'Prescribed by', doctorName, const Color(0xFF6C5CE7)),
                if (!taken) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.snooze, size: 18),
                          label: const Text('Remind Later'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Mark as Taken'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // Detail Row
  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // Schedule Section
  Widget _buildScheduleSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, String>> medications,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: medications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final med = medications[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.medication, color: color, size: 20),
                ),
                title: Text(med['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(med['dosage']!, style: const TextStyle(fontSize: 13)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    med['time']!,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Stat Item
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // History Item
  Widget _buildHistoryItem({
    required String date,
    required String medication,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                const SizedBox(height: 4),
                Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}