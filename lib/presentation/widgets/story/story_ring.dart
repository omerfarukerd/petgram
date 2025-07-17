import 'package:flutter/material.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/user_model.dart';

class StoryRing extends StatelessWidget {
  final UserModel user;
  final StoryModel? story;
  final bool isCurrentUser;
  final VoidCallback onTap;
  final VoidCallback? onAddStory;

  const StoryRing({
    super.key,
    required this.user,
    this.story,
    required this.isCurrentUser,
    required this.onTap,
    this.onAddStory,
  });

  @override
  Widget build(BuildContext context) {
    final hasStory = story != null && story!.isActive;
    final isViewed = hasStory && story!.viewers.contains('current-user-id'); // TODO: get current user id

    return GestureDetector(
      onTap: hasStory || !isCurrentUser ? onTap : onAddStory,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Gradient ring
                if (hasStory)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isViewed
                          ? LinearGradient(
                              colors: [
                                Colors.grey.shade400,
                                Colors.grey.shade400,
                              ],
                            )
                          : const LinearGradient(
                              colors: [
                                Color(0xFFDE0046),
                                Color(0xFFF7A34B),
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                    ),
                  )
                else
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                
                // White border
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                
                // Profile image
                CircleAvatar(
                  radius: 32,
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null
                      ? Text(
                          user.username[0].toUpperCase(),
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                
                // Add story button
                if (isCurrentUser && !hasStory)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 72,
              child: Text(
                isCurrentUser ? 'Hikayen' : user.username,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}