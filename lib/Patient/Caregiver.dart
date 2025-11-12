import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// CORRECT RELATIVE PATHS
import 'Home.dart';
import 'Medication.dart';
import 'Appointment.dart';
import 'Profile.dart';

// CORRECT MODEL PATH
import '../../models/caregiver_profile.dart';

class PatientCaregiverScreen extends StatefulWidget {
  const PatientCaregiverScreen({super.key}); // super.key

  @override
  State<PatientCaregiverScreen> createState() => _PatientCaregiverScreenState();
}

class _PatientCaregiverScreenState extends State<PatientCaregiverScreen> {
  final String _selectedLocation = 'All Locations'; // final
  final TextEditingController _searchController = TextEditingController();

  Stream<List<CaregiverProfile>>? _caregiversStream;
  List<CaregiverProfile> _allCaregivers = [];

  @override
  void initState() {
    super.initState();
    _caregiversStream = FirebaseFirestore.instance
        .collection('caregiver_profile')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CaregiverProfile.fromMap(doc.data(), doc.id))
            .toList());

    _searchController.addListener(() => setState(() {}));
  }

  List<CaregiverProfile> get _filteredCaregivers {
    if (_allCaregivers.isEmpty) return [];
    return _allCaregivers.where((c) {
      final fullName = '${c.firstName} ${c.lastName}'.toLowerCase();
      final search = _searchController.text.toLowerCase();
      return search.isEmpty ||
          fullName.contains(search) ||
          c.skills.any((s) => s.toLowerCase().contains(search)) ||
          c.bio.toLowerCase().contains(search);
    }).toList();
  }

  // Colors
  static const Color primary = Color(0xFFFF6B6B);
  static const Color muted = Colors.grey;

  // Bottom Nav
  Widget _buildBottomNav(BuildContext context, int activeIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -1))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _navItem(Icons.home, 'Home', activeIndex == 0, 0, context),
              _navItem(Icons.medication, 'Meds', activeIndex == 1, 1, context),
              _navItem(Icons.local_hospital, 'Caregiver', activeIndex == 2, 2, context),
              _navItem(Icons.calendar_today, 'Schedule', activeIndex == 3, 3, context),
              _navItem(Icons.person_outline, 'Profile', activeIndex == 4, 4, context),
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
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientHomePage()));
                    break;
                  case 1:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientMedicationScreen()));
                    break;
                  case 2:
                    break;
                  case 3:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppointmentPage()));
                    break;
                  case 4:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientProfileScreen()));
                    break;
                }
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? primary : muted, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Find a Caregiver', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, skill, or bio…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // List
            Expanded(
              child: StreamBuilder<List<CaregiverProfile>>(
                stream: _caregiversStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading caregivers'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  _allCaregivers = snapshot.data!;
                  final filtered = _filteredCaregivers;

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No caregivers found'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _caregiverCard(filtered[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 2),
    );
  }

  // Card
  Widget _caregiverCard(CaregiverProfile c) {
    final name = '${c.firstName} ${c.lastName}';
    final initials = c.firstName.isNotEmpty && c.lastName.isNotEmpty
        ? c.firstName[0] + c.lastName[0]
        : 'CG';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: c.profilePhotoUrl != null ? NetworkImage(c.profilePhotoUrl!) : null,
              backgroundColor: c.profilePhotoUrl == null ? primary.withOpacity(0.2) : null,
              child: c.profilePhotoUrl == null
                  ? Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, color: primary))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Text(
                    c.skills.isNotEmpty ? c.skills.take(2).join(', ') : 'Caregiver',
                    style: const TextStyle(color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const Text('4.8'),
                      const SizedBox(width: 4),
                      Text('(${c.experienceYears}+ yrs exp)'),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showCaregiverDetails(c),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Sheet
  void _showCaregiverDetails(CaregiverProfile c) {
    final name = '${c.firstName} ${c.lastName}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, color: Colors.grey[300])),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(c.bio, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              _infoRow(Icons.phone, c.phone),
              _infoRow(Icons.email, c.email),
              _infoRow(Icons.attach_money, '\$${c.hourlyRate}/hr'),
              _infoRow(Icons.access_time, '${c.availableHoursPerWeek} hrs/week'),
              _infoRow(Icons.language, c.languages.join(', ')),
              const SizedBox(height: 12),
              const Text('Skills', style: TextStyle(fontWeight: FontWeight.w600)),
              Wrap(
                spacing: 8,
                children: c.skills.map((s) => Chip(label: Text(s), backgroundColor: primary.withOpacity(0.1))).toList(),
              ),
              if (c.certifications.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Certifications', style: TextStyle(fontWeight: FontWeight.w600)),
                ...c.certifications.map((cert) => _infoRow(Icons.verified, cert.name, color: Colors.green)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Book Caregiver', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}