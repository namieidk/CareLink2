// lib/screens/patient.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Home.dart';
import 'caremed.dart';
import 'calendar.dart';
import 'Profile.dart';
import '../shared/message.dart';
import '../models/patient_profile.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String _currentUserName = 'Caregiver';

  List<PatientProfile> patients = [];
  bool isLoading = true;
  final Map<String, bool> _expandedMap = {};

  // Messages
  List<Map<String, dynamic>> _messageList = [];
  int _totalUnread = 0;
  bool _isLoadingMessages = true;

  @override
  void initState() {
    super.initState();
    _loadCaregiverName();
    _loadPatients();
    _listenToAllChats();
  }

  Future<void> _loadCaregiverName() async {
    try {
      final doc = await _firestore.collection('caregiver_profile').doc(_currentUserId).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _currentUserName = doc.data()!['fullName'] ?? 'Caregiver';
        });
      }
    } catch (e) {
      debugPrint('Error loading name: $e');
    }
  }

  Future<void> _loadPatients() async {
    try {
      final snapshot = await _firestore.collection('patient_profiles').get();
      final loaded = snapshot.docs
          .map((doc) => PatientProfile.fromMap(doc.data(), doc.id))
          .toList();

      if (mounted) {
        setState(() {
          patients = loaded;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _listenToAllChats() {
    _firestore.collection('messages').snapshots().listen((snapshot) async {
      List<Map<String, dynamic>> chats = [];
      int totalUnread = 0;

      for (var doc in snapshot.docs) {
        final chatId = doc.id;
        if (!chatId.contains(_currentUserId)) continue;

        final ids = chatId.split('_');
        final patientId = ids[0] == _currentUserId ? ids[1] : ids[0];

        final patientDoc = await _firestore.collection('patient_profiles').doc(patientId).get();
        if (!patientDoc.exists) continue;

        final pData = patientDoc.data()!;
        final name = pData['fullName'] ?? 'Patient';
        final photo = pData['profilePhotoUrl'] as String? ?? '';

        final lastMsgSnap = await _firestore
            .collection('messages')
            .doc(chatId)
            .collection('chat')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        String lastMessage = 'No messages yet';
        Timestamp? lastTime;
        bool hasUnread = false;

        if (lastMsgSnap.docs.isNotEmpty) {
          final msg = lastMsgSnap.docs.first.data();
          lastMessage = msg['text'] ?? 'Sent a photo';
          lastTime = msg['timestamp'] as Timestamp?;
          final senderId = msg['senderId'] as String;

          if (senderId != _currentUserId && (msg['isRead'] == false || msg['isRead'] == null)) {
            hasUnread = true;
            totalUnread++;
          }
        }

        chats.add({
          'chatId': chatId,
          'patientId': patientId,
          'patientName': name,
          'patientPhoto': photo,
          'lastMessage': lastMessage,
          'lastTime': lastTime,
          'hasUnread': hasUnread,
        });
      }

      chats.sort((a, b) {
        final tA = a['lastTime'] as Timestamp?;
        final tB = b['lastTime'] as Timestamp?;
        if (tB == null) return 1;
        if (tA == null) return -1;
        return tB.compareTo(tA);
      });

      if (mounted) {
        setState(() {
          _messageList = chats;
          _totalUnread = totalUnread;
          _isLoadingMessages = false;
        });
      }
    });
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${date.month}/${date.day}';
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
              _totalUnread > 0 ? '$_totalUnread unread messages' : 'No unread messages',
              Icons.message,
              const Color(0xFFFF6B6B),
            ),
            Expanded(
              child: _isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : _messageList.isEmpty
                      ? const Center(child: Text('No conversations yet', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _messageList.length,
                          itemBuilder: (_, i) {
                            final chat = _messageList[i];
                            return _buildMessageCard(
                              chat['patientName'],
                              chat['lastMessage'],
                              _formatTime(chat['lastTime']),
                              chat['hasUnread'],
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => MessageScreen(
      patientName: chat['patientName'],
      patientPhoto: chat['patientPhoto'],
      patientId: chat['patientId'],
      caregiverId: _currentUserId,
      caregiverName: _currentUserName,
      caregiverPhoto: '', // Add caregiver photo if available
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

  void _showBookingRequests() {
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
            _buildBottomSheetHeader('Booking Requests', '3 pending requests', Icons.calendar_today, const Color(0xFF6C5CE7)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildBookingRequestCard('Maria Santos', 'Initial Consultation', 'Nov 20, 2025', '2:00 PM', 'Would like to discuss care options for elderly mother with arthritis.'),
                  const SizedBox(height: 16),
                  _buildBookingRequestCard('Jose Reyes', 'Follow-up', 'Nov 22, 2025', '10:00 AM', 'Follow-up consultation regarding medication management.'),
                  const SizedBox(height: 16),
                  _buildBookingRequestCard('Ana Lopez', 'Health Assessment', 'Nov 25, 2025', '3:30 PM', 'Need comprehensive health assessment for 75-year-old father.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(PatientProfile patient) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedType = 'Job Application';
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF6C5CE7).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.work, color: Color(0xFF6C5CE7), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Book Appointment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Text('with ${patient.fullName}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Job Application Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                      items: ['Job Application', 'Initial Consultation', 'Follow-up']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setDialog(() => selectedType = v!),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Select Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                        builder: (_, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF6C5CE7))), child: child!),
                      );
                      if (d != null) setDialog(() => selectedDate = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF6C5CE7), size: 20),
                          const SizedBox(width: 12),
                          Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: const TextStyle(fontSize: 15, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Select Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: selectedTime,
                        builder: (_, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF6C5CE7))), child: child!),
                      );
                      if (t != null) setDialog(() => selectedTime = t);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFF6C5CE7), size: 20),
                          const SizedBox(width: 12),
                          Text(selectedTime.format(ctx), style: const TextStyle(fontSize: 15, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Additional Notes (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter any specific concerns...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Color(0xFFE8EAED)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showBookingConfirmation(patient, selectedDate, selectedTime, selectedType);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingConfirmation(PatientProfile patient, DateTime date, TimeOfDay time, String type) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 48)),
              const SizedBox(height: 20),
              const Text('Appointment Booked!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              Text('Your $type with ${patient.fullName} has been scheduled for:', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF5F6F7), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.work, size: 16, color: Color(0xFF6C5CE7)), SizedBox(width: 8), Text('Job Application', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87))]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6C5CE7)), const SizedBox(width: 8), Text('${date.day}/${date.month}/${date.year}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87))]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.access_time, size: 16, color: Color(0xFF6C5CE7)), const SizedBox(width: 8), Text('${time.hour}:${time.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87))]),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
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
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))]),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.black54)),
                      const Text('Browse Patients', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const Spacer(),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.black54)),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _iconButton(
                          icon: Icons.notifications_active,
                          badge: 3,
                          color: const Color(0xFF6C5CE7),
                          onTap: _showBookingRequests,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _iconButton(
                          icon: Icons.message,
                          badge: _totalUnread,
                          color: const Color(0xFFFF6B6B),
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
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
                  : patients.isEmpty
                      ? const Center(child: Text('No patients found.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: patients.length,
                          itemBuilder: (_, i) => Column(
                            children: [
                              _buildExpandablePatientCard(patients[i]),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomMessageNav(context, 1),
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
                  child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandablePatientCard(PatientProfile p) {
    final bool isExpanded = _expandedMap[p.id] ?? false;
    final chat = _messageList.firstWhere((c) => c['patientId'] == p.id, orElse: () => {'hasUnread': false});
    final unread = chat['hasUnread'] == true;

    return GestureDetector(
      onTap: () => setState(() => _expandedMap[p.id] = !isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EAED), width: 1),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
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
                  child: p.profilePhotoUrl != null && p.profilePhotoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(p.profilePhotoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 36, color: Colors.grey)),
                        )
                      : const Icon(Icons.person, size: 36, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text('${p.age} years', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      if (p.conditions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF6C5CE7).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(p.conditions.first, style: const TextStyle(color: Color(0xFF6C5CE7), fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(color: Color(0xFFFF5252), borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: const Text('!', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 8),
                AnimatedRotation(turns: isExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 300), child: const Icon(Icons.keyboard_arrow_down, color: Colors.grey)),
              ],
            ),

            if (isExpanded) ...[
              const SizedBox(height: 16),
              _infoRow(Icons.email_outlined, p.email),
              const SizedBox(height: 8),
              _infoRow(Icons.phone_outlined, p.phone),
              const SizedBox(height: 8),
              _infoRow(Icons.location_on_outlined, p.address),
              const SizedBox(height: 8),
              if (p.bloodType.isNotEmpty) _infoRow(Icons.bloodtype, p.bloodType),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE8EAED), height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => MessageScreen(
      patientName: p.fullName,
      patientPhoto: p.profilePhotoUrl ?? '',
      patientId: p.id,
      caregiverId: _currentUserId,
      caregiverName: _currentUserName,
      caregiverPhoto: '', // Add caregiver photo if available
    ),
  ),
);
                      },
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text('Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6C5CE7),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBookingDialog(p),
                      icon: const Icon(Icons.work, size: 18),
                      label: const Text('Book'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        foregroundColor: Colors.white,
                        elevation: 0,
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

  Widget _infoRow(IconData icon, String text) {
    if (text.isEmpty || text == 'Not provided') return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87))),
      ],
    );
  }

  Widget _buildBottomMessageNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE8EAED), width: 1))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(context, Icons.home, 'Home', currentIndex == 0, 0),
              _navItem(context, Icons.people, 'Patients', currentIndex == 1, 1),
              _navItem(context, Icons.medication, 'Medications', currentIndex == 2, 2),
              _navItem(context, Icons.calendar_month, 'Calendar', currentIndex == 3, 3),
              _navItem(context, Icons.person, 'Profile', currentIndex == 4, 4),
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
            0: CaregiverHomeScreen(),
            1: const PatientsScreen(),
            2: MedicationScreen(),
            3: CalendarScreen(),
            4: ProfileScreen(),
          }[index]!;
          Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => target));
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? const Color(0xFF6C5CE7) : Colors.grey, size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: active ? const Color(0xFF6C5CE7) : Colors.grey, fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
          ],
        ),
      ),
    );
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

  Widget _buildMessageCard(String name, String message, String time, bool isUnread, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFFF6B6B).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isUnread ? const Color(0xFFFF6B6B).withOpacity(0.3) : const Color(0xFFE8EAED)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFF5F6F7),
              child: Text(name.isNotEmpty ? name[0] : 'P', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(fontSize: 13, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              children: [
                Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (isUnread)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingRequestCard(String name, String type, String date, String time, String notes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: const Color(0xFFF5F6F7), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.person, size: 28, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF6C5CE7).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(type, style: const TextStyle(color: Color(0xFF6C5CE7), fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFFF9800).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Text('Pending', style: TextStyle(color: Color(0xFFFF9800), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF5F6F7), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6C5CE7)),
                const SizedBox(width: 8),
                Text(date, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Color(0xFF6C5CE7)),
                const SizedBox(width: 8),
                Text(time, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(notes, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFE8EAED)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Decline', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}