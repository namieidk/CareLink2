// lib/screens/PatientCaregiverScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'Home.dart';
import 'Medication.dart';
import 'Appointment.dart';
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

  List<Map<String, dynamic>> _messageList = [];
  bool _isLoadingMessages = true;
  int _totalUnread = 0;
  
  List<Map<String, dynamic>> _bookingList = [];
  bool _isLoadingBookings = true;
  int _totalPendingBookings = 0;

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
    _listenToBookings();
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
    debugPrint('Starting to listen for messages...');
    
    _firestore.collection('messages').snapshots().listen((snapshot) async {
      debugPrint('Messages collection snapshot received: ${snapshot.docs.length} chat documents');
      
      List<Map<String, dynamic>> chats = [];
      int totalUnread = 0;

      for (var chatDoc in snapshot.docs) {
        final chatId = chatDoc.id;
        debugPrint('   Processing chat document: $chatId');
        
        if (!chatId.contains(_currentUserId)) {
          debugPrint('   Skipping - chat does not involve current user');
          continue;
        }

        final ids = chatId.split('_');
        if (ids.length != 2) {
          debugPrint('   Invalid chat ID format');
          continue;
        }

        final caregiverId = ids[0] == _currentUserId ? ids[1] : ids[0];
        debugPrint('   Caregiver ID: $caregiverId');

        final caregiverQuery = await _firestore
            .collection('caregiver_profile')
            .where('caregiverId', isEqualTo: caregiverId)
            .limit(1)
            .get();

        if (caregiverQuery.docs.isEmpty) {
          debugPrint('   No caregiver profile found with caregiverId: $caregiverId');
          continue;
        }

        final caregiverDoc = caregiverQuery.docs.first;
        final cgData = caregiverDoc.data();
        
        final caregiverName = '${cgData['firstName'] ?? 'Caregiver'} ${cgData['lastName'] ?? ''}'.trim();
        final caregiverPhoto = cgData['profilePhotoUrl'] as String? ?? '';
        debugPrint('   Found caregiver: $caregiverName');

        final lastMsgQuery = await _firestore
            .collection('messages')
            .doc(chatId)
            .collection('chat')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (lastMsgQuery.docs.isEmpty) {
          debugPrint('   No messages in this chat yet');
          continue;
        }

        final msgData = lastMsgQuery.docs.first.data();
        final lastMessage = msgData['text'] ?? 'Sent a photo';
        final lastTime = msgData['timestamp'] as Timestamp?;
        final senderId = msgData['senderId'] as String?;

        debugPrint('   Last message: "$lastMessage" from $senderId');

        bool isUnread = false;
        if (senderId != null && 
            senderId != _currentUserId && 
            (msgData['isRead'] == null || msgData['isRead'] == false)) {
          isUnread = true;
          totalUnread++;
          debugPrint('   Message is UNREAD');
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

      debugPrint('Final result: ${chats.length} chats, $totalUnread unread messages');

      if (mounted) {
        setState(() {
          _messageList = chats;
          _totalUnread = totalUnread;
          _isLoadingMessages = false;
        });
      }
    }, onError: (e) {
      debugPrint('Stream error: $e');
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
    });
  }

  void _listenToBookings() {
    debugPrint('Starting to listen for bookings...');
    
    // FIXED: Changed from 'patientId' to 'caregiverId' to show bookings FROM caregivers
    _firestore
        .collection('bookings')
        .where('caregiverId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      debugPrint('Bookings snapshot received: ${snapshot.docs.length} pending bookings from caregivers');
      
      List<Map<String, dynamic>> bookings = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
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
        });
      }
      
      // Sort by creation time (newest first)
      bookings.sort((a, b) {
        final t1 = a['createdAt'] as Timestamp?;
        final t2 = b['createdAt'] as Timestamp?;
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t2.compareTo(t1);
      });
      
      debugPrint('Processed ${bookings.length} pending bookings from caregivers');
      
      if (mounted) {
        setState(() {
          _bookingList = bookings;
          _totalPendingBookings = bookings.length;
          _isLoadingBookings = false;
        });
      }
    }, onError: (e) {
      debugPrint('Booking stream error: $e');
      if (mounted) {
        setState(() => _isLoadingBookings = false);
      }
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
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            _buildBottomSheetHeader(
              'Booking Requests from Caregivers',
              _totalPendingBookings > 0 
                  ? '$_totalPendingBookings pending' 
                  : 'No pending requests',
              Icons.notifications_active,
              purple,
            ),
            Expanded(
              child: _isLoadingBookings
                  ? const Center(
                      child: CircularProgressIndicator(color: purple),
                    )
                  : _bookingList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available, 
                                size: 64, 
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No booking requests',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Booking requests from caregivers will appear here',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _bookingList.length,
                          itemBuilder: (_, i) {
                            final booking = _bookingList[i];
                            return _buildBookingCard(booking);
                          },
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
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: purple.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  booking['interviewType'] == 'Video Call' 
                      ? Icons.videocam 
                      : Icons.person_pin_circle,
                  color: purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['caregiverName'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Booking from: ${booking['patientName'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      booking['interviewType'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (dateTime != null) ...[
            _infoRow(
              Icons.calendar_today,
              DateFormat('MMM d, yyyy').format(dateTime),
              color: purple,
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.access_time,
              '${DateFormat('h:mm a').format(dateTime)} (${booking['durationHours']}h)',
              color: purple,
            ),
            const SizedBox(height: 8),
          ],
          if (booking['meetLink'] != null) ...[
            _infoRow(
              Icons.link,
              'Google Meet link included',
              color: purple,
            ),
            const SizedBox(height: 8),
          ],
          if (booking['address'] != null && booking['address'].toString().isNotEmpty) ...[
            _infoRow(
              Icons.location_on,
              booking['address'],
              color: purple,
            ),
            const SizedBox(height: 8),
          ],
          if (booking['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking['notes'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleBookingResponse(booking['id'], 'rejected'),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleBookingResponse(booking['id'], 'approved'),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleBookingResponse(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'respondedAt': FieldValue.serverTimestamp(),
      });
      
      Navigator.pop(context); // Close the modal
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved' 
                ? 'Booking approved successfully!' 
                : 'Booking rejected',
          ),
          backgroundColor: status == 'approved' ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      debugPrint('Error updating booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMessagesInbox() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
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
                  ? const Center(
                      child: CircularProgressIndicator(color: pink),
                    )
                  : _messageList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, 
                                size: 64, 
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Start a conversation with a caregiver',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
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
                              time: msg['lastTime'] != null
                                  ? _formatTimestamp(msg['lastTime'])
                                  : '',
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

  Widget _buildBottomSheetHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8EAED), width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
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
          border: Border.all(
            color: isUnread ? pink.withOpacity(0.3) : const Color(0xFFE8EAED),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFF5F6F7),
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: pink,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isUnread ? Colors.black87 : Colors.black54,
                      fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: isUnread ? pink : Colors.grey,
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isUnread)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: pink,
                      shape: BoxShape.circle,
                    ),
                  ),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.black54),
                      ),
                      const Text(
                        'Find a Caregiver',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list, color: Colors.black54),
                      ),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: pink, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _iconButton(
                          icon: Icons.notifications_active,
                          badge: _totalPendingBookings,
                          color: purple,
                          onTap: _showBookingsInbox,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _iconButton(
                          icon: Icons.message,
                          badge: _totalUnread,
                          color: pink,
                          onTap: _showMessagesInbox,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: pink),
                    )
                  : _filteredCaregivers.isEmpty
                      ? const Center(
                          child: Text(
                            'No caregivers found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredCaregivers.length,
                          itemBuilder: (_, i) => Column(
                            children: [
                              _buildExpandableCaregiverCard(
                                _filteredCaregivers[i],
                              ),
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

  Widget _iconButton({
    required IconData icon,
    required int badge,
    required Color color,
    required VoidCallback onTap,
  }) {
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5252),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================
  // BOOKING MODAL — IMPROVED ERROR HANDLING
  // =========================================
  void _showBookingModal(CaregiverProfile caregiver) {
    final name = '${caregiver.firstName} ${caregiver.lastName}';
    final rate = caregiver.hourlyRate;

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
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
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
                        // Interview Type
                        const Text('Interview Type', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _optionCard(
                                'Video Call',
                                Icons.videocam,
                                interviewType == 'Video Call',
                                () => setModalState(() => interviewType = 'Video Call'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _optionCard(
                                'In-Person',
                                Icons.person_pin_circle,
                                interviewType == 'In-Person',
                                () => setModalState(() => interviewType = 'In-Person'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Address Input (only for In-Person)
                        if (interviewType == 'In-Person') ...[
                          const Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: addressController,
                            decoration: InputDecoration(
                              hintText: 'Enter meeting address',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: pink, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Date
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
                            if (date != null) {
                              setModalState(() => selectedDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE8EAED)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: pink),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat('EEE, MMM d, yyyy').format(selectedDate),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Time
                        const Text('Time', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setModalState(() => selectedTime = time);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE8EAED)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: pink),
                                const SizedBox(width: 12),
                                Text(
                                  selectedTime.format(context),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Duration
                        const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Slider(
                          value: durationHours.toDouble(),
                          min: 1,
                          max: 8,
                          divisions: 7,
                          label: '$durationHours hour${durationHours > 1 ? 's' : ''}',
                          activeColor: pink,
                          onChanged: (val) {
                            setModalState(() => durationHours = val.round());
                          },
                        ),
                        const SizedBox(height: 20),

                        // Notes
                        const Text('Notes (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Any special requirements?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: pink, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Submit Button with loading state
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (interviewType == 'In-Person' && addressController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter an address for In-Person meeting'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              final startDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );

                              // Show loading dialog
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(color: pink),
                                ),
                              );

                              String? meetLink;
                              String? address;
                              
                              if (interviewType == 'Video Call') {
                                debugPrint('🎥 Creating Google Meet link...');
                                final link = await _authService.createGoogleMeetLink(
                                  startTime: startDateTime,
                                  durationMinutes: durationHours * 60,
                                  summary: 'Interview with $_currentUserName',
                                );
                                
                                // Close loading dialog
                                Navigator.pop(context);
                                
                                if (link == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Google Calendar Permission Required',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Please sign in with Google and grant calendar access. Click "Advanced" if you see a verification warning.',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.orange,
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                  return;
                                }
                                meetLink = link;
                                debugPrint('✅ Meet link created: $meetLink');
                              } else {
                                // Close loading dialog for In-Person
                                Navigator.pop(context);
                                address = addressController.text.trim();
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
                                'status': 'pending',
                                'createdAt': FieldValue.serverTimestamp(),
                                'meetLink': meetLink,
                                'address': address,
                              };

                              try {
                                await _firestore.collection('bookings').add(bookingData);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      interviewType == 'Video Call'
                                          ? 'Booking sent! Meet link created.'
                                          : 'Booking request sent!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                debugPrint('❌ Booking error: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error creating booking: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pink,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Send Booking Request',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
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
          border: Border.all(
            color: selected ? pink : const Color(0xFFE8EAED),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? pink : Colors.grey[600], size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: selected ? pink : Colors.grey[700],
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: c.profilePhotoUrl != null && c.profilePhotoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            c.profilePhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            c.firstName.isNotEmpty && c.lastName.isNotEmpty
                                ? '${c.firstName[0]}${c.lastName[0]}'
                                : 'CG',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: pink,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${c.experienceYears}+ yrs exp',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      if (c.skills.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.skills.take(2).join(', '),
                            style: const TextStyle(
                              color: pink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              _infoRow(Icons.phone_outlined, c.phone),
              const SizedBox(height: 8),
              _infoRow(Icons.email_outlined, c.email),
              const SizedBox(height: 8),
              // FIXED: Changed from '\${c.hourlyRate}/hr' to actual value interpolation
              _infoRow(Icons.attach_money, '\$${c.hourlyRate}/hr'),
              const SizedBox(height: 8),
              _infoRow(Icons.access_time, '${c.availableHoursPerWeek} hrs/week'),
              const SizedBox(height: 8),
              _infoRow(Icons.language, c.languages.join(', ')),
              const SizedBox(height: 16),
              if (c.skills.isNotEmpty) ...[
                const Text(
                  'Skills',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: c.skills
                      .map((s) => Chip(
                            label: Text(s, style: const TextStyle(fontSize: 12)),
                            backgroundColor: pink.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ))
                      .toList(),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE8EAED), width: 1),
        ),
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

  Widget _navItem(
    BuildContext ctx,
    IconData icon,
    String label,
    bool active,
    int index,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (active) return;
          final target = {
            0: const PatientHomePage(),
            1: const PatientMedicationScreen(),
            2: const PatientCaregiverScreen(),
            3: const AppointmentPage(),
            4: const PatientProfileScreen(),
          }[index]!;
          Navigator.pushReplacement(
            ctx,
            MaterialPageRoute(builder: (_) => target),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? pink : Colors.grey, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active ? pink : Colors.grey,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
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