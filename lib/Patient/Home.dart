import 'package:flutter/material.dart';
import 'Medication.dart';
import 'Caregiver.dart';
import 'Appointment.dart';


// Optional: Create these screens later if not ready
// import 'Settings.dart';

class PatientHomePage extends StatelessWidget {
  const PatientHomePage({Key? key}) : super(key: key);

  // Bottom nav item with full navigation
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required BuildContext context,
    required int index,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          // Prevent unnecessary navigation if already on the same screen
          if (isActive) return;

          switch (index) {
            case 0: // Home - do nothing or reload
              break;
            case 1: // Medication
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PatientMedicationScreen()),
              );
              break;
            case 2: // Caregiver
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PatientCaregiverScreen()),
              );
              break;
            case 3: // Appointment
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AppointmentPage()),
              );
              break;
            case 4: // Settings (create this screen later)
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const Placeholder()), // Replace with PatientSettingsScreen()
              );
              break;
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
               color: isActive ? const Color(0xFFFF6B6B) : Colors.grey[400],
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? const Color(0xFFFF6B6B) : Colors.grey[400],
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Custom App Bar
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF9B9B),
                      Color(0xFFFFB5B5),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Greeting
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Patient',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Search Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey[400], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search medications, doctors...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            Icon(Icons.mic_none, color: Colors.grey[400], size: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Reminder Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFCFCF),
                          Color(0xFFFFE0E0),
                        ],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFF9B9B),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: const Icon(
                            Icons.alarm,
                            color: Color(0xFFFF6B6B),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Medication Reminder',
                                style: TextStyle(
                                  color: Color(0xFFD63031),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Get reminders for your pills',
                                style: TextStyle(
                                  color: Color(0xFFD63031),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFFD63031),
                          size: 18,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Section Header
                  Text(
                    'Medication Management',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Grid Cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [
                      _buildFeatureCard(
                        context: context,
                        icon: Icons.medication_outlined,
                        title: 'My Current\nMedication List',
                        color: const Color(0xFFFFCFCF),
                        iconColor: const Color(0xFFD63031),
                        iconBg: Colors.white,
                        destination: const PatientMedicationScreen(),
                      ),
                      _buildFeatureCard(
                        context: context,
                        icon: Icons.local_hospital_outlined,
                        title: 'My Assigned\nCaregiver Details',
                        color: const Color(0xFFD4C5F9),
                        iconColor: const Color(0xFF6C5CE7),
                        iconBg: Colors.white,
                        destination: const PatientCaregiverScreen(),
                      ),
                      _buildFeatureCard(
                        context: context,
                        icon: Icons.favorite_outline,
                        title: 'Daily Health and\nWellness Tips',
                        color: const Color(0xFFE8D4F8),
                        iconColor: const Color(0xFFA29BFE),
                        iconBg: Colors.white,
                      ),
                      _buildFeatureCard(
                        context: context,
                        icon: Icons.calendar_today_outlined,
                        title: 'Plan Your Next\nMedical Visit',
                        color: const Color(0xFFFFE6C7),
                        iconColor: const Color(0xFFE17055),
                        iconBg: Colors.white,
                        destination: const AppointmentPage(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar - FULLY FUNCTIONAL
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home,
                  label: 'Home',
                  isActive: true,
                  context: context,
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.medication,
                  label: 'Medication',
                  isActive: false,
                  context: context,
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.local_hospital,
                  label: 'Caregiver',
                  isActive: false,
                  context: context,
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.calendar_month,
                  label: 'Appointment',
                  isActive: false,
                  context: context,
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isActive: false,
                  context: context,
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Updated _buildFeatureCard with navigation
  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required Color iconColor,
    required Color iconBg,
    Widget? destination,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: destination != null
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => destination),
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Navigate to',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}