// lib/screens/PatientCaregiverScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Home.dart';
import 'Medication.dart';
import 'Appointment.dart';
import 'Profile.dart';
import '../shared/message.dart';
import '../../models/caregiver_profile.dart';

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
              debugPrint('⚠️ Skipping profile ${doc.id} - no caregiverId found');
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
    debugPrint('🎧 Starting to listen for messages...');
    
    _firestore.collection('messages').snapshots().listen((snapshot) async {
      debugPrint('📬 Messages collection snapshot received: ${snapshot.docs.length} chat documents');
      
      List<Map<String, dynamic>> chats = [];
      int totalUnread = 0;

      for (var chatDoc in snapshot.docs) {
        final chatId = chatDoc.id;
        debugPrint('   📂 Processing chat document: $chatId');
        
        // Check if this chat involves the current user
        if (!chatId.contains(_currentUserId)) {
          debugPrint('   ⏭️ Skipping - chat does not involve current user');
          continue;
        }

        // Extract the other user's ID (caregiver)
        final ids = chatId.split('_');
        if (ids.length != 2) {
          debugPrint('   ❌ Invalid chat ID format');
          continue;
        }

        final caregiverId = ids[0] == _currentUserId ? ids[1] : ids[0];
        debugPrint('   👤 Caregiver ID: $caregiverId');

        // Query all caregiver profiles to find matching caregiverId
        final caregiverQuery = await _firestore
            .collection('caregiver_profile')
            .where('caregiverId', isEqualTo: caregiverId)
            .limit(1)
            .get();

        if (caregiverQuery.docs.isEmpty) {
          debugPrint('   ❌ No caregiver profile found with caregiverId: $caregiverId');
          continue;
        }

        final caregiverDoc = caregiverQuery.docs.first;
        final cgData = caregiverDoc.data();
        
        final caregiverName = '${cgData['firstName'] ?? 'Caregiver'} ${cgData['lastName'] ?? ''}'.trim();
        final caregiverPhoto = cgData['profilePhotoUrl'] as String? ?? '';
        debugPrint('   ✅ Found caregiver: $caregiverName');

        // Get the last message in this chat
        final lastMsgQuery = await _firestore
            .collection('messages')
            .doc(chatId)
            .collection('chat')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (lastMsgQuery.docs.isEmpty) {
          debugPrint('   📭 No messages in this chat yet');
          continue;
        }

        final msgData = lastMsgQuery.docs.first.data();
        final lastMessage = msgData['text'] ?? 'Sent a photo';
        final lastTime = msgData['timestamp'] as Timestamp?;
        final senderId = msgData['senderId'] as String?;

        debugPrint('   💬 Last message: "$lastMessage" from $senderId');

        bool isUnread = false;
        if (senderId != null && 
            senderId != _currentUserId && 
            (msgData['isRead'] == null || msgData['isRead'] == false)) {
          isUnread = true;
          totalUnread++;
          debugPrint('   🔴 Message is UNREAD');
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

      // Sort by most recent message
      chats.sort((a, b) {
        final t1 = a['lastTime'] as Timestamp?;
        final t2 = b['lastTime'] as Timestamp?;
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t2.compareTo(t1);
      });

      debugPrint('📋 Final result: ${chats.length} chats, $totalUnread unread messages');

      if (mounted) {
        setState(() {
          _messageList = chats;
          _totalUnread = totalUnread;
          _isLoadingMessages = false;
        });
      }
    }, onError: (e) {
      debugPrint('❌ Stream error: $e');
      if (mounted) {
        setState(() => _isLoadingMessages = false);
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
                          badge: 3,
                          color: purple,
                          onTap: () {},
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
                      onPressed: () {},
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