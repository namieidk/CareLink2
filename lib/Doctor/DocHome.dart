import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import other doctor screens
import 'DoctorPatients.dart';
import 'DoctorSchedule.dart';
import 'DoctorProfile.dart';

// Import the doctor profile model
import '../../models/doctor_profile.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({Key? key}) : super(key: key);

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  // Blue theme for doctor
  static const Color primary = Color(0xFF4A90E2);
  static const Color accent = Color(0xFF1976D2);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color muted = Colors.grey;
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardShadow = Color(0x12000000);

  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Doctor profile
  DoctorProfile? _doctorProfile;
  bool _isLoading = true;
  String? _currentDoctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  Future<void> _loadDoctorProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        _currentDoctorId = user.uid;
        
        final docSnapshot = await _firestore
            .collection('doctor_profiles')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          setState(() {
            _doctorProfile = DoctorProfile.fromFirestore(docSnapshot);
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading doctor profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Streams for real-time data
  Stream<int> get todayAppointmentsStream {
    if (_currentDoctorId == null) return Stream.value(0);
    
    return _firestore
        .collection('doctor_schedules')
        .doc(_currentDoctorId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return 0;
      
      final data = snapshot.data() as Map<String, dynamic>;
      final bookings = data['bookings'] as Map<String, dynamic>? ?? {};
      
      // Get today's date string (YYYY-MM-DD format)
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      if (bookings.containsKey(dateString)) {
        final todayBookings = bookings[dateString] as List<dynamic>? ?? [];
        return todayBookings.length;
      }
      
      return 0;
    });
  }
  
  Stream<int> get totalPatientsStream {
    if (_currentDoctorId == null) return Stream.value(0);
    
    // Get total unique patients from doctor's bookings
    return _firestore
        .collection('doctor_schedules')
        .doc(_currentDoctorId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return 0;
      
      final data = snapshot.data() as Map<String, dynamic>;
      final bookings = data['bookings'] as Map<String, dynamic>? ?? {};
      
      // Collect all unique patient IDs from all bookings
      final patientIds = <String>{};
      
      bookings.forEach((dateString, bookingsList) {
        if (bookingsList is List) {
          for (var booking in bookingsList) {
            if (booking is Map<String, dynamic>) {
              final patientId = booking['patientId'] as String?;
              if (patientId != null && patientId.isNotEmpty) {
                patientIds.add(patientId);
              }
            }
          }
        }
      });
      
      return patientIds.length;
    });
  }
  
  Stream<int> get pendingTasksStream {
    if (_currentDoctorId == null) return Stream.value(0);
    
    return _firestore
        .collection('tasks')
        .where('doctorId', isEqualTo: _currentDoctorId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
  
  Stream<int> get upcomingAppointmentsStream {
    if (_currentDoctorId == null) return Stream.value(0);
    
    return _firestore
        .collection('doctor_schedules')
        .doc(_currentDoctorId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return 0;
      
      final data = snapshot.data() as Map<String, dynamic>;
      final bookings = data['bookings'] as Map<String, dynamic>? ?? {};
      
      int upcomingCount = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      bookings.forEach((dateString, bookingsList) {
        try {
          final dateParts = dateString.split('-');
          if (dateParts.length == 3) {
            final year = int.parse(dateParts[0]);
            final month = int.parse(dateParts[1]);
            final day = int.parse(dateParts[2]);
            final date = DateTime(year, month, day);
            
            // Include today and future dates
            if (date.isAfter(today) || date.isAtSameMomentAs(today)) {
              if (bookingsList is List) {
                upcomingCount += bookingsList.length;
              }
            }
          }
        } catch (e) {
          // Skip invalid date strings
          print('Error parsing date: $dateString - $e');
        }
      });
      
      return upcomingCount;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
                    // Already on home, do nothing
                    break;
                  case 1:
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => const DoctorPatientsScreen()),
                    );
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primary),
          ),
        ),
      );
    }

    if (_doctorProfile == null) {
      return Scaffold(
        backgroundColor: background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Doctor profile not found',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadDoctorProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            _header(),

            // SCROLLABLE CONTENT
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDoctorProfile,
                color: primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // STATS GRID (2 × 2)
                      _statsGrid(),

                      const SizedBox(height: 20),

                      // QUICK ACTIONS
                      _quickActions(),

                      const SizedBox(height: 20),

                      // WELCOME MESSAGE
                      _welcomeMessage(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(context, 0),
    );
  }

  // HEADER
  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, accent],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Doctor Profile Image or Initials
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _doctorProfile!.profileImageUrl != null &&
                      _doctorProfile!.profileImageUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        _doctorProfile!.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              _doctorProfile!.getInitials(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        _doctorProfile!.getInitials(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _doctorProfile!.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _doctorProfile!.specialty,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _doctorProfile!.hospital,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // STATS GRID WITH STREAMS
  Widget _statsGrid() => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          _buildStreamStatCard(
            stream: todayAppointmentsStream,
            icon: Icons.event_available,
            color: info,
            label: 'Today\'s Appointments',
          ),
          _buildStreamStatCard(
            stream: totalPatientsStream,
            icon: Icons.people_alt,
            color: success,
            label: 'Total Patients',
          ),
          _buildStreamStatCard(
            stream: upcomingAppointmentsStream,
            icon: Icons.calendar_today,
            color: primary,
            label: 'Upcoming Appointments',
          ),
          _buildStreamStatCard(
            stream: pendingTasksStream,
            icon: Icons.assignment,
            color: warning,
            label: 'Pending Tasks',
          ),
        ],
      );

  // STREAM BUILDER FOR STAT CARDS
  Widget _buildStreamStatCard({
    required Stream<int> stream,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _bigStatLoading(icon: icon, color: color, label: label);
        }
        
        final count = snapshot.data ?? 0;
        return _bigStat(
          icon: icon,
          color: color,
          value: count.toString(),
          label: label,
        );
      },
    );
  }

  // LOADING STAT CARD
  Widget _bigStatLoading({
    required IconData icon,
    required Color color,
    required String label,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: cardShadow, blurRadius: 8, offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const Spacer(),
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  // SINGLE BIG STAT CARD
  Widget _bigStat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: cardShadow, blurRadius: 8, offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  // QUICK ACTIONS
  Widget _quickActions() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _actionItem(Icons.people, 'My Patients', primary, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorPatientsScreen()),
                );
              }),
              _actionItem(Icons.calendar_today, 'Schedule', info, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorScheduleScreen()),
                );
              }),
              _actionItem(Icons.assignment, 'Tasks', warning, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tasks feature coming soon!')),
                );
              }),
              _actionItem(Icons.medical_services, 'Consultations', success, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Consultations feature coming soon!')),
                );
              }),
            ],
          ),
        ],
      );

  Widget _actionItem(IconData icon, String label, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: cardShadow, blurRadius: 6, offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

  // WELCOME MESSAGE
  Widget _welcomeMessage() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withOpacity(0.1),
              accent.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.local_hospital, size: 40, color: primary),
            const SizedBox(height: 12),
            const Text(
              "Welcome to Your Doctor Portal",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Manage your patients, view appointments, and stay connected with your care team.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
}