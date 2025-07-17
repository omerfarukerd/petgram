class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? userProfileImage;
  final String text;
  final DateTime createdAt;
  final List<String> likes;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.userProfileImage,
    required this.text,
    required this.createdAt,
    required this.likes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'userId': userId,
    'username': username,
    'userProfileImage': userProfileImage,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'likes': likes,
  };

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    id: json['id'],
    postId: json['postId'],
    userId: json['userId'],
    username: json['username'],
    userProfileImage: json['userProfileImage'],
    text: json['text'],
    createdAt: DateTime.parse(json['createdAt']),
    likes: List<String>.from(json['likes'] ?? []),
  );
}