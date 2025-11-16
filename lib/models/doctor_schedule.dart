// ========================================
// FILE: doctor_schedule.dart
// Location: lib/models/doctor_schedule.dart
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

// Booking class to store patient details with time slot
class Booking {
  final String timeSlot;
  final String? patientId;
  final String? patientName;
  final DateTime? bookedAt;
  final String? appointmentType;
  final String? notes;

  Booking({
    required this.timeSlot,
    this.patientId,
    this.patientName,
    this.bookedAt,
    this.appointmentType,
    this.notes,
  });

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      timeSlot: map['timeSlot'] ?? '',
      patientId: map['patientId'],
      patientName: map['patientName'],
      bookedAt: map['bookedAt'] != null 
          ? (map['bookedAt'] as Timestamp).toDate() 
          : null,
      appointmentType: map['appointmentType'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timeSlot': timeSlot,
      if (patientId != null) 'patientId': patientId,
      if (patientName != null) 'patientName': patientName,
      if (bookedAt != null) 'bookedAt': Timestamp.fromDate(bookedAt!),
      if (appointmentType != null) 'appointmentType': appointmentType,
      if (notes != null) 'notes': notes,
    };
  }
}

class DoctorSchedule {
  final String id; // Doctor ID (references doctor_profiles)
  final String doctorName;
  final Map<String, List<String>> schedule; // Date string (YYYY-MM-DD) -> List of time slots
  final Map<String, List<Booking>> bookings; // Date string (YYYY-MM-DD) -> List of bookings with patient details
  final DateTime createdAt;
  final DateTime updatedAt;

  DoctorSchedule({
    required this.id,
    required this.doctorName,
    required this.schedule,
    required this.bookings,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create DoctorSchedule from Firestore document
  factory DoctorSchedule.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return DoctorSchedule(
      id: doc.id,
      doctorName: data['doctorName'] ?? '',
      schedule: _parseScheduleMap(data['schedule']),
      bookings: _parseBookingsMap(data['bookings']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Factory constructor to create DoctorSchedule from Map
  factory DoctorSchedule.fromMap(Map<String, dynamic> data, String documentId) {
    return DoctorSchedule(
      id: documentId,
      doctorName: data['doctorName'] ?? '',
      schedule: _parseScheduleMap(data['schedule']),
      bookings: _parseBookingsMap(data['bookings']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Helper method to parse schedule map
  static Map<String, List<String>> _parseScheduleMap(dynamic data) {
    if (data == null) return {};
    
    final Map<String, dynamic> rawMap = Map<String, dynamic>.from(data);
    return rawMap.map((key, value) {
      if (value is List) {
        return MapEntry(key, List<String>.from(value));
      }
      return MapEntry(key, <String>[]);
    });
  }

  // Helper method to parse bookings map with patient details
  static Map<String, List<Booking>> _parseBookingsMap(dynamic data) {
    if (data == null) return {};
    
    final Map<String, dynamic> rawMap = Map<String, dynamic>.from(data);
    return rawMap.map((key, value) {
      if (value is List) {
        List<Booking> bookingsList = [];
        for (var item in value) {
          if (item is String) {
            // Legacy format: just time slots
            bookingsList.add(Booking(timeSlot: item));
          } else if (item is Map) {
            // New format: booking objects with patient details
            bookingsList.add(Booking.fromMap(Map<String, dynamic>.from(item)));
          }
        }
        return MapEntry(key, bookingsList);
      }
      return MapEntry(key, <Booking>[]);
    });
  }

  // Convert DoctorSchedule to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'doctorName': doctorName,
      'schedule': schedule,
      'bookings': bookings.map((key, value) => 
        MapEntry(key, value.map((booking) => booking.toMap()).toList())
      ),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with method for updating specific fields
  DoctorSchedule copyWith({
    String? id,
    String? doctorName,
    Map<String, List<String>>? schedule,
    Map<String, List<Booking>>? bookings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoctorSchedule(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      schedule: schedule ?? Map<String, List<String>>.from(this.schedule),
      bookings: bookings ?? Map<String, List<Booking>>.from(this.bookings),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to convert DateTime to date string (YYYY-MM-DD)
  static String dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper method to convert date string to DateTime
  static DateTime? stringToDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Get available slots for a specific date
  List<String> getAvailableSlotsForDate(DateTime date) {
    final dateString = dateToString(date);
    return schedule[dateString] ?? [];
  }

  // Get booked slots for a specific date (just the time slots)
  List<String> getBookedSlotsForDate(DateTime date) {
    final dateString = dateToString(date);
    final dateBookings = bookings[dateString] ?? [];
    return dateBookings.map((b) => b.timeSlot).toList();
  }

  // Get booking details for a specific date
  List<Booking> getBookingDetailsForDate(DateTime date) {
    final dateString = dateToString(date);
    return bookings[dateString] ?? [];
  }

  // Get free slots (available but not booked) for a specific date
  List<String> getFreeSlotsForDate(DateTime date) {
    final available = getAvailableSlotsForDate(date);
    final booked = getBookedSlotsForDate(date);
    return available.where((slot) => !booked.contains(slot)).toList();
  }

  // Check if a specific slot is available on a date
  bool isSlotAvailable(DateTime date, String time) {
    final available = getAvailableSlotsForDate(date);
    final booked = getBookedSlotsForDate(date);
    return available.contains(time) && !booked.contains(time);
  }

  // Check if a specific slot is booked on a date
  bool isSlotBooked(DateTime date, String time) {
    final booked = getBookedSlotsForDate(date);
    return booked.contains(time);
  }

  // Add a booking with patient details for a specific date
  DoctorSchedule addBooking(DateTime date, Booking booking) {
    final dateString = dateToString(date);
    final newBookings = Map<String, List<Booking>>.from(bookings);
    if (!newBookings.containsKey(dateString)) {
      newBookings[dateString] = [];
    }
    // Check if slot is already booked
    if (!newBookings[dateString]!.any((b) => b.timeSlot == booking.timeSlot)) {
      newBookings[dateString]!.add(booking);
    }
    return copyWith(
      bookings: newBookings,
      updatedAt: DateTime.now(),
    );
  }

  // Remove a booking from a specific date
  DoctorSchedule removeBooking(DateTime date, String time) {
    final dateString = dateToString(date);
    final newBookings = Map<String, List<Booking>>.from(bookings);
    if (newBookings.containsKey(dateString)) {
      newBookings[dateString]!.removeWhere((b) => b.timeSlot == time);
    }
    return copyWith(
      bookings: newBookings,
      updatedAt: DateTime.now(),
    );
  }

  // Get total number of available slots across all dates
  int getTotalAvailableSlots() {
    return schedule.values.fold(0, (sum, slots) => sum + slots.length);
  }

  // Get total number of booked slots across all dates
  int getTotalBookedSlots() {
    return bookings.values.fold(0, (sum, bookingsList) => sum + bookingsList.length);
  }

  // Get total number of free slots across all dates
  int getTotalFreeSlots() {
    return getTotalAvailableSlots() - getTotalBookedSlots();
  }

  // Get booking percentage
  double getBookingPercentage() {
    final total = getTotalAvailableSlots();
    if (total == 0) return 0.0;
    return (getTotalBookedSlots() / total) * 100;
  }

  // Get all scheduled dates
  List<DateTime> getScheduledDates() {
    return schedule.keys
        .map((dateString) => stringToDate(dateString))
        .where((date) => date != null)
        .map((date) => date!)
        .toList()
      ..sort();
  }

  // Check if doctor has schedule on a specific date
  bool hasScheduleOnDate(DateTime date) {
    final dateString = dateToString(date);
    return schedule.containsKey(dateString) && schedule[dateString]!.isNotEmpty;
  }

  // Get schedule for a date range
  Map<DateTime, List<String>> getScheduleForDateRange(DateTime start, DateTime end) {
    final Map<DateTime, List<String>> rangeSchedule = {};
    
    for (var entry in schedule.entries) {
      final date = stringToDate(entry.key);
      if (date != null && 
          (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
          (date.isBefore(end) || date.isAtSameMomentAs(end))) {
        rangeSchedule[date] = entry.value;
      }
    }
    
    return rangeSchedule;
  }

  // Get bookings for a date range
  Map<DateTime, List<Booking>> getBookingsForDateRange(DateTime start, DateTime end) {
    final Map<DateTime, List<Booking>> rangeBookings = {};
    
    for (var entry in bookings.entries) {
      final date = stringToDate(entry.key);
      if (date != null && 
          (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
          (date.isBefore(end) || date.isAtSameMomentAs(end))) {
        rangeBookings[date] = entry.value;
      }
    }
    
    return rangeBookings;
  }

  @override
  String toString() {
    return 'DoctorSchedule(id: $id, doctorName: $doctorName, scheduledDates: ${schedule.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is DoctorSchedule &&
        other.id == id &&
        other.doctorName == doctorName;
  }

  @override
  int get hashCode {
    return Object.hash(id, doctorName);
  }
}

// Helper class for creating date-based schedules
class DateScheduleGenerator {
  // Generate schedule for a date range with specific time slots
  static Map<String, List<String>> generateScheduleForDateRange(
    DateTime startDate,
    DateTime endDate,
    List<String> timeSlots, {
    List<int>? excludeWeekdays, // 1 = Monday, 7 = Sunday
  }) {
    final Map<String, List<String>> schedule = {};
    final excludeDays = excludeWeekdays ?? [];
    
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      // Check if this weekday should be excluded
      if (!excludeDays.contains(currentDate.weekday)) {
        final dateString = DoctorSchedule.dateToString(currentDate);
        schedule[dateString] = List<String>.from(timeSlots);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return schedule;
  }

  // Generate schedule for specific dates
  static Map<String, List<String>> generateScheduleForSpecificDates(
    List<DateTime> dates,
    List<String> timeSlots,
  ) {
    final Map<String, List<String>> schedule = {};
    
    for (var date in dates) {
      final dateString = DoctorSchedule.dateToString(date);
      schedule[dateString] = List<String>.from(timeSlots);
    }
    
    return schedule;
  }

  // Generate time slots between start and end hour (hourly intervals)
  static List<String> generateTimeSlots(int startHour, int endHour) {
    List<String> slots = [];
    for (int hour = startHour; hour < endHour; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
    }
    return slots;
  }

  // Generate time slots with 30-minute intervals
  static List<String> generateHalfHourSlots(int startHour, int endHour) {
    List<String> slots = [];
    for (int hour = startHour; hour < endHour; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
      slots.add('${hour.toString().padLeft(2, '0')}:30');
    }
    return slots;
  }

  // Generate time slots with custom minute intervals
  static List<String> generateCustomIntervalSlots(
    int startHour,
    int endHour,
    int intervalMinutes,
  ) {
    List<String> slots = [];
    for (int hour = startHour; hour < endHour; hour++) {
      for (int minute = 0; minute < 60; minute += intervalMinutes) {
        slots.add('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      }
    }
    return slots;
  }
}

// Firestore service for DoctorSchedule operations
class DoctorScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'doctor_schedules';

  // Create or update a doctor schedule
  Future<void> saveSchedule(DoctorSchedule schedule) async {
    try {
      await _firestore.collection(_collection).doc(schedule.id).set(
            schedule.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to save schedule: $e');
    }
  }

  // Get a doctor's schedule
  Future<DoctorSchedule?> getSchedule(String doctorId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(doctorId).get();
      if (doc.exists) {
        return DoctorSchedule.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get schedule: $e');
    }
  }

  // Stream a doctor's schedule (real-time updates)
  Stream<DoctorSchedule?> streamSchedule(String doctorId) {
    return _firestore
        .collection(_collection)
        .doc(doctorId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return DoctorSchedule.fromFirestore(doc);
      }
      return null;
    });
  }

  // Add a booking to a doctor's schedule for a specific date
  Future<void> addBooking(String doctorId, DateTime date, Booking booking) async {
    try {
      final schedule = await getSchedule(doctorId);
      if (schedule == null) {
        throw Exception('Schedule not found');
      }

      final updatedSchedule = schedule.addBooking(date, booking);
      await saveSchedule(updatedSchedule);
    } catch (e) {
      throw Exception('Failed to add booking: $e');
    }
  }

  // Remove a booking from a doctor's schedule for a specific date
  Future<void> removeBooking(String doctorId, DateTime date, String time) async {
    try {
      final schedule = await getSchedule(doctorId);
      if (schedule == null) {
        throw Exception('Schedule not found');
      }

      final updatedSchedule = schedule.removeBooking(date, time);
      await saveSchedule(updatedSchedule);
    } catch (e) {
      throw Exception('Failed to remove booking: $e');
    }
  }

  // Create initial schedule for a doctor with date range
  Future<void> createInitialSchedule(
    String doctorId,
    String doctorName, {
    Map<String, List<String>>? customSchedule,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? defaultTimeSlots,
    List<int>? excludeWeekdays, // Optional: exclude specific weekdays
  }) async {
    try {
      Map<String, List<String>> scheduleMap;
      
      if (customSchedule != null) {
        scheduleMap = customSchedule;
      } else if (startDate != null && endDate != null && defaultTimeSlots != null) {
        // Generate schedule for date range
        // Only exclude weekdays if explicitly provided
        scheduleMap = DateScheduleGenerator.generateScheduleForDateRange(
          startDate,
          endDate,
          defaultTimeSlots,
          excludeWeekdays: excludeWeekdays, // Don't exclude by default
        );
      } else {
        // Create empty schedule
        scheduleMap = {};
      }

      final schedule = DoctorSchedule(
        id: doctorId,
        doctorName: doctorName,
        schedule: scheduleMap,
        bookings: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await saveSchedule(schedule);
    } catch (e) {
      throw Exception('Failed to create initial schedule: $e');
    }
  }

  // Add schedule for a specific date
  Future<void> addDateSchedule(
    String doctorId,
    DateTime date,
    List<String> timeSlots,
  ) async {
    try {
      final dateString = DoctorSchedule.dateToString(date);
      final schedule = await getSchedule(doctorId);
      
      if (schedule == null) {
        throw Exception('Schedule not found');
      }

      final newSchedule = Map<String, List<String>>.from(schedule.schedule);
      newSchedule[dateString] = timeSlots;

      await _firestore.collection(_collection).doc(doctorId).update({
        'schedule': newSchedule,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to add date schedule: $e');
    }
  }

  // Remove schedule for a specific date
  Future<void> removeDateSchedule(String doctorId, DateTime date) async {
    try {
      final dateString = DoctorSchedule.dateToString(date);
      final schedule = await getSchedule(doctorId);
      
      if (schedule == null) {
        throw Exception('Schedule not found');
      }

      final newSchedule = Map<String, List<String>>.from(schedule.schedule);
      newSchedule.remove(dateString);

      await _firestore.collection(_collection).doc(doctorId).update({
        'schedule': newSchedule,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to remove date schedule: $e');
    }
  }

  // Update doctor's entire schedule
  Future<void> updateSchedule(
    String doctorId,
    Map<String, List<String>> newSchedule,
  ) async {
    try {
      await _firestore.collection(_collection).doc(doctorId).update({
        'schedule': newSchedule,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  // Delete a doctor's schedule
  Future<void> deleteSchedule(String doctorId) async {
    try {
      await _firestore.collection(_collection).doc(doctorId).delete();
    } catch (e) {
      throw Exception('Failed to delete schedule: $e');
    }
  }

  // Get all schedules (for admin purposes)
  Future<List<DoctorSchedule>> getAllSchedules() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs
          .map((doc) => DoctorSchedule.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all schedules: $e');
    }
  }

  // Check if a slot is available on a specific date
  Future<bool> isSlotAvailable(
    String doctorId,
    DateTime date,
    String time,
  ) async {
    try {
      final schedule = await getSchedule(doctorId);
      if (schedule == null) return false;
      return schedule.isSlotAvailable(date, time);
    } catch (e) {
      return false;
    }
  }

  // Get available dates in a range
  Future<List<DateTime>> getAvailableDates(
    String doctorId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final schedule = await getSchedule(doctorId);
      if (schedule == null) return [];
      
      return schedule.getScheduledDates().where((date) {
        return (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
               (date.isBefore(endDate) || date.isAtSameMomentAs(endDate));
      }).toList();
    } catch (e) {
      return [];
    }
  }
}