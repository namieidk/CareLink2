import 'package:flutter/material.dart';
import 'Home.dart';
import 'patient.dart';
import 'calendar.dart';
import 'Profile.dart'; // Added Profile import

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFAFBFC),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 2),
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
                          onPressed: () {},
                          icon: Icon(Icons.add_circle_outline, color: Colors.grey[700], size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMedStat('12', 'Due Today'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMedStat('8', 'Completed'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMedStat('4', 'Pending'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Tabs
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFDFE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE8EAED),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTab('Today', true),
                  ),
                  Expanded(
                    child: _buildTab('Upcoming', false),
                  ),
                  Expanded(
                    child: _buildTab('History', false),
                  ),
                ],
              ),
            ),
            
            // Medication List by Patient
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Roberto Cruz
                  _buildPatientSection(
                    patientName: 'Roberto Cruz',
                    patientAge: 68,
                    patientCondition: 'Diabetes Type 2',
                    medications: [
                      {
                        'time': '08:00 AM',
                        'medication': 'Metformin 500mg',
                        'dosage': '1 tablet',
                        'instructions': 'Take with food',
                        'isPending': true,
                      },
                      {
                        'time': '02:00 PM',
                        'medication': 'Glipizide 5mg',
                        'dosage': '1 tablet',
                        'instructions': '30 min before meal',
                        'isPending': true,
                      },
                      {
                        'time': '08:00 PM',
                        'medication': 'Aspirin 81mg',
                        'dosage': '1 tablet',
                        'instructions': 'Take with water',
                        'isPending': false,
                      },
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Elena Torres
                  _buildPatientSection(
                    patientName: 'Elena Torres',
                    patientAge: 72,
                    patientCondition: 'Hypertension',
                    medications: [
                      {
                        'time': '08:00 AM',
                        'medication': 'Lisinopril 10mg',
                        'dosage': '1 tablet',
                        'instructions': 'Take in the morning',
                        'isPending': false,
                      },
                      {
                        'time': '06:00 PM',
                        'medication': 'Amlodipine 5mg',
                        'dosage': '1 tablet',
                        'instructions': 'Take with dinner',
                        'isPending': false,
                      },
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Miguel Santos
                  _buildPatientSection(
                    patientName: 'Miguel Santos',
                    patientAge: 65,
                    patientCondition: 'High Cholesterol',
                    medications: [
                      {
                        'time': '09:00 AM',
                        'medication': 'Atorvastatin 20mg',
                        'dosage': '1 tablet',
                        'instructions': 'Take with breakfast',
                        'isPending': true,
                      },
                      {
                        'time': '09:00 PM',
                        'medication': 'Omega-3 1000mg',
                        'dosage': '1 capsule',
                        'instructions': 'Take with food',
                        'isPending': false,
                      },
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Carmen Reyes
                  _buildPatientSection(
                    patientName: 'Carmen Reyes',
                    patientAge: 70,
                    patientCondition: 'Osteoporosis',
                    medications: [
                      {
                        'time': '08:30 AM',
                        'medication': 'Calcium 500mg',
                        'dosage': '1 tablet',
                        'instructions': 'Take with water',
                        'isPending': false,
                      },
                      {
                        'time': '08:00 PM',
                        'medication': 'Vitamin D 2000 IU',
                        'dosage': '1 capsule',
                        'instructions': 'Take with food',
                        'isPending': true,
                      },
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 2),
    );
  }

  Widget _buildMedStat(String count, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8EAED),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
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
    required List<Map<String, dynamic>> medications,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8EAED),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 28,
                    color: Colors.grey[500],
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
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$patientAge years • $patientCondition',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
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
                    '${medications.length} meds',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Medications List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: medications.asMap().entries.map((entry) {
                final index = entry.key;
                final med = entry.value;
                return Column(
                  children: [
                    if (index > 0) const SizedBox(height: 12),
                    _buildMedicationItem(
                      time: med['time'],
                      medication: med['medication'],
                      dosage: med['dosage'],
                      instructions: med['instructions'],
                      isPending: med['isPending'],
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
    required bool isPending,
    required String instructions,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending ? const Color(0xFFDFE1E6) : const Color(0xFFE8EAED),
          width: 1,
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
                  size: 24,
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
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (isPending)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F1F3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Pending',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Icon(Icons.check_circle, color: const Color(0xFF4CAF50), size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      medication,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[900],
                        fontWeight: FontWeight.w600,
                      ),
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
              Icon(Icons.info_outline, size: 15, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                'Dosage: $dosage',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.description_outlined, size: 15, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  instructions,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
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
                      side: BorderSide(color: const Color(0xFFE8EAED)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  // === BOTTOM NAVIGATION (Copied from Home) ===
  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFC),
        border: Border(
          top: BorderSide(
            color: Color(0xFFE8EAED),
            width: 1,
          ),
        ),
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

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CaregiverHomeScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PatientsScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MedicationScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CalendarScreen()),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? Color(0xFF6C5CE7) : Colors.grey[400],
                size: 26,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? Color(0xFF6C5CE7) : Colors.grey[400],
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