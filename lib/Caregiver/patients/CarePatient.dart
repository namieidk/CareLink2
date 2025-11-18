import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/patient_profile.dart';
import '../../models/rating.dart';

class CarePatient extends StatefulWidget {
  const CarePatient({Key? key}) : super(key: key);

  @override
  State<CarePatient> createState() => _CarePatientState();
}

class _CarePatientState extends State<CarePatient> {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color muted = Colors.grey;
  static const Color background = Color(0xFFF8F9FA);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<PatientProfile> _patients = [];
  bool _isLoading = true;

  Map<String, bool> _expandedStates = {};

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final String currentUserId = await _getCurrentUserId();

      final QuerySnapshot assignmentsSnapshot = await _firestore
          .collection('caregiver_assignments')
          .where('caregiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'active')
          .get();

      if (assignmentsSnapshot.docs.isEmpty) {
        setState(() {
          _patients = [];
          _isLoading = false;
        });
        return;
      }

      final List<String> patientIds = assignmentsSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['patientId'] as String)
          .where((id) => id.isNotEmpty)
          .toList();

      if (patientIds.isEmpty) {
        setState(() {
          _patients = [];
          _isLoading = false;
        });
        return;
      }

      final QuerySnapshot patientsSnapshot = await _firestore
          .collection('patient_profiles')
          .where(FieldPath.documentId, whereIn: patientIds)
          .get();

      final List<PatientProfile> loadedPatients = [];

      for (var doc in patientsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final patient = PatientProfile.fromMap(data, doc.id);
        loadedPatients.add(patient);
        _expandedStates[patient.id] = false;
      }

      setState(() {
        _patients = loadedPatients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patients'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String> _getCurrentUserId() async {
    return "Fko6yS2iPAe9xbC6ppPR9si4q5j1";
  }

  List<PatientProfile> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    return _patients.where((patient) =>
        patient.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        patient.conditions.any((c) => c.toLowerCase().contains(_searchQuery.toLowerCase()))).toList();
  }

  void _toggleExpand(String patientId) {
    setState(() {
      _expandedStates[patientId] = !(_expandedStates[patientId] ?? false);
    });
  }

  Future<void> _ratePatient(PatientProfile patient) async {
    double selectedRating = 5.0;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(dialogBackgroundColor: Colors.white),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Rate ${patient.fullName}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: StatefulBuilder(
                builder: (context, setStateDialog) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'How was working with this patient?',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FittedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) => IconButton(
                          iconSize: 48,
                          onPressed: () => setStateDialog(() => selectedRating = (i + 1).toDouble()),
                          icon: Icon(
                            i < selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 48,
                          ),
                        )),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: commentController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Write a review (optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primary, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 4,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final caregiverId = await _getCurrentUserId();
                final caregiverDoc = await _firestore.collection('caregiver_profile').doc(caregiverId).get();
                final caregiverData = caregiverDoc.data() ?? {};

                await _firestore.collection('ratings').add({
                  'fromUserId': caregiverId,
                  'fromUserRole': 'caregiver',
                  'fromUserName': '${caregiverData['firstName'] ?? ''} ${caregiverData['lastName'] ?? ''}'.trim(),
                  'fromUserPhotoUrl': caregiverData['profilePhotoUrl'],
                  'toUserId': patient.id,
                  'toUserRole': 'patient',
                  'toUserName': patient.fullName,
                  'toUserPhotoUrl': patient.profilePhotoUrl,
                  'jobId': 'assignment_${patient.id}',
                  'rating': selectedRating,
                  'comment': commentController.text.trim(),
                  'isAnonymous': false,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you for your rating!'), backgroundColor: success),
                  );
                }
              },
              child: const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.bold)),
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
      appBar: AppBar(
        title: const Text('My Patients', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => _isLoading = true);
              await _loadPatients();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _searchBar(),
          _patientsCount(),
          Expanded(child: _patientsList()),
        ],
      ),
    );
  }

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
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
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
      );

  Widget _patientsCount() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_filteredPatients.length} Assigned Patients', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            Text('Total: ${_patients.length}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );

  Widget _patientsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primary)));
    }

    if (_filteredPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: muted),
            const SizedBox(height: 16),
            const Text('No patients assigned yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Patients will appear here once assigned to you', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPatients,
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              child: const Text('Refresh', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPatients,
      color: primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredPatients.length,
        itemBuilder: (context, index) => _patientCard(_filteredPatients[index]),
      ),
    );
  }

  Widget _patientCard(PatientProfile patient) {
    final bool isExpanded = _expandedStates[patient.id] ?? false;
    final String primaryCondition = patient.conditions.isNotEmpty ? patient.conditions.first : 'No conditions listed';

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
                          Text(patient.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 2),
                          Text('${patient.age} years • $primaryCondition', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _toggleExpand(patient.id),
                      icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: primary, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: muted),
                    const SizedBox(width: 6),
                    Expanded(child: Text(patient.phone, style: const TextStyle(fontSize: 14, color: Colors.grey))),
                    Icon(Icons.calendar_today, size: 16, color: muted),
                    const SizedBox(width: 6),
                    Text('Since ${DateFormat('MMM yyyy').format(patient.createdAt)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
              if (patient.conditions.isNotEmpty) _infoItem(Icons.health_and_safety, 'Conditions', patient.conditions.join(', ')),
              if (patient.allergies.isNotEmpty) _infoItem(Icons.warning, 'Allergies', patient.allergies.join(', ')),
            ],
          ),
          const SizedBox(height: 16),
          if (patient.emergencyContacts.isNotEmpty) ...[
            _infoSection(
              title: 'Emergency Contacts',
              icon: Icons.emergency,
              children: patient.emergencyContacts.map((c) => _emergencyContactItem(c)).toList(),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionButton(icon: Icons.visibility, label: 'View Details', color: primary, onPressed: () => _viewPatientDetails(patient)),
              _actionButton(icon: Icons.message, label: 'Message', color: success, onPressed: () => _messagePatient(patient)),
              _actionButton(icon: Icons.assignment, label: 'Tasks', color: warning, onPressed: () => _viewTasks(patient)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _ratePatient(patient),
              icon: const Icon(Icons.star, color: primary),
              label: const Text('Rate Patient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primary,
                elevation: 6,
                shadowColor: primary.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: primary, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSection({required String title, required IconData icon, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 18, color: primary), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emergencyContactItem(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: const Color(0xFFF8F9FA),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: primary, radius: 16, child: const Icon(Icons.person, color: Colors.white, size: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('${contact.relation} • ${contact.phone}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return Column(
      children: [
        IconButton(onPressed: onPressed, icon: Icon(icon, color: color, size: 24)),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPatientAvatar(PatientProfile patient) {
    final hasValidPhoto = patient.profilePhotoUrl != null && patient.profilePhotoUrl!.isNotEmpty && patient.profilePhotoUrl!.startsWith('http');
    if (hasValidPhoto) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: CachedNetworkImage(
            imageUrl: patient.profilePhotoUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(25)),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(primary))),
            ),
            errorWidget: (context, url, error) => _buildPlaceholderAvatar(patient),
          ),
        ),
      );
    } else {
      return _buildPlaceholderAvatar(patient);
    }
  }

  Widget _buildPlaceholderAvatar(PatientProfile patient) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withOpacity(0.1)),
      child: Center(
        child: Text(
          patient.fullName.isNotEmpty ? patient.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase() : '?',
          style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
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