class PostModel {
  final String id;
  final String userId;
  final List<MediaItem> mediaItems; // Çoklu medya
  final String? caption;
  final List<String> likes;
  final int commentCount;
  final DateTime createdAt;
  final bool isAdoption;

  PostModel({
    required this.id,
    required this.userId,
    required this.mediaItems,
    this.caption,
    required this.likes,
    this.commentCount = 0,
    required this.createdAt,
    this.isAdoption = false,
  });

  // Eski postlar için uyumluluk
  String get mediaUrl => mediaItems.isNotEmpty ? mediaItems.first.url : '';
  String get imageUrl => mediaUrl; // Feed_tab için
  bool get isVideo => mediaItems.isNotEmpty ? mediaItems.first.isVideo : false;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'mediaItems': mediaItems.map((e) => e.toJson()).toList(),
    'caption': caption,
    'likes': likes,
    'commentCount': commentCount,
    'createdAt': createdAt.toIso8601String(),
    'isAdoption': isAdoption,
  };

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Eski postlar için uyumluluk
    if (json['mediaUrl'] != null || json['imageUrl'] != null) {
      return PostModel(
        id: json['id'],
        userId: json['userId'],
        mediaItems: [
          MediaItem(
            url: json['mediaUrl'] ?? json['imageUrl'],
            isVideo: json['isVideo'] ?? false,
          ),
        ],
        caption: json['caption'],
        likes: List<String>.from(json['likes'] ?? []),
        commentCount: json['commentCount'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
        isAdoption: json['isAdoption'] ?? false,
      );
    }

    return PostModel(
      id: json['id'],
      userId: json['userId'],
      mediaItems: (json['mediaItems'] as List?)
          ?.map((e) => MediaItem.fromJson(e))
          .toList() ?? [],
      caption: json['caption'],
      likes: List<String>.from(json['likes'] ?? []),
      commentCount: json['commentCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      isAdoption: json['isAdoption'] ?? false,
    );
  }
}

class MediaItem {
  final String url;
  final bool isVideo;

  MediaItem({
    required this.url,
    required this.isVideo,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'isVideo': isVideo,
  };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
    url: json['url'],
    isVideo: json['isVideo'] ?? false,
  );
}