import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// Import other doctor screens
import 'DocHome.dart';
import 'DoctorPatients.dart';
import 'DoctorProfile.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({Key? key}) : super(key: key);

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  // Blue theme for doctor
  static const Color primary = Color(0xFF4A90E2);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color secondary = Color(0xFF64B5F6);
  static const Color accent = Color(0xFF1976D2);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color muted = Colors.grey;
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardShadow = Color(0x12000000);

  // Calendar and schedule variables
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  
  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sample appointment data
  final List<Appointment> _appointments = [
    Appointment(
      id: '1',
      patientName: 'John Smith',
      patientId: 'p1',
      date: DateTime.now().add(const Duration(hours: 2)),
      duration: 30,
      type: 'Follow-up',
      status: 'Scheduled',
      notes: 'Regular checkup for hypertension',
    ),
    Appointment(
      id: '2',
      patientName: 'Mary Johnson',
      patientId: 'p2',
      date: DateTime.now().add(const Duration(hours: 3)),
      duration: 45,
      type: 'Consultation',
      status: 'Scheduled',
      notes: 'Diabetes management review',
    ),
    Appointment(
      id: '3',
      patientName: 'Robert Brown',
      patientId: 'p3',
      date: DateTime.now().add(const Duration(days: 1, hours: 10)),
      duration: 30,
      type: 'Follow-up',
      status: 'Scheduled',
      notes: 'Arthritis treatment follow-up',
    ),
    Appointment(
      id: '4',
      patientName: 'Sarah Davis',
      patientId: 'p4',
      date: DateTime.now().add(const Duration(days: 1, hours: 14)),
      duration: 60,
      type: 'Initial Consultation',
      status: 'Scheduled',
      notes: 'New patient with heart condition',
    ),
    Appointment(
      id: '5',
      patientName: 'Michael Wilson',
      patientId: 'p5',
      date: DateTime.now().add(const Duration(days: 2, hours: 11)),
      duration: 30,
      type: 'Follow-up',
      status: 'Scheduled',
      notes: 'Asthma control assessment',
    ),
    Appointment(
      id: '6',
      patientName: 'Lisa Anderson',
      patientId: 'p6',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      duration: 30,
      type: 'Follow-up',
      status: 'Completed',
      notes: 'Completed - Blood pressure normal',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  List<Appointment> get _selectedDayAppointments {
    if (_selectedDay == null) return [];
    
    return _appointments.where((appointment) {
      return isSameDay(appointment.date, _selectedDay);
    }).toList();
  }

  List<Appointment> get _todayAppointments {
    return _appointments.where((appointment) {
      return isSameDay(appointment.date, DateTime.now());
    }).toList();
  }

  // BOTTOM NAVIGATION
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
                _navItem(Icons.people_alt, 'Patient', active == 1, 1, context),
                _navItem(Icons.schedule, 'Schedule', active == 2, 2, context),
                _navItem(Icons.person_outline, 'Profile', active == 3, 3, context),
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
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => const DoctorHomePage()),
                    );
                    break;
                  case 1:
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => const DoctorPatientsScreen()),
                    );
                    break;
                  case 2:
                    // Already on schedule, do nothing
                    break;
                  case 3:
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => const DoctorProfileScreen()),
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
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            _header(),

            // CALENDAR SECTION
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // CALENDAR
                    _calendarSection(),

                    // APPOINTMENTS LIST
                    _appointmentsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(context, 2),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAppointment,
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // HEADER
  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorHomePage()),
                );
              },
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Schedule',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Manage your appointments',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.today, color: Colors.black87),
              onPressed: _goToToday,
            ),
          ],
        ),
      );

  // CALENDAR SECTION
  Widget _calendarSection() => Card(
        margin: const EdgeInsets.all(16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // TODAY'S SUMMARY
              _todaySummary(),
              const SizedBox(height: 16),
              
              // CALENDAR
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                
                // Calendar styling
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  formatButtonTextStyle: const TextStyle(color: Colors.white),
                ),
                
                // Event markers for days with appointments
                eventLoader: (day) {
                  return _appointments.where((appointment) {
                    return isSameDay(appointment.date, day);
                  }).toList();
                },
              ),
            ],
          ),
        ),
      );

  // TODAY'S SUMMARY
  Widget _todaySummary() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.today, color: primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Appointments",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_todayAppointments.length} appointments scheduled',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _todayAppointments.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

  // APPOINTMENTS SECTION
  Widget _appointmentsSection() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDay != null && isSameDay(_selectedDay, DateTime.now())
                      ? "Today's Appointments"
                      : "Appointments for ${DateFormat('MMM d, yyyy').format(_selectedDay!)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${_selectedDayAppointments.length} appointments',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // APPOINTMENTS LIST
            _selectedDayAppointments.isEmpty
                ? _emptyAppointments()
                : Column(
                    children: _selectedDayAppointments
                        .map((appointment) => _appointmentCard(appointment))
                        .toList(),
                  ),
            
            const SizedBox(height: 20),
          ],
        ),
      );

  // EMPTY APPOINTMENTS STATE
  Widget _emptyAppointments() => Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.event_available, size: 64, color: muted),
            const SizedBox(height: 16),
            Text(
              'No appointments scheduled',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDay != null && isSameDay(_selectedDay, DateTime.now())
                  ? 'Enjoy your free time today!'
                  : 'No appointments for this date',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addNewAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
              ),
              child: const Text(
                'Schedule Appointment',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

  // APPOINTMENT CARD
  Widget _appointmentCard(Appointment appointment) {
    Color statusColor;
    IconData statusIcon;
    
    switch (appointment.status.toLowerCase()) {
      case 'completed':
        statusColor = success;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'scheduled':
      default:
        statusColor = appointment.date.isBefore(DateTime.now()) 
            ? warning 
            : info;
        statusIcon = appointment.date.isBefore(DateTime.now())
            ? Icons.watch_later
            : Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER WITH TIME AND STATUS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('h:mm a').format(appointment.date),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        appointment.status,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // PATIENT INFO
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.1),
                  radius: 20,
                  child: Text(
                    _getInitials(appointment.patientName),
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${appointment.type} • ${appointment.duration} mins',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // NOTES
            if (appointment.notes.isNotEmpty) ...[
              const Divider(height: 16),
              Text(
                appointment.notes,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // ACTIONS
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (appointment.status == 'Scheduled' && 
                    appointment.date.isAfter(DateTime.now())) 
                  TextButton(
                    onPressed: () => _cancelAppointment(appointment),
                    child: const Text('Cancel'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _viewAppointmentDetails(appointment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // HELPER METHODS
  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length < 2) return name.substring(0, 2).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _addNewAppointment() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Schedule New Appointment'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('This feature will allow you to schedule new appointments.'),
              SizedBox(height: 16),
              Text('In a full implementation, this would open a form to select patient, date, time, and type.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Schedule appointment functionality coming soon!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _viewAppointmentDetails(Appointment appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailScreen(appointment: appointment),
      ),
    );
  }

  void _cancelAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Appointment'),
          content: Text('Are you sure you want to cancel the appointment with ${appointment.patientName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // In real app, update in database
                  _appointments.removeWhere((a) => a.id == appointment.id);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Appointment with ${appointment.patientName} cancelled'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Cancel Appointment'),
            ),
          ],
        );
      },
    );
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
    });
  }
}

// APPOINTMENT MODEL
class Appointment {
  final String id;
  final String patientName;
  final String patientId;
  final DateTime date;
  final int duration;
  final String type;
  final String status;
  final String notes;

  Appointment({
    required this.id,
    required this.patientName,
    required this.patientId,
    required this.date,
    required this.duration,
    required this.type,
    required this.status,
    required this.notes,
  });
}

// APPOINTMENT DETAIL SCREEN (Placeholder)
class AppointmentDetailScreen extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({Key? key, required this.appointment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF4A90E2).withOpacity(0.1),
                      radius: 40,
                      child: Text(
                        appointment.patientName.split(' ').map((n) => n[0]).join(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      appointment.patientName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(appointment.date),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Appointment details screen would show comprehensive information including:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text('• Patient medical history'),
            const Text('• Previous appointments'),
            const Text('• Treatment notes'),
            const Text('• Prescription history'),
            const Text('• Lab results'),
          ],
        ),
      ),
    );
  }
}