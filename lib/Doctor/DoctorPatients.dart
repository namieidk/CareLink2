import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import other doctor screens
import 'DocHome.dart';
import 'DoctorSchedule.dart';
import 'DoctorProfile.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  // Blue theme for doctor
  static const Color primary = Color(0xFF4A90E2);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color secondary = Color(0xFF64B5F6);
  static const Color accent = Color(0xFF1976D2);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color muted = Colors.grey;
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardShadow = Color(0x12000000);

  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Sample patient data (in real app, this would come from Firestore)
  final List<Patient> _patients = [
    Patient(
      id: '1',
      name: 'John Smith',
      age: 65,
      condition: 'Hypertension',
      lastVisit: DateTime.now().subtract(const Duration(days: 5)),
      status: 'Stable',
      phone: '+1 (555) 123-4567',
    ),
    Patient(
      id: '2',
      name: 'Mary Johnson',
      age: 72,
      condition: 'Diabetes',
      lastVisit: DateTime.now().subtract(const Duration(days: 12)),
      status: 'Improving',
      phone: '+1 (555) 234-5678',
    ),
    Patient(
      id: '3',
      name: 'Robert Brown',
      age: 58,
      condition: 'Arthritis',
      lastVisit: DateTime.now().subtract(const Duration(days: 3)),
      status: 'Stable',
      phone: '+1 (555) 345-6789',
    ),
    Patient(
      id: '4',
      name: 'Sarah Davis',
      age: 81,
      condition: 'Heart Condition',
      lastVisit: DateTime.now().subtract(const Duration(days: 20)),
      status: 'Needs Attention',
      phone: '+1 (555) 456-7890',
    ),
    Patient(
      id: '5',
      name: 'Michael Wilson',
      age: 67,
      condition: 'Asthma',
      lastVisit: DateTime.now().subtract(const Duration(days: 7)),
      status: 'Stable',
      phone: '+1 (555) 567-8901',
    ),
  ];

  List<Patient> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    return _patients.where((patient) =>
      patient.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      patient.condition.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  // BOTTOM NAVIGATION
  Widget _bottomNav(BuildContext context, int active) => Container(
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
                _navItem(Icons.home, 'Home', active == 0, 0, context),
                _navItem(Icons.people_alt, 'Patient', active == 1, 1, context),
                _navItem(Icons.schedule, 'Schedule', active == 2, 2, context),
                _navItem(Icons.person_outline, 'Profile', active == 3, 3, context),
              ],
            ),
          ),
        ),
      );

  Widget _navItem(
      IconData icon, String label, bool active, int index, BuildContext ctx) {
    return Expanded(
      child: GestureDetector(
        onTap: active
            ? null
            : () {
                switch (index) {
                  case 0:
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => const DoctorHomePage()),
                    );
                    break;
                  case 1:
                    // Already on patients, do nothing
                    break;
                  case 2:
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => const DoctorScheduleScreen()),
                    );
                    break;
                  case 3:
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => const DoctorProfileScreen()),
                    );
                    break;
                }
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? primary : muted, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            _header(),

            // SEARCH BAR
            _searchBar(),

            // PATIENTS COUNT
            _patientsCount(),

            // PATIENTS LIST
            Expanded(
              child: _patientsList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(context, 1),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPatient,
        backgroundColor: primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  // HEADER
  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorHomePage()),
                );
              },
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Patients',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Manage your patient list',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.black87),
              onPressed: _showFilterOptions,
            ),
          ],
        ),
      );

  // SEARCH BAR
  Widget _searchBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: cardShadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search patients...',
              prefixIcon: const Icon(Icons.search, color: muted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: muted),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      );

  // PATIENTS COUNT
  Widget _patientsCount() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_filteredPatients.length} Patients',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              'Total: ${_patients.length}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );

  // PATIENTS LIST
  Widget _patientsList() {
    if (_filteredPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: muted),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No patients yet' : 'No patients found',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Add your first patient to get started'
                  : 'Try a different search term',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = _filteredPatients[index];
        return _patientCard(patient);
      },
    );
  }

  // PATIENT CARD
  Widget _patientCard(Patient patient) {
    Color statusColor;
    switch (patient.status.toLowerCase()) {
      case 'needs attention':
        statusColor = warning;
        break;
      case 'improving':
        statusColor = success;
        break;
      default:
        statusColor = info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.1),
                  child: Text(
                    _getInitials(patient.name),
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${patient.age} years • ${patient.condition}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    patient.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: muted),
                const SizedBox(width: 6),
                Text(
                  patient.phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 16, color: muted),
                const SizedBox(width: 6),
                Text(
                  'Last visit: ${DateFormat('MMM d, yyyy').format(patient.lastVisit)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _viewPatientDetails(patient),
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _contactPatient(patient),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                  ),
                  child: const Text(
                    'Contact',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // HELPER METHODS
  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length < 2) return name.substring(0, 2).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _addNewPatient() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Patient'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('This feature will allow you to add new patients to your care.'),
              SizedBox(height: 16),
              Text('In a full implementation, this would open a form to enter patient details.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add patient functionality coming soon!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _viewPatientDetails(Patient patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailScreen(patient: patient),
      ),
    );
  }

  void _contactPatient(Patient patient) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contact ${patient.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('Call Patient'),
                subtitle: Text(patient.phone),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling ${patient.phone}...'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Colors.blue),
                title: const Text('Send Message'),
                subtitle: const Text('Send SMS or in-app message'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening message to ${patient.name}...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.orange),
                title: const Text('Send Email'),
                subtitle: const Text('Send email communication'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening email for ${patient.name}...'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Patients',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _filterOption('All Patients', Icons.people),
              _filterOption('Recent Visits', Icons.calendar_today),
              _filterOption('Needs Attention', Icons.warning),
              _filterOption('Stable Condition', Icons.check_circle),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Filters applied'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filtered by: $title'),
            backgroundColor: primary,
          ),
        );
      },
    );
  }
}

// PATIENT MODEL
class Patient {
  final String id;
  final String name;
  final int age;
  final String condition;
  final DateTime lastVisit;
  final String status;
  final String phone;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.condition,
    required this.lastVisit,
    required this.status,
    required this.phone,
  });
}

// PATIENT DETAIL SCREEN (Placeholder)
class PatientDetailScreen extends StatelessWidget {
  final Patient patient;

  const PatientDetailScreen({Key? key, required this.patient}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patient.name),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF4A90E2).withOpacity(0.1),
                      radius: 40,
                      child: Text(
                        patient.name.split(' ').map((n) => n[0]).join(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${patient.age} years old',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Patient details screen would show comprehensive information including:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text('• Medical history'),
            const Text('• Treatment plans'),
            const Text('• Appointment history'),
            const Text('• Prescriptions'),
            const Text('• Lab results'),
          ],
        ),
      ),
    );
  }
}