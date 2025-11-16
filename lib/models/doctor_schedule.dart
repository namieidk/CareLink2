import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorSchedule {
  final String id; // Doctor ID (references doctor_profiles)
  final String doctorName;
  final Map<String, List<String>> schedule; // Day -> List of time slots
  final Map<String, List<String>> bookings; // Day -> List of booked time slots
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
      bookings: _parseScheduleMap(data['bookings']),
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
      bookings: _parseScheduleMap(data['bookings']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Helper method to parse schedule/bookings map
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

  // Convert DoctorSchedule to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'doctorName': doctorName,
      'schedule': schedule,
      'bookings': bookings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with method for updating specific fields
  DoctorSchedule copyWith({
    String? id,
    String? doctorName,
    Map<String, List<String>>? schedule,
    Map<String, List<String>>? bookings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoctorSchedule(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      schedule: schedule ?? Map<String, List<String>>.from(this.schedule),
      bookings: bookings ?? Map<String, List<String>>.from(this.bookings),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get available slots for a specific day
  List<String> getAvailableSlotsForDay(String day) {
    return schedule[day] ?? [];
  }

  // Get booked slots for a specific day
  List<String> getBookedSlotsForDay(String day) {
    return bookings[day] ?? [];
  }

  // Get free slots (available but not booked) for a specific day
  List<String> getFreeSlotsForDay(String day) {
    final available = getAvailableSlotsForDay(day);
    final booked = getBookedSlotsForDay(day);
    return available.where((slot) => !booked.contains(slot)).toList();
  }

  // Check if a specific slot is available
  bool isSlotAvailable(String day, String time) {
    final available = getAvailableSlotsForDay(day);
    final booked = getBookedSlotsForDay(day);
    return available.contains(time) && !booked.contains(time);
  }

  // Check if a specific slot is booked
  bool isSlotBooked(String day, String time) {
    final booked = getBookedSlotsForDay(day);
    return booked.contains(time);
  }

  // Add a booking
  DoctorSchedule addBooking(String day, String time) {
    final newBookings = Map<String, List<String>>.from(bookings);
    if (!newBookings.containsKey(day)) {
      newBookings[day] = [];
    }
    if (!newBookings[day]!.contains(time)) {
      newBookings[day]!.add(time);
    }
    return copyWith(
      bookings: newBookings,
      updatedAt: DateTime.now(),
    );
  }

  // Remove a booking
  DoctorSchedule removeBooking(String day, String time) {
    final newBookings = Map<String, List<String>>.from(bookings);
    if (newBookings.containsKey(day)) {
      newBookings[day]!.remove(time);
    }
    return copyWith(
      bookings: newBookings,
      updatedAt: DateTime.now(),
    );
  }

  // Get total number of available slots for the week
  int getTotalAvailableSlots() {
    return schedule.values.fold(0, (sum, slots) => sum + slots.length);
  }

  // Get total number of booked slots for the week
  int getTotalBookedSlots() {
    return bookings.values.fold(0, (sum, slots) => sum + slots.length);
  }

  // Get total number of free slots for the week
  int getTotalFreeSlots() {
    return getTotalAvailableSlots() - getTotalBookedSlots();
  }

  // Get booking percentage
  double getBookingPercentage() {
    final total = getTotalAvailableSlots();
    if (total == 0) return 0.0;
    return (getTotalBookedSlots() / total) * 100;
  }

  // Get all working days
  List<String> getWorkingDays() {
    return schedule.keys.toList();
  }

  // Check if doctor works on a specific day
  bool worksOnDay(String day) {
    return schedule.containsKey(day) && schedule[day]!.isNotEmpty;
  }

  @override
  String toString() {
    return 'DoctorSchedule(id: $id, doctorName: $doctorName, workingDays: ${getWorkingDays().length})';
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

// Helper class for creating default schedules
class DefaultScheduleGenerator {
  // Generate a standard 9-5 weekday schedule
  static Map<String, List<String>> generateStandardSchedule() {
    return {
      'Monday': _generateTimeSlots(9, 17),
      'Tuesday': _generateTimeSlots(9, 17),
      'Wednesday': _generateTimeSlots(9, 17),
      'Thursday': _generateTimeSlots(9, 17),
      'Friday': _generateTimeSlots(9, 17),
    };
  }

  // Generate morning shift schedule
  static Map<String, List<String>> generateMorningSchedule() {
    return {
      'Monday': _generateTimeSlots(8, 13),
      'Tuesday': _generateTimeSlots(8, 13),
      'Wednesday': _generateTimeSlots(8, 13),
      'Thursday': _generateTimeSlots(8, 13),
      'Friday': _generateTimeSlots(8, 13),
      'Saturday': _generateTimeSlots(8, 12),
    };
  }

  // Generate afternoon shift schedule
  static Map<String, List<String>> generateAfternoonSchedule() {
    return {
      'Monday': _generateTimeSlots(13, 18),
      'Tuesday': _generateTimeSlots(13, 18),
      'Wednesday': _generateTimeSlots(13, 18),
      'Thursday': _generateTimeSlots(13, 18),
      'Friday': _generateTimeSlots(13, 18),
    };
  }

  // Generate time slots between start and end hour (hourly intervals)
  static List<String> _generateTimeSlots(int startHour, int endHour) {
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

  // Generate custom schedule for specific days
  static Map<String, List<String>> generateCustomSchedule(
    Map<String, List<int>> dayHours,
  ) {
    return dayHours.map((day, hours) {
      if (hours.length >= 2) {
        return MapEntry(day, _generateTimeSlots(hours[0], hours[1]));
      }
      return MapEntry(day, <String>[]);
    });
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

  // Add a booking to a doctor's schedule
  Future<void> addBooking(String doctorId, String day, String time) async {
    try {
      final schedule = await getSchedule(doctorId);
      if (schedule == null) {
        throw Exception('Schedule not found');
      }

      final updatedSchedule = schedule.addBooking(day, time);
      await saveSchedule(updatedSchedule);
    } catch (e) {
      throw Exception('Failed to add booking: $e');
    }
  }

  // Remove a booking from a doctor's schedule
  Future<void> removeBooking(String doctorId, String day, String time) async {
    try {
      final schedule = await getSchedule(doctorId);
      if (schedule == null) {
        throw Exception('Schedule not found');
      }

      final updatedSchedule = schedule.removeBooking(day, time);
      await saveSchedule(updatedSchedule);
    } catch (e) {
      throw Exception('Failed to remove booking: $e');
    }
  }

  // Create initial schedule for a doctor
  Future<void> createInitialSchedule(
    String doctorId,
    String doctorName, {
    Map<String, List<String>>? customSchedule,
  }) async {
    try {
      final schedule = DoctorSchedule(
        id: doctorId,
        doctorName: doctorName,
        schedule: customSchedule ?? DefaultScheduleGenerator.generateStandardSchedule(),
        bookings: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await saveSchedule(schedule);
    } catch (e) {
      throw Exception('Failed to create initial schedule: $e');
    }
  }

  // Update doctor's working schedule
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

  // Check if a slot is available
  Future<bool> isSlotAvailable(
    String doctorId,
    String day,
    String time,
  ) async {
    try {
      final schedule = await getSchedule(doctorId);
      if (schedule == null) return false;
      return schedule.isSlotAvailable(day, time);
    } catch (e) {
      return false;
    }
  }
}