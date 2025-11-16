// lib/screens/PatientCaregiverScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import 'Home.dart';
import 'Medication.dart';
import 'doctor.dart';
import 'Profile.dart';
import '../shared/message.dart';
import '../../models/caregiver_profile.dart';
import '../../auth_service.dart';

class PatientCaregiverScreen extends StatefulWidget {
  const PatientCaregiverScreen({super.key});

  @override
  State<PatientCaregiverScreen> createState() => _PatientCaregiverScreenState();
}

class _PatientCaregiverScreenState extends State<PatientCaregiverScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final String _currentUserId;
  String _currentUserName = 'Patient';
  String _currentUserPhoto = '';

  List<CaregiverProfile> caregivers = [];
  bool isLoading = true;
  final Map<String, bool> _expandedMap = {};
  final TextEditingController _searchController = TextEditingController();

  static const Color pink = Color(0xFFFF6B6B);
  static const Color purple = Color(0xFF6C5CE7);
  static const Color green = Color(0xFF00B894);

  // Messages
  List<Map<String, dynamic>> _messageList = [];
  bool _isLoadingMessages = true;
  int _totalUnread = 0;

  // Pending incoming requests (only from caregivers)
  List<Map<String, dynamic>> _bookingList = [];
  bool _isLoadingBookings = true;
  int _totalPendingBookings = 0;

  // Accepted bookings (both directions, once accepted)
  List<Map<String, dynamic>> _acceptedBookingList = [];
  bool _isLoadingAcceptedBookings = true;
  int _totalAcceptedBookings = 0;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    _currentUserId = user.uid;
    _loadPatientName();
    _loadCaregivers();
    _listenToMessages();
    _listenToBookings();           // only real incoming from caregivers
    _listenToAcceptedBookings();
    _searchController.addListener(() => setState(() {}));
  }

  Future<void> _loadPatientName() async {
    try {
      final doc = await _firestore.collection('patient_profiles').doc(_currentUserId).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _currentUserName = doc.data()!['fullName'] ?? 'Patient';
          _currentUserPhoto = doc.data()!['profilePhotoUrl'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading patient name: $e');
    }
  }

  Future<void> _loadCaregivers() async {
    try {
      final snapshot = await _firestore.collection('caregiver_profile').get();
      final loaded = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final authUid = data['caregiverId'] as String?;
            if (authUid == null || authUid.isEmpty) {
              debugPrint('Warning: Skipping profile ${doc.id} - no caregiverId found');
              return null;
            }
            return CaregiverProfile.fromMap(data, authUid);
          })
          .whereType<CaregiverProfile>()
          .toList();
      if (mounted) {
        setState(() {
          caregivers = loaded;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading caregivers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getChatId(String caregiverId) {
    final ids = [_currentUserId, caregiverId];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  void _listenToMessages() {
    _firestore.collection('messages').snapshots().listen((snapshot) async {
      List<Map<String, dynamic>> chats = [];
      int totalUnread = 0;

      for (var chatDoc in snapshot.docs) {
        final chatId = chatDoc.id;
        if (!chatId.contains(_currentUserId)) continue;

        final ids = chatId.split('_');
        if (ids.length != 2) continue;

        final caregiverId = ids[0] == _currentUserId ? ids[1] : ids[0];

        final caregiverQuery = await _firestore
            .collection('caregiver_profile')
            .where('caregiverId', isEqualTo: caregiverId)
            .limit(1)
            .get();
        if (caregiverQuery.docs.isEmpty) continue;

        final cgData = caregiverQuery.docs.first.data();
        final caregiverName = '${cgData['firstName'] ?? 'Caregiver'} ${cgData['lastName'] ?? ''}'.trim();
        final caregiverPhoto = cgData['profilePhotoUrl'] as String? ?? '';

        final lastMsgQuery = await _firestore
            .collection('messages')
            .doc(chatId)
            .collection('chat')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (lastMsgQuery.docs.isEmpty) continue;

        final msgData = lastMsgQuery.docs.first.data();
        final lastMessage = msgData['text'] ?? 'Sent a photo';
        final lastTime = msgData['timestamp'] as Timestamp?;
        final senderId = msgData['senderId'] as String?;

        bool isUnread = false;
        if (senderId != null && senderId != _currentUserId &&
            (msgData['isRead'] == null || msgData['isRead'] == false)) {
          isUnread = true;
          totalUnread++;
        }

        chats.add({
          'chatId': chatId,
          'caregiverId': caregiverId,
          'caregiverName': caregiverName,
          'caregiverPhoto': caregiverPhoto,
          'lastMessage': lastMessage,
          'lastTime': lastTime,
          'isUnread': isUnread,
        });
      }

      chats.sort((a, b) {
        final t1 = a['lastTime'] as Timestamp?;
        final t2 = b['lastTime'] as Timestamp?;
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t2.compareTo(t1);
      });

      if (mounted) {
        setState(() {
          _messageList = chats;
          _totalUnread = totalUnread;
          _isLoadingMessages = false;
        });
      }
    }, onError: (e) {
      if (mounted) setState(() => _isLoadingMessages = false);
    });
  }

  // Only real incoming requests from caregivers - FIXED VERSION
  void _listenToBookings() {
    _firestore
        .collection('bookings')
        .where('patientId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      final List<Map<String, dynamic>> bookings = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Show ALL pending bookings for this patient, regardless of who requested
        // This includes bookings from caregivers AND patient's own requests
        bookings.add({
          'id': doc.id,
          'caregiverName': data['caregiverName'] ?? 'Unknown',
          'patientName': data['patientName'] ?? 'Unknown Patient',
          'interviewType': data['interviewType'] ?? 'Video Call',
          'startTime': data['startTime'] as Timestamp?,
          'durationHours': data['durationHours'] ?? 1,
          'meetLink': data['meetLink'],
          'address': data['address'],
          'notes': data['notes'] ?? '',
          'createdAt': data['createdAt'] as Timestamp?,
          'requestedBy': data['requestedBy'] ?? 'patient', // Track who made the request
        });
      }

      bookings.sort((a, b) {
        final t1 = a['createdAt'] as Timestamp?;
        final t2 = b['createdAt'] as Timestamp?;
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t2.compareTo(t1);
      });

      if (mounted) {
        setState(() {
          _bookingList = bookings;
          _totalPendingBookings = bookings.length;
          _isLoadingBookings = false;
        });
      }
    }, onError: (e) {
      if (mounted) setState(() => _isLoadingBookings = false);
    });
  }

  // All accepted bookings (both directions)
  void _listenToAcceptedBookings() {
    _firestore
        .collection('bookings')
        .where('patientId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
      final List<Map<String, dynamic>> acceptedBookings = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        acceptedBookings.add({
          'id': doc.id,
          'caregiverName': data['caregiverName'] ?? 'Unknown',
          'patientName': data['patientName'] ?? 'Unknown Patient',
          'interviewType': data['interviewType'] ?? 'Video Call',
          'startTime': data['startTime'] as Timestamp?,
          'durationHours': data['durationHours'] ?? 1,
          'meetLink': data['meetLink'],
          'address': data['address'],
          'notes': data['notes'] ?? '',
          'respondedAt': data['respondedAt'] as Timestamp?,
          'requestedBy': data['requestedBy'] ?? 'patient',
        });
      }

      acceptedBookings.sort((a, b) {
        final t1 = a['startTime'] as Timestamp?;
        final t2 = b['startTime'] as Timestamp?;
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t1.compareTo(t2);
      });

      if (mounted) {
        setState(() {
          _acceptedBookingList = acceptedBookings;
          _totalAcceptedBookings = acceptedBookings.length;
          _isLoadingAcceptedBookings = false;
        });
      }
    }, onError: (e) {
      if (mounted) setState(() => _isLoadingAcceptedBookings = false);
    });
  }

  List<CaregiverProfile> get _filteredCaregivers {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return caregivers;
    return caregivers.where((c) {
      final name = '${c.firstName} ${c.lastName}'.toLowerCase();
      final skills = c.skills.any((s) => s.toLowerCase().contains(query));
      final bio = c.bio.toLowerCase().contains(query);
      return name.contains(query) || skills || bio;
    }).toList();
  }

  void _showBookingsInbox() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildBottomSheetHeader(
              'Booking Requests',
              _totalPendingBookings > 0 ? '$_totalPendingBookings pending' : 'No pending requests',
              Icons.notifications_active,
              purple,
            ),
            Expanded(
              child: _isLoadingBookings
                  ? const Center(child: CircularProgressIndicator(color: purple))
                  : _bookingList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text('No booking requests', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              const Text('Booking requests will appear here', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _bookingList.length,
                          itemBuilder: (_, i) => _buildBookingCard(_bookingList[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAcceptedBookings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildBottomSheetHeader(
              'Accepted Bookings',
              _totalAcceptedBookings > 0 ? '$_totalAcceptedBookings upcoming' : 'No accepted bookings',
              Icons.check_circle,
              green,
            ),
            Expanded(
              child: _isLoadingAcceptedBookings
                  ? const Center(child: CircularProgressIndicator(color: green))
                  : _acceptedBookingList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text('No accepted bookings', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              const Text('Accepted bookings will appear here', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _acceptedBookingList.length,
                          itemBuilder: (_, i) => _buildAcceptedBookingCard(_acceptedBookingList[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final startTime = booking['startTime'] as Timestamp?;
    final dateTime = startTime?.toDate();
    final requestedBy = booking['requestedBy'] ?? 'patient';

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: purple.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(
                  booking['interviewType'] == 'Video Call' ? Icons.videocam : Icons.person_pin_circle,
                  color: purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking['caregiverName'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text(booking['interviewType'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    if (requestedBy == 'caregiver')
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'From Caregiver',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (dateTime != null) ...[
            _infoRow(Icons.calendar_today, DateFormat('MMM d, yyyy').format(dateTime), color: purple),
            const SizedBox(height: 8),
            _infoRow(Icons.access_time, '${DateFormat('h:mm a').format(dateTime)} (${booking['durationHours']}h)', color: purple),
            const SizedBox(height: 8),
          ],
          if (booking['meetLink'] != null) ...[
            _infoRow(Icons.link, 'Google Meet link included', color: purple),
            const SizedBox(height: 8),
          ],
          if (booking['address'] != null && booking['address'].toString().isNotEmpty) ...[
            _infoRow(Icons.location_on, booking['address'], color: purple),
            const SizedBox(height: 8),
          ],
          if (booking['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(booking['notes'], style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Only show action buttons for requests from caregivers
          if (requestedBy == 'caregiver')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleBookingResponse(booking['id'], 'rejected', booking),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleBookingResponse(booking['id'], 'accepted', booking),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            )
          else
            // Show status for patient's own requests
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pending, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Text(
                    'Waiting for caregiver response',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAcceptedBookingCard(Map<String, dynamic> booking) {
    final startTime = booking['startTime'] as Timestamp?;
    final dateTime = startTime?.toDate();
    final meetLink = booking['meetLink'] as String?;
    final requestedBy = booking['requestedBy'] ?? 'patient';

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(
                  booking['interviewType'] == 'Video Call' ? Icons.videocam : Icons.person_pin_circle,
                  color: green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking['caregiverName'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text(booking['interviewType'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    if (requestedBy == 'caregiver')
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'From Caregiver',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Accepted', style: TextStyle(color: green, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (dateTime != null) ...[
            _infoRow(Icons.calendar_today, DateFormat('MMM d, yyyy').format(dateTime), color: green),
            const SizedBox(height: 8),
            _infoRow(Icons.access_time, '${DateFormat('h:mm a').format(dateTime)} (${booking['durationHours']}h)', color: green),
            const SizedBox(height: 8),
          ],
          if (booking['address'] != null && booking['address'].toString().isNotEmpty) ...[
            _infoRow(Icons.location_on, booking['address'], color: green),
            const SizedBox(height: 8),
          ],
          if (booking['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(booking['notes'], style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                ],
              ),
            ),
          ],
          if (meetLink != null && meetLink.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchMeetLink(meetLink),
                icon: const Icon(Icons.video_call, size: 20),
                label: const Text('Join Google Meet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _launchMeetLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the meeting link'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleBookingResponse(String bookingId, String status, Map<String, dynamic> bookingData) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: purple)),
      );

      String? generatedMeetLink;
      if (status == 'accepted' && (bookingData['interviewType'] ?? 'Video Call') == 'Video Call') {
        final dateTime = (bookingData['startTime'] as Timestamp).toDate();
        generatedMeetLink = await _authService.createGoogleMeetLink(
          startTime: dateTime,
          durationMinutes: (bookingData['durationHours'] ?? 1) * 60,
          summary: 'Interview: ${bookingData['caregiverName']} (Video Call)',
        );
      }

      final updateData = <String, dynamic>{
        'status': status,
        'respondedAt': FieldValue.serverTimestamp(),
      };
      if (generatedMeetLink != null) {
        updateData['meetLink'] = generatedMeetLink;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updateData);

      if (mounted) Navigator.pop(context);
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'accepted' ? 'Booking accepted!' : 'Booking rejected'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showMessagesInbox() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildBottomSheetHeader(
              'Messages',
              _totalUnread > 0 ? '$_totalUnread unread' : 'All caught up!',
              Icons.message,
              pink,
            ),
            Expanded(
              child: _isLoadingMessages
                  ? const Center(child: CircularProgressIndicator(color: pink))
                  : _messageList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text('No messages yet', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              const Text('Start a conversation with a caregiver', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _messageList.length,
                          itemBuilder: (_, i) {
                            final msg = _messageList[i];
                            return _buildMessageCard(
                              name: msg['caregiverName'],
                              message: msg['lastMessage'],
                              photoUrl: msg['caregiverPhoto'],
                              time: msg['lastTime'] != null ? _formatTimestamp(msg['lastTime']) : '',
                              isUnread: msg['isUnread'],
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MessageScreen(
                                      patientName: _currentUserName,
                                      patientPhoto: _currentUserPhoto,
                                      patientId: _currentUserId,
                                      caregiverId: msg['caregiverId'],
                                      caregiverName: msg['caregiverName'],
                                      caregiverPhoto: msg['caregiverPhoto'],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }

  Widget _buildBottomSheetHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: Color(0xFFE8EAED), width: 1)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard({
    required String name,
    required String message,
    required String photoUrl,
    required String time,
    required bool isUnread,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isUnread ? pink.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isUnread ? pink.withOpacity(0.3) : const Color(0xFFE8EAED)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFF5F6F7),
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'C',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: pink, fontSize: 18))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 15, fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(message,
                      style: TextStyle(fontSize: 13, color: isUnread ? Colors.black87 : Colors.black54, fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: TextStyle(fontSize: 11, color: isUnread ? pink : Colors.grey, fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal)),
                if (isUnread)
                  Container(margin: const EdgeInsets.only(top: 6), width: 10, height: 10, decoration: const BoxDecoration(color: pink, shape: BoxShape.circle)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.black54)),
                      const Text('Find a Caregiver', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const Spacer(),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, skill, or bio...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: pink),
                      filled: true,
                      fillColor: const Color(0xFFF5F6F7),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: pink, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _iconButton(icon: Icons.notifications_active, badge: _totalPendingBookings, color: purple, onTap: _showBookingsInbox)),
                      const SizedBox(width: 12),
                      Expanded(child: _iconButton(icon: Icons.check_circle, badge: _totalAcceptedBookings, color: green, onTap: _showAcceptedBookings)),
                      const SizedBox(width: 12),
                      Expanded(child: _iconButton(icon: Icons.message, badge: _totalUnread, color: pink, onTap: _showMessagesInbox)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: pink))
                  : _filteredCaregivers.isEmpty
                      ? const Center(child: Text('No caregivers found.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredCaregivers.length,
                          itemBuilder: (_, i) => Column(
                            children: [
                              _buildExpandableCaregiverCard(_filteredCaregivers[i]),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 2),
    );
  }

  Widget _iconButton({required IconData icon, required int badge, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: color, size: 28)),
            if (badge > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFFF5252), shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Center(
                    child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBookingModal(CaregiverProfile caregiver) {
    final name = '${caregiver.firstName} ${caregiver.lastName}';
    String interviewType = 'Video Call';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    int durationHours = 1;
    final notesController = TextEditingController();
    final addressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _buildBottomSheetHeader('Book $name', 'Interview & Schedule', Icons.calendar_today, pink),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Interview Type', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _optionCard('Video Call', Icons.videocam, interviewType == 'Video Call', () => setModalState(() => interviewType = 'Video Call'))),
                            const SizedBox(width: 12),
                            Expanded(child: _optionCard('In-Person', Icons.person_pin_circle, interviewType == 'In-Person', () => setModalState(() => interviewType = 'In-Person'))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (interviewType == 'In-Person') ...[
                          const Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: addressController,
                            decoration: InputDecoration(
                              hintText: 'Enter meeting address',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: pink, width: 2)),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (date != null) setModalState(() => selectedDate = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: pink),
                                const SizedBox(width: 12),
                                Text(DateFormat('EEE, MMM d, yyyy').format(selectedDate), style: const TextStyle(fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Time', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final time = await showTimePicker(context: context, initialTime: selectedTime);
                            if (time != null) setModalState(() => selectedTime = time);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: pink),
                                const SizedBox(width: 12),
                                Text(selectedTime.format(context), style: const TextStyle(fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Slider(
                          value: durationHours.toDouble(),
                          min: 1,
                          max: 8,
                          divisions: 7,
                          label: '$durationHours hour${durationHours > 1 ? 's' : ''}',
                          activeColor: pink,
                          onChanged: (val) => setModalState(() => durationHours = val.round()),
                        ),
                        const SizedBox(height: 20),
                        const Text('Notes (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Any special requirements?',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: pink, width: 2)),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (interviewType == 'In-Person' && addressController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter an address for In-Person meeting'), backgroundColor: Colors.orange),
                                );
                                return;
                              }

                              final startDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator(color: pink)),
                              );

                              String? meetLink;
                              String? address;

                              if (interviewType == 'Video Call') {
                                final link = await _authService.createGoogleMeetLink(
                                  startTime: startDateTime,
                                  durationMinutes: durationHours * 60,
                                  summary: 'Interview with $_currentUserName',
                                );
                                Navigator.pop(context);
                                if (link == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Google Calendar permission required'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 5),
                                    ),
                                  );
                                  return;
                                }
                                meetLink = link;
                              } else {
                                address = addressController.text.trim();
                                Navigator.pop(context);
                              }

                              final bookingData = {
                                'patientId': _currentUserId,
                                'patientName': _currentUserName,
                                'caregiverId': caregiver.id,
                                'caregiverName': name,
                                'interviewType': interviewType,
                                'startTime': Timestamp.fromDate(startDateTime),
                                'durationHours': durationHours,
                                'notes': notesController.text.trim(),
                                'meetLink': meetLink,
                                'address': address,
                                'status': 'pending',
                                'requestedBy': 'patient',   // NEW FIELD
                                'createdAt': FieldValue.serverTimestamp(),
                              };

                              try {
                                await _firestore.collection('bookings').add(bookingData);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(interviewType == 'Video Call'
                                        ? 'Request sent with Meet link! Awaiting caregiver approval.'
                                        : 'In-person request sent! Awaiting caregiver approval.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error creating booking: $e'), backgroundColor: Colors.red),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pink,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Send Booking Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _optionCard(String title, IconData icon, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? pink.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? pink : const Color(0xFFE8EAED), width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? pink : Colors.grey[600], size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: selected ? pink : Colors.grey[700], fontWeight: selected ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableCaregiverCard(CaregiverProfile c) {
    final bool isExpanded = _expandedMap[c.id] ?? false;
    final name = '${c.firstName} ${c.lastName}';
    return GestureDetector(
      onTap: () => setState(() => _expandedMap[c.id] = !isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EAED), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(color: const Color(0xFFF5F6F7), borderRadius: BorderRadius.circular(16)),
                  child: c.profilePhotoUrl != null && c.profilePhotoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(c.profilePhotoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 36, color: Colors.grey)),
                        )
                      : Center(child: Text(c.firstName.isNotEmpty && c.lastName.isNotEmpty ? '${c.firstName[0]}${c.lastName[0]}' : 'CG',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: pink))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text('${c.experienceYears}+ yrs exp', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      if (c.skills.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: pink.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(c.skills.take(2).join(', '), style: const TextStyle(color: pink, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ),
                AnimatedRotation(turns: isExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 300), child: const Icon(Icons.keyboard_arrow_down, color: Colors.grey)),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              _infoRow(Icons.phone_outlined, c.phone),
              const SizedBox(height: 8),
              _infoRow(Icons.email_outlined, c.email),
              const SizedBox(height: 8),
              _infoRow(Icons.attach_money, '\${c.hourlyRate}/hr'),
              const SizedBox(height: 8),
              _infoRow(Icons.access_time, '${c.availableHoursPerWeek} hrs/week'),
              const SizedBox(height: 8),
              _infoRow(Icons.language, c.languages.join(', ')),
              const SizedBox(height: 16),
              if (c.skills.isNotEmpty) ...[
                const Text('Skills', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: c.skills.map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 12)), backgroundColor: pink.withOpacity(0.1), padding: const EdgeInsets.symmetric(horizontal: 8))).toList(),
                ),
                const SizedBox(height: 16),
              ],
              const Divider(color: Color(0xFFE8EAED), height: 1),
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
                              patientName: _currentUserName,
                              patientPhoto: _currentUserPhoto,
                              patientId: _currentUserId,
                              caregiverId: c.id,
                              caregiverName: name,
                              caregiverPhoto: c.profilePhotoUrl ?? '',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: pink,
                        side: const BorderSide(color: pink, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBookingModal(c),
                      icon: const Icon(Icons.work, size: 18),
                      label: const Text('Book'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    if (text.isEmpty || text == 'Not provided') return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? pink),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87))),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EAED), width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(context, Icons.home, 'Home', currentIndex == 0, 0),
              _navItem(context, Icons.medication, 'Meds', currentIndex == 1, 1),
              _navItem(context, Icons.local_hospital, 'Caregiver', currentIndex == 2, 2),
              _navItem(context, Icons.calendar_today, 'Schedule', currentIndex == 3, 3),
              _navItem(context, Icons.person_outline, 'Profile', currentIndex == 4, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext ctx, IconData icon, String label, bool active, int index) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (active) return;
          final target = {
            0: const PatientHomePage(),
            1: const PatientMedicationScreen(),
            2: const PatientCaregiverScreen(),
            3: const DoctorPage(),
            4: const PatientProfileScreen(),
          }[index]!;
          Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => target));
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? pink : Colors.grey, size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: active ? pink : Colors.grey, fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}