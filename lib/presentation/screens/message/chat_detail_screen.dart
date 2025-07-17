import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../widgets/message/message_bubble.dart';
import '../../widgets/message/message_input.dart';
import '../../widgets/message/typing_indicator.dart';
import 'call_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final UserModel otherUser;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  MessageModel? _replyTo;

  @override
  void initState() {
    super.initState();
    final messageProvider = context.read<MessageProvider>();
    final authProvider = context.read<AuthProvider>();
    
    messageProvider.loadMessages(widget.conversationId);
    messageProvider.markMessagesAsRead(authProvider.currentUser?.uid ?? '');
  }

  void _startCall(bool isVideo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: widget.conversationId,
          token: 'GENERATE_FROM_SERVER',
          isVideo: isVideo,
          callerName: widget.otherUser.username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.otherUser.profileImageUrl != null
                  ? NetworkImage(widget.otherUser.profileImageUrl!)
                  : null,
              child: widget.otherUser.profileImageUrl == null
                  ? Text(widget.otherUser.username[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUser.username, style: const TextStyle(fontSize: 16)),
                  if (messageProvider.typingUsers[widget.otherUser.uid] == true)
                    Row(
                      children: [
                        const TypingIndicator(),
                        const SizedBox(width: 4),
                        Text('yazıyor...', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => _startCall(true),
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _startCall(false),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messageProvider.currentMessages.length,
              itemBuilder: (context, index) {
                final message = messageProvider.currentMessages[index];
                final isMe = message.senderId == currentUserId;
                
                return Dismissible(
                  key: Key(message.id),
                  direction: isMe ? DismissDirection.endToStart : DismissDirection.startToEnd,
                  background: Container(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.blue,
                    child: Icon(Icons.reply, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    setState(() => _replyTo = message);
                    return false;
                  },
                  child: MessageBubble(
                    message: message,
                    isMe: isMe,
                  ),
                );
              },
            ),
          ),
          MessageInput(
            replyTo: _replyTo,
            onCancelReply: () => setState(() => _replyTo = null),
            onSendMessage: (text, replyToId) async {
              await messageProvider.sendMessage(
                senderId: currentUserId,
                type: MessageType.text,
                text: text,
                replyToId: replyToId,
              );
            },
            onTypingChanged: (isTyping) {
              messageProvider.setTypingStatus(currentUserId, isTyping);
            },
          ),
        ],
      ),
    );
  }
}