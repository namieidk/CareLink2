// lib/screens/Profile/PatientProfileScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Home.dart';
import 'Medication.dart';
import 'Caregiver.dart';
import 'doctor.dart';
import 'Profile/EditProfile.dart';
import '../../models/patient_profile.dart';
import '../Signin/up/Signin.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({Key? key}) : super(key: key);
  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  // Updated color scheme with pink Color(0xFFE91E63)
  static const Color primary = Color(0xFFE91E63);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFE53935);
  static const Color bg = Colors.white;
  static const Color card = Colors.white;
  static const Color text = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  // Spacing
  static const double p2 = 8.0;
  static const double p3 = 12.0;
  static const double p4 = 20.0;
  static const double p6 = 24.0;

  PatientProfile? profile;
  bool isLoading = true;
  
  // Toggle states
  bool allNotifications = true;
  bool medicationReminders = true;
  bool appointmentReminders = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadNotificationSettings();
  }

  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('patient_profiles')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        profile = PatientProfile.fromMap(doc.data()!, doc.id);
      }
      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('notification_settings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          allNotifications = doc.data()!['allNotifications'] ?? true;
          medicationReminders = doc.data()!['medicationReminders'] ?? true;
          appointmentReminders = doc.data()!['appointmentReminders'] ?? true;
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  Future<void> _saveNotificationSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('notification_settings')
          .doc(user.uid)
          .set({
        'allNotifications': allNotifications,
        'medicationReminders': medicationReminders,
        'appointmentReminders': appointmentReminders,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving notification settings: $e');
    }
  }

  void _goToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PatientEditProfileScreen()),
    );
    if (result == true) {
      setState(() => isLoading = true);
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profile == null) {
      return _buildEmptyProfile();
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Container(
              padding: const EdgeInsets.all(p4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEC407A), Color(0xFFF8BBD0)],
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
                        backgroundImage: profile!.profilePhotoUrl != null
                            ? NetworkImage(profile!.profilePhotoUrl!)
                            : null,
                        child: profile!.profilePhotoUrl == null
                            ? Text(
                                profile!.fullName.isNotEmpty
                                    ? profile!.fullName.split(' ').map((e) => e[0]).take(2).join()
                                    : 'JD',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: p3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile!.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('${profile!.age} years old', style: const TextStyle(fontSize: 16, color: Colors.white70)),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: p2, vertical: p2 / 2),
                        decoration: BoxDecoration(color: success.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle, color: success, size: 16),
                            SizedBox(width: 4),
                            Text('Active', style: TextStyle(color: success, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _goToEdit,
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
                      _infoChip(Icons.water_drop, 'Blood Type', profile!.bloodType, danger),
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
                    _contactItem(Icons.phone, 'Phone Number', profile!.phone, Colors.green),
                    const SizedBox(height: p2),
                    _contactItem(Icons.email, 'Email Address', profile!.email, Colors.blue),
                    const SizedBox(height: p2),
                    _contactItem(Icons.location_on, 'Home Address', profile!.address, danger),

                    const SizedBox(height: p6),

                    _sectionHeader(Icons.favorite, 'Medical Profile'),
                    const SizedBox(height: p3),

                    // Allergies
                    Container(
                      padding: const EdgeInsets.all(p3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: warning.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.warning_amber, color: warning),
                              SizedBox(width: p2),
                              Text('Allergies', style: TextStyle(fontWeight: FontWeight.bold, color: text)),
                              Text(' Important to know', style: TextStyle(color: textMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: p2),
                          ...profile!.allergies.isEmpty
                              ? [const Text('No allergies recorded', style: TextStyle(color: textMuted))]
                              : profile!.allergies.map((a) => _allergyItem(a)).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: p4),

                    // Conditions
                    Container(
                      padding: const EdgeInsets.all(p3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.description, color: primary),
                              SizedBox(width: p2),
                              Text('Conditions', style: TextStyle(fontWeight: FontWeight.bold, color: text)),
                              Text(' Active diagnoses', style: TextStyle(color: textMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: p2),
                          ...profile!.conditions.isEmpty
                              ? [const Text('No conditions recorded', style: TextStyle(color: textMuted))]
                              : profile!.conditions.map((c) => _conditionItem(c)).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: p6),

                    _sectionHeader(Icons.health_and_safety, 'Insurance Coverage'),
                    const SizedBox(height: p3),
                    Container(
                      padding: const EdgeInsets.all(p3),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFEC407A), Color(0xFFF8BBD0)]),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.shield, color: Colors.white),
                              SizedBox(width: p2),
                              Text('Insurance Coverage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Text('Active policy', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                              children: const [
                                Text('Medicare Plan A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                Text('****-****-1234', style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: p6),

                    // ================= EMERGENCY CONTACTS (REAL DATA) =================
                    _sectionHeader(Icons.phone_in_talk, 'Emergency Contacts'),
                    const SizedBox(height: p3),
                    Container(
                      padding: const EdgeInsets.all(p3),
                      decoration: BoxDecoration(
                        color: Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFF90CAF9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.phone, color: Color(0xFF1976D2)),
                              SizedBox(width: p2),
                              Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold, color: text)),
                              Text(' Quick access to family', style: TextStyle(color: textMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: p2),
                          if (profile!.emergencyContacts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('No emergency contacts added', style: TextStyle(color: textMuted)),
                            )
                          else
                            ...profile!.emergencyContacts.map((contact) {
                              final color = _getContactColor(contact.relation);
                              return _emergencyContact(
                                contact.name,
                                contact.relation,
                                contact.phone,
                                color,
                              );
                            }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: p6),

                    _sectionHeader(Icons.notifications, 'Notification Settings'),
                    const SizedBox(height: p3),
                    _toggleItem(
                      'All Notifications', 
                      'Master toggle for all alerts', 
                      allNotifications, 
                      (value) {
                        setState(() {
                          allNotifications = value;
                          // If turning off all notifications, turn off individual ones too
                          if (!value) {
                            medicationReminders = false;
                            appointmentReminders = false;
                          }
                        });
                        _saveNotificationSettings();
                      }
                    ),
                    const SizedBox(height: p2),
                    _toggleItem(
                      'Medication Reminders', 
                      'Never miss your medicine', 
                      medicationReminders, 
                      (value) {
                        setState(() {
                          medicationReminders = value;
                          // If turning on medication reminders, ensure all notifications is on
                          if (value && !allNotifications) {
                            allNotifications = true;
                          }
                        });
                        _saveNotificationSettings();
                      }
                    ),
                    const SizedBox(height: p2),
                    _toggleItem(
                      'Appointment Reminders', 
                      'Stay on top of visits', 
                      appointmentReminders, 
                      (value) {
                        setState(() {
                          appointmentReminders = value;
                          // If turning on appointment reminders, ensure all notifications is on
                          if (value && !allNotifications) {
                            allNotifications = true;
                          }
                        });
                        _saveNotificationSettings();
                      }
                    ),

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
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const SignInScreen()),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout, color: danger),
                        label: const Text('Sign Out', style: TextStyle(color: danger, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: danger),
                          padding: const EdgeInsets.symmetric(vertical: p3),
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
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -1))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: p2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_outlined, 'Home', false, 0),
                _navItem(Icons.medical_services_outlined, 'Meds', false, 1),
                _navItem(Icons.people_alt_outlined, 'Caregiver', false, 2),
                _navItem(Icons.calendar_today, 'Schedule', false, 3),
                _navItem(Icons.person_outline, 'Profile', true, 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= EMPTY PROFILE =================
  Widget _buildEmptyProfile() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No Profile Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _goToEdit,
              icon: const Icon(Icons.edit),
              label: const Text('Create Profile'),
            ),
          ],
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
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DoctorPage())); 
              break;
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: active ? primary : textMuted),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: active ? primary : textMuted, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPERS =================
  Widget _statCard(String label, String value, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(p3),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(p2),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: p2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
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
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: text)),
      ],
    );
  }

  Widget _contactItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(p3),
      decoration: BoxDecoration(
        color: Colors.white,
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
                Text(label, style: const TextStyle(color: textMuted, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: text)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _allergyItem(String allergy) {
    return Container(
      margin: const EdgeInsets.only(bottom: p2),
      padding: const EdgeInsets.symmetric(horizontal: p3, vertical: p2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: warning, size: 18),
          const SizedBox(width: p2),
          Text(allergy, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _conditionItem(String condition) {
    return Container(
      margin: const EdgeInsets.only(bottom: p2),
      padding: const EdgeInsets.symmetric(horizontal: p3, vertical: p2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Text(condition, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  // ================= DYNAMIC EMERGENCY CONTACT (REAL DATA) =================
  Color _getContactColor(String relation) {
    final lower = relation.toLowerCase();
    if (lower.contains('daughter') || lower.contains('sister')) return Colors.pink;
    if (lower.contains('son') || lower.contains('brother')) return Colors.blue;
    if (lower.contains('spouse') || lower.contains('wife') || lower.contains('husband')) return Colors.purple;
    if (lower.contains('parent') || lower.contains('mother') || lower.contains('father')) return Colors.green;
    if (lower.contains('friend')) return Colors.orange;
    return primary;
  }

  Widget _emergencyContact(String name, String relation, String phone, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: p3),
      padding: const EdgeInsets.all(p3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: p3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(relation, style: const TextStyle(color: textMuted)),
                Text(phone, style: const TextStyle(color: textMuted)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Optional: Add call functionality
              // launchUrl(Uri(scheme: 'tel', path: phone));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: p3, vertical: p2),
            ),
            child: const Text('Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ================= UPDATED TOGGLE ITEM WITH FUNCTIONALITY =================
  Widget _toggleItem(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: p2),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primary,
            activeTrackColor: primary.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: textMuted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: card,
      onTap: () {},
    );
  }
}