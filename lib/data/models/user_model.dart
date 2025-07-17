class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? profileImageUrl;
  final String? bio;
  final List<String> followers;
  final List<String> following;
  final int postCount;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.profileImageUrl,
    this.bio,
    List<String>? followers,
    List<String>? following,
    this.postCount = 0,
    DateTime? createdAt,
  })  : followers = followers ?? [],
        following = following ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'username': username,
    'profileImageUrl': profileImageUrl,
    'bio': bio,
    'followers': followers,
    'following': following,
    'postCount': postCount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      bio: json['bio'] as String?,
      followers: (json['followers'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      following: (json['following'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      postCount: json['postCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}