import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/message_repository.dart';
import '../../providers/auth_provider.dart';

class MessageReactions extends StatelessWidget {
  final String messageId;
  final String conversationId;
  final Map<String, String> reactions;
  
  const MessageReactions({
    super.key,
    required this.messageId,
    required this.conversationId,
    required this.reactions,
  });

  static const List<String> availableEmojis = ['❤️', '😂', '😮', '😢', '👍', '🔥'];

  void _showReactionPicker(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().currentUser?.uid ?? '';
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          children: availableEmojis.map((emoji) {
            return GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await MessageRepository.addReaction(
                  conversationId: conversationId,
                  messageId: messageId,
                  userId: currentUserId,
                  emoji: emoji,
                );
              },
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    
    final groupedReactions = <String, List<String>>{};
    reactions.forEach((userId, emoji) {
      groupedReactions[emoji] = [...(groupedReactions[emoji] ?? []), userId];
    });
    
    return Wrap(
      spacing: 4,
      children: groupedReactions.entries.map((entry) {
        return GestureDetector(
          onTap: () => _showReactionPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  entry.value.length.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}