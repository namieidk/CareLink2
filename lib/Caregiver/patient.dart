import 'dart:io';
import 'package:flutter/material.dart';
import 'Home.dart';
import 'caremed.dart';
import 'calendar.dart';
import 'patients/addpatient.dart';

/// Patient model
class Patient {
  final String name;
  final int age;
  final String condition;
  final List<String> medications;
  final String nextMedication;
  final String bloodPressure;
  final String glucose;
  final Color statusColor;
  final String? photoPath;
  final String gender;
  final String address;
  final String email;
  final String phoneNumber;

  Patient({
    required this.name,
    required this.age,
    required this.condition,
    required this.medications,
    required this.nextMedication,
    required this.bloodPressure,
    required this.glucose,
    required this.statusColor,
    this.photoPath,
    required this.gender,
    required this.address,
    required this.email,
    required this.phoneNumber,
    
  });
}

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({Key? key}) : super(key: key);

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  List<Patient> patients = [
    Patient(
      name: 'Roberto Cruz',
      age: 68,
      condition: 'Diabetes Type 2',
      medications: ['Metformin 500mg', 'Glipizide 5mg', 'Aspirin 81mg'],
      nextMedication: '08:00 AM',
      bloodPressure: '128/82',
      glucose: '110 mg/dL',
      statusColor: const Color(0xFF4CAF50),
      gender: 'Male',
      address: '123 Rizal St, Manila',
      email: 'roberto.cruz@email.com',
      phoneNumber: '+63 912 345 6789',
      
    ),
    Patient(
      name: 'Elena Torres',
      age: 72,
      condition: 'Hypertension',
      medications: ['Lisinopril 10mg', 'Amlodipine 5mg'],
      nextMedication: '12:00 PM',
      bloodPressure: '135/85',
      glucose: '95 mg/dL',
      statusColor: const Color(0xFF4CAF50),
      gender: 'Female',
      address: '456 Bonifacio Ave, Quezon City',
      email: 'elena.torres@email.com',
      phoneNumber: '+63 917 234 5678',
      
    ),
  ];

  void _addPatient(Patient p) => setState(() => patients.add(p));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF8B7FE8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Text(
                        'My Patients',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPatientStat('${patients.length}', 'Total'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPatientStat(
                          '${patients.where((p) => p.statusColor == const Color(0xFF4CAF50)).length}',
                          'Active',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildPatientStat('1', 'Alerts')),
                    ],
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: patients.length,
                itemBuilder: (c, i) => Column(
                  children: [
                    _buildDetailedPatientCard(patients[i]),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newPatient = await Navigator.of(context).push<Patient>(
            MaterialPageRoute(builder: (_) => const AddPatientScreen()),
          );
          if (newPatient != null) _addPatient(newPatient);
        },
        backgroundColor: const Color(0xFF6C5CE7),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Patient',
      ),

      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Widget _buildPatientStat(String count, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(count,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDetailedPatientCard(Patient p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: p.photoPath != null && p.photoPath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(p.photoPath!), fit: BoxFit.cover),
                      )
                    : const Icon(Icons.person, size: 36, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('${p.age} • ${p.gender}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(p.condition,
                        style: const TextStyle(color: Color(0xFF6C5CE7), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.email, p.email),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home, 'Home', currentIndex == 0, 0),
            _buildNavItem(context, Icons.people, 'Patients', currentIndex == 1, 1),
            _buildNavItem(context, Icons.medication, 'Medications', currentIndex == 2, 2),
            _buildNavItem(context, Icons.calendar_month, 'Calendar', currentIndex == 3, 3),
            _buildNavItem(context, Icons.settings, 'Settings', currentIndex == 4, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, bool isActive, int index) {
    return InkWell(
      onTap: () {
        if (index == 0) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const CaregiverHomeScreen()));
        } else if (index == 1) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const PatientsScreen()));
        } else if (index == 2) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const MedicationScreen()));
        } else if (index == 3) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive ? const Color(0xFF6C5CE7) : Colors.grey[400], size: 26),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF6C5CE7) : Colors.grey[400],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
