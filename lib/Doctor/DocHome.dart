import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import other doctor screens
import 'DoctorPatients.dart';
import 'DoctorSchedule.dart';
import 'DoctorProfile.dart';

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

  // Sample doctor data
  final String doctorName = "Dr. Sarah Johnson";
  final String specialty = "Cardiologist";
  final String hospital = "City Hospital";

  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Streams for real-time data
  Stream<int> get todayAppointmentsStream => 
      _firestore.collection('appointments')
          .where('doctorId', isEqualTo: 'current_doctor_id')
          .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(DateTime.now()))
          .snapshots()
          .map((snapshot) => snapshot.size);
  
  Stream<int> get totalPatientsStream => 
      _firestore.collection('patients')
          .where('assignedDoctor', isEqualTo: 'current_doctor_id')
          .snapshots()
          .map((snapshot) => snapshot.size);
  
  Stream<int> get pendingTasksStream => 
      _firestore.collection('tasks')
          .where('doctorId', isEqualTo: 'current_doctor_id')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) => snapshot.size);
  
  Stream<int> get unreadMessagesStream => 
      _firestore.collection('messages')
          .where('doctorId', isEqualTo: 'current_doctor_id')
          .where('read', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.size);

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
    final String currentTime = DateFormat('h:mm a').format(DateTime.now());
    final String greeting = _getGreeting();

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            _header(greeting, currentTime),

            // SCROLLABLE CONTENT
            Expanded(
              child: SingleChildScrollView(
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
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(context, 0),
    );
  }

  // HEADER
  Widget _header(String greeting, String currentTime) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: primary,
                  child: Text(
                    _getInitials(doctorName),
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
                        doctorName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty,
                        style: TextStyle(
                          fontSize: 14,
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        hospital,
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
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$greeting, Dr. Johnson!",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Today is ${DateFormat('EEEE, MMMM d').format(DateTime.now())}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    "Current time: $currentTime",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
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
            trend: '+2',
          ),
          _buildStreamStatCard(
            stream: totalPatientsStream,
            icon: Icons.people_alt,
            color: success,
            label: 'Total Patients',
            trend: '+5',
          ),
          _buildStreamStatCard(
            stream: pendingTasksStream,
            icon: Icons.assignment,
            color: warning,
            label: 'Pending Tasks',
            trend: '-1',
          ),
          _buildStreamStatCard(
            stream: unreadMessagesStream,
            icon: Icons.message,
            color: accent,
            label: 'Unread Messages',
            trend: '+3',
          ),
        ],
      );

  // STREAM BUILDER FOR STAT CARDS
  Widget _buildStreamStatCard({
    required Stream<int> stream,
    required IconData icon,
    required Color color,
    required String label,
    required String trend,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return _bigStat(
          icon: icon,
          color: color,
          value: count.toString(),
          label: label,
          trend: trend,
        );
      },
    );
  }

  // SINGLE BIG STAT CARD
  Widget _bigStat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required String trend,
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
            // Icon and trend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: trend.startsWith('+') ? success.withOpacity(0.1) : 
                           trend.startsWith('-') ? Colors.red.withOpacity(0.1) : 
                           Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend.startsWith('+') ? Icons.trending_up : 
                        trend.startsWith('-') ? Icons.trending_down : Icons.trending_flat,
                        size: 12,
                        color: trend.startsWith('+') ? success : 
                               trend.startsWith('-') ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Text(trend,
                          style: TextStyle(
                              fontSize: 10,
                              color: trend.startsWith('+') ? success : 
                                     trend.startsWith('-') ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 24,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
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
          color: primary.withOpacity(0.1),
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

  // Helper: Get greeting based on time
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  // Helper: Get initials from name
  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length < 2) return "DR";
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}