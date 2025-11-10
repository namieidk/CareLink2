import 'package:flutter/material.dart';
import 'Home.dart';
import 'Medication.dart';
import 'Caregiver.dart';
import 'Profile.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({Key? key}) : super(key: key);
  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  // -------------------------------------------------
  //  Sample appointment data (replace with real data)
  // -------------------------------------------------
  final List<Map<String, dynamic>> _appointments = [
    {
      'id': 1,
      'doctor': 'Dr. Sarah Johnson',
      'specialty': 'Cardiologist',
      'date': '2025-11-14',
      'time': '10:30 AM',
      'type': 'In-Person',
      'status': 'Confirmed',
      'location': 'City Hospital, Room 204',
    },
    {
      'id': 2,
      'doctor': 'Dr. Michael Lee',
      'specialty': 'General Practitioner',
      'date': '2025-11-20',
      'time': '02:00 PM',
      'type': 'Video Call',
      'status': 'Pending',
      'location': 'Zoom Meeting',
    },
    // Add more …
  ];

  // -------------------------------------------------
  //  Bottom navigation (same as other pages)
  // -------------------------------------------------
  static const Color primary = Color(0xFFFF6B6B);
  static const Color muted = Colors.grey;

  Widget _buildBottomNav(BuildContext context, int activeIndex) {
    return Container(
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
            children: [
              _navItem(Icons.home, 'Home', activeIndex == 0, 0, context),
              _navItem(Icons.medication, 'Meds', activeIndex == 1, 1, context),
              _navItem(Icons.local_hospital, 'Caregiver', activeIndex == 2, 2, context),
              _navItem(Icons.calendar_today, 'Schedule', activeIndex == 3, 3, context),
              _navItem(Icons.person_outline, 'Profile', activeIndex == 4, 4, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, int index, BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: active
            ? null
            : () {
                switch (index) {
                  case 0:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientHomePage()),
                    );
                    break;
                  case 1:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientMedicationScreen()),
                    );
                    break;
                  case 2:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientCaregiverScreen()),
                    );
                    break;
                  case 3:
                    break;
                  case 4:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientProfileScreen()),
                    );
                    break;
                }
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? primary : muted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? primary : muted,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------
  //  UI
  // -------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ----- Header -----
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'My Appointments',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.add), onPressed: () => _showNewAppointmentDialog()),
                ],
              ),
            ),

            // ----- List -----
            Expanded(
              child: _appointments.isEmpty
                  ? const Center(child: Text('No appointments yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _appointments.length,
                      itemBuilder: (context, i) => _appointmentCard(_appointments[i]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewAppointmentDialog,
        backgroundColor: primary,
        icon: const Icon(Icons.add),
        label: const Text('Book Appointment'),
      ),
      bottomNavigationBar: _buildBottomNav(context, 3), // Schedule active
    );
  }

  // -------------------------------------------------
  //  Appointment Card
  // -------------------------------------------------
  Widget _appointmentCard(Map<String, dynamic> a) {
    final bool isConfirmed = a['status'] == 'Confirmed';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primary.withOpacity(0.15),
                  child: const Icon(Icons.person, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['doctor'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(a['specialty'], style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Chip(
                  label: Text(a['status'],
                      style: TextStyle(
                          color: isConfirmed ? Colors.green[700] : Colors.orange[700])),
                  backgroundColor: isConfirmed ? Colors.green[50] : Colors.orange[50],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.calendar_today, '${a['date']} • ${a['time']}'),
            _infoRow(Icons.location_on, a['location']),
            _infoRow(Icons.videocam, a['type']),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isConfirmed)
                  TextButton(onPressed: () {}, child: const Text('Reschedule')),
                TextButton(
                  onPressed: () => _showCancelDialog(a['id']),
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primary),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // -------------------------------------------------
  //  New Appointment Dialog (placeholder)
  // -------------------------------------------------
  void _showNewAppointmentDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Book New Appointment'),
        content: const Text('Booking UI goes here…'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }

  // -------------------------------------------------
  //  Cancel Confirmation
  // -------------------------------------------------
  void _showCancelDialog(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                setState(() => _appointments.removeWhere((a) => a['id'] == id));
                Navigator.pop(context);
              },
              child: const Text('Yes, Cancel')),
        ],
      ),
    );
  }
}