import 'package:pet_gram/data/models/message_model.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final String? groupName;
  final String? groupPhoto;
  final MessageModel? lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;
  final Map<String, DateTime> lastSeen;
  final bool isGroup;
  final String? adminId;
  final bool vanishMode;

  ConversationModel({
    required this.id,
    required this.participants,
    this.groupName,
    this.groupPhoto,
    this.lastMessage,
    required this.lastMessageTime,
    Map<String, int>? unreadCount,
    Map<String, DateTime>? lastSeen,
    this.isGroup = false,
    this.adminId,
    this.vanishMode = false,
  }) : unreadCount = unreadCount ?? {},
        lastSeen = lastSeen ?? {};

  Map<String, dynamic> toJson() => {
    'id': id,
    'participants': participants,
    'groupName': groupName,
    'groupPhoto': groupPhoto,
    'lastMessage': lastMessage?.toJson(),
    'lastMessageTime': lastMessageTime.toIso8601String(),
    'unreadCount': unreadCount,
    'lastSeen': lastSeen.map((k, v) => MapEntry(k, v.toIso8601String())),
    'isGroup': isGroup,
    'adminId': adminId,
    'vanishMode': vanishMode,
  };

  factory ConversationModel.fromJson(Map<String, dynamic> json) => ConversationModel(
    id: json['id'],
    participants: List<String>.from(json['participants']),
    groupName: json['groupName'],
    groupPhoto: json['groupPhoto'],
    lastMessage: json['lastMessage'] != null 
        ? MessageModel.fromJson(json['lastMessage']) 
        : null,
    lastMessageTime: DateTime.parse(json['lastMessageTime']),
    unreadCount: Map<String, int>.from(json['unreadCount'] ?? {}),
    lastSeen: (json['lastSeen'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, DateTime.parse(v))
    ) ?? {},
    isGroup: json['isGroup'] ?? false,
    adminId: json['adminId'],
    vanishMode: json['vanishMode'] ?? false,
  );
}