import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'patient.dart';
import 'caremed.dart';
import 'calendar.dart';
import 'Profile.dart'; 
import '../models/caregiver_profile.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({Key? key}) : super(key: key);

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _caregiverName = 'Caregiver';
  String? _caregiverPhotoUrl;
  List<Map<String, dynamic>> _medicationReminders = [];
  List<Map<String, dynamic>> _patients = [];
  int _dueTodayCount = 0;
  int _totalPatients = 0;
  int _alertCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final String caregiverId = user.uid;

      await _loadCaregiverProfile(caregiverId);

      final QuerySnapshot assignmentSnap = await _firestore
          .collection('caregiver_assignments')
          .where('caregiverId', isEqualTo: caregiverId)
          .where('status', isEqualTo: 'active')
          .get();

      final List<String> patientIds = assignmentSnap.docs
          .map((doc) => doc['patientId'] as String)
          .toList();

      setState(() {
        _totalPatients = patientIds.length;
      });

      final List<Map<String, dynamic>> patients = [];
      if (patientIds.isNotEmpty) {
        final QuerySnapshot patientSnap = await _firestore
            .collection('patient_profiles')
            .where(FieldPath.documentId, whereIn: patientIds)
            .get();

        for (var doc in patientSnap.docs) {
          final patientData = doc.data() as Map<String, dynamic>;
          patients.add({
            'id': doc.id,
            'name': patientData['fullName'] ?? 'Unknown Patient',
            'age': patientData['age'] ?? 0,
            'condition': patientData['conditions'] != null && (patientData['conditions'] as List).isNotEmpty 
                ? (patientData['conditions'] as List).first 
                : 'No condition',
            'photoUrl': patientData['profilePhotoUrl'],
          });
        }
      }

      final List<Map<String, dynamic>> medicationReminders = [];
      int dueToday = 0;

      if (patientIds.isNotEmpty) {
        final QuerySnapshot medSnap = await _firestore
            .collection('medications')
            .where('patientId', whereIn: patientIds)
            .where('isActive', isEqualTo: true)
            .get();

        final now = DateTime.now();
        final todayStr = _formatTime(now);

        for (var doc in medSnap.docs) {
          final medData = doc.data() as Map<String, dynamic>;
          final List<String> times = (medData['times'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [];
          
          for (var time in times) {
            final isPending = _compareTime(time, todayStr) >= 0;
            if (isPending) dueToday++;

            final String patientId = medData['patientId'] as String;
            final patient = patients.firstWhere(
              (p) => p['id'] == patientId,
              orElse: () => {'name': 'Unknown Patient'},
            );

            medicationReminders.add({
              'id': doc.id,
              'time': time,
              'patientName': patient['name'],
              'patientId': patientId,
              'medication': medData['name'] ?? 'Unknown Medication',
              'dose': medData['dose'] ?? '',
              'isPending': isPending,
            });
          }
        }

        medicationReminders.sort((a, b) => _compareTime(a['time'], b['time']));
      }

      final int alerts = dueToday > 3 ? dueToday - 3 : 0;

      setState(() {
        _patients = patients;
        _medicationReminders = medicationReminders;
        _dueTodayCount = dueToday;
        _alertCount = alerts;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCaregiverProfile(String caregiverId) async {
    try {
      QuerySnapshot caregiverQuery = await _firestore
          .collection('caregiver_profile')
          .limit(1)
          .get();

      if (caregiverQuery.docs.isNotEmpty) {
        final caregiverDoc = caregiverQuery.docs.first;
        final caregiverData = caregiverDoc.data() as Map<String, dynamic>;
        
        final firstName = caregiverData['firstName'] ?? '';
        final lastName = caregiverData['lastName'] ?? '';
        final fullName = firstName.isNotEmpty && lastName.isNotEmpty 
            ? '$firstName $lastName' 
            : caregiverData['fullName'] ?? 'Caregiver';
        
        final profilePhotoUrl = caregiverData['profilePhotoUrl'] ?? 
                              caregiverData['profilePicture'];
        
        setState(() {
          _caregiverName = fullName;
          _caregiverPhotoUrl = profilePhotoUrl;
        });
        return;
      }

      final User? user = _auth.currentUser;
      if (user?.displayName != null) {
        setState(() {
          _caregiverName = user!.displayName!;
        });
      } else if (user?.email != null) {
        setState(() {
          _caregiverName = user!.email!.split('@').first;
        });
      }
    } catch (error) {
      final User? user = _auth.currentUser;
      if (user?.displayName != null) {
        setState(() {
          _caregiverName = user!.displayName!;
        });
      } else if (user?.email != null) {
        setState(() {
          _caregiverName = user!.email!.split('@').first;
        });
      }
    }
  }

  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  int _compareTime(String time1, String time2) {
    try {
      return time1.compareTo(time2);
    } catch (error) {
      return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFAFBFC),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5F6F7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.grey[200],
                                    child: _caregiverPhotoUrl != null && _caregiverPhotoUrl!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: _caregiverPhotoUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.person,
                                                color: Colors.grey[400],
                                                size: 28,
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Icon(
                                              Icons.person,
                                              color: Colors.grey[400],
                                              size: 28,
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            color: Colors.grey[400],
                                            size: 28,
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    _caregiverName,
                                    style: TextStyle(
                                      color: Colors.grey[900],
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5F6F7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.grey[700],
                                      size: 28,
                                    ),
                                    if (_alertCount > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF6C5CE7),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5F6F7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.menu,
                                  color: Colors.grey[700],
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      _isLoading 
                          ? _buildLoadingStats()
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildQuickStat(
                                    icon: Icons.people_outline,
                                    count: '$_totalPatients',
                                    label: 'My Patients',
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickStat(
                                    icon: Icons.medication_outlined,
                                    count: '$_dueTodayCount',
                                    label: 'Due Today',
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickStat(
                                    icon: Icons.warning_amber_outlined,
                                    count: '$_alertCount',
                                    label: 'Alerts',
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Medication Reminders",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MedicationScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFF6C5CE7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (_isLoading)
                    _buildLoadingMedications()
                  else if (_medicationReminders.isEmpty)
                    _buildEmptyMedications()
                  else
                    ..._medicationReminders.take(3).map((reminder) => Column(
                      children: [
                        _buildMedicationCard(
                          time: reminder['time'],
                          patientName: reminder['patientName'],
                          medication: reminder['medication'],
                          isPending: reminder['isPending'],
                        ),
                        SizedBox(height: 12),
                      ],
                    )),
                  SizedBox(height: 24),
                  Text(
                    'My Patients',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  SizedBox(height: 16),
                  if (_isLoading)
                    _buildLoadingPatients()
                  else if (_patients.isEmpty)
                    _buildEmptyPatients()
                  else
                    ..._patients.take(3).map((patient) => Column(
                      children: [
                        _buildPatientCard(
                          context,
                          name: patient['name'],
                          age: patient['age'],
                          condition: patient['condition'],
                          medicationCount: 0,
                          lastChecked: 'Today',
                          statusColor: Color(0xFF4CAF50),
                          photoUrl: patient['photoUrl'],
                        ),
                        SizedBox(height: 12),
                      ],
                    )),
                  SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildActionCard(
                        icon: Icons.check_circle_outline,
                        title: 'Log\nMedication',
                        color: Color(0xFF4CAF50),
                      ),
                      _buildActionCard(
                        icon: Icons.add_alert_outlined,
                        title: 'Set\nReminder',
                        color: Color(0xFFFF6B6B),
                      ),
                      _buildActionCard(
                        icon: Icons.chat_bubble_outline,
                        title: 'Contact\nDoctor',
                        color: Color(0xFF42A5F5),
                      ),
                      _buildActionCard(
                        icon: Icons.description_outlined,
                        title: 'View\nReports',
                        color: Color(0xFFFFA726),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildActivityItem(
                    icon: Icons.check_circle,
                    title: 'Medication administered',
                    subtitle: 'Roberto Cruz - Metformin - 8:00 AM',
                    iconColor: Color(0xFF4CAF50),
                  ),
                  _buildActivityItem(
                    icon: Icons.event_available,
                    title: 'Appointment scheduled',
                    subtitle: 'Elena Torres - Dr. Martinez - Dec 15',
                    iconColor: Color(0xFF42A5F5),
                  ),
                  _buildActivityItem(
                    icon: Icons.warning_amber,
                    title: 'Missed medication alert',
                    subtitle: 'Miguel Santos - Reminder sent',
                    iconColor: Color(0xFFFFA726),
                  ),
                  SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  Widget _buildLoadingStats() {
    return Row(
      children: [
        Expanded(child: _buildQuickStat(icon: Icons.people_outline, count: '...', label: 'My Patients')),
        SizedBox(width: 12),
        Expanded(child: _buildQuickStat(icon: Icons.medication_outlined, count: '...', label: 'Due Today')),
        SizedBox(width: 12),
        Expanded(child: _buildQuickStat(icon: Icons.warning_amber_outlined, count: '...', label: 'Alerts')),
      ],
    );
  }

  Widget _buildLoadingMedications() {
    return Column(
      children: [
        _buildMedicationCard(time: '...', patientName: 'Loading...', medication: 'Loading...', isPending: true),
        SizedBox(height: 12),
        _buildMedicationCard(time: '...', patientName: 'Loading...', medication: 'Loading...', isPending: false),
      ],
    );
  }

  Widget _buildLoadingPatients() {
    return Column(
      children: [
        _buildPatientCard(
          context, 
          name: 'Loading...', 
          age: 0, 
          condition: 'Loading...', 
          medicationCount: 0, 
          lastChecked: '...', 
          statusColor: Colors.grey,
          photoUrl: null,
        ),
        SizedBox(height: 12),
        _buildPatientCard(
          context, 
          name: 'Loading...', 
          age: 0, 
          condition: 'Loading...', 
          medicationCount: 0, 
          lastChecked: '...', 
          statusColor: Colors.grey,
          photoUrl: null,
        ),
      ],
    );
  }

  Widget _buildEmptyMedications() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFDFDFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE8EAED)),
      ),
      child: Column(
        children: [
          Icon(Icons.medication_outlined, size: 48, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'No medications due',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'All medications are up to date',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPatients() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFDFDFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE8EAED)),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'No patients assigned',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Patients will appear here once assigned',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String count,
    required String label,
  }) {
    Color iconColor;
    if (label == 'My Patients') {
      iconColor = Color(0xFF6C5CE7);
    } else if (label == 'Due Today') {
      iconColor = Color(0xFF4CAF50);
    } else if (label == 'Alerts') {
      iconColor = Color(0xFFFF6B6B);
    } else {
      iconColor = Colors.grey[700]!;
    }
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFE8EAED),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          SizedBox(height: 6),
          Text(
            count,
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard({
    required String time,
    required String patientName,
    required String medication,
    required bool isPending,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFDFDFE),
        borderRadius: BorderRadius.circular(16),
        border: isPending ? Border.all(
          color: Color(0xFFDFE1E6),
          width: 1,
        ) : Border.all(
          color: Color(0xFFE8EAED),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPending 
                  ? Color(0xFFFF6B6B).withOpacity(0.1)
                  : Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication,
              color: isPending ? Color(0xFFFF6B6B) : Color(0xFF4CAF50),
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    if (isPending)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFF0F1F3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Pending',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  patientName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  medication,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          if (isPending)
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                'Mark Done',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(
    BuildContext context, {
    required String name,
    required int age,
    required String condition,
    required int medicationCount,
    required String lastChecked,
    required Color statusColor,
    required String? photoUrl,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientsScreen(),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFFDFDFE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFFE8EAED),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(0xFFF5F6F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.grey[400],
                    ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$age years • $condition',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.medication,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$medicationCount medications',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 4),
                      Text(
                        lastChecked,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFDFDFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFFE8EAED),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFDFDFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFE8EAED),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFAFBFC),
        border: Border(
          top: BorderSide(
            color: Color(0xFFE8EAED),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.home, 'Home', currentIndex == 0, 0),
              _buildNavItem(context, Icons.people, 'Patients', currentIndex == 1, 1),
              _buildNavItem(context, Icons.medication, 'Medications', currentIndex == 2, 2),
              _buildNavItem(context, Icons.calendar_month, 'Calendar', currentIndex == 3, 3),
              _buildNavItem(context, Icons.person, 'Profile', currentIndex == 4, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isActive, int index) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (isActive) return;

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CaregiverHomeScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PatientsScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MedicationScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CalendarScreen()),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? Color(0xFF6C5CE7) : Colors.grey[400],
                size: 26,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? Color(0xFF6C5CE7) : Colors.grey[400],
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}