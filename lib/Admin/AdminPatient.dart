import 'package:flutter/material.dart';

import 'AdminHome.dart';
import 'AdminDoctor.dart';
import 'AdminCaregiver.dart';
import 'AdminProfile.dart';

// Placeholder for Add Patient screen
class AdminAddPatientScreen extends StatelessWidget {
  const AdminAddPatientScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Add New Patient Form Here')));
}

class AdminPatientsScreen extends StatefulWidget {
  const AdminPatientsScreen({Key? key}) : super(key: key);

  @override
  State<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends State<AdminPatientsScreen> {
  static const Color primary = Color(0xFFFF6B6B);
  static const Color muted = Colors.grey;
  static const Color cardShadow = Color(0x08000000);

  String searchQuery = '';
  String selectedStatus = 'All';

  final List<Map<String, String>> patients = const [
    {
      'name': 'Robert Anderson',
      'age': '68',
      'caregiver': 'Maria Santos',
      'conditions': 'Hypertension, Diabetes',
      'status': 'Active',
      'lastCheckIn': '2 hours ago',
      'email': 'robert.anderson@email.com',
      'phone': '+63 912 345 6789',
      'joined': 'Jan 2024',
      'adherence': '94%',
    },
    {
      'name': 'Elena Garcia',
      'age': '72',
      'caregiver': 'Juan Cruz',
      'conditions': 'Heart Disease, Arthritis',
      'status': 'Critical',
      'lastCheckIn': '6 hours ago',
      'email': 'elena.garcia@email.com',
      'phone': '+63 923 456 7890',
      'joined': 'Mar 2023',
      'adherence': '78%',
    },
    {
      'name': 'William Chen',
      'age': '55',
      'caregiver': 'Luzviminda Reyes',
      'conditions': 'COPD, Asthma',
      'status': 'Stable',
      'lastCheckIn': '1 day ago',
      'email': 'william.chen@email.com',
      'phone': '+63 934 567 8901',
      'joined': 'Jul 2024',
      'adherence': '89%',
    },
    {
      'name': 'Sophia Martinez',
      'age': '81',
      'caregiver': 'Pedro Garcia',
      'conditions': 'Dementia, Hypertension',
      'status': 'Active',
      'lastCheckIn': '30 mins ago',
      'email': 'sophia.martinez@email.com',
      'phone': '+63 945 678 9012',
      'joined': 'Nov 2022',
      'adherence': '96%',
    },
    {
      'name': 'James Wilson',
      'age': '64',
      'caregiver': 'Ana Lim',
      'conditions': 'Diabetes, Kidney Disease',
      'status': 'Critical',
      'lastCheckIn': '3 days ago',
      'email': 'james.wilson@email.com',
      'phone': '+63 956 789 0123',
      'joined': 'May 2023',
      'adherence': '65%',
    },
    {
      'name': 'Linda Tan',
      'age': '59',
      'caregiver': 'Carlos Tan',
      'conditions': 'Cancer, Pain Management',
      'status': 'Stable',
      'lastCheckIn': '12 hours ago',
      'email': 'linda.tan@email.com',
      'phone': '+63 967 890 1234',
      'joined': 'Sep 2025',
      'adherence': '82%',
    },
  ];

  late final List<String> statuses;

  @override
  void initState() {
    super.initState();
    final Set<String> stats = patients.map((p) => p['status']!).toSet();
    statuses = ['All', ...stats];
  }

  int get totalPatients => patients.length;
  int get activePatients => patients.where((p) => p['status'] == 'Active').length;
  int get criticalPatients => patients.where((p) => p['status'] == 'Critical').length;
  int get stablePatients => patients.where((p) => p['status'] == 'Stable').length;

  List<Map<String, String>> get filteredPatients {
    return patients.where((pt) {
      final matchesSearch = pt['name']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          pt['caregiver']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          pt['conditions']!.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesStatus = selectedStatus == 'All' || pt['status'] == selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  String getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length < 2) return '??';
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // === BOTTOM NAVIGATION (Patient tab active - index 3) ===
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -1))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home, 'Home', false, 0, context),
              _navItem(Icons.local_hospital, 'Doctor', false, 1, context),
              _navItem(Icons.supervisor_account, 'Caregiver', false, 2, context),
              _navItem(Icons.people_alt, 'Patient', true, 3, context),
              _navItem(Icons.person_outline, 'Profile', false, 4, context),
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
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomePage()));
                    break;
                  case 1:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDoctorsScreen()));
                    break;
                  case 2:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminCaregiversScreen()));
                    break;
                  case 4:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
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
      backgroundColor: const Color(0xFFF8F9FA),
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
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Manage Patients',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminAddPatientScreen()),
                            );
                          },
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('New Patient'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // === STATISTICS IN HEADER ===
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: cardShadow, blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem('Total', totalPatients.toString(), const Color(0xFF6EC1E4)),
                          _statItem('Active', activePatients.toString(), const Color(0xFF4CAF50)),
                          _statItem('Critical', criticalPatients.toString(), const Color(0xFFE57373)),
                          _statItem('Stable', stablePatients.toString(), const Color(0xFF42A5F5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('${filteredPatients.length} Patients', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                    const SizedBox(height: 20),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        prefixIcon: const Icon(Icons.monitor_heart),
                      ),
                      items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => selectedStatus = val!),
                    ),
                    const SizedBox(height: 16),

                    // Search Field
                    TextField(
                      onChanged: (val) => setState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search by name, caregiver or condition...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Patients List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredPatients.length,
                      itemBuilder: (context, index) {
                        final pt = filteredPatients[index];
                        return _patientCard(pt);
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // === HEADER ===
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: primary,
            child: Text(
              'AD',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Hello, Admin',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  'Patient Management',
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 30),
                onPressed: () {},
              ),
              const Positioned(
                right: 10,
                top: 10,
                child: CircleAvatar(radius: 5, backgroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === SMALL STAT ITEM IN HEADER ===
  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  // === PATIENT CARD ===
  Widget _patientCard(Map<String, String> pt) {
    final isCritical = pt['status'] == 'Critical';
    final statusColor = pt['status'] == 'Active'
        ? const Color(0xFF4CAF50)
        : isCritical
            ? const Color(0xFFE57373)
            : const Color(0xFF42A5F5);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: cardShadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: primary,
            child: Text(
              getInitials(pt['name']!),
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(pt['name']!, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pt['status']!,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Age ${pt['age']} • ${pt['conditions']}', style: TextStyle(fontSize: 15, color: muted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                _infoRow(Icons.person_outline, 'Caregiver: ${pt['caregiver']}'),
                _infoRow(Icons.access_time, 'Last check-in: ${pt['lastCheckIn']}'),
                _infoRow(Icons.calendar_today, 'Joined: ${pt['joined']}'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Adherence: ', style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                    Text(pt['adherence']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isCritical ? Colors.red : const Color(0xFF4CAF50))),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: muted),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: muted),
            onSelected: (value) {
              if (value == 'view') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View patient profile - coming soon')));
              } else if (value == 'edit') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit patient - coming soon')));
              } else if (value == 'delete') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete patient - coming soon')));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('View Profile')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: muted),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[700]), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}