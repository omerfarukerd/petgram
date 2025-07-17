class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? text;
  final List<String>? mediaUrls;
  final MessageType type;
  final DateTime timestamp;
  final List<String> readBy;
  final List<String> deliveredTo;
  final String? replyToId;
  final Map<String, String> reactions; // userId: emoji
  final bool isEdited;
  final DateTime? editedAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.text,
    this.mediaUrls,
    required this.type,
    required this.timestamp,
    List<String>? readBy,
    List<String>? deliveredTo,
    this.replyToId,
    Map<String, String>? reactions,
    this.isEdited = false,
    this.editedAt,
  }) : readBy = readBy ?? [senderId],
        deliveredTo = deliveredTo ?? [senderId],
        reactions = reactions ?? {};

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'text': text,
    'mediaUrls': mediaUrls,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'readBy': readBy,
    'deliveredTo': deliveredTo,
    'replyToId': replyToId,
    'reactions': reactions,
    'isEdited': isEdited,
    'editedAt': editedAt?.toIso8601String(),
  };

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'],
    conversationId: json['conversationId'],
    senderId: json['senderId'],
    text: json['text'],
    mediaUrls: json['mediaUrls'] != null 
        ? List<String>.from(json['mediaUrls']) 
        : null,
    type: MessageType.values.byName(json['type']),
    timestamp: DateTime.parse(json['timestamp']),
    readBy: List<String>.from(json['readBy'] ?? []),
    deliveredTo: List<String>.from(json['deliveredTo'] ?? []),
    replyToId: json['replyToId'],
    reactions: Map<String, String>.from(json['reactions'] ?? {}),
    isEdited: json['isEdited'] ?? false,
    editedAt: json['editedAt'] != null 
        ? DateTime.parse(json['editedAt']) 
        : null,
  );
}

enum MessageType {
  text,
  image,
  video,
  voice,
  storyReply,
  postShare,
  profileShare,
}