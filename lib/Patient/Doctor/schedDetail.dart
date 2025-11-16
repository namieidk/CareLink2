// ========================================
// FILE: SchedDetail.dart
// Location: lib/screens/Patient/SchedDetail.dart
// ========================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/doctor_profile.dart';
import '../../models/doctor_schedule.dart';

class SchedDetail extends StatefulWidget {
  final DoctorProfile doctor;
  
  const SchedDetail({Key? key, required this.doctor}) : super(key: key);

  @override
  _SchedDetailState createState() => _SchedDetailState();
}

class _SchedDetailState extends State<SchedDetail> {
  final DoctorScheduleService _scheduleService = DoctorScheduleService();
  
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  DoctorSchedule? _doctorSchedule;
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _loadDoctorSchedule();
  }

  Future<void> _initializeUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = user.displayName ?? 'Patient';
      });
    }
  }

  // Get formatted date for display
  String _getFormattedDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  // Get full formatted date
  String _getFullFormattedDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  // Get day name from DateTime
  String _getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  // Check if date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  // Check if date is same day
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Normalize date to remove time component
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _loadDoctorSchedule() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to get existing schedule
      DoctorSchedule? schedule = await _scheduleService.getSchedule(widget.doctor.id);
      
      // If no schedule exists, create a default one for the next 30 days
      if (schedule == null) {
        print('No schedule found, creating initial schedule...');
        final startDate = DateTime.now();
        final endDate = DateTime.now().add(const Duration(days: 30));
        final defaultTimeSlots = DateScheduleGenerator.generateTimeSlots(9, 17);
        
        print('Start date: $startDate');
        print('End date: $endDate');
        print('Time slots: $defaultTimeSlots');
        
        // Create schedule INCLUDING weekends (remove excludeWeekdays parameter)
        await _scheduleService.createInitialSchedule(
          widget.doctor.id,
          widget.doctor.name,
          startDate: startDate,
          endDate: endDate,
          defaultTimeSlots: defaultTimeSlots,
        );
        schedule = await _scheduleService.getSchedule(widget.doctor.id);
        print('Schedule created. Total dates: ${schedule?.schedule.length}');
      } else {
        print('Schedule found. Total dates: ${schedule.schedule.length}');
        print('Schedule keys: ${schedule.schedule.keys.take(5).join(", ")}...');
      }

      if (schedule != null) {
        final normalizedDate = _normalizeDate(_selectedDate);
        final dateString = DoctorSchedule.dateToString(normalizedDate);
        print('Checking slots for date: $dateString');
        print('Has schedule for this date: ${schedule.hasScheduleOnDate(normalizedDate)}');
        final slots = schedule.getAvailableSlotsForDate(normalizedDate);
        print('Available slots: $slots');
      }

      setState(() {
        _doctorSchedule = schedule;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading schedule: $e';
        _isLoading = false;
      });
      print('Error loading schedule: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfafafa),
      appBar: AppBar(
        title: const Text(
          'Doctor Schedule',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFE91E63),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDoctorSchedule,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
              ),
            ),
          ],
        ),
      );
    }

    if (_doctorSchedule == null) {
      return const Center(
        child: Text('No schedule available'),
      );
    }

    // Use the exact date instead of day name
    final normalizedDate = _normalizeDate(_selectedDate);
    final availableSlots = _doctorSchedule!.getAvailableSlotsForDate(normalizedDate);
    final bookedSlots = _doctorSchedule!.getBookedSlotsForDate(normalizedDate);

    return RefreshIndicator(
      onRefresh: _loadDoctorSchedule,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Info Card
              _buildDoctorInfoCard(),
              const SizedBox(height: 24),
              
              // Calendar Section
              _buildCalendarSection(),
              const SizedBox(height: 24),
              
              // Selected Date Display
              _buildSelectedDateDisplay(),
              const SizedBox(height: 16),
              
              // Schedule Display
              _buildScheduleSection(availableSlots, bookedSlots),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE91E63), Color(0xFFF06292)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Doctor Profile Image or Initials
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(35),
            ),
            child: widget.doctor.profileImageUrl != null && 
                   widget.doctor.profileImageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: Image.network(
                      widget.doctor.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            widget.doctor.getInitials(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      widget.doctor.getInitials(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.doctor.specialty,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.doctor.experienceFormatted} experience',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    // Get all scheduled dates to mark them on the calendar
    final scheduledDates = _doctorSchedule?.getScheduledDates() ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Color(0xFFE91E63),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => _isSameDay(day, _selectedDate),
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            // Add event loader to show markers for scheduled dates
            eventLoader: (day) {
              final normalizedDay = _normalizeDate(day);
              final hasSchedule = scheduledDates.any((date) => 
                _isSameDay(date, normalizedDay)
              );
              return hasSchedule ? [normalizedDay] : [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
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
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: const BoxDecoration(
                color: Color(0xFFE91E63),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.bold,
              ),
              weekendTextStyle: const TextStyle(
                color: Color(0xFFE91E63),
              ),
              defaultTextStyle: const TextStyle(
                color: Color(0xFF424242),
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xFFE91E63),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: true,
              titleTextStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF424242),
              ),
              formatButtonTextStyle: const TextStyle(
                color: Color(0xFFE91E63),
                fontSize: 12,
              ),
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE91E63)),
                borderRadius: BorderRadius.circular(8),
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: Color(0xFFE91E63),
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: Color(0xFFE91E63),
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Color(0xFF9E9E9E),
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDateDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event,
                  color: Color(0xFFE91E63),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDayName(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getFullFormattedDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isToday(_selectedDate))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  color: Color(0xFFE91E63),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(List<String> availableSlots, List<String> bookedSlots) {
    final normalizedDate = _normalizeDate(_selectedDate);
    final hasSchedule = _doctorSchedule?.hasScheduleOnDate(normalizedDate) ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Time Slots',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              if (!hasSchedule && availableSlots.isEmpty)
                TextButton.icon(
                  onPressed: () => _showAddScheduleDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Schedule'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE91E63),
                  ),
                ),
            ],
          ),
        ),
        availableSlots.isEmpty
            ? Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        hasSchedule 
                            ? 'All slots are booked for this date'
                            : 'No schedule available for this date',
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasSchedule
                            ? 'Try selecting another date'
                            : 'Doctor has not set up schedule for this date',
                        style: const TextStyle(
                          color: Color(0xFFBDBDBD),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: availableSlots.length,
                itemBuilder: (context, index) {
                  final slot = availableSlots[index];
                  final isBooked = bookedSlots.contains(slot);
                  
                  return Material(
                    borderRadius: BorderRadius.circular(12),
                    color: isBooked ? const Color(0xFF9E9E9E) : const Color(0xFFE91E63),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: isBooked ? null : () => _bookSlot(slot),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (isBooked ? const Color(0xFF9E9E9E) : const Color(0xFFE91E63)).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                slot,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isBooked)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.lock_clock,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        if (availableSlots.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildLegend(bookedSlots.length, availableSlots.length),
        ],
      ],
    );
  }

  void _showAddScheduleDialog() {
    // This is for debugging/admin purposes
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('No Schedule Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The doctor has not set up a schedule for this date yet.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'Selected Date: ${_getFullFormattedDate(_selectedDate)}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Day: ${_getDayName(_selectedDate)}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(int bookedCount, int totalSlots) {
    final availableCount = totalSlots - bookedCount;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLegendItem(const Color(0xFFE91E63), 'Available', Icons.check_circle),
          _buildLegendItem(const Color(0xFF9E9E9E), 'Booked', Icons.lock_clock),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  availableCount.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4CAF50),
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Open',
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF424242),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _bookSlot(String slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Book Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor: ${widget.doctor.name}'),
            const SizedBox(height: 8),
            Text('Specialty: ${widget.doctor.specialty}'),
            const SizedBox(height: 8),
            Text('Date: ${_getFullFormattedDate(_selectedDate)}'),
            const SizedBox(height: 8),
            Text('Day: ${_getDayName(_selectedDate)}'),
            const SizedBox(height: 8),
            Text('Time: $slot'),
            const SizedBox(height: 16),
            const Text(
              'Would you like to book this appointment?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmBooking(slot);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking(String slot) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
        ),
      ),
    );

    try {
      // Normalize the date to remove time component
      final normalizedDate = _normalizeDate(_selectedDate);
      
      // Create booking with patient details
      final booking = Booking(
        timeSlot: slot,
        patientId: _currentUserId,
        patientName: _currentUserName,
        bookedAt: DateTime.now(),
        appointmentType: 'Consultation',
        notes: 'Appointment booked via mobile app',
      );
      
      // Add booking to Firestore using the exact date
      await _scheduleService.addBooking(
        widget.doctor.id,
        normalizedDate,
        booking,
      );

      // Reload the schedule to get updated data
      await _loadDoctorSchedule();

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Appointment booked for ${_getFormattedDate(_selectedDate)} at $slot'
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Optional: Navigate to appointments page
            },
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book appointment: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}