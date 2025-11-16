import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Import other doctor screens
import 'DocHome.dart';
import 'DoctorSchedule.dart';
import 'DoctorProfile.dart';
import '../models/patient_profile.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  // Blue theme for doctor
  static const Color primary = Color(0xFF4A90E2);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color muted = Colors.grey;
  static const Color background = Color(0xFFF8F9FA);

  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // List to store patient profiles from Firestore
  List<PatientProfile> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  // Load patients from Firestore
  Future<void> _loadPatients() async {
    try {
      print('🔄 Loading patients from Firestore...');
      
      final QuerySnapshot snapshot = await _firestore
          .collection('patient_profiles')
          .orderBy('createdAt', descending: true)
          .get();

      print('📄 Found ${snapshot.docs.length} documents in patient_profiles');

      List<PatientProfile> loadedPatients = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('👤 Processing patient: ${data['fullName']}');
          print('📸 Photo URL: ${data['profilePhotoUrl'] ?? 'No photo'}');
          
          final patient = PatientProfile.fromMap(data, doc.id);
          loadedPatients.add(patient);
          
        } catch (e) {
          print('❌ Error parsing patient ${doc.id}: $e');
        }
      }

      setState(() {
        _patients = loadedPatients;
        _isLoading = false;
      });

      print('✅ Successfully loaded ${_patients.length} patients');

    } catch (e) {
      print('❌ Error loading patients: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading patients: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<PatientProfile> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    return _patients.where((patient) =>
      patient.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      patient.conditions.any((condition) => 
        condition.toLowerCase().contains(_searchQuery.toLowerCase())
      )
    ).toList();
  }

  // Get status based on patient data
  String _getPatientStatus(PatientProfile patient) {
    if (patient.conditions.any((condition) => 
        condition.toLowerCase().contains('critical') || 
        condition.toLowerCase().contains('emergency'))) {
      return 'Needs Attention';
    } else if (patient.conditions.isEmpty) {
      return 'Stable';
    } else {
      return 'Under Observation';
    }
  }

  // Get last visit date
  DateTime _getLastVisitDate(PatientProfile patient) {
    return patient.createdAt;
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
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: _refreshPatients,
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
                color: Colors.black12,
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primary),
        ),
      );
    }

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
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshPatients,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                ),
                child: const Text(
                  'Refresh',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPatients,
      backgroundColor: Colors.white,
      color: primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = _filteredPatients[index];
          return _patientCard(patient);
        },
      ),
    );
  }

  // PATIENT CARD
  Widget _patientCard(PatientProfile patient) {
    final String status = _getPatientStatus(patient);
    final DateTime lastVisit = _getLastVisitDate(patient);
    
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'needs attention':
        statusColor = warning;
        break;
      case 'under observation':
        statusColor = info;
        break;
      case 'stable':
        statusColor = success;
        break;
      default:
        statusColor = info;
    }

    String primaryCondition = patient.conditions.isNotEmpty 
        ? patient.conditions.first 
        : 'No conditions listed';

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
                // Profile Photo with better error handling
                _buildPatientAvatar(patient, 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${patient.age} years • $primaryCondition',
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
                Icon(Icons.phone, size: 16, color: muted),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: Text(
                    patient.phone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(flex: 1),
                Icon(Icons.calendar_today, size: 16, color: muted),
                const SizedBox(width: 6),
                Flexible(
                  flex: 3,
                  child: Text(
                    'Last: ${DateFormat('MMM d').format(lastVisit)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (patient.allergies.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning, size: 16, color: warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Allergies: ${patient.allergies.join(', ')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: warning,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _viewPatientDetails(patient),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _contactPatient(patient),
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

  // PATIENT AVATAR WIDGET - IMPROVED VERSION
  Widget _buildPatientAvatar(PatientProfile patient, double size) {
    final hasValidPhoto = patient.profilePhotoUrl != null && 
                         patient.profilePhotoUrl!.isNotEmpty &&
                         patient.profilePhotoUrl!.startsWith('http');
    
    print('🖼️ Building avatar for ${patient.fullName}');
    print('   Photo URL: ${patient.profilePhotoUrl}');
    print('   Has valid photo: $hasValidPhoto');

    if (hasValidPhoto) {
      return CachedNetworkImage(
        imageUrl: patient.profilePhotoUrl!,
        imageBuilder: (context, imageProvider) {
          print('✅ Successfully loaded image for ${patient.fullName}');
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
        placeholder: (context, url) {
          print('⏳ Loading image for ${patient.fullName}...');
          return _buildPlaceholderAvatar(patient, size);
        },
        errorWidget: (context, url, error) {
          print('❌ Error loading image for ${patient.fullName}: $error');
          return _buildPlaceholderAvatar(patient, size);
        },
      );
    } else {
      print('ℹ️ Using placeholder for ${patient.fullName}');
      return _buildPlaceholderAvatar(patient, size);
    }
  }

  Widget _buildPlaceholderAvatar(PatientProfile patient, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primary.withOpacity(0.1),
      ),
      child: Center(
        child: Text(
          _getInitials(patient.fullName),
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }

  // HELPER METHODS
  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length < 2) {
      return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _refreshPatients() async {
    setState(() {
      _isLoading = true;
    });
    await _loadPatients();
  }

  void _addNewPatient() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Add New Patient',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: muted),
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _viewPatientDetails(PatientProfile patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailScreen(patient: patient),
      ),
    );
  }

  void _contactPatient(PatientProfile patient) {
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
              Text(
                'Contact ${patient.fullName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
                      content: Text('Opening message to ${patient.fullName}...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.orange),
                title: const Text('Send Email'),
                subtitle: Text(patient.email),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening email for ${patient.fullName}...'),
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
                'Filter Patients',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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

// PATIENT DETAIL SCREEN
class PatientDetailScreen extends StatelessWidget {
  final PatientProfile patient;

  const PatientDetailScreen({Key? key, required this.patient}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          patient.fullName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // PATIENT PROFILE CARD
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPatientDetailAvatar(patient, 80),
                    const SizedBox(height: 16),
                    Text(
                      patient.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${patient.age} years old',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      patient.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // CONTACT INFORMATION
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow(Icons.phone, 'Phone', patient.phone),
                    _infoRow(Icons.email, 'Email', patient.email),
                    _infoRow(Icons.location_on, 'Address', patient.address),
                    _infoRow(Icons.bloodtype, 'Blood Type', patient.bloodType),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // MEDICAL INFORMATION
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medical Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Conditions
                    if (patient.conditions.isNotEmpty) ...[
                      const Text(
                        'Conditions:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: patient.conditions.map((condition) => Chip(
                          label: Text(condition),
                          backgroundColor: const Color(0xFF4A90E2).withOpacity(0.1),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Allergies
                    if (patient.allergies.isNotEmpty) ...[
                      const Text(
                        'Allergies:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: patient.allergies.map((allergy) => Chip(
                          label: Text(allergy),
                          backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // EMERGENCY CONTACTS
            if (patient.emergencyContacts.isNotEmpty) ...[
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...patient.emergencyContacts.map((contact) => 
                        _emergencyContactCard(contact)
                      ).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ACCOUNT INFORMATION
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow(Icons.calendar_today, 'Member Since', 
                      DateFormat('MMM d, yyyy').format(patient.createdAt)),
                    if (patient.updatedAt != null)
                      _infoRow(Icons.update, 'Last Updated', 
                        DateFormat('MMM d, yyyy').format(patient.updatedAt!)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PATIENT DETAIL AVATAR WIDGET
  Widget _buildPatientDetailAvatar(PatientProfile patient, double size) {
    final hasValidPhoto = patient.profilePhotoUrl != null && 
                         patient.profilePhotoUrl!.isNotEmpty &&
                         patient.profilePhotoUrl!.startsWith('http');

    if (hasValidPhoto) {
      return CachedNetworkImage(
        imageUrl: patient.profilePhotoUrl!,
        imageBuilder: (context, imageProvider) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
            border: Border.all(
              color: const Color(0xFF4A90E2).withOpacity(0.3),
              width: 3,
            ),
          ),
        ),
        placeholder: (context, url) => _buildDetailPlaceholder(patient, size),
        errorWidget: (context, url, error) => _buildDetailPlaceholder(patient, size),
      );
    } else {
      return _buildDetailPlaceholder(patient, size);
    }
  }

  Widget _buildDetailPlaceholder(PatientProfile patient, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF4A90E2).withOpacity(0.1),
        border: Border.all(
          color: const Color(0xFF4A90E2).withOpacity(0.3),
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(patient.fullName),
          style: TextStyle(
            color: const Color(0xFF4A90E2),
            fontWeight: FontWeight.bold,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length < 2) {
      return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emergencyContactCard(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFFF8F9FA),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF4A90E2),
              radius: 20,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    contact.relation,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    contact.phone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}