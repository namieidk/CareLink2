// lib/screens/Profile.dart
import 'package:flutter/material.dart';
import 'Home.dart';                 // CaregiverHomeScreen
import 'patient.dart';              // PatientsScreen
import 'caremed.dart';              // MedicationScreen
import 'calendar.dart';             // CalendarScreen
import 'Profile/addprofile.dart';  // ADD PROFILE SCREEN

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      profileData = args;
    }
  }

  void _goToAddProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProfileScreen()),
    );

    if (result is Map<String, dynamic>) {
      setState(() {
        profileData = result;
      });
      // Send updated data back to HomeScreen
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // === NO PROFILE YET ===
    if (profileData == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'No Profile Yet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete your profile to get started',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _goToAddProfile,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Create Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context, 4),
      );
    }

    // === FULL PROFILE VIEW ===
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C5CE7), Color(0xFF8B7FE8)],
                  ),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.grey[300],
                            ),
                            child: const Icon(Icons.person, size: 60, color: Colors.white),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profileData!['name'] ?? 'Caregiver',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Freelance Caregiver', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(
                      profileData!['bio'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatChip('4.9', 'Rating'),
                        _buildStatChip('127', 'Jobs Done'),
                        _buildStatChip('${profileData!['experienceYears'] ?? '0'} yrs', 'Experience'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionTitle('Freelance Details'),
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    icon: Icons.payments_outlined,
                    title: 'Hourly Rate',
                    value: '\$${profileData!['hourlyRate'] ?? '0'}/hour',
                    color: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Total Earnings',
                    value: '\$14,280',
                    color: const Color(0xFF42A5F5),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    icon: Icons.work_history_outlined,
                    title: 'Experience',
                    value: '${profileData!['experienceYears'] ?? '0'} years',
                    color: const Color(0xFFFFA726),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Certifications'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: (profileData!['certifications'] as List<dynamic>? ?? [])
                        .map<Widget>((cert) => _buildChip(cert, Icons.verified))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Skills & Services'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: (profileData!['skills'] as List<dynamic>? ?? [])
                        .map<Widget>((skill) => _buildServiceChip(skill))
                        .toList(),
                  ),
                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 4),
    );
  }

  // === HELPERS ===
  Widget _buildStatChip(String value, String label) => Column(children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))]);

  Widget _buildDetailCard({required IconData icon, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]));

  Widget _buildChip(String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: const Color(0xFF4CAF50)), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)))]),
      );

  Widget _buildServiceChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[300]!)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      );

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
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
          final screens = [
            const CaregiverHomeScreen(),
            const PatientsScreen(),
            const MedicationScreen(),
            const CalendarScreen(),
            ProfileScreen(),
          ];
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => screens[index]));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? const Color(0xFF6C5CE7) : Colors.grey[400], size: 26),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: isActive ? const Color(0xFF6C5CE7) : Colors.grey[400], fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}