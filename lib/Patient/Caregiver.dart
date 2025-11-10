import 'package:flutter/material.dart';
import 'Medication.dart';
import 'Appointment.dart';
import 'Home.dart';
import 'Caregiver/message.dart'; // MessageScreen is here

// -----------------------------------------------------------------------------
// Caregiver Model
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
// PatientCaregiverScreen
// -----------------------------------------------------------------------------
class PatientCaregiverScreen extends StatefulWidget {
  const PatientCaregiverScreen({Key? key}) : super(key: key);

  @override
  State<PatientCaregiverScreen> createState() => _PatientCaregiverScreenState();
}

class _PatientCaregiverScreenState extends State<PatientCaregiverScreen> {
  bool _hasAssignedCaregiver = false;
  Caregiver? _selectedCaregiver;
  String _selectedLocation = 'All Locations';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _locations = [
    'All Locations',
    'New York',
    'Los Angeles',
    'Chicago',
    'Houston',
    'Miami',
    'Seattle',
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
      specialty: 'Diabetes Care Expert',
      experience: 8,
      rating: 4.8,
      reviewCount: 62,
      phone: '+1 (555) 987-6543',
      email: 'james.carter@care.com',
      location: 'Los Angeles',
      services: ['Glucose Monitoring', 'Diet Planning', 'Exercise Support', 'Insulin Admin'],
      availability: 'Tue, Thu, Sat',
      workingHours: '7:00 AM - 4:00 PM',
      hourlyRate: 42.00,
      isVerified: true,
    ),
    Caregiver(
      name: 'Sarah Johnson',
      photo: '',
      specialty: 'Cardiology Nurse',
      experience: 6,
      rating: 4.7,
      reviewCount: 35,
      phone: '+1 (555) 456-7890',
      email: 'sarah.j@care.com',
      location: 'Chicago',
      services: ['Heart Monitoring', 'BP Management', 'Medication Support', 'Emergency Response'],
      availability: 'Mon, Tue, Wed',
      workingHours: '9:00 AM - 6:00 PM',
      hourlyRate: 38.00,
      isVerified: true,
    ),
    Caregiver(
      name: 'Michael Chen',
      photo: '',
      specialty: 'Physical Therapy Assistant',
      experience: 4,
      rating: 4.6,
      reviewCount: 28,
      phone: '+1 (555) 321-0987',
      email: 'michael.chen@care.com',
      location: 'Miami',
      services: ['Mobility Training', 'Pain Relief', 'Rehab Exercises', 'Fall Prevention'],
      availability: 'Wed, Thu, Fri',
      workingHours: '10:00 AM - 7:00 PM',
      hourlyRate: 32.00,
      isVerified: true,
    ),
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

  // -------------------------------------------------------------------------
  // Bottom navigation item
  // -------------------------------------------------------------------------
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required int index,
  }) {
    final Color primary = const Color(0xFFFF6B6B);
    return Expanded(
      child: InkWell(
        onTap: isActive
            ? null
            : () {
                switch (index) {
                  case 0:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientHomePage()));
                    break;
                  case 1:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientMedicationScreen()));
                    break;
                  case 3:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppointmentPage()));
                    break;
                  case 4:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Placeholder()));
                    break;
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? primary : Colors.grey[400], size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? primary : Colors.grey[400],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Bottom-sheet detail view
  // -------------------------------------------------------------------------
  void _showCaregiverDetails(Caregiver caregiver) {
    final Color primary = const Color(0xFFFF6B6B);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFFFF8A80), Color(0xFFFF6B6B)]),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, size: 56, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(caregiver.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                                if (caregiver.isVerified)
                                  const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.verified, color: Color(0xFF4CAF50), size: 26)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(caregiver.specialty, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, color: Color(0xFFFFA726), size: 22),
                                const SizedBox(width: 6),
                                Text('${caregiver.rating} (${caregiver.reviewCount} reviews)',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Rate & Hours
                      Row(
                        children: [
                          Expanded(child: _buildInfoCard(Icons.attach_money, 'Hourly Rate', '\$${caregiver.hourlyRate.toStringAsFixed(0)}', primary)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildInfoCard(Icons.access_time, 'Working Hours', caregiver.workingHours, const Color(0xFF42A5F5))),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Contact
                      const Text('Contact Information', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.phone, caregiver.phone, primary),
                      const SizedBox(height: 10),
                      _buildDetailRow(Icons.email, caregiver.email, primary),
                      const SizedBox(height: 10),
                      _buildDetailRow(Icons.location_on, caregiver.location, primary),
                      const SizedBox(height: 28),
                      // Availability
                      const Text('Availability', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 12),
                      _buildAvailabilityChip(caregiver.availability, primary),
                      const SizedBox(height: 28),
                      // Services
                      const Text('Services Offered', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: caregiver.services
                            .map((s) => Chip(
                                  label: Text(s, style: const TextStyle(fontSize: 13, color: Colors.white)),
                                  backgroundColor: primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 32),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context); // Close bottom sheet
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MessageScreen(
                                      caregiverName: caregiver.name,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.message, size: 18),
                              label: const Text('Message', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primary,
                                side: BorderSide(color: primary, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  _hasAssignedCaregiver = true;
                                  _selectedCaregiver = caregiver;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${caregiver.name} is now your caregiver!'),
                                    backgroundColor: const Color(0xFF4CAF50),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Assign Caregiver', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helper widgets
  // -------------------------------------------------------------------------
  Widget _buildInfoCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, Color primary) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: primary),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87))),
      ],
    );
  }

  Widget _buildAvailabilityChip(String text, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: primary, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFFFF6B6B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header + Filters
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFBFC),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 3))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientHomePage())),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFF5F6F7), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.arrow_back, size: 22),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Find a Caregiver', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Text('Trusted professionals near you', style: TextStyle(fontSize: 15, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedLocation,
                          decoration: InputDecoration(
                            labelText: 'Location',
                            prefixIcon: Icon(Icons.location_on, color: primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: _locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                          onChanged: (val) => setState(() => _selectedLocation = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search name or specialty...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Caregiver list – WHITE CARDS
            Expanded(
              child: _filteredCaregivers.isEmpty
                  ? const Center(child: Text('No caregivers found.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredCaregivers.length,
                      itemBuilder: (_, i) {
                        final c = _filteredCaregivers[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 18),
                          color: Colors.white,
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 76,
                                      height: 76,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(colors: [Color(0xFFFF8A80), Color(0xFFFF6B6B)]),
                                        borderRadius: BorderRadius.all(Radius.circular(16)),
                                      ),
                                      child: const Icon(Icons.person, size: 38, color: Colors.white),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(child: Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))),
                                              if (c.isVerified) const Icon(Icons.verified, color: Color(0xFF4CAF50), size: 22),
                                            ],
                                          ),
                                          Text(c.specialty, style: const TextStyle(color: Colors.black54)),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, size: 17, color: Color(0xFFFFA726)),
                                              Text(' ${c.rating} (${c.reviewCount})', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                                              const Spacer(),
                                              Text('\$${c.hourlyRate}/hr',
                                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 32),
                                Row(
                                  children: [
                                    _buildTag(Icons.location_on, c.location, primary),
                                    const SizedBox(width: 12),
                                    _buildTag(Icons.access_time, c.workingHours, primary),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MessageScreen(
                                                caregiverName: c.name,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.message),
                                        label: const Text('Message'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showCaregiverDetails(c),
                                        icon: const Icon(Icons.arrow_forward),
                                        label: const Text('View Details'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // Bottom navigation
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAFBFC),
          border: Border(top: BorderSide(color: Color(0xFFE8EAED))),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _buildNavItem(icon: Icons.home, label: 'Home', isActive: false, index: 0),
                _buildNavItem(icon: Icons.medication, label: 'Medication', isActive: false, index: 1),
                _buildNavItem(icon: Icons.local_hospital, label: 'Caregiver', isActive: true, index: 2),
                _buildNavItem(icon: Icons.calendar_month, label: 'Appointment', isActive: false, index: 3),
                _buildNavItem(icon: Icons.settings, label: 'Settings', isActive: false, index: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}