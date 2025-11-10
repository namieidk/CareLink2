import 'package:flutter/material.dart';
import 'Home.dart';
import 'Medication.dart';
import 'Caregiver.dart';
import 'Appointment.dart';
import 'Profile/EditProfile.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({Key? key}) : super(key: key);

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  // Tailwind-inspired + PINK THEME
  static const Color primary      = Color(0xFFFF6B6B);
  static const Color success      = Color(0xFF4CAF50);
  static const Color warning      = Color(0xFFFF9800);
  static const Color danger       = Color(0xFFE53935);
  static const Color bg           = Colors.white;
  static const Color card         = Colors.white;
  static const Color text         = Color(0xFF1F2937);
  static const Color textMuted    = Color(0xFF6B7280);
  static const Color border       = Color(0xFFE5E7EB);

  // Spacing
  static const double p  = 16.0;
  static const double p2 = 8.0;
  static const double p3 = 12.0;
  static const double p4 = 20.0;
  static const double p6 = 24.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Container(
              padding: const EdgeInsets.all(p4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFFE1BEE7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.orange,
                        child: Text(
                          'JD',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: p3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('John Doe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('70 years old', style: TextStyle(fontSize: 16, color: Colors.white70)),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: p2, vertical: p2 / 2),
                        decoration: BoxDecoration(
                          color: success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: success, size: 16),
                            const SizedBox(width: 4),
                            Text('Active', style: TextStyle(color: success, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PatientEditProfileScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: p6),

                  // Stats Cards
                  Row(
                    children: [
                      _statCard('Medications', '5', primary.withOpacity(0.2)),
                      const SizedBox(width: p3),
                      _statCard('Appointments', '2', primary.withOpacity(0.15)),
                      const SizedBox(width: p3),
                      _statCard('Years Active', '3', primary.withOpacity(0.1)),
                    ],
                  ),
                  const SizedBox(height: p6),

                  // Birth Date & Blood Type
                  Row(
                    children: [
                      _infoChip(Icons.calendar_today, 'Birth Date', 'March 15, 1955', primary),
                      const SizedBox(width: p3),
                      _infoChip(Icons.water_drop, 'Blood Type', 'O+', danger),
                    ],
                  ),
                ],
              ),
            ),

            // ================= SCROLLABLE CONTENT =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(p4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(Icons.person_outline, 'Contact Information'),
                    const SizedBox(height: p3),
                    _contactItem(Icons.phone, 'Phone Number', '(555) 123-4567', Colors.green),
                    const SizedBox(height: p2),
                    _contactItem(Icons.email, 'Email Address', 'john.doe@email.com', Colors.blue),
                    const SizedBox(height: p2),
                    _contactItem(Icons.location_on, 'Home Address', '123 Main Street, Springfield,\nIL 62701', danger),

                    const SizedBox(height: p6),

                    _sectionHeader(Icons.favorite, 'Medical Profile'),
                    const SizedBox(height: p3),

                    // Allergies
                    Container(
                      padding: const EdgeInsets.all(p3),
                      decoration: BoxDecoration(
                        color: warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: warning.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber, color: warning),
                              const SizedBox(width: p2),
                              Text('Allergies', style: TextStyle(fontWeight: FontWeight.bold, color: text)),
                              Text(' Important to know', style: TextStyle(color: textMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: p2),
                          _allergyItem('Penicillin'),
                          const SizedBox(height: p2),
                          _allergyItem('Peanuts'),
                          const SizedBox(height: p2),
                          _allergyItem('Latex'),
                        ],
                      ),
                    ),

                    const SizedBox(height: p4),

                    // Conditions
                    Container(
                      padding: const EdgeInsets.all(p3),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description, color: primary),
                              const SizedBox(width: p2),
                              Text('Conditions', style: TextStyle(fontWeight: FontWeight.bold, color: text)),
                              Text(' Active diagnoses', style: TextStyle(color: textMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: p2),
                          _conditionItem('Hypertension'),
                          const SizedBox(height: p2),
                          _conditionItem('Type 2 Diabetes'),
                          const SizedBox(height: p2),
                          _conditionItem('High Cholesterol'),
                        ],
                      ),
                    ),

                    const SizedBox(height: p6),

                    _sectionHeader(Icons.health_and_safety, 'Insurance Coverage'),
                    const SizedBox(height: p3),
                    Container(
                      padding: const EdgeInsets.all(p3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFFE1BEE7)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield, color: Colors.white),
                              const SizedBox(width: p2),
                              Text('Insurance Coverage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Text('Active policy', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: p2),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(p3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Medicare Plan A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                Text('****-****-1234', style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: p6),

                    _sectionHeader(Icons.phone_in_talk, 'Emergency Contacts'),
                    const SizedBox(height: p3),
                    Container(
                      padding: const EdgeInsets.all(p3),
                      decoration: BoxDecoration(
                        color: danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: danger.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.phone, color: danger),
                              const SizedBox(width: p2),
                              Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold, color: text)),
                              Text(' Quick access to family', style: TextStyle(color: textMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: p2),
                          _emergencyContact('Jane Doe', 'Daughter', '(555) 234-5678', primary),
                          const SizedBox(height: p3),
                          _emergencyContact('Robert Doe', 'Son', '(555) 345-6789', Colors.blue),
                        ],
                      ),
                    ),

                    const SizedBox(height: p6),

                    _sectionHeader(Icons.notifications, 'Notification Settings'),
                    const SizedBox(height: p3),
                    _toggleItem('All Notifications', 'Master toggle for all alerts', true),
                    const SizedBox(height: p2),
                    _toggleItem('Medication Reminders', 'Never miss your medicine', true),
                    const SizedBox(height: p2),
                    _toggleItem('Appointment Reminders', 'Stay on top of visits', true),

                    const SizedBox(height: p6),

                    _sectionHeader(Icons.settings, 'More Options'),
                    const SizedBox(height: p3),
                    _menuItem(Icons.privacy_tip, 'Privacy & Security', primary),
                    const SizedBox(height: p2),
                    _menuItem(Icons.folder_open, 'Medical Records', Colors.purple),
                    const SizedBox(height: p2),
                    _menuItem(Icons.volume_up, 'Sound & Alerts', Colors.orange),

                    const SizedBox(height: p6),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.logout, color: danger),
                        label: Text('Sign Out', style: TextStyle(color: danger, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: danger),
                          padding: EdgeInsets.symmetric(vertical: p3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ================= BOTTOM NAVIGATION =================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: card,
          border: Border(top: BorderSide(color: border)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -1))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: p2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home, 'Home', false, 0),
                _navItem(Icons.medication, 'Meds', false, 1),
                _navItem(Icons.local_hospital, 'Caregiver', false, 2),
                _navItem(Icons.calendar_today, 'Schedule', false, 3),
                _navItem(Icons.person, 'Profile', true, 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= NAV ITEM =================
  Widget _navItem(IconData icon, String label, bool active, int index) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (active) return;
          switch (index) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientHomePage()));
              break;
            case 1:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientMedicationScreen()));
              break;
            case 2:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientCaregiverScreen()));
              break;
            case 3:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppointmentPage()));
              break;
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: active ? primary : textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active ? primary : textMuted,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPERS (unchanged) =================
  Widget _statCard(String label, String value, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(p3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(p2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: p2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: text, size: 20),
        const SizedBox(width: p2),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: text)),
      ],
    );
  }

  Widget _contactItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(p3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: p2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: textMuted, fontSize: 12)),
                Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: text)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _allergyItem(String allergy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: p3, vertical: p2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: warning, size: 18),
          const SizedBox(width: p2),
          Text(allergy, style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _conditionItem(String condition) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: p3, vertical: p2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Text(condition, style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _emergencyContact(String name, String relation, String phone, Color color) {
    return Container(
      padding: const EdgeInsets.all(p3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color,
            child: Text(name[0] + relation[0], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: p3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(relation, style: TextStyle(color: textMuted)),
                Text(phone, style: TextStyle(color: textMuted)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.symmetric(horizontal: p3, vertical: p2),
            ),
            child: Text('Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _toggleItem(String title, String subtitle, bool value) {
    return Container(
      padding: const EdgeInsets.all(p3),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: (val) {}, activeColor: primary),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right, color: textMuted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: card,
      onTap: () {},
    );
  }
}