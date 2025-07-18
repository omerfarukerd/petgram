
class NotificationModel {
  final String id;
  final String userId; // Bildirimi alan kullanıcı
  final NotificationType type;
  final String fromUserId; // Bildirimi tetikleyen kullanıcı
  final String? postId; // Beğeni, yorum, mention için
  final String? postImageUrl; // Beğeni, yorum, mention için önizleme
  final String? commentText; // Yorum bildirimi için
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.fromUserId,
    this.postId,
    this.postImageUrl,
    this.commentText,
    this.isRead = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'fromUserId': fromUserId,
    'postId': postId,
    'postImageUrl': postImageUrl,
    'commentText': commentText,
    'isRead': isRead,
    'timestamp': timestamp.toIso8601String(),
  };

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'],
    userId: json['userId'],
    type: NotificationType.values.byName(json['type']),
    fromUserId: json['fromUserId'],
    postId: json['postId'],
    postImageUrl: json['postImageUrl'],
    commentText: json['commentText'],
    isRead: json['isRead'] ?? false,
    timestamp: DateTime.parse(json['timestamp']),
  );
}

enum NotificationType {
  like,
  comment,
  follow,
  newMessage,
  commentLike,
  mention,
  friendActivity, // "X'in yeni gönderisine göz at"
  system, // "Keşfet'teki popüler gönderileri kaçırma!"
}