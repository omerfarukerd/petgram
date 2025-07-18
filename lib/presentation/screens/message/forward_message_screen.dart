import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';

class ForwardMessageScreen extends StatelessWidget {
  final MessageModel messageToForward;

  const ForwardMessageScreen({super.key, required this.messageToForward});

  // GÜNCELLENDİ: Provider'daki yeni fonksiyonu kullanır.
  void _forwardMessageTo(BuildContext context, String targetConversationId) async {
    final messageProvider = context.read<MessageProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.uid ?? '';

    await messageProvider.forwardMessage(
      targetConversationId: targetConversationId,
      messageToForward: messageToForward,
      senderId: currentUserId,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj iletildi!')),
      );
      // Sadece iletme ekranını kapatır.
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final messageProvider = context.watch<MessageProvider>();
    final currentUserId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajı İlet'),
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: Stream.value(messageProvider.conversations),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('İletecek sohbet bulunamadı.'),
            );
          }

          final conversations = snapshot.data!;
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherUserId = conversation.participants
                  .firstWhere((id) => id != currentUserId, orElse: () => '');
              
              // Grup sohbetleri için özel mantık
              final isGroup = conversation.isGroup;
              final title = isGroup ? (conversation.groupName ?? 'Grup Sohbeti') : null;
              
              return FutureBuilder<UserModel?>(
                future: isGroup ? null : UserRepository.getUser(otherUserId),
                builder: (context, userSnapshot) {
                  final otherUser = userSnapshot.data;
                  final displayName = title ?? otherUser?.username ?? 'Kullanıcı';
                  final displayImage = isGroup ? conversation.groupPhoto : otherUser?.profileImageUrl;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: displayImage != null
                          ? NetworkImage(displayImage)
                          : null,
                      child: displayImage == null
                          ? Text(displayName[0].toUpperCase())
                          : null,
                    ),
                    title: Text(displayName),
                    subtitle: Text(
                      conversation.isGroup 
                        ? '${conversation.participants.length} üye'
                        : 'Sohbet'
                    ),
                    onTap: () => _forwardMessageTo(context, conversation.id),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}