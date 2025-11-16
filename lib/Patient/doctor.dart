import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Home.dart';
import 'Medication.dart';
import 'Caregiver.dart';
import 'Profile.dart';
import 'Doctor/schedDetail.dart';
import '../models/doctor_profile.dart';

class DoctorPage extends StatefulWidget {
  const DoctorPage({Key? key}) : super(key: key);
  @override
  State<DoctorPage> createState() => _DoctorPageState();
}

class _DoctorPageState extends State<DoctorPage> {
  // Pink theme for doctor
  static const Color primary = Color(0xFFE91E63);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color muted = Colors.grey;
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardShadow = Color(0x12000000);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Stream to get doctors from Firestore
  Stream<List<DoctorProfile>> _getDoctorsStream() {
    return _firestore
        .collection('doctor_profiles')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DoctorProfile.fromFirestore(doc))
          .toList();
    });
  }

  // Filter doctors based on search query
  List<DoctorProfile> _filterDoctors(List<DoctorProfile> doctors) {
    if (_searchQuery.isEmpty) return doctors;
    return doctors.where((doctor) {
      final name = doctor.name.toLowerCase();
      final specialty = doctor.specialty.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || specialty.contains(query);
    }).toList();
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
                _navItem(Icons.home_outlined, 'Home', active == 0, 0, context),
                _navItem(Icons.medical_services_outlined, 'Meds', active == 1, 1, context),
                _navItem(Icons.people_alt_outlined, 'Caregiver', active == 2, 2, context),
                _navItem(Icons.calendar_today, 'Schedule', active == 3, 3, context),
                _navItem(Icons.person_outline, 'Profile', active == 4, 4, context),
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
                      MaterialPageRoute(builder: (_) => const PatientHomePage()),
                    );
                    break;
                  case 1:
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => const PatientMedicationScreen()),
                    );
                    break;
                  case 2:
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => const PatientCaregiverScreen()),
                    );
                    break;
                  case 3:
                    // Already on doctor page, do nothing
                    break;
                  case 4:
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => const PatientProfileScreen()),
                    );
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
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            _header(),

            // SEARCH BAR
            _searchBar(),

            // DOCTORS LIST WITH STREAM
            Expanded(
              child: StreamBuilder<List<DoctorProfile>>(
                stream: _getDoctorsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _errorWidget('Error loading doctors: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _loadingWidget();
                  }

                  final allDoctors = snapshot.data ?? [];
                  final filteredDoctors = _filterDoctors(allDoctors);

                  return Column(
                    children: [
                      // DOCTORS COUNT
                      _doctorsCount(filteredDoctors.length, allDoctors.length),
                      
                      // DOCTORS LIST
                      Expanded(
                        child: _doctorsList(filteredDoctors),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(context, 3),
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
                  MaterialPageRoute(builder: (_) => const PatientHomePage()),
                );
              },
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find a Doctor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Browse and contact healthcare providers',
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
              hintText: 'Search by name or specialty...',
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

  // DOCTORS COUNT
  Widget _doctorsCount(int filtered, int total) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$filtered Doctor${filtered != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Text(
                'Total: $total',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      );

  // LOADING WIDGET
  Widget _loadingWidget() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
            SizedBox(height: 16),
            Text(
              'Loading doctors...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );

  // ERROR WIDGET
  Widget _errorWidget(String message) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {}); // Trigger rebuild
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
              ),
            ),
          ],
        ),
      );

  // DOCTORS LIST
  Widget _doctorsList(List<DoctorProfile> doctors) {
    if (doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined, size: 64, color: muted),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No doctors available' : 'No doctors found',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Doctors will appear here when available'
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
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        final doctor = doctors[index];
        return _doctorCard(doctor);
      },
    );
  }

  // DOCTOR CARD
  Widget _doctorCard(DoctorProfile doctor) {
    // Determine status color (you can add a status field to DoctorProfile if needed)
    final statusColor = success; // Default to available
    final status = 'Available';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile Image or Initials
                doctor.profileImageUrl != null && doctor.profileImageUrl!.isNotEmpty
                    ? CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(doctor.profileImageUrl!),
                        backgroundColor: primary.withOpacity(0.1),
                        onBackgroundImageError: (_, __) {},
                        child: doctor.profileImageUrl!.isEmpty
                            ? Text(
                                doctor.getInitials(),
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      )
                    : CircleAvatar(
                        radius: 24,
                        backgroundColor: primary.withOpacity(0.1),
                        child: Text(
                          doctor.getInitials(),
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
                        doctor.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${doctor.specialty} • ${doctor.experienceFormatted}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            doctor.patientSatisfaction > 0
                                ? doctor.satisfactionPercentage
                                : 'New',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                    status,
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
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: muted),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: Text(
                    doctor.hospital,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(flex: 1),
                Icon(Icons.language, size: 16, color: muted),
                const SizedBox(width: 6),
                Flexible(
                  flex: 3,
                  child: Text(
                    doctor.languages,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _viewDoctorDetails(doctor),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View Schedule'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _contactDoctor(doctor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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

  void _viewDoctorDetails(DoctorProfile doctor) {
    // Navigate to Schedule Detail page with doctor data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SchedDetail(doctor: doctor),
      ),
    );
  }

  void _contactDoctor(DoctorProfile doctor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Contact ${doctor.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.phone, color: Colors.white),
                ),
                title: const Text('Call'),
                subtitle: Text(doctor.phone),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling ${doctor.phone}...'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.email, color: Colors.white),
                ),
                title: const Text('Email'),
                subtitle: Text(doctor.email),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening email to ${doctor.email}...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.message, color: Colors.white),
                ),
                title: const Text('Send Message'),
                subtitle: const Text('Send SMS or in-app message'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening message to ${doctor.name}...'),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Doctors',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _filterOption('All Doctors', Icons.medical_services),
              _filterOption('High Rating', Icons.star),
              _filterOption('Most Experienced', Icons.workspace_premium),
              _filterOption('Recently Joined', Icons.new_releases),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: muted,
                        side: BorderSide(color: muted),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
      title: Text(
        title,
        style: const TextStyle(color: Colors.black87),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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