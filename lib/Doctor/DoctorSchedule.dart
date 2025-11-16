import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// Import other screens
import 'DocHome.dart';
import 'DoctorPatients.dart';
import 'DoctorProfile.dart';
import '../models/doctor_schedule.dart'; // Your NEW date-based model

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({Key? key}) : super(key: key);

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  // ──────────────────────────────────────────────────────────────
  // Theme
  // ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF4A90E2);
  static const Color accent = Color(0xFF1976D2);
  static const Color muted = Colors.grey;
  static const Color background = Color(0xFFF8F9FA);

  // ──────────────────────────────────────────────────────────────
  // Calendar state
  // ──────────────────────────────────────────────────────────────
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  // ──────────────────────────────────────────────────────────────
  // Data
  // ──────────────────────────────────────────────────────────────
  String? _doctorId;
  DoctorSchedule? _doctorSchedule;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _initializeDoctor();
  }

  // ──────────────────────────────────────────────────────────────
  // Init
  // ──────────────────────────────────────────────────────────────
  Future<void> _initializeDoctor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    _doctorId = user.uid;
    await _loadDoctorSchedule();
  }

  Future<void> _loadDoctorSchedule() async {
    if (_doctorId == null) return;

    try {
      setState(() => _isLoading = true);

      final doc = await FirebaseFirestore.instance
          .collection('doctor_schedules')
          .doc(_doctorId)
          .get();

      if (doc.exists) {
        setState(() {
          _doctorSchedule = DoctorSchedule.fromFirestore(doc);
          _isLoading = false;
        });
      } else {
        await _createInitialSchedule();
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createInitialSchedule() async {
    if (_doctorId == null) return;

    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('doctor_profiles')
          .doc(_doctorId)
          .get();

      final doctorName = profileDoc.exists
          ? (profileDoc.data()?['fullName'] ?? 'Doctor')
          : 'Doctor';

      // Generate 30 days of schedule (Mon-Fri, 9-5)
      final start = DateTime.now();
      final end = start.add(const Duration(days: 30));
      final timeSlots = DateScheduleGenerator.generateTimeSlots(9, 17);

      final scheduleMap = DateScheduleGenerator.generateScheduleForDateRange(
        start,
        end,
        timeSlots,
        excludeWeekdays: [6, 7], // No Sat/Sun
      );

      final schedule = DoctorSchedule(
        id: _doctorId!,
        doctorName: doctorName,
        schedule: scheduleMap,
        bookings: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('doctor_schedules')
          .doc(_doctorId)
          .set(schedule.toMap());

      setState(() {
        _doctorSchedule = schedule;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error creating schedule: $e');
      setState(() => _isLoading = false);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────
  String _formatDate(DateTime date) => DoctorSchedule.dateToString(date);

  List<Booking> _getUpcomingBookingsForDate(DateTime date) {
    if (_doctorSchedule == null) return [];

    final allBookings = _doctorSchedule!.getBookingDetailsForDate(date);
    final now = DateTime.now();
    final targetDate = DateTime(date.year, date.month, date.day);

    return allBookings.where((b) {
      final parts = b.timeSlot.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final slotTime = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
      return slotTime.isAfter(now) || (isSameDay(slotTime, now) && slotTime.isAfter(now));
    }).toList();
  }

  List<Booking> _getBookingsForSelectedDay() {
    return _selectedDay != null ? _getUpcomingBookingsForDate(_selectedDay!) : [];
  }

  List<Booking> _getTodayBookings() {
    return _getUpcomingBookingsForDate(DateTime.now());
  }

  // ──────────────────────────────────────────────────────────────
  // UI – Bottom navigation
  // ──────────────────────────────────────────────────────────────
  Widget _bottomNav(BuildContext ctx, int active) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -1))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home, 'Home', active == 0, 0, ctx),
                _navItem(Icons.people_alt, 'Patient', active == 1, 1, ctx),
                _navItem(Icons.schedule, 'Schedule', active == 2, 2, ctx),
                _navItem(Icons.person_outline, 'Profile', active == 3, 3, ctx),
              ],
            ),
          ),
        ),
      );

  Widget _navItem(IconData icon, String label, bool active, int idx, BuildContext ctx) {
    return Expanded(
      child: GestureDetector(
        onTap: active
            ? null
            : () {
                switch (idx) {
                  case 0:
                    Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => const DoctorHomePage()));
                    break;
                  case 1:
                    Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => const DoctorPatientsScreen()));
                    break;
                  case 3:
                    Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => const DoctorProfileScreen()));
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

  // ──────────────────────────────────────────────────────────────
  // Main Scaffold
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primary))
                  : RefreshIndicator(
                      onRefresh: _loadDoctorSchedule,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _calendarSection(),
                            _appointmentsSection(),
                          ],
                        ),
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

  // ──────────────────────────────────────────────────────────────
  // Header
  // ──────────────────────────────────────────────────────────────
  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DoctorHomePage()),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Schedule', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text('Manage your appointments', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.today, color: Colors.black87),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                });
              },
            ),
          ],
        ),
      );

  // ──────────────────────────────────────────────────────────────
  // Calendar (WHITE background)
  // ──────────────────────────────────────────────────────────────
  Widget _calendarSection() => Card(
        margin: const EdgeInsets.all(16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          color: Colors.white, // WHITE
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _todaySummary(),
              const SizedBox(height: 16),
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  final today = DateTime.now();
                  final todayOnly = DateTime(today.year, today.month, today.day);
                  if (selectedDay.isBefore(todayOnly)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cannot select past dates'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (fmt) => setState(() => _calendarFormat = fmt),
                onPageChanged: (fd) => setState(() => _focusedDay = fd),

                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.red),
                  selectedDecoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: Color(0x334A90E2), shape: BoxShape.circle),
                  markerDecoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  defaultTextStyle: TextStyle(color: Colors.black87),
                  disabledTextStyle: TextStyle(color: Colors.grey),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(color: primary, borderRadius: BorderRadius.all(Radius.circular(8))),
                  formatButtonTextStyle: TextStyle(color: Colors.white),
                ),

                // MARKERS: Only on dates with future/upcoming bookings
                eventLoader: (day) {
                  final dateStr = _formatDate(day);
                  final hasSchedule = _doctorSchedule?.schedule.containsKey(dateStr) ?? false;
                  if (!hasSchedule) return [];

                  final bookings = _getUpcomingBookingsForDate(day);
                  return bookings.isNotEmpty ? [bookings.length] : [];
                },
              ),
            ],
          ),
        ),
      );

  // ──────────────────────────────────────────────────────────────
  // Today summary
  // ──────────────────────────────────────────────────────────────
  Widget _todaySummary() => Container(
        width: double.infinity,
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
                  const Text("Today's Appointments", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${_getTodayBookings().length} scheduled', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(20)),
              child: Text(
                _getTodayBookings().length.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

  // ──────────────────────────────────────────────────────────────
  // Appointments list
  // ──────────────────────────────────────────────────────────────
  Widget _appointmentsSection() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDay != null && isSameDay(_selectedDay, DateTime.now())
                      ? "Today's Appointments"
                      : "Appointments on ${DateFormat('MMM d, yyyy').format(_selectedDay!)}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text('${_getBookingsForSelectedDay().length} booked', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            _getBookingsForSelectedDay().isEmpty
                ? _emptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _getBookingsForSelectedDay().length,
                    itemBuilder: (_, i) => _bookingCard(_getBookingsForSelectedDay()[i]),
                  ),
            const SizedBox(height: 100),
          ],
        ),
      );

  Widget _emptyState() => Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(Icons.event_available, size: 64, color: muted),
            const SizedBox(height: 16),
            const Text('No upcoming appointments', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              _selectedDay != null && isSameDay(_selectedDay, DateTime.now())
                  ? 'You are free today!'
                  : 'No bookings for this date',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addNewAppointment,
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              child: const Text('Schedule Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  // ──────────────────────────────────────────────────────────────
  // Booking card – WHITE
  // ──────────────────────────────────────────────────────────────
  Widget _bookingCard(Booking booking) {
    final parts = booking.timeSlot.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final slotDt = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, hour, minute);
    final isUpcoming = slotDt.isAfter(DateTime.now());

    return Card(
      color: Colors.white, // WHITE
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(booking.timeSlot, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUpcoming ? primary.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isUpcoming ? primary : Colors.orange, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isUpcoming ? Icons.schedule : Icons.access_time, size: 14, color: isUpcoming ? primary : Colors.orange),
                      const SizedBox(width: 4),
                      Text(isUpcoming ? 'Upcoming' : 'Today', style: TextStyle(fontSize: 12, color: isUpcoming ? primary : Colors.orange, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.1),
                  radius: 20,
                  child: Text(
                    booking.patientName?.isNotEmpty == true
                        ? booking.patientName!.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                        : '??',
                    style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.patientName ?? 'Unknown Patient', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(
                        '${booking.appointmentType ?? 'Consultation'} • Booked: ${booking.bookedAt != null ? DateFormat('MMM d, h:mm a').format(booking.bookedAt!) : 'N/A'}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (booking.notes?.isNotEmpty == true) ...[
              const Divider(height: 24),
              Text(booking.notes!, style: const TextStyle(fontSize: 14, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => _removeBooking(booking), child: const Text('Remove', style: TextStyle(color: Colors.red))),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showBookingDetails(booking),
                  style: ElevatedButton.styleFrom(backgroundColor: primary),
                  child: const Text('Details', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────────────────────────
  void _addNewAppointment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add appointment – coming soon!'), backgroundColor: primary),
    );
  }

  void _showBookingDetails(Booking b) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(b.patientName ?? 'Patient'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time: ${b.timeSlot}', style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('Type: ${b.appointmentType ?? 'N/A'}'),
              if (b.bookedAt != null) Text('Booked: ${DateFormat('MMM d, yyyy • h:mm a').format(b.bookedAt!)}'),
              if (b.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(b.notes!),
              ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _removeBooking(Booking b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Booking'),
        content: Text('Remove ${b.patientName} from ${b.timeSlot}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && _doctorId != null && _selectedDay != null) {
      final updated = _doctorSchedule!.removeBooking(_selectedDay!, b.timeSlot);
      await FirebaseFirestore.instance
          .collection('doctor_schedules')
          .doc(_doctorId)
          .set(updated.toMap(), SetOptions(merge: true));

      await _loadDoctorSchedule();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${b.patientName} removed'), backgroundColor: Colors.green),
        );
      }
    }
  }
}