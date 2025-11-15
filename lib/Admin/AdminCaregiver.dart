import 'package:flutter/material.dart';

import 'AdminHome.dart';
import 'AdminDoctor.dart';
import 'AdminPatient.dart';
import 'AdminProfile.dart';

// Placeholder for Add Caregiver screen
class AdminAddCaregiverScreen extends StatelessWidget {
  const AdminAddCaregiverScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Add New Caregiver Form Here')));
}

class AdminCaregiversScreen extends StatefulWidget {
  const AdminCaregiversScreen({Key? key}) : super(key: key);

  @override
  State<AdminCaregiversScreen> createState() => _AdminCaregiversScreenState();
}

class _AdminCaregiversScreenState extends State<AdminCaregiversScreen> {
  static const Color primary = Color(0xFFFF6B6B);
  static const Color muted = Colors.grey;
  static const Color cardShadow = Color(0x08000000);

  String searchQuery = '';
  String selectedStatus = 'All';

  final List<Map<String, String>> caregivers = const [
    {
      'name': 'Maria Santos',
      'patients': '3',
      'status': 'Active',
      'email': 'maria.santos@care.com',
      'phone': '+63 912 345 6789',
      'joined': 'Jan 2024',
      'rating': '4.9',
    },
    {
      'name': 'Juan Cruz',
      'patients': '5',
      'status': 'Active',
      'email': 'juan.cruz@care.com',
      'phone': '+63 923 456 7890',
      'joined': 'Mar 2023',
      'rating': '4.8',
    },
    {
      'name': 'Luzviminda Reyes',
      'patients': '2',
      'status': 'On Leave',
      'email': 'luz.reyes@care.com',
      'phone': '+63 934 567 8901',
      'joined': 'Jul 2024',
      'rating': '5.0',
    },
    {
      'name': 'Pedro Garcia',
      'patients': '4',
      'status': 'Active',
      'email': 'pedro.garcia@care.com',
      'phone': '+63 945 678 9012',
      'joined': 'Nov 2022',
      'rating': '4.7',
    },
    {
      'name': 'Ana Lim',
      'patients': '6',
      'status': 'Active',
      'email': 'ana.lim@care.com',
      'phone': '+63 956 789 0123',
      'joined': 'May 2023',
      'rating': '4.9',
    },
    {
      'name': 'Carlos Tan',
      'patients': '1',
      'status': 'Inactive',
      'email': 'carlos.tan@care.com',
      'phone': '+63 967 890 1234',
      'joined': 'Sep 2025',
      'rating': '4.6',
    },
  ];

  late final List<String> statuses;

  @override
  void initState() {
    super.initState();
    final Set<String> stats = caregivers.map((c) => c['status']!).toSet();
    statuses = ['All', ...stats];
  }

  int get totalCaregivers => caregivers.length;
  int get activeCaregivers => caregivers.where((c) => c['status'] == 'Active').length;
  int get onLeaveCaregivers => caregivers.where((c) => c['status'] == 'On Leave').length;
  int get inactiveCaregivers => caregivers.where((c) => c['status'] == 'Inactive').length;

  List<Map<String, String>> get filteredCaregivers {
    return caregivers.where((cg) {
      final matchesSearch = cg['name']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          cg['email']!.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesStatus = selectedStatus == 'All' || cg['status'] == selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  String getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length < 2) return '??';
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // === BOTTOM NAVIGATION (Caregiver tab active - index 2) ===
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
              _navItem(Icons.supervisor_account, 'Caregiver', true, 2, context),
              _navItem(Icons.people_alt, 'Patient', false, 3, context),
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
                  case 3:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPatientsScreen()));
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
                          'Manage Caregivers',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminAddCaregiverScreen()),
                            );
                          },
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('New Caregiver'),
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
                          _statItem('Total', totalCaregivers.toString(), const Color(0xFF6EC1E4)),
                          _statItem('Active', activeCaregivers.toString(), const Color(0xFF4CAF50)),
                          _statItem('On Leave', onLeaveCaregivers.toString(), const Color(0xFFF4A261)),
                          _statItem('Inactive', inactiveCaregivers.toString(), const Color(0xFFE57373)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('${filteredCaregivers.length} Caregivers', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                    const SizedBox(height: 20),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        prefixIcon: const Icon(Icons.verified_user),
                      ),
                      items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => selectedStatus = val!),
                    ),
                    const SizedBox(height: 16),

                    // Search Field
                    TextField(
                      onChanged: (val) => setState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Caregivers List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredCaregivers.length,
                      itemBuilder: (context, index) {
                        final cg = filteredCaregivers[index];
                        return _caregiverCard(cg);
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
                  'Caregiver Management',
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

  // === CAREGIVER CARD ===
  Widget _caregiverCard(Map<String, String> cg) {
    final isActive = cg['status'] == 'Active';
    final isOnLeave = cg['status'] == 'On Leave';
    final statusColor = isActive
        ? const Color(0xFF4CAF50)
        : isOnLeave
            ? const Color(0xFFF4A261)
            : const Color(0xFFE57373);

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
              getInitials(cg['name']!),
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
                    Text(cg['name']!, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cg['status']!,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Managing ${cg['patients']} patients', style: TextStyle(fontSize: 15, color: primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _infoRow(Icons.email_outlined, cg['email']!),
                _infoRow(Icons.phone_outlined, cg['phone']!),
                _infoRow(Icons.calendar_today, 'Joined ${cg['joined']}'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 22),
                    const SizedBox(width: 4),
                    Text('${cg['rating']} (89 reviews)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: muted),
            onSelected: (value) {
              if (value == 'edit') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit caregiver - coming soon')));
              } else if (value == 'delete') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete caregiver - coming soon')));
              }
            },
            itemBuilder: (context) => [
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