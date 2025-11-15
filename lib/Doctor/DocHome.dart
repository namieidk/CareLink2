import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorHomePage extends StatelessWidget {
  const DoctorHomePage({Key? key}) : super(key: key);

  // Soft pink theme (same as admin)
  static const Color primary = Color(0xFFFF8BA0);
  static const Color primaryLight = Color(0xFFFFD1DB);
  static const Color background = Color(0xFFF8F9FA);

  // Sample doctor data
  final String doctorName = "Dr. Sarah Johnson";
  final String specialty = "Cardiologist";
  final String hospital = "City Hospital";

  @override
  Widget build(BuildContext context) {
    final String currentTime = DateFormat('h:mm a').format(DateTime.now());
    final String greeting = _getGreeting();

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === PROFILE HEADER ===
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: primary,
                      child: Text(
                        _getInitials(doctorName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            specialty,
                            style: const TextStyle(
                              fontSize: 16,
                              color: primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hospital,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // === GREETING & TIME ===
              Text(
                "$greeting, Dr. Johnson!",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Today is ${DateFormat('EEEE, MMMM d').format(DateTime.now())}",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                "Current time: $currentTime",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 32),

              // === QUICK STATS CARDS ===
              const Text(
                "Today's Overview",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _statCard("Patients Today", "8", Icons.people, primaryLight)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard("Appointments", "12", Icons.event_available, primaryLight)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _statCard("Pending Reports", "3", Icons.description, Colors.orange.shade50)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard("Messages", "5", Icons.message, Colors.blue.shade50)),
                ],
              ),

              const SizedBox(height: 32),

              // === WELCOME MESSAGE ===
              Container(
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
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

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
    if (parts.length < 2) return "??";
    return '${parts[1][0]}${parts[2][0]}'.toUpperCase();
  }

  // Reusable stat card
  Widget _statCard(String title, String value, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}