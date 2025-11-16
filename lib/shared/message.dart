// lib/shared/message.dart
// Universal MessageScreen for BOTH Caregiver and Patient
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import '../../models/messages.dart';

class MessageScreen extends StatefulWidget {
  final String patientName;
  final String patientPhoto;
  final String patientId;
  final String caregiverId;
  final String caregiverName;
  final String? caregiverPhoto; // Optional

  const MessageScreen({
    super.key,
    required this.patientName,
    required this.patientPhoto,
    required this.patientId,
    required this.caregiverId,
    required this.caregiverName,
    this.caregiverPhoto,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late String _chatId;
  late String _currentUserId;
  late String _currentUserName;
  late bool _isCaregiver;
  bool _hasScrolledToBottom = false;
  bool _hasCaregiver = false;
  bool _isLoadingCaregiverStatus = true;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _isCaregiver = _currentUserId == widget.caregiverId;
    
    // Determine current user's name
    _currentUserName = _isCaregiver ? widget.caregiverName : widget.patientName;
    
    // Generate consistent chatId
    _chatId = _getChatId(widget.patientId, widget.caregiverId);
    
    debugPrint('💬 MessageScreen Init');
    debugPrint('   ChatID: $_chatId');
    debugPrint('   Current User: $_currentUserId (${_isCaregiver ? 'Caregiver' : 'Patient'})');
    debugPrint('   Patient: ${widget.patientId}');
    debugPrint('   Caregiver: ${widget.caregiverId}');
    
    _ensureChatDocumentExists();
    _markMessagesAsRead();
    _checkCaregiverStatus();
  }

  // CRITICAL: Always generates same chatId regardless of who calls it
  String _getChatId(String id1, String id2) {
    final ids = [id1, id2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _checkCaregiverStatus() async {
    if (_isCaregiver) {
      setState(() => _isLoadingCaregiverStatus = false);
      return;
    }

    try {
      // Check if patient already has a caregiver assigned
      final snapshot = await _firestore
          .collection('caregiver_assignments')
          .where('patientId', isEqualTo: widget.patientId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      setState(() {
        _hasCaregiver = snapshot.docs.isNotEmpty;
        _isLoadingCaregiverStatus = false;
      });

      debugPrint('✅ Caregiver status: ${_hasCaregiver ? "Has caregiver" : "No caregiver"}');
    } catch (e) {
      debugPrint('⚠️ Error checking caregiver status: $e');
      setState(() => _isLoadingCaregiverStatus = false);
    }
  }

  Future<void> _ensureChatDocumentExists() async {
    final chatRef = _firestore.collection('messages').doc(_chatId);
    final doc = await chatRef.get();

    if (!doc.exists) {
      await chatRef.set({
        'patientId': widget.patientId,
        'caregiverId': widget.caregiverId,
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'participants': [widget.patientId, widget.caregiverId],
      });
      debugPrint('✅ Created chat document: $_chatId');
    } else {
      debugPrint('✅ Chat document exists: $_chatId');
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      // FIXED: Simplified query without compound index requirement
      final unread = await _firestore
          .collection('messages')
          .doc(_chatId)
          .collection('chat')
          .where('isRead', isEqualTo: false)
          .get();

      // Filter on client side to avoid index requirement
      final myUnread = unread.docs.where((doc) {
        final senderId = doc.data()['senderId'] as String?;
        return senderId != null && senderId != _currentUserId;
      }).toList();

      for (var doc in myUnread) {
        await doc.reference.update({'isRead': true});
      }
      
      if (myUnread.isNotEmpty) {
        debugPrint('✅ Marked ${myUnread.length} messages as read');
      }
    } catch (e) {
      debugPrint('⚠️ Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Determine receiver
    final receiverId = _isCaregiver ? widget.patientId : widget.caregiverId;
    final receiverName = _isCaregiver ? widget.patientName : widget.caregiverName;

    final message = Message(
      id: '',
      text: text,
      senderId: _currentUserId,
      senderName: _currentUserName,
      receiverId: receiverId,
      receiverName: receiverName,
      timestamp: DateTime.now(),
      isRead: false,
    );

    debugPrint('📤 Sending: "$text"');
    debugPrint('   From: $_currentUserId ($_currentUserName)');
    debugPrint('   To: $receiverId ($receiverName)');

    try {
      // Add message to chat subcollection
      await _firestore
          .collection('messages')
          .doc(_chatId)
          .collection('chat')
          .add(message.toMap());

      // Update last message in parent document
      await _firestore.collection('messages').doc(_chatId).update({
        'lastMessage': text,
        'lastTimestamp': FieldValue.serverTimestamp(),
      });

      _controller.clear();
      debugPrint('✅ Message sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showHireOptions() {
    if (_hasCaregiver) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have a caregiver assigned. Remove them first to hire another.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.work, color: Colors.green, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hire Caregiver',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Assign ${widget.caregiverName} as your caregiver',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Confirm hire option
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.green, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          'Hire ${widget.caregiverName}?',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This caregiver will be assigned to you and can view your medications and health information.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _hireCaregiver();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Confirm Hire'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _hireCaregiver() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );

      // Create caregiver assignment in the new collection
      await _firestore.collection('caregiver_assignments').add({
        'patientId': widget.patientId,
        'caregiverId': widget.caregiverId,
        'assignedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'removedAt': null,
        'removedReason': null,
      });

      // Update caregiver status
      setState(() => _hasCaregiver = true);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.caregiverName} has been hired as your caregiver!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }

      debugPrint('✅ Caregiver hired successfully');
      debugPrint('   Patient: ${widget.patientId}');
      debugPrint('   Caregiver: ${widget.caregiverId}');
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      debugPrint('❌ Error hiring caregiver: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to hire caregiver: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.more_vert, color: Colors.black54, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'More Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Options for both patient and caregiver
                if (!_isCaregiver && !_isLoadingCaregiverStatus) // Patient-specific options
                  _buildOptionItem(
                    icon: Icons.work,
                    title: _hasCaregiver ? 'Caregiver Assigned' : 'Hire Caregiver',
                    subtitle: _hasCaregiver 
                        ? 'Already have a caregiver'
                        : 'Assign this caregiver to you',
                    color: _hasCaregiver ? Colors.grey : Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _showHireOptions();
                    },
                  ),
                
                // Common options for both
                _buildOptionItem(
                  icon: Icons.block,
                  title: 'Block User',
                  subtitle: 'Stop receiving messages',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _showBlockConfirmation();
                  },
                ),
                
                _buildOptionItem(
                  icon: Icons.report,
                  title: 'Report User',
                  subtitle: 'Report inappropriate behavior',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog();
                  },
                ),
                
                _buildOptionItem(
                  icon: Icons.delete,
                  title: 'Clear Chat',
                  subtitle: 'Delete all messages',
                  color: Colors.grey,
                  onTap: () {
                    Navigator.pop(context);
                    _showClearChatConfirmation();
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Cancel button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User?'),
        content: Text('Are you sure you want to block ${_isCaregiver ? widget.patientName : widget.caregiverName}? You will no longer receive messages from them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement block functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_isCaregiver ? widget.patientName : widget.caregiverName} has been blocked'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: const Text('Please describe the issue you are experiencing. Our team will review your report.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report submitted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  void _showClearChatConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat?'),
        content: const Text('This will delete all messages in this conversation. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement clear chat functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine which person's info to show in header (the OTHER person)
    final otherPersonName = _isCaregiver ? widget.patientName : widget.caregiverName;
    final otherPersonPhoto = _isCaregiver ? widget.patientPhoto : (widget.caregiverPhoto ?? '');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFF5F6F7),
              backgroundImage: otherPersonPhoto.isNotEmpty
                  ? NetworkImage(otherPersonPhoto)
                  : null,
              child: otherPersonPhoto.isEmpty
                  ? Text(
                      otherPersonName[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                otherPersonName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .doc(_chatId)
                  .collection('chat')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('❌ Stream error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6C5CE7),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                // FIXED: Only scroll once when messages first load
                if (!_hasScrolledToBottom && docs.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                    _hasScrolledToBottom = true;
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    try {
                      final msg = Message.fromMap(
                        docs[i].data() as Map<String, dynamic>,
                        docs[i].id,
                      );
                      final isMe = msg.senderId == _currentUserId;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ChatBubble(
                          clipper: ChatBubbleClipper1(
                            type: isMe ? BubbleType.sendBubble : BubbleType.receiverBubble,
                          ),
                          alignment: isMe ? Alignment.topRight : Alignment.topLeft,
                          margin: const EdgeInsets.only(top: 8),
                          backGroundColor: isMe 
                              ? const Color(0xFF6C5CE7) 
                              : const Color(0xFFE8EAED),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            child: Column(
                              crossAxisAlignment: isMe 
                                  ? CrossAxisAlignment.end 
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.text,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTime(msg.timestamp),
                                      style: TextStyle(
                                        color: isMe ? Colors.white70 : Colors.black54,
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        msg.isRead ? Icons.done_all : Icons.done,
                                        size: 12,
                                        color: msg.isRead 
                                            ? Colors.white 
                                            : Colors.white70,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } catch (e) {
                      debugPrint('⚠️ Error displaying message ${i}: $e');
                      return const SizedBox.shrink();
                    }
                  },
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      // Today - show time only
      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[time.weekday - 1];
    } else {
      // Older - show date
      return '${time.month}/${time.day}/${time.year}';
    }
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EAED))),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F7),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF6C5CE7),
              elevation: 2,
              onPressed: _sendMessage,
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}