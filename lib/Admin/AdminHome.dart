import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// ── YOUR ORIGINAL IMPORTS ─────────────────────────────────────
import 'AdminDoctor.dart';      // List/Search/Add Doctors
import 'AdminCaregiver.dart';   // List/Search/Add Caregivers
import 'AdminPatient.dart';      // List/Search/Add Patients
import 'Reports/AdminReports.dart';     // Reports screen
import 'Reports/analytics.dart';     // Analytics screen
import 'AdminProfile.dart'; // NEW: Profile screen import

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  // ── COLORS ───────────────────────────────────────────────────────
  static const Color primary = Color(0xFF4F6BED);
  static const Color accent = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color muted = Colors.grey;
  static const Color cardShadow = Color(0x12000000);
  static const Color homeNavColor = Color(0xFFFF8BA0); // NEW: Home navbar color

  // ── FIRESTORE REFERENCES ─────────────────────────────────────────
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ── STREAMS FOR REAL-TIME DATA ───────────────────────────────────
  Stream<int> get patientCountStream => 
      _firestore.collection('patients').snapshots().map((snapshot) => snapshot.size);
  
  Stream<int> get doctorCountStream => 
      _firestore.collection('doctors').snapshots().map((snapshot) => snapshot.size);
  
  Stream<int> get caregiverCountStream => 
      _firestore.collection('caregivers').snapshots().map((snapshot) => snapshot.size);
  
  Stream<int> get activeTodayCountStream => 
      _firestore.collection('patients')
          .where('lastLogin', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24))))
          .snapshots()
          .map((snapshot) => snapshot.size);

  // ── LAUNCH URL FUNCTION ──────────────────────────────────────────
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  // ── SHOW HELP DIALOG ─────────────────────────────────────────────
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _helpOption(
                  icon: Icons.email,
                  title: 'Email Support',
                  subtitle: 'Get help via email',
                  onTap: () => _launchUrl('mailto:support@carelink.com?subject=Admin%20Support&body=Hello%20Support%20Team,'),
                ),
                _helpOption(
                  icon: Icons.phone,
                  title: 'Call Support',
                  subtitle: '+1 (555) 123-4567',
                  onTap: () => _launchUrl('tel:+15551234567'),
                ),
                _helpOption(
                  icon: Icons.live_help,
                  title: 'Live Chat',
                  subtitle: 'Chat with our support team',
                  onTap: () => _showLiveChatOptions(),
                ),
                _helpOption(
                  icon: Icons.description,
                  title: 'Documentation',
                  subtitle: 'View user guides and manuals',
                  onTap: () => _showDocumentation(),
                ),
                _helpOption(
                  icon: Icons.video_library,
                  title: 'Video Tutorials',
                  subtitle: 'Watch how-to videos',
                  onTap: () => _showVideoTutorials(),
                ),
                _helpOption(
                  icon: Icons.bug_report,
                  title: 'Report a Bug',
                  subtitle: 'Report technical issues',
                  onTap: () => _showBugReport(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ── SHOW LIVE CHAT OPTIONS ───────────────────────────────────────
  void _showLiveChatOptions() {
    Navigator.of(context).pop(); // Close the main help dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Live Chat Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chatOption(
                platform: 'WhatsApp',
                description: 'Chat on WhatsApp',
                onTap: () => _launchUrl('https://wa.me/15551234567?text=Hello%20CareLink%20Support'),
              ),
              _chatOption(
                platform: 'Telegram',
                description: 'Chat on Telegram',
                onTap: () => _launchUrl('https://t.me/carelinksupport'),
              ),
              _chatOption(
                platform: 'Web Chat',
                description: 'Chat on our website',
                onTap: () => _launchUrl('https://carelink.com/support'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back'),
            ),
          ],
        );
      },
    );
  }

  // ── SHOW DOCUMENTATION ───────────────────────────────────────────
  void _showDocumentation() {
    Navigator.of(context).pop(); // Close the main help dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Documentation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _docOption(
                title: 'Admin Guide',
                description: 'Complete admin manual',
                onTap: () => _launchUrl('https://carelink.com/docs/admin-guide'),
              ),
              _docOption(
                title: 'User Management',
                description: 'Managing users guide',
                onTap: () => _launchUrl('https://carelink.com/docs/user-management'),
              ),
              _docOption(
                title: 'System Settings',
                description: 'Configuration guide',
                onTap: () => _launchUrl('https://carelink.com/docs/system-settings'),
              ),
              _docOption(
                title: 'Troubleshooting',
                description: 'Common issues and solutions',
                onTap: () => _launchUrl('https://carelink.com/docs/troubleshooting'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back'),
            ),
          ],
        );
      },
    );
  }

  // ── SHOW VIDEO TUTORIALS ─────────────────────────────────────────
  void _showVideoTutorials() {
    Navigator.of(context).pop(); // Close the main help dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Video Tutorials'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _videoOption(
                title: 'Getting Started',
                duration: '5:30',
                onTap: () => _launchUrl('https://youtube.com/watch?v=carelink-getting-started'),
              ),
              _videoOption(
                title: 'User Management',
                duration: '8:15',
                onTap: () => _launchUrl('https://youtube.com/watch?v=carelink-user-management'),
              ),
              _videoOption(
                title: 'Reports & Analytics',
                duration: '6:45',
                onTap: () => _launchUrl('https://youtube.com/watch?v=carelink-reports'),
              ),
              _videoOption(
                title: 'System Settings',
                duration: '7:20',
                onTap: () => _launchUrl('https://youtube.com/watch?v=carelink-settings'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back'),
            ),
          ],
        );
      },
    );
  }

  // ── SHOW BUG REPORT ──────────────────────────────────────────────
  void _showBugReport() {
    Navigator.of(context).pop(); // Close the main help dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report a Bug'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please describe the issue you\'re experiencing:'),
              SizedBox(height: 16),
              TextField(
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Describe the bug in detail...',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              Text('You can also email us at: support@carelink.com'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Here you would typically send the bug report
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bug report submitted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Submit Report'),
            ),
          ],
        );
      },
    );
  }

  // ── HELP OPTION WIDGET ───────────────────────────────────────────
  Widget _helpOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  // ── CHAT OPTION WIDGET ───────────────────────────────────────────
  Widget _chatOption({
    required String platform,
    required String description,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: const Icon(Icons.chat, color: Colors.green),
      title: Text(platform, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(description),
      onTap: onTap,
      trailing: const Icon(Icons.open_in_new, size: 16),
    );
  }

  // ── DOCUMENTATION OPTION WIDGET ──────────────────────────────────
  Widget _docOption({
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: const Icon(Icons.article, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(description),
      onTap: onTap,
      trailing: const Icon(Icons.open_in_new, size: 16),
    );
  }

  // ── VIDEO OPTION WIDGET ──────────────────────────────────────────
  Widget _videoOption({
    required String title,
    required String duration,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: const Icon(Icons.play_circle_fill, color: Colors.red),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('Duration: $duration'),
      onTap: onTap,
      trailing: const Icon(Icons.open_in_new, size: 16),
    );
  }

  // ── BOTTOM NAVIGATION ─────────────────────────────────────────────
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
                _navItem(Icons.local_hospital, 'Doctor', active == 1, 1, context),
                _navItem(Icons.supervisor_account, 'Caregiver', active == 2, 2, context),
                _navItem(Icons.people_alt, 'Patient', active == 3, 3, context),
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
                    // Already on home, do nothing
                    break;
                  case 1:
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => const AdminDoctorsScreen()),
                    );
                    break;
                  case 2:
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => const AdminCaregiversScreen()),
                    );
                    break;
                  case 3:
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => const AdminPatientsScreen()),
                    );
                    break;
                  case 4:
                    // UPDATED: Navigate to AdminProfileScreen
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
                    );
                    break;
                }
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: active 
                  ? (index == 0 ? homeNavColor : primary) // NEW: Home gets special color
                  : muted, 
              size: 26
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active 
                    ? (index == 0 ? homeNavColor : primary) // NEW: Home gets special color
                    : muted,
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
            // ── HEADER (UPDATED - NOTIFICATION ICON REMOVED) ─────────────────
            _header(),

            // ── SCROLLABLE CONTENT ───────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── MAIN STAT GRID (2 × 2) ─────────────────────
                    _statsGrid(),

                    const SizedBox(height: 20),

                    // ── QUICK ACTIONS ───────────────────────────
                    _quickActions(),

                    const SizedBox(height: 40), // Extra spacing at the bottom
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

  // ── HEADER (UPDATED - NOTIFICATION ICON REMOVED) ───────────────────────────
  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Hello, Admin',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  Text('Welcome to your dashboard',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            // Notification icon removed completely
          ],
        ),
      );

  // ── 2 × 2 STAT GRID WITH FIREBASE STREAMS ───────────────────────────────
  Widget _statsGrid() => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          _buildStreamStatCard(
            stream: patientCountStream,
            icon: Icons.people_alt,
            color: info,
            label: 'Total Patients',
            trend: '+12%',
          ),
          _buildStreamStatCard(
            stream: doctorCountStream,
            icon: Icons.local_hospital,
            color: success,
            label: 'Total Doctors',
            trend: '+5%',
          ),
          _buildStreamStatCard(
            stream: caregiverCountStream,
            icon: Icons.supervisor_account,
            color: warning,
            label: 'Total Caregivers',
            trend: '+8%',
          ),
          _buildStreamStatCard(
            stream: activeTodayCountStream,
            icon: Icons.online_prediction,
            color: accent,
            label: 'Active Today',
            trend: '+3%',
          ),
        ],
      );

  // ── STREAM BUILDER FOR STAT CARDS ─────────────────────────────────────
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
          value: _formatCount(count),
          label: label,
          trend: trend,
        );
      },
    );
  }

  // ── FORMAT COUNT FOR DISPLAY ────────────────────────────────────────
  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // ── SINGLE BIG STAT CARD ─────────────────────────────────────────────
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
                    color: success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 12, color: success),
                      const SizedBox(width: 2),
                      Text(trend,
                          style: TextStyle(
                              fontSize: 10,
                              color: success,
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

  // ── QUICK ACTIONS ───────────────────────────────────────────────
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
            crossAxisCount: 2, // Changed from 3 to 2 for better layout with 4 items
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2, // Adjusted for better proportions
            children: [
              _actionItem(Icons.person_add, 'Add Doctor', primary, () {
                // Navigate to add doctor screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDoctorsScreen()),
                );
              }),
              _actionItem(Icons.assignment, 'Reports', warning, () {
                // Navigate to reports screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminReports()),
                );
              }),
              _actionItem(Icons.analytics, 'Analytics', success, () {
                // Navigate to analytics screen - FIXED
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminAnalytics()),
                );
              }),
              _actionItem(Icons.help_outline, 'Help', accent, () {
                // Show help dialog
                _showHelpDialog();
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
}