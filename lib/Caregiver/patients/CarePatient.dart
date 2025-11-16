import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/patient_profile.dart';


class CarePatient extends StatefulWidget {
  const CarePatient({Key? key}) : super(key: key);

  @override
  State<CarePatient> createState() => _CarePatientState();
}

class _CarePatientState extends State<CarePatient> {
  // Updated color scheme with purple theme
  static const Color primary = Color(0xFF6C5CE7);
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

  // Track expanded state for each patient card
  Map<String, bool> _expandedStates = {};

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  // Load patients assigned to current user from Firestore
  Future<void> _loadPatients() async {
    try {
      print('🔄 Loading patients for current user...');
      
      // Get current user ID
      final String currentUserId = await _getCurrentUserId();
      print('👤 Current user ID: $currentUserId');

      // STEP 1: Get all assignments for this caregiver
      final QuerySnapshot assignmentsSnapshot = await _firestore
          .collection('caregiver_assignments')
          .where('caregiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'active')
          .get();

      print('📋 Found ${assignmentsSnapshot.docs.length} active assignments');

      // Debug: Print all assignments
      for (var doc in assignmentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('📝 Assignment ID: ${doc.id}');
        print('   👨‍⚕️ Caregiver ID: ${data['caregiverId']}');
        print('   👤 Patient ID: ${data['patientId']}');
        print('   📊 Status: ${data['status']}');
      }

      if (assignmentsSnapshot.docs.isEmpty) {
        print('ℹ️ No active assignments found');
        setState(() {
          _patients = [];
          _isLoading = false;
        });
        return;
      }

      // STEP 2: Extract patient IDs from assignments
      final List<String> patientIds = assignmentsSnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['patientId'] as String;
          })
          .where((patientId) => patientId.isNotEmpty)
          .toList();

      print('👥 Patient IDs to fetch: $patientIds');

      if (patientIds.isEmpty) {
        print('ℹ️ No valid patient IDs found in assignments');
        setState(() {
          _patients = [];
          _isLoading = false;
        });
        return;
      }

      // STEP 3: Fetch patient profiles for these IDs
      print('🔄 Fetching patient profiles...');
      final QuerySnapshot patientsSnapshot = await _firestore
          .collection('patient_profiles')
          .where(FieldPath.documentId, whereIn: patientIds)
          .get();

      print('📄 Found ${patientsSnapshot.docs.length} patient profiles');

      // Debug: Print all patient profiles found
      for (var doc in patientsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('   ✅ Patient: ${data['fullName']} (ID: ${doc.id})');
        print('   📧 Email: ${data['email']}');
        print('   📞 Phone: ${data['phone']}');
      }

      List<PatientProfile> loadedPatients = [];

      for (var doc in patientsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('🎯 Successfully processing patient: ${data['fullName']}');
          
          final patient = PatientProfile.fromMap(data, doc.id);
          loadedPatients.add(patient);
          _expandedStates[patient.id] = false;
          
        } catch (e) {
          print('❌ Error parsing patient ${doc.id}: $e');
        }
      }

      setState(() {
        _patients = loadedPatients;
        _isLoading = false;
      });

      print('🎉 SUCCESS! Loaded ${_patients.length} patients');

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

  // TODO: Replace this with your actual authentication method
  Future<String> _getCurrentUserId() async {
    // This is a placeholder - you need to implement this based on your auth system
    // For Firebase Auth, it would be:
    // return FirebaseAuth.instance.currentUser!.uid;
    
    // Using the CORRECT caregiver ID from your assignment document
    return "Fko6yS2iPAe9xbC6ppPR9si4q5j1"; // This matches your assignment
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

  // Toggle expand/collapse for patient card
  void _toggleExpand(String patientId) {
    setState(() {
      _expandedStates[patientId] = !(_expandedStates[patientId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'My Patients',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPatients,
            tooltip: 'Refresh patients',
          ),
        ],
      ),
      body: Column(
        children: [
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
    );
  }

  // SEARCH BAR
  Widget _searchBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            textAlignVertical: TextAlignVertical.center,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search my patients...',
              hintStyle: const TextStyle(color: muted),
              prefixIcon: const Icon(Icons.search, color: muted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              '${_filteredPatients.length} Assigned Patients',
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your patients...',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
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
            const Text(
              'No patients assigned yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Patients will appear here once assigned to you',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
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

  // PATIENT CARD WITH DROPDOWN
  Widget _patientCard(PatientProfile patient) {
    final bool isExpanded = _expandedStates[patient.id] ?? false;
    final String primaryCondition = patient.conditions.isNotEmpty 
        ? patient.conditions.first 
        : 'No conditions listed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildPatientAvatar(patient),
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
                    IconButton(
                      onPressed: () => _toggleExpand(patient.id),
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: primary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        patient.phone,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Icon(Icons.calendar_today, size: 16, color: muted),
                    const SizedBox(width: 6),
                    Text(
                      'Since ${DateFormat('MMM yyyy').format(patient.createdAt)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _dropdownContent(patient),
          ],
        ],
      ),
    );
  }

  // DROPDOWN CONTENT
  Widget _dropdownContent(PatientProfile patient) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoSection(
            title: 'Contact Information',
            icon: Icons.contact_phone,
            children: [
              _infoItem(Icons.email, 'Email', patient.email),
              _infoItem(Icons.location_on, 'Address', patient.address),
              _infoItem(Icons.bloodtype, 'Blood Type', patient.bloodType),
            ],
          ),
          const SizedBox(height: 16),
          _infoSection(
            title: 'Medical Information',
            icon: Icons.medical_services,
            children: [
              if (patient.conditions.isNotEmpty) ...[
                _infoItem(Icons.health_and_safety, 'Conditions', 
                  patient.conditions.join(', ')),
              ],
              if (patient.allergies.isNotEmpty) ...[
                _infoItem(Icons.warning, 'Allergies', 
                  patient.allergies.join(', ')),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (patient.emergencyContacts.isNotEmpty) ...[
            _infoSection(
              title: 'Emergency Contacts',
              icon: Icons.emergency,
              children: patient.emergencyContacts.map((contact) => 
                _emergencyContactItem(contact)
              ).toList(),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionButton(
                icon: Icons.visibility,
                label: 'View Details',
                color: primary,
                onPressed: () => _viewPatientDetails(patient),
              ),
              _actionButton(
                icon: Icons.message,
                label: 'Message',
                color: success,
                onPressed: () => _messagePatient(patient),
              ),
              _actionButton(
                icon: Icons.assignment,
                label: 'Tasks',
                color: warning,
                onPressed: () => _viewTasks(patient),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // All the helper widgets remain the same...
  Widget _infoSection({required String title, required IconData icon, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 18, color: primary), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8), ...children,
      ],
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 16, color: muted), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)), Text(value, style: const TextStyle(fontSize: 14, color: Colors.grey))]))]));
  }

  Widget _emergencyContactItem(EmergencyContact contact) {
    return Card(margin: const EdgeInsets.symmetric(vertical: 4), color: const Color(0xFFF8F9FA), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)), child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [CircleAvatar(backgroundColor: primary, radius: 16, child: const Icon(Icons.person, color: Colors.white, size: 14)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(contact.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), Text('${contact.relation} • ${contact.phone}', style: const TextStyle(fontSize: 12, color: Colors.grey))]))])));
  }

  Widget _actionButton({required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return Column(children: [IconButton(onPressed: onPressed, icon: Icon(icon, color: color, size: 24)), Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500))]);
  }

  Widget _buildPatientAvatar(PatientProfile patient) {
    final hasValidPhoto = patient.profilePhotoUrl != null && patient.profilePhotoUrl!.isNotEmpty && patient.profilePhotoUrl!.startsWith('http');
    if (hasValidPhoto) {
      return SizedBox(width: 50, height: 50, child: ClipRRect(borderRadius: BorderRadius.circular(25), child: CachedNetworkImage(imageUrl: patient.profilePhotoUrl!, fit: BoxFit.cover, placeholder: (context, url) => Container(decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(25)), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(primary))))), errorWidget: (context, url, error) => _buildPlaceholderAvatar(patient))));
    } else {
      return _buildPlaceholderAvatar(patient);
    }
  }

  Widget _buildPlaceholderAvatar(PatientProfile patient) {
    return Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withOpacity(0.1)), child: Center(child: Text(_getInitials(patient.fullName), style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 16))));
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length < 2) return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _refreshPatients() async {
    setState(() {_isLoading = true;});
    await _loadPatients();
  }

  void _viewPatientDetails(PatientProfile patient) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Viewing details for ${patient.fullName}'), backgroundColor: primary));
  }

  void _messagePatient(PatientProfile patient) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Messaging ${patient.fullName}'), backgroundColor: success));
  }

  void _viewTasks(PatientProfile patient) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Viewing tasks for ${patient.fullName}'), backgroundColor: warning));
  }
}