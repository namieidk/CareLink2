import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  DoctorSchedule? _doctorSchedule;
  bool _isLoading = true;
  String? _errorMessage;

  // Get list of next 14 weekdays (excluding weekends)
  List<DateTime> _getWeekdays() {
    List<DateTime> weekdays = [];
    DateTime current = DateTime.now();
    
    while (weekdays.length < 14) {
      // Only add if it's a weekday (Monday = 1 to Friday = 5)
      if (current.weekday >= 1 && current.weekday <= 5) {
        weekdays.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    
    return weekdays;
  }

  // Get day name from DateTime
  String _getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  // Get short day name
  String _getShortDayName(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  // Get formatted date (e.g., "Jan 15")
  String _getFormattedDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  // Check if date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  // Check if date is tomorrow
  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && 
           date.month == tomorrow.month && 
           date.day == tomorrow.day;
  }

  @override
  void initState() {
    super.initState();
    // Set initial selected date to today or next weekday
    _selectedDate = _getWeekdays().first;
    _loadDoctorSchedule();
  }

  Future<void> _loadDoctorSchedule() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to get existing schedule
      DoctorSchedule? schedule = await _scheduleService.getSchedule(widget.doctor.id);
      
      // If no schedule exists, create a default one
      if (schedule == null) {
        await _scheduleService.createInitialSchedule(
          widget.doctor.id,
          widget.doctor.name,
        );
        schedule = await _scheduleService.getSchedule(widget.doctor.id);
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

    final dayName = _getDayName(_selectedDate);
    final availableSlots = _doctorSchedule!.getAvailableSlotsForDay(dayName);
    final bookedSlots = _doctorSchedule!.getBookedSlotsForDay(dayName);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Info Card
          _buildDoctorInfoCard(),
          const SizedBox(height: 24),
          
          // Date Selector
          _buildDateSelector(),
          const SizedBox(height: 24),
          
          // Selected Date Display
          _buildSelectedDateDisplay(),
          const SizedBox(height: 16),
          
          // Schedule Display
          _buildScheduleSection(availableSlots, bookedSlots),
        ],
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

  Widget _buildDateSelector() {
    final weekdays = _getWeekdays();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Select Date',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weekdays.length,
            itemBuilder: (context, index) {
              final date = weekdays[index];
              final isSelected = date.year == _selectedDate.year &&
                                date.month == _selectedDate.month &&
                                date.day == _selectedDate.day;
              final isCurrentDay = _isToday(date);
              
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Material(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected 
                      ? const Color(0xFFE91E63) 
                      : Colors.white,
                  elevation: isSelected ? 4 : 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      width: 70,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Day name
                          Text(
                            _getShortDayName(date),
                            style: TextStyle(
                              color: isSelected 
                                  ? Colors.white 
                                  : const Color(0xFF9E9E9E),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Date number
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: isSelected 
                                  ? Colors.white 
                                  : const Color(0xFF424242),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Month
                          Text(
                            _getFormattedDate(date).split(' ')[0],
                            style: TextStyle(
                              color: isSelected 
                                  ? Colors.white70 
                                  : const Color(0xFF9E9E9E),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Today badge (only if needed)
                          if (isCurrentDay) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.white.withOpacity(0.2)
                                    : const Color(0xFFE91E63).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Today',
                                style: TextStyle(
                                  color: isSelected 
                                      ? Colors.white 
                                      : const Color(0xFFE91E63),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today,
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
                DateFormat('MMMM d, yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(List<String> availableSlots, List<String> bookedSlots) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Available Time Slots',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
          ),
          Expanded(
            child: availableSlots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No available slots for this day',
                          style: TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
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
          ),
          const SizedBox(height: 20),
          _buildLegend(bookedSlots.length, availableSlots.length),
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
            Text('Date: ${DateFormat('MMMM d, yyyy').format(_selectedDate)}'),
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
      final dayName = _getDayName(_selectedDate);
      
      // Add booking to Firestore using the service
      await _scheduleService.addBooking(
        widget.doctor.id,
        dayName,
        slot,
      );

      // Reload the schedule to get updated data
      await _loadDoctorSchedule();

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Appointment booked for ${DateFormat('MMM d').format(_selectedDate)} at $slot'
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