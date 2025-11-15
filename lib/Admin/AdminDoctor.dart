import 'package:flutter/material.dart';

import 'AdminHome.dart';
import 'AdminCaregiver.dart';
import 'AdminPatient.dart';
import 'AdminProfile.dart';
import 'DoctorAcc/AddDocAcc.dart'; // <-- Your actual Add Doctor page

class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({Key? key}) : super(key: key);

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen> {
  static const Color primary = Color(0xFFFF8BA0);
  static const Color muted = Colors.grey;
  static const Color cardShadow = Color(0x08000000);

  String searchQuery = '';
  String selectedSpecialty = 'All';
  Set<int> expandedCards = {};

  final List<Map<String, String>> doctors = const [
    {
      'name': 'Dr. Sarah Johnson',
      'specialty': 'Cardiologist',
      'hospital': 'City Hospital',
      'experience': '15 years',
      'email': 'sarah.johnson@hospital.com',
      'phone': '+1 234 567 890',
      'rating': '4.9',
    },
    {
      'name': 'Dr. Michael Chen',
      'specialty': 'Neurologist',
      'hospital': 'Central Medical Center',
      'experience': '12 years',
      'email': 'michael.chen@medical.com',
      'phone': '+1 345 678 901',
      'rating': '4.8',
    },
    {
      'name': 'Dr. Emily Rodriguez',
      'specialty': 'Pediatrician',
      'hospital': 'Children\'s Clinic',
      'experience': '10 years',
      'email': 'emily.rodriguez@clinic.com',
      'phone': '+1 456 789 012',
      'rating': '5.0',
    },
    {
      'name': 'Dr. David Lee',
      'specialty': 'Orthopedic Surgeon',
      'hospital': 'Ortho Care Center',
      'experience': '18 years',
      'email': 'david.lee@ortho.com',
      'phone': '+1 567 890 123',
      'rating': '4.7',
    },
    {
      'name': 'Dr. Sophia Martinez',
      'specialty': 'Dermatologist',
      'hospital': 'Skin Health Institute',
      'experience': '8 years',
      'email': 'sophia.martinez@skin.com',
      'phone': '+1 678 901 234',
      'rating': '4.9',
    },
    {
      'name': 'Dr. James Wilson',
      'specialty': 'General Practitioner',
      'hospital': 'Family Health Clinic',
      'experience': '20 years',
      'email': 'james.wilson@family.com',
      'phone': '+1 789 012 345',
      'rating': '4.8',
    },
  ];

  late final List<String> specialties;

  @override
  void initState() {
    super.initState();
    final Set<String> specs = doctors.map((d) => d['specialty']!).toSet();
    specialties = ['All', ...specs];
  }

  List<Map<String, String>> get filteredDoctors {
    return doctors.where((doc) {
      final matchesSearch = doc['name']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          doc['hospital']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          doc['specialty']!.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesSpecialty = selectedSpecialty == 'All' || doc['specialty'] == selectedSpecialty;

      return matchesSearch && matchesSpecialty;
    }).toList();
  }

  String getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length < 3) return '??';
    return '${parts[1][0]}${parts[2][0]}'.toUpperCase();
  }

  // === BOTTOM NAVIGATION (Doctor tab active - index 1) ===
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
              _navItem(Icons.local_hospital, 'Doctor', true, 1, context),
              _navItem(Icons.supervisor_account, 'Caregiver', false, 2, context),
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminHomePage()),
                    );
                    break;
                  case 2:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminCaregiversScreen()),
                    );
                    break;
                  case 3:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminPatientsScreen()),
                    );
                    break;
                  case 4:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${filteredDoctors.length} Doctors',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),

                    // Specialty Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedSpecialty,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: primary, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.medical_services, color: primary),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => selectedSpecialty = val!),
                    ),
                    const SizedBox(height: 16),

                    // Search Field
                    TextField(
                      onChanged: (val) => setState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search by name, hospital or specialty...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.search, color: primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: primary, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Doctors List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDoctors.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDoctors[index];
                        final isExpanded = expandedCards.contains(index);
                        return _doctorCard(doc, index, isExpanded);
                      },
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminAddDoctorScreen()), // Now goes to your real Add Doctor page
          );
        },
        backgroundColor: primary,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // === HEADER ===
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Manage Doctors',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 28, color: primary),
                  onPressed: () {
                    // Handle notification tap
                  },
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === DOCTOR CARD (COLLAPSIBLE) ===
  Widget _doctorCard(Map<String, String> doc, int index, bool isExpanded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Collapsed Header (Always Visible)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedCards.remove(index);
                } else {
                  expandedCards.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: primary,
                    child: Text(
                      getInitials(doc['name']!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc['name']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doc['specialty']!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              doc['rating']!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: primary,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Details (Conditionally Visible)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  const Divider(thickness: 1, height: 1),
                  const SizedBox(height: 16),
                  _detailRow(Icons.business, 'Hospital', doc['hospital']!),
                  _detailRow(Icons.work_history, 'Experience', doc['experience']!),
                  _detailRow(Icons.email_outlined, 'Email', doc['email']!),
                  _detailRow(Icons.phone_outlined, 'Phone', doc['phone']!),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit doctor - coming soon')),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primary,
                            side: const BorderSide(color: primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showDeleteConfirmation(context, doc['name']!);
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String doctorName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Doctor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Are you sure you want to delete $doctorName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$doctorName deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}