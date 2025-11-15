import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'AdminHome.dart';
import 'AdminDoctor.dart';
import 'AdminCaregiver.dart';
import 'AdminProfile.dart';
import '../models/patient_profile.dart'; // Import model

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

  final List<String> statuses = ['All', 'Active'];

  String getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length < 2) return name.isNotEmpty ? name[0].toUpperCase() : '?';
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Stream<List<PatientProfile>> getPatientsStream() {
    return FirebaseFirestore.instance
        .collection('patient_profiles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PatientProfile.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  List<PatientProfile> filterPatients(List<PatientProfile> patients) {
    return patients.where((pt) {
      final matchesSearch = pt.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          pt.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
          pt.conditions.any((c) => c.toLowerCase().contains(searchQuery.toLowerCase()));

      final matchesStatus = selectedStatus == 'All' || selectedStatus == 'Active';

      return matchesSearch && matchesStatus;
    }).toList();
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
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: const Text(
                'Manage Patients',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),

            Expanded(
              child: StreamBuilder<List<PatientProfile>>(
                stream: getPatientsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No patients found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    );
                  }

                  final allPatients = snapshot.data!;
                  final filteredPatients = filterPatients(allPatients);
                  final totalPatients = allPatients.length;
                  final activePatients = allPatients.length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // === STATISTICS CARDS ===
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text('${filteredPatients.length} Patients', style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),

                        // Search Field
                        TextField(
                          onChanged: (val) => setState(() => searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search by name, email or condition...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Status Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            prefixIcon: const Icon(Icons.monitor_heart),
                          ),
                          items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setState(() => selectedStatus = val!),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _patientCard(PatientProfile pt) {
    const statusColor = Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: primary,
            backgroundImage: pt.profilePhotoUrl != null && pt.profilePhotoUrl!.isNotEmpty
                ? NetworkImage(pt.profilePhotoUrl!)
                : null,
            child: pt.profilePhotoUrl == null || pt.profilePhotoUrl!.isEmpty
                ? Text(
                    getInitials(pt.fullName),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          title: Text(
            pt.fullName,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Age ${pt.age} • ${pt.conditions.isNotEmpty ? pt.conditions.join(", ") : "No conditions"}',
            style: const TextStyle(fontSize: 13, color: muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Active',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            _infoRow(Icons.bloodtype, 'Blood Type: ${pt.bloodType}'),
            _infoRow(Icons.email_outlined, pt.email),
            _infoRow(Icons.phone_outlined, pt.phone),
            _infoRow(Icons.location_on_outlined, pt.address),
            if (pt.allergies.isNotEmpty)
              _infoRow(Icons.warning_amber_outlined, 'Allergies: ${pt.allergies.join(", ")}'),
            if (pt.emergencyContacts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Emergency Contacts:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              ...pt.emergencyContacts.map((contact) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _infoRow(
                      Icons.contact_emergency,
                      '${contact.name} (${contact.relation}) - ${contact.phone}',
                    ),
                  )),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Joined: ${_formatDate(pt.createdAt)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: muted, size: 20),
                  onSelected: (value) {
                    if (value == 'view') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View patient profile - coming soon')));
                    } else if (value == 'edit') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit patient - coming soon')));
                    } else if (value == 'delete') {
                      _confirmDelete(pt);
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
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _confirmDelete(PatientProfile patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Are you sure you want to delete ${patient.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('patient_profiles')
                    .doc(patient.id)
                    .delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Patient deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting patient: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}