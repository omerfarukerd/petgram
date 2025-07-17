import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;
  final VoidCallback onEditProfile;
  final VoidCallback onFollowToggle;
  final VoidCallback? onMessage; // YENİ

  const ProfileHeader({
    super.key,
    required this.user,
    required this.isCurrentUser,
    required this.onEditProfile,
    required this.onFollowToggle,
    this.onMessage, // YENİ
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid ?? '';
    final isFollowing = user.followers.contains(currentUserId);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Text(
                        user.username[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('Gönderi', user.postCount.toString()),
                    _buildStatColumn('Takipçi', user.followers.length.toString()),
                    _buildStatColumn('Takip', user.following.length.toString()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(user.bio!),
          ],
          const SizedBox(height: 16),
          isCurrentUser
              ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onEditProfile,
                    child: const Text('Profili Düzenle'),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onFollowToggle,
                        style: isFollowing
                            ? ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black,
                              )
                            : null,
                        child: Text(
                          isFollowing ? 'Takipten Çık' : 'Takip Et',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onMessage, // GÜNCELLEME
                        child: const Text('Mesaj'),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}