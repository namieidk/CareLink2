import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';   // correct import

/// ---------------------------------------------------------------
/// Chat screen – patient (right)  ↔  caregiver (left)
/// ---------------------------------------------------------------
class MessageScreen extends StatefulWidget {
  final String caregiverName;
  final String caregiverPhoto;

  const MessageScreen({
    super.key,                     
    required this.caregiverName,
    this.caregiverPhoto = '',
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Sample messages – replace with real data later
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello Maria, I need help with my medication schedule tomorrow.',
      'isSender': true,
      'time': '10:30 AM',
    },
    {
      'text': 'Hi! Sure, I can assist. What time do you usually take your meds?',
      'isSender': false,
      'time': '10:32 AM',
    },
    {
      'text': 'Morning dose at 8:00 AM and evening at 7:00 PM.',
      'isSender': true,
      'time': '10:33 AM',
    },
    {
      'text': 'Got it. I’ll set a reminder and check in with you at 7:45 AM tomorrow.',
      'isSender': false,
      'time': '10:35 AM',
    },
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': _controller.text.trim(),
        'isSender': true,
        'time': _formatTime(DateTime.now()),
      });
    });

    _controller.clear();
    _scrollToBottom();
  }

  String _formatTime(DateTime time) {
    final h = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFFFF6B6B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: primary,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.caregiverName,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  Text(
                    'Online',
                    style: TextStyle(fontSize: 13, color: Colors.green[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.phone, color: Colors.black54), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black54), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // ─── Chat messages ────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final bool isSender = msg['isSender'];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment:
                        isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      ChatBubble(
                        clipper: isSender
                            ? ChatBubbleClipper1(type: BubbleType.sendBubble)
                            : ChatBubbleClipper1(type: BubbleType.receiverBubble),
                        alignment: isSender ? Alignment.topRight : Alignment.topLeft,
                        margin: const EdgeInsets.only(bottom: 6),
                        backGroundColor:
                            isSender ? primary : const Color(0xFFE5E5EA),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: Text(
                            msg['text'],
                            style: TextStyle(
                              color: isSender ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          msg['time'],
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ─── Input field ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF5F6F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: primary,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}