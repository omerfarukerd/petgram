class StoryModel {
  final String id;
  final String userId;
  final List<StoryItem> items;
  final DateTime createdAt;
  final DateTime expiresAt;
  final Set<String> viewers;
  final bool isHighlight;
  final String? highlightTitle;

  StoryModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    DateTime? expiresAt,
    Set<String>? viewers,
    this.isHighlight = false,
    this.highlightTitle,
  }) : viewers = viewers ?? {},
        expiresAt = expiresAt ?? createdAt.add(const Duration(hours: 24));

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => !isExpired && items.isNotEmpty;
  int get viewCount => viewers.length;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'items': items.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'viewers': viewers.toList(),
    'isHighlight': isHighlight,
    'highlightTitle': highlightTitle,
  };

  factory StoryModel.fromJson(Map<String, dynamic> json) => StoryModel(
    id: json['id'],
    userId: json['userId'],
    items: (json['items'] as List)
        .map((e) => StoryItem.fromJson(e))
        .toList(),
    createdAt: DateTime.parse(json['createdAt']),
    expiresAt: DateTime.parse(json['expiresAt']),
    viewers: Set<String>.from(json['viewers'] ?? []),
    isHighlight: json['isHighlight'] ?? false,
    highlightTitle: json['highlightTitle'],
  );
}

class StoryItem {
  final String id;
  final String mediaUrl;
  final bool isVideo;
  final String? caption;
  final List<StorySticker> stickers;
  final DateTime createdAt;
  final Map<String, StoryReaction> reactions;
  final int duration; // seconds

  StoryItem({
    required this.id,
    required this.mediaUrl,
    required this.isVideo,
    this.caption,
    List<StorySticker>? stickers,
    required this.createdAt,
    Map<String, StoryReaction>? reactions,
    int? duration,
  }) : stickers = stickers ?? [],
        reactions = reactions ?? {},
        duration = duration ?? (isVideo ? 0 : 5);

  Map<String, dynamic> toJson() => {
    'id': id,
    'mediaUrl': mediaUrl,
    'isVideo': isVideo,
    'caption': caption,
    'stickers': stickers.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'reactions': reactions.map((k, v) => MapEntry(k, v.toJson())),
    'duration': duration,
  };

  factory StoryItem.fromJson(Map<String, dynamic> json) => StoryItem(
    id: json['id'],
    mediaUrl: json['mediaUrl'],
    isVideo: json['isVideo'],
    caption: json['caption'],
    stickers: (json['stickers'] as List?)
        ?.map((e) => StorySticker.fromJson(e))
        .toList(),
    createdAt: DateTime.parse(json['createdAt']),
    reactions: (json['reactions'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, StoryReaction.fromJson(v))) ?? {},
    duration: json['duration'] ?? 5,
  );
}

class StorySticker {
  final String type; // mention, location, poll, quiz, music, question
  final Map<String, dynamic> data;
  final double x;
  final double y;
  final double scale;
  final double rotation;

  StorySticker({
    required this.type,
    required this.data,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
    'x': x,
    'y': y,
    'scale': scale,
    'rotation': rotation,
  };

  factory StorySticker.fromJson(Map<String, dynamic> json) => StorySticker(
    type: json['type'],
    data: json['data'],
    x: json['x'],
    y: json['y'],
    scale: json['scale'] ?? 1.0,
    rotation: json['rotation'] ?? 0.0,
  );
}

class StoryReaction {
  final String emoji;
  final DateTime timestamp;

  StoryReaction({
    required this.emoji,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'timestamp': timestamp.toIso8601String(),
  };

  factory StoryReaction.fromJson(Map<String, dynamic> json) => StoryReaction(
    emoji: json['emoji'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}