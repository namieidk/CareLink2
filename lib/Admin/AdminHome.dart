import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── YOUR ORIGINAL IMPORTS (unchanged) ─────────────────────────────────────
import 'AdminDoctor.dart';      // List/Search/Add Doctors
import 'AdminCaregiver.dart';   // List/Search/Add Caregivers
import 'AdminPatient.dart';      // List/Search/Add Patients
import 'AdminProfile.dart';      // Admin profile/settings

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  // ── COLORS ───────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFF6B6B);
  static const Color muted   = Colors.grey;
  static const Color cardShadow = Color(0x08000000);

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
    final String today = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ───────────────────────────────────────
            _header(today),

            // ── SCROLLABLE CONTENT ───────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Title + Date
                    Text('Admin Dashboard',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(today,
                        style:
                            TextStyle(fontSize: 15, color: Colors.grey[600])),
                    const SizedBox(height: 24),

                    // ── MAIN STAT GRID (2 × 2) ─────────────────────
                    _statsGrid(),

                    const SizedBox(height: 28),

                    // ── EXTRA ROW (Pending + Appointments) ───────
                    _extraRow(),

                    const SizedBox(height: 28),

                    // ── ADHERENCE CARD ───────────────────────────
                    _adherenceCard(),

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

  // ── HEADER ───────────────────────────────────────────────────────
  Widget _header(String date) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: primary,
              child: Text('AD',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Hello, Admin',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  Text('Welcome back!',
                      style: TextStyle(fontSize: 15, color: Colors.grey)),
                ],
              ),
            ),
            Stack(
              children: [
                IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 30),
                    onPressed: () {}),
                const Positioned(
                    right: 10,
                    top: 10,
                    child:
                        CircleAvatar(radius: 5, backgroundColor: Colors.red)),
              ],
            ),
          ],
        ),
      );

  // ── 2 × 2 STAT GRID ───────────────────────────────────────────────
  Widget _statsGrid() => LayoutBuilder(
        builder: (context, constraints) {
          final bool tiny = constraints.maxWidth < 400;
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: tiny ? 1.35 : 1.55,
            children: [
              _bigStat(
                  icon: Icons.people_alt,
                  color: const Color(0xFF6EC1E4),
                  value: '1,284',
                  label: 'Total Patients'),
              _bigStat(
                  icon: Icons.local_hospital,
                  color: const Color(0xFF4CAF50),
                  value: '87',
                  label: 'Total Doctors'),
              _bigStat(
                  icon: Icons.supervisor_account,
                  color: const Color(0xFFFF9B9B),
                  value: '156',
                  label: 'Total Caregivers'),
              _bigStat(
                  icon: Icons.online_prediction,
                  color: const Color(0xFFD0A9F5),
                  value: '942',
                  label: 'Active Today'),
            ],
          );
        },
      );

  // ── SINGLE BIG STAT CARD ───────────────────────────────────────
  Widget _bigStat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: cardShadow, blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon bubble
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  // ── EXTRA ROW (Pending + Appointments) ─────────────────────────────
  Widget _extraRow() => Row(
        children: [
          Expanded(
            child: _smallStat(
                icon: Icons.hourglass_bottom,
                color: const Color(0xFFF4A261),
                value: '12',
                label: 'Pending\nApprovals'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _smallStat(
                icon: Icons.calendar_today,
                color: const Color(0xFF42A5F5),
                value: '68',
                label: 'Today\'s\nAppointments'),
          ),
        ],
      );

  // ── SMALL STAT CARD ───────────────────────────────────────────────
  Widget _smallStat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: cardShadow, blurRadius: 10, offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold)),
                  Text(label,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );

  // ── ADHERENCE CARD ───────────────────────────────────────────────
  Widget _adherenceCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: cardShadow, blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Avg. Medication Adherence',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                Text('84%',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32))),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 0.84,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Excellent! Keep it up',
                style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}