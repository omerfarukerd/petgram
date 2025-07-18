import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/notification_provider.dart';

class NotificationItemTile extends StatelessWidget {
  final NotificationModel notification;

  const NotificationItemTile({super.key, required this.notification});

  // DÜZELTİLDİ: BuildContext eklendi
  Widget _buildNotificationText(BuildContext context, UserModel fromUser) {
    String text;
    switch (notification.type) {
      case NotificationType.like:
        text = 'gönderinizi beğendi.';
        break;
      case NotificationType.comment:
        text = 'gönderinize yorum yaptı: "${notification.commentText ?? ''}"';
        break;
      case NotificationType.follow:
        text = 'sizi takip etmeye başladı.';
        break;
      case NotificationType.newMessage:
        text = 'size bir mesaj gönderdi.';
        break;
      case NotificationType.commentLike:
        text = 'bir yorumunuzu beğendi.';
        break;
      default:
        text = 'yeni bir bildiriminiz var.';
    }
    
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style, // Artık 'context'e erişebilir
        children: [
          TextSpan(
            text: fromUser.username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: ' $text'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: UserRepository.getUser(notification.fromUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            leading: CircleAvatar(),
            title: Text('Yükleniyor...'),
          );
        }
        final fromUser = snapshot.data!;
        
        return Container(
          color: notification.isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: fromUser.profileImageUrl != null
                  ? CachedNetworkImageProvider(fromUser.profileImageUrl!)
                  : null,
              child: fromUser.profileImageUrl == null
                  ? Text(fromUser.username[0].toUpperCase())
                  : null,
            ),
            // DÜZELTİLDİ: context parametresi iletildi
            title: _buildNotificationText(context, fromUser),
            subtitle: Text(
              DateFormat('dd MMM, HH:mm').format(notification.timestamp),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: notification.postImageUrl != null
              ? SizedBox(
                  width: 50,
                  height: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: CachedNetworkImage(
                      imageUrl: notification.postImageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : null,
            onTap: () {
              if (!notification.isRead) {
                context.read<NotificationProvider>().markAsRead(notification.id);
              }
              // İlgili gönderiye, profile veya sohbete yönlendirme eklenecek.
            },
          ),
        );
      },
    );
  }
}