import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../../data/models/message_model.dart';
import 'package:intl/intl.dart';
import 'message_reactions.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final void Function(MessageModel message) onReply;
  final void Function(MessageModel message) onEdit;
  final void Function(MessageModel message) onDelete;
  final void Function(MessageModel message) onCopy;
  final void Function(MessageModel message) onForward;
  final void Function(MessageModel message) onInfo;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    required this.onForward,
    required this.onInfo,
  });

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text('Yanıtla'),
                  onTap: () {
                    Navigator.pop(context);
                    onReply(message);
                  },
                ),
                if (message.text != null && message.type == MessageType.text)
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text('Kopyala'),
                    onTap: () {
                      Navigator.pop(context);
                      onCopy(message);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.forward),
                  title: const Text('İlet'),
                  onTap: () {
                    Navigator.pop(context);
                    onForward(message);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Bilgi'),
                  onTap: () {
                    Navigator.pop(context);
                    onInfo(message);
                  },
                ),
                if (isMe && message.type == MessageType.text)
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Düzenle'),
                    onTap: () {
                      Navigator.pop(context);
                      onEdit(message);
                    },
                  ),
                if (isMe)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Sil', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      onDelete(message);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // YENİ: Mesaj içeriğini türüne göre oluşturan ana widget
  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.postShare:
        return _buildSharedPost(context);
      case MessageType.profileShare:
        return _buildSharedProfile(context);
      case MessageType.storyReply:
        return _buildSharedStory(context);
      case MessageType.image:
        return _buildImage(context);
      default:
        return _buildTextMessage(context);
    }
  }

  // YENİ: Paylaşılan gönderi önizlemesi
  Widget _buildSharedPost(BuildContext context) {
    return Container(
      width: 220, // Sabit genişlik
      decoration: BoxDecoration(
        color: isMe ? Colors.blue.withOpacity(0.8) : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.sharedContentImageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: message.sharedContentImageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              message.sharedContentText ?? 'Gönderi',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  
  // YENİ: Paylaşılan hikaye önizlemesi
  Widget _buildSharedStory(BuildContext context) {
     return Container(
      width: 220,
      decoration: BoxDecoration(
        color: isMe ? Colors.blue.withOpacity(0.8) : Colors.grey[300],
         border: Border.all(color: Colors.deepPurpleAccent, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.sharedContentImageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: message.sharedContentImageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              message.sharedContentText ?? 'Hikaye yanıtı',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // YENİ: Paylaşılan profil önizlemesi
  Widget _buildSharedProfile(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue.withOpacity(0.8) : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: message.sharedContentImageUrl != null
              ? CachedNetworkImageProvider(message.sharedContentImageUrl!)
              : null,
            child: message.sharedContentImageUrl == null 
              ? const Icon(Icons.person) 
              : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.sharedContentText ?? 'Profil',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
     return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: message.mediaUrls!.first,
        placeholder: (context, url) => Container(
          width: 200,
          height: 200,
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  Widget _buildTextMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message.text ?? '',
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

 @override
 Widget build(BuildContext context) {
  return GestureDetector(
    onLongPress: () => _showOptions(context),
    child: Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildMessageContent(context),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isEdited) ...[
                  Text(
                    'Düzenlendi',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                   const SizedBox(width: 4),
                ],
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.readBy.length > 1
                        ? Icons.done_all
                        : Icons.done,
                    size: 14,
                    color: message.readBy.length > 1
                        ? Colors.blue
                        : Colors.grey[600],
                  ),
                ],
              ],
            ),
            if (message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: MessageReactions(
                  messageId: message.id,
                  conversationId: message.conversationId,
                  reactions: message.reactions,
                ),
              ),
          ],
        ),
      ),
    ),
  );
 }
}