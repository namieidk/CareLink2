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
  }

  // CRITICAL: Always generates same chatId regardless of who calls it
  String _getChatId(String id1, String id2) {
    final ids = [id1, id2]..sort();
    return '${ids[0]}_${ids[1]}';
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
            onPressed: () {
              // Add more options here
            },
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