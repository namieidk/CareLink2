import 'package:flutter/material.dart';
import 'Home.dart';
import 'Medication.dart';
import 'Appointment.dart';
import 'Profile.dart';

class Caregiver {
  final String name;
  final String photo;
  final String specialty;
  final int experience;
  final double rating;
  final int reviewCount;
  final String phone;
  final String email;
  final String location;
  final List<String> services;
  final String availability;
  final String workingHours;
  final double hourlyRate;
  final bool isVerified;

  Caregiver({
    required this.name,
    required this.photo,
    required this.specialty,
    required this.experience,
    required this.rating,
    required this.reviewCount,
    required this.phone,
    required this.email,
    required this.location,
    required this.services,
    required this.availability,
    required this.workingHours,
    required this.hourlyRate,
    required this.isVerified,
  });
}

class PatientCaregiverScreen extends StatefulWidget {
  const PatientCaregiverScreen({Key? key}) : super(key: key);
  @override
  State<PatientCaregiverScreen> createState() => _PatientCaregiverScreenState();
}

class _PatientCaregiverScreenState extends State<PatientCaregiverScreen> {
  // -------------------------------------------------
  //  UI data (replace with your real data later)
  // -------------------------------------------------
  bool _hasAssignedCaregiver = false;
  Caregiver? _selectedCaregiver;
  String _selectedLocation = 'All Locations';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _locations = [
    'All Locations', 'New York', 'Los Angeles', 'Chicago', 'Houston', 'Miami', 'Seattle',
  ];

  final List<Caregiver> _allCaregivers = [
    Caregiver(
      name: 'Maria Lopez',
      photo: '',
      specialty: 'Elderly Care Specialist',
      experience: 5,
      rating: 4.9,
      reviewCount: 48,
      phone: '+1 (555) 123-4567',
      email: 'maria.lopez@care.com',
      location: 'New York',
      services: ['Medication Management', 'Health Monitoring', 'Meal Prep', 'Companionship'],
      availability: 'Mon, Wed, Fri',
      workingHours: '8:00 AM - 5:00 PM',
      hourlyRate: 35.00,
      isVerified: true,
    ),
    Caregiver(
      name: 'James Carter',
      photo: '',
      specialty: 'Post-Surgery Care',
      experience: 8,
      rating: 4.7,
      reviewCount: 32,
      phone: '+1 (555) 987-6543',
      email: 'james.carter@care.com',
      location: 'Los Angeles',
      services: ['Wound Care', 'Physical Therapy', 'Daily Assistance'],
      availability: 'Tue, Thu, Sat',
      workingHours: '9:00 AM - 6:00 PM',
      hourlyRate: 42.00,
      isVerified: true,
    ),
    // Add more caregivers as needed …
  ];

  List<Caregiver> get _filteredCaregivers {
    return _allCaregivers.where((c) {
      final matchesLocation = _selectedLocation == 'All Locations' || c.location == _selectedLocation;
      final matchesSearch = _searchController.text.isEmpty ||
          c.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          c.specialty.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesLocation && matchesSearch;
    }).toList();
  }

  // -------------------------------------------------
  //  Bottom navigation (identical across all pages)
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
                    break;
                  case 3:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AppointmentPage()),
                    );
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
  //  UI – Header + Filters + List
  // -------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
                    'Find a Caregiver',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
                ],
              ),
            ),

            // ----- Search & Location -----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search caregiver…',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedLocation,
                    items: _locations
                        .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedLocation = val!),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down),
                    style: const TextStyle(color: Colors.black87),
                    dropdownColor: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ----- Caregiver List -----
            Expanded(
              child: _filteredCaregivers.isEmpty
                  ? const Center(child: Text('No caregivers found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredCaregivers.length,
                      itemBuilder: (context, i) {
                        final c = _filteredCaregivers[i];
                        return _caregiverCard(c);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 2), // Caregiver active
    );
  }

  // -------------------------------------------------
  //  Caregiver Card (you can expand this later)
  // -------------------------------------------------
  Widget _caregiverCard(Caregiver c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: primary.withOpacity(0.2),
              child: Text(
                c.name.split(' ').map((e) => e[0]).take(2).join(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Text(c.specialty, style: const TextStyle(color: Colors.grey)),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text('${c.rating} (${c.reviewCount} reviews)'),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showCaregiverDetails(c),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------
  //  Detail Bottom Sheet (placeholder – expand as needed)
  // -------------------------------------------------
  void _showCaregiverDetails(Caregiver c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 5, color: Colors.grey[300]),
              ),
              const SizedBox(height: 16),
              Text(c.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(c.specialty, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              _infoRow(Icons.phone, c.phone),
              _infoRow(Icons.email, c.email),
              _infoRow(Icons.location_on, c.location),
              _infoRow(Icons.access_time, '${c.availability} • ${c.workingHours}'),
              _infoRow(Icons.attach_money, '\$${c.hourlyRate}/hr'),
              const SizedBox(height: 12),
              const Text('Services', style: TextStyle(fontWeight: FontWeight.w600)),
              Wrap(
                spacing: 8,
                children: c.services
                    .map((s) => Chip(label: Text(s), backgroundColor: primary.withOpacity(0.1)))
                    .toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: booking logic
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Book Caregiver', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primary),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}