import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final messageProvider = context.watch<MessageProvider>();
    final currentUserId = authProvider.currentUser?.uid ?? '';

    if (currentUserId.isEmpty) {
      return const Center(child: Text('Giriş yapmanız gerekiyor'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            onPressed: () {
              // Yeni mesaj başlatma
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: Stream.value(messageProvider.conversations),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data!;
          
          if (conversations.isEmpty) {
            return const Center(
              child: Text('Henüz mesajınız yok'),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherUserId = conversation.participants
                  .firstWhere((id) => id != currentUserId);
              
              return FutureBuilder<UserModel?>(
                future: UserRepository.getUser(otherUserId),
                builder: (context, userSnapshot) {
                  final otherUser = userSnapshot.data;
                  final lastMessage = conversation.lastMessage;
                  final unreadCount = conversation.unreadCount[currentUserId] ?? 0;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: otherUser?.profileImageUrl != null
                          ? NetworkImage(otherUser!.profileImageUrl!)
                          : null,
                      child: otherUser?.profileImageUrl == null
                          ? Text(otherUser?.username[0].toUpperCase() ?? '?')
                          : null,
                    ),
                    title: Text(otherUser?.username ?? 'Kullanıcı'),
                    subtitle: lastMessage != null
                        ? Text(
                            lastMessage.text ?? 'Medya',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            conversationId: conversation.id,
                            otherUser: otherUser!,
                          ),
                        ),
                      );
                    },
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