import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'AdminHome.dart';
import 'AdminDoctor.dart';
import 'AdminPatient.dart';
import 'AdminProfile.dart';
import '../models/caregiver_profile.dart'; // Import model

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

  final List<String> statuses = ['All', 'Active', 'Inactive'];

  String getInitials(String firstName, String lastName) {
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  Stream<List<CaregiverProfile>> getCaregiversStream() {
    return FirebaseFirestore.instance
        .collection('caregiver_profile')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CaregiverProfile.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  List<CaregiverProfile> filterCaregivers(List<CaregiverProfile> caregivers) {
    return caregivers.where((cg) {
      final matchesSearch = '${cg.firstName} ${cg.lastName}'.toLowerCase().contains(searchQuery.toLowerCase()) ||
          cg.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
          cg.skills.any((s) => s.toLowerCase().contains(searchQuery.toLowerCase()));

      final isActive = cg.availableHoursPerWeek > 0;
      final matchesStatus = selectedStatus == 'All' ||
          (selectedStatus == 'Active' && isActive) ||
          (selectedStatus == 'Inactive' && !isActive);

      return matchesSearch && matchesStatus;
    }).toList();
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
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: const Text(
                'Manage Caregivers',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),

            Expanded(
              child: StreamBuilder<List<CaregiverProfile>>(
                stream: getCaregiversStream(),
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
                      child: Text('No caregivers found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    );
                  }

                  final allCaregivers = snapshot.data!;
                  final filteredCaregivers = filterCaregivers(allCaregivers);
                  final totalCaregivers = allCaregivers.length;
                  final activeCaregivers = allCaregivers.where((c) => c.availableHoursPerWeek > 0).length;

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
                              _statItem('Total', totalCaregivers.toString(), const Color(0xFF6EC1E4)),
                              _statItem('Active', activeCaregivers.toString(), const Color(0xFF4CAF50)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text('${filteredCaregivers.length} Caregivers', style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),

                        // Search Field
                        TextField(
                          onChanged: (val) => setState(() => searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search by name, email or skill...',
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
                            prefixIcon: const Icon(Icons.verified_user),
                          ),
                          items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setState(() => selectedStatus = val!),
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

  Widget _caregiverCard(CaregiverProfile cg) {
    final isActive = cg.availableHoursPerWeek > 0;
    final statusColor = isActive ? const Color(0xFF4CAF50) : const Color(0xFFE57373);

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
            backgroundImage: cg.profilePhotoUrl != null && cg.profilePhotoUrl!.isNotEmpty
                ? NetworkImage(cg.profilePhotoUrl!)
                : null,
            child: cg.profilePhotoUrl == null || cg.profilePhotoUrl!.isEmpty
                ? Text(
                    getInitials(cg.firstName, cg.lastName),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          title: Text(
            '${cg.firstName} ${cg.lastName}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${cg.experienceYears} yrs • ${cg.skills.isNotEmpty ? cg.skills.take(2).join(", ") : "No skills"}',
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
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            _infoRow(Icons.email_outlined, cg.email),
            _infoRow(Icons.phone_outlined, cg.phone),
            _infoRow(Icons.attach_money, '₱${cg.hourlyRate}/hr'),
            _infoRow(Icons.access_time, '${cg.availableHoursPerWeek} hrs/week'),
            _infoRow(Icons.school, cg.education),
            if (cg.skills.isNotEmpty)
              _infoRow(Icons.handyman, 'Skills: ${cg.skills.join(", ")}'),
            if (cg.certifications.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Certifications:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              ...cg.certifications.map((cert) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _infoRow(
                      Icons.verified,
                      '${cert.name}',
                      trailing: cert.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(cert.imageUrl, width: 24, height: 24, fit: BoxFit.cover),
                            )
                          : null,
                    ),
                  )),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Joined: ${_formatDate(cg.createdAt)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: muted, size: 20),
                  onSelected: (value) {
                    if (value == 'view') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View caregiver profile - coming soon')));
                    } else if (value == 'edit') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit caregiver - coming soon')));
                    } else if (value == 'delete') {
                      _confirmDelete(cg);
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

  Widget _infoRow(IconData icon, String text, {Widget? trailing}) {
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
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _confirmDelete(CaregiverProfile caregiver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Caregiver'),
        content: Text('Are you sure you want to delete ${caregiver.firstName} ${caregiver.lastName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('caregiver_profile')
                    .doc(caregiver.id)
                    .delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caregiver deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting caregiver: $e')),
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