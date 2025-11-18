import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Home.dart';
import 'patient.dart';
import 'caremed.dart';
import 'Profile.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache for events
  Map<DateTime, List<CalendarEvent>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInterviewEvents();
  }

  Future<void> _loadInterviewEvents() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Query bookings where this caregiver is assigned and status is "accepted"
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('caregiverId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      Map<DateTime, List<CalendarEvent>> loadedEvents = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final startTime = (data['startTime'] as Timestamp).toDate();
        final dateKey = DateTime(startTime.year, startTime.month, startTime.day);
        
        final event = CalendarEvent(
          time: DateFormat('hh:mm a').format(startTime),
          title: 'Interview - ${data['patientName'] ?? 'Patient'}',
          subtitle: data['interviewType'] ?? 'Interview',
          type: EventType.interview,
          bookingId: doc.id,
          meetLink: data['meetLink'],
          notes: data['notes'],
          durationHours: data['durationHours'] ?? 1,
        );

        if (loadedEvents[dateKey] == null) {
          loadedEvents[dateKey] = [];
        }
        loadedEvents[dateKey]!.add(event);
      }

      // Sort events by time for each day
      loadedEvents.forEach((key, value) {
        value.sort((a, b) => a.time.compareTo(b.time));
      });

      setState(() {
        _events = loadedEvents;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading interviews: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading interviews: $e'),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    DateTime dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  bool _hasEventsOnDay(DateTime day) {
    DateTime dateKey = DateTime(day.year, day.month, day.day);
    return _events.containsKey(dateKey) && _events[dateKey]!.isNotEmpty;
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _currentMonth = DateTime.now();
    });
  }

  void _onDayTapped(DateTime day) {
    DateTime today = DateTime.now();
    DateTime todayDate = DateTime(today.year, today.month, today.day);
    DateTime selectedDate = DateTime(day.year, day.month, day.day);
    
    // Prevent selecting past dates
    if (selectedDate.isBefore(todayDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot select past dates'),
          backgroundColor: Colors.red[400],
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _selectedDate = day;
    });
  }

  void _showAddEventDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEventSheet(
        selectedDate: _selectedDate,
        onEventAdded: (event) {
          setState(() {
            DateTime dateKey = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
            );
            if (_events[dateKey] == null) {
              _events[dateKey] = [];
            }
            _events[dateKey]!.add(event);
            // Sort events by time
            _events[dateKey]!.sort((a, b) => a.time.compareTo(b.time));
          });
        },
      ),
    );
  }

  void _showEventDetails(CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventDetailsSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6C5CE7),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCalendar(),
                          _buildScheduleSection(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFF8B7FE8),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                ),
                Text(
                  'Calendar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: _goToToday,
                  icon: Icon(Icons.today, color: Colors.white),
                ),
                IconButton(
                  onPressed: _loadInterviewEvents,
                  icon: Icon(Icons.refresh, color: Colors.white, size: 26),
                ),
                IconButton(
                  onPressed: _showAddEventDialog,
                  icon: Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: Icon(Icons.chevron_left, color: Colors.white, size: 32),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: Icon(Icons.chevron_right, color: Colors.white, size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => Container(
                      width: 36,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: 12),
          ..._buildCalendarDays(),
        ],
      ),
    );
  }

  List<Widget> _buildCalendarDays() {
    List<Widget> rows = [];
    DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    int firstWeekday = firstDayOfMonth.weekday % 7;
    int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    
    int currentDay = 1;
    
    for (int week = 0; week < 6; week++) {
      List<Widget> dayWidgets = [];
      
      for (int weekday = 0; weekday < 7; weekday++) {
        if (week == 0 && weekday < firstWeekday) {
          dayWidgets.add(Container(width: 36, height: 36));
        } else if (currentDay > daysInMonth) {
          dayWidgets.add(Container(width: 36, height: 36));
        } else {
          DateTime dayDate = DateTime(_currentMonth.year, _currentMonth.month, currentDay);
          dayWidgets.add(_buildCalendarDay(dayDate, currentDay));
          currentDay++;
        }
      }
      
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayWidgets,
          ),
        ),
      );
      
      if (currentDay > daysInMonth) break;
    }
    
    return rows;
  }

  Widget _buildCalendarDay(DateTime dayDate, int day) {
    DateTime today = DateTime.now();
    DateTime todayDate = DateTime(today.year, today.month, today.day);
    DateTime selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime currentDate = DateTime(dayDate.year, dayDate.month, dayDate.day);
    
    bool isToday = currentDate.isAtSameMomentAs(todayDate);
    bool isSelected = currentDate.isAtSameMomentAs(selectedDate);
    bool hasEvent = _hasEventsOnDay(dayDate);
    bool isPast = currentDate.isBefore(todayDate);
    
    return GestureDetector(
      onTap: () => _onDayTapped(dayDate),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF6C5CE7)
              : isToday
                  ? Color(0xFF6C5CE7).withOpacity(0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: hasEvent && !isSelected
              ? Border.all(color: Color(0xFF6C5CE7), width: 1.5)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              day.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                color: isPast
                    ? Colors.grey[400]
                    : isSelected
                        ? Colors.white
                        : Colors.grey[800],
              ),
            ),
            if (hasEvent && !isSelected)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFF6C5CE7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    List<CalendarEvent> events = _getEventsForDay(_selectedDate);
    
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isToday(_selectedDate) ? "Today's Interviews" : "Interviews for ${DateFormat('MMM d').format(_selectedDate)}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              if (events.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF6C5CE7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${events.length} interview${events.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Color(0xFF6C5CE7),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 16),
        events.isEmpty
            ? Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                padding: EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No interviews scheduled',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Accepted interviews will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: events.length,
                separatorBuilder: (context, index) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildEventItem(events[index]);
                },
              ),
        SizedBox(height: 20),
      ],
    );
  }

  bool _isToday(DateTime date) {
    DateTime today = DateTime.now();
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }

  Widget _buildEventItem(CalendarEvent event) {
    return InkWell(
      onTap: () => _showEventDetails(event),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: event.color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: event.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                event.icon,
                color: event.color,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    event.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (event.durationHours != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        '${event.durationHours} hour${event.durationHours! > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFC),
        border: Border(
          top: BorderSide(
            color: Color(0xFFE8EAED),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.home, 'Home', currentIndex == 0, 0),
              _buildNavItem(context, Icons.people, 'Patients', currentIndex == 1, 1),
              _buildNavItem(context, Icons.medication, 'Medications', currentIndex == 2, 2),
              _buildNavItem(context, Icons.calendar_month, 'Calendar', currentIndex == 3, 3),
              _buildNavItem(context, Icons.person, 'Profile', currentIndex == 4, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isActive, int index) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (isActive) return;

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CaregiverHomeScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PatientsScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MedicationScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CalendarScreen()),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? Color(0xFF6C5CE7) : Colors.grey[400],
                size: 26,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? Color(0xFF6C5CE7) : Colors.grey[400],
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Event Type Enum
enum EventType {
  medication,
  appointment,
  interview,
  therapy,
  checkIn,
  custom,
}

// Calendar Event Model
class CalendarEvent {
  final String time;
  final String title;
  final String subtitle;
  final EventType type;
  final String? bookingId;
  final String? meetLink;
  final String? notes;
  final int? durationHours;

  CalendarEvent({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.type,
    this.bookingId,
    this.meetLink,
    this.notes,
    this.durationHours,
  });

  Color get color {
    switch (type) {
      case EventType.medication:
        return Color(0xFF4CAF50);
      case EventType.appointment:
        return Color(0xFF42A5F5);
      case EventType.interview:
        return Color(0xFFFF7043);
      case EventType.therapy:
        return Color(0xFFFFA726);
      case EventType.checkIn:
        return Color(0xFF6C5CE7);
      case EventType.custom:
        return Color(0xFF26A69A);
    }
  }

  IconData get icon {
    switch (type) {
      case EventType.medication:
        return Icons.medication;
      case EventType.appointment:
        return Icons.local_hospital;
      case EventType.interview:
        return Icons.people_alt;
      case EventType.therapy:
        return Icons.fitness_center;
      case EventType.checkIn:
        return Icons.checklist;
      case EventType.custom:
        return Icons.event_note;
    }
  }
}

// Event Details Bottom Sheet
class EventDetailsSheet extends StatelessWidget {
  final CalendarEvent event;

  const EventDetailsSheet({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Interview Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildDetailRow(Icons.access_time, 'Time', event.time),
              SizedBox(height: 16),
              _buildDetailRow(Icons.person, 'Patient', event.title.replaceAll('Interview - ', '')),
              SizedBox(height: 16),
              _buildDetailRow(Icons.video_call, 'Type', event.subtitle),
              if (event.durationHours != null) ...[
                SizedBox(height: 16),
                _buildDetailRow(Icons.schedule, 'Duration', '${event.durationHours} hour${event.durationHours! > 1 ? 's' : ''}'),
              ],
              if (event.meetLink != null && event.meetLink!.isNotEmpty) ...[
                SizedBox(height: 16),
                _buildDetailRow(Icons.link, 'Meeting Link', event.meetLink!),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Open meet link
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening meeting link...')),
                      );
                    },
                    icon: Icon(Icons.video_call, color: Colors.white),
                    label: Text(
                      'Join Meeting',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              if (event.notes != null && event.notes!.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.notes!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF6C5CE7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(0xFF6C5CE7), size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Add Event Bottom Sheet (for custom tasks)
class AddEventSheet extends StatefulWidget {
  final DateTime selectedDate;
  final Function(CalendarEvent) onEventAdded;

  const AddEventSheet({
    Key? key,
    required this.selectedDate,
    required this.onEventAdded,
  }) : super(key: key);

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  EventType _selectedType = EventType.custom;
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveEvent() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final event = CalendarEvent(
      time: _selectedTime.format(context),
      title: _titleController.text,
      subtitle: _subtitleController.text,
      type: _selectedType,
    );

    widget.onEventAdded(event);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task added successfully'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Custom Task',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(widget.selectedDate),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Task Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  EventType.medication,
                  EventType.appointment,
                  EventType.therapy,
                  EventType.checkIn,
                  EventType.custom,
                ].map((type) {
                  bool isSelected = type == _selectedType;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFF6C5CE7) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        type.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 24),
              Text(
                'Time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Color(0xFF6C5CE7)),
                      SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _subtitleController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C5CE7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add Task',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}