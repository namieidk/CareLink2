import 'dart:io';
import 'package:flutter/material.dart';
import 'Home.dart';
import 'caremed.dart';
import 'calendar.dart';
import 'patients/addpatient.dart';
import 'Profile.dart'; // Added Profile import

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
                        'My Patients',
                        style: TextStyle(
                          color: Colors.grey[900],
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.search, color: Colors.grey[700]),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.filter_list, color: Colors.grey[700]),
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

  Widget _buildDetailedPatientCard(Patient p) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: p.photoPath != null && p.photoPath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(p.photoPath!), fit: BoxFit.cover),
                      )
                    : Icon(Icons.person, size: 36, color: Colors.grey[400]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    Text(
                      '${p.age} • ${p.gender}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      p.condition,
                      style: const TextStyle(
                        color: Color(0xFF6C5CE7),
                        fontSize: 13,
                      ),
                    ),
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
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      );

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