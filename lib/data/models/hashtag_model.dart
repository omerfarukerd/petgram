import 'package:cloud_firestore/cloud_firestore.dart'; // HATA DÜZELTİLDİ

class HashtagModel {
  final String tag;
  final int postCount;
  final Timestamp lastUsed;
  final int recentPostCount;

  HashtagModel({
    required this.tag,
    this.postCount = 0,
    required this.lastUsed,
    this.recentPostCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'postCount': postCount,
    'lastUsed': lastUsed,
    'recentPostCount': recentPostCount,
  };

  factory HashtagModel.fromJson(Map<String, dynamic> json) => HashtagModel(
    tag: json['tag'],
    postCount: json['postCount'] ?? 0,
    lastUsed: json['lastUsed'] ?? Timestamp.now(),
    recentPostCount: json['recentPostCount'] ?? 0,
  );
}