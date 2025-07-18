import 'package:pet_gram/data/models/post_model.dart';

class ReelModel extends PostModel {
  final String? audioId;
  final String? audioName;
  final String? artistName;
  final bool allowDuet;
  final bool allowRemix;

  ReelModel({
    required super.id,
    required super.userId,
    required super.mediaItems,
    super.caption,
    required super.likes,
    super.commentCount,
    required super.createdAt,
    super.isAdoption,
    this.audioId,
    this.audioName,
    this.artistName,
    this.allowDuet = true,
    this.allowRemix = true,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'isReel': true, // Post'tan ayırmak için bir belirteç
      'audioId': audioId,
      'audioName': audioName,
      'artistName': artistName,
      'allowDuet': allowDuet,
      'allowRemix': allowRemix,
    });
    return json;
  }

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['id'],
      userId: json['userId'],
      mediaItems: (json['mediaItems'] as List)
          .map((e) => MediaItem.fromJson(e))
          .toList(),
      caption: json['caption'],
      likes: List<String>.from(json['likes'] ?? []),
      commentCount: json['commentCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      isAdoption: json['isAdoption'] ?? false,
      audioId: json['audioId'],
      audioName: json['audioName'],
      artistName: json['artistName'],
      allowDuet: json['allowDuet'] ?? true,
      allowRemix: json['allowRemix'] ?? true,
    );
  }
}