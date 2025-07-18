import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../widgets/message/message_bubble.dart';
import '../../widgets/message/message_input.dart';
import '../../widgets/message/typing_indicator.dart';
import 'call_screen.dart';
import 'forward_message_screen.dart';
import 'message_info_screen.dart'; // YENİ İMPORT

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
        token: 'GENERATE_FROM_SERVER', // Bu token sunucudan alınmalıdır.
        isVideo: isVideo,
        callerName: widget.otherUser.username,
      ),
    ),
  );
 }
 
 void _handleDeleteMessage(MessageModel message) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Mesajı Sil'), content: const Text('Bu mesajı silmek istediğinizden emin misiniz?'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')), TextButton(onPressed: () {context.read<MessageProvider>().deleteMessage(message.id); Navigator.pop(context);}, child: const Text('Sil', style: TextStyle(color: Colors.red)))]));
 }

 void _handleEditMessage(MessageModel message) {
    final textController = TextEditingController(text: message.text);
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Mesajı Düzenle'), content: TextField(controller: textController, autofocus: true, maxLines: null), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')), TextButton(onPressed: () {final newText = textController.text.trim(); if (newText.isNotEmpty) {context.read<MessageProvider>().editMessage(message.id, newText);} Navigator.pop(context);}, child: const Text('Kaydet'))]));
 }
 
 void _handleReplyMessage(MessageModel message) {
    setState(() => _replyTo = message);
 }

 void _handleCopyMessage(MessageModel message) {
    Clipboard.setData(ClipboardData(text: message.text ?? ''));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mesaj kopyalandı!')));
 }

 void _handleForwardMessage(MessageModel message) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ForwardMessageScreen(messageToForward: message)));
 }

 // GÜNCELLENDİ
 void _handleMessageInfo(MessageModel message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageInfoScreen(message: message),
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
                
                return MessageBubble(
                  message: message,
                  isMe: isMe,
                  onReply: _handleReplyMessage,
                  onEdit: _handleEditMessage,
                  onDelete: _handleDeleteMessage,
                  onCopy: _handleCopyMessage,
                  onForward: _handleForwardMessage,
                  onInfo: _handleMessageInfo,
                );
              },
            ),
          ),
          MessageInput(
            replyTo: _replyTo,
            onCancelReply: () => setState(() => _replyTo = null),
            onSendMessage: (text, replyToId) {
              messageProvider.sendMessage(
                senderId: currentUserId,
                type: MessageType.text,
                text: text,
                replyToId: replyToId,
              );
              setState(() => _replyTo = null);
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