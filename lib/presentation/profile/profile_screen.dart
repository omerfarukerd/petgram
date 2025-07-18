import 'package:flutter/material.dart';
import 'package:pet_gram/presentation/providers/auth_provider.dart';
import 'package:pet_gram/presentation/providers/user_provider.dart';
import 'package:pet_gram/presentation/providers/message_provider.dart';
import 'package:pet_gram/presentation/screens/message/chat_detail_screen.dart';
import 'package:pet_gram/presentation/screens/message/forward_message_screen.dart';
import 'package:pet_gram/presentation/widgets/profile/profile_header.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/user_repository.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  void _startConversation(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final messageProvider = context.read<MessageProvider>();
    
    final currentUserId = authProvider.currentUser?.uid;
    if (currentUserId == null || currentUserId == userId) return;
    
    final conversationId = await messageProvider.createOrGetConversation([
      currentUserId,
      userId,
    ]);
    
    if (conversationId.isNotEmpty) {
      final targetUser = await UserRepository.getUser(userId);
      if (targetUser != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              conversationId: conversationId,
              otherUser: targetUser,
            ),
          ),
        );
      }
    }
  }

  // YENİ: Profili paylaşma fonksiyonu
  void _shareProfile(BuildContext context, UserModel user) {
     final messageToShare = MessageModel(
      id: '',
      conversationId: '',
      senderId: '',
      type: MessageType.profileShare,
      timestamp: DateTime.now(),
      sharedContentId: user.uid,
      sharedContentImageUrl: user.profileImageUrl,
      sharedContentText: "${user.username} adlı kullanıcının profiline göz at",
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForwardMessageScreen(messageToForward: messageToShare),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isCurrentUser = authProvider.currentUser?.uid == userId;

    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: userProvider.getUserStream(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData) {
            return const Center(child: Text('Kullanıcı bulunamadı'));
          }
          
          final user = userSnapshot.data!;

          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Text(user.username),
                actions: [
                  // YENİ: Paylaş Butonu
                  IconButton(
                    icon: const Icon(Icons.send_outlined),
                    onPressed: () => _shareProfile(context, user),
                  ),
                  if (isCurrentUser)
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        // Settings sayfası
                      },
                    ),
                ],
              ),
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: ProfileHeader(
                        user: user,
                        isCurrentUser: isCurrentUser,
                        onEditProfile: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(user: user),
                            ),
                          );
                        },
                        onFollowToggle: () async {
                          final currentUserId = authProvider.currentUser!.uid;
                          final isFollowing = user.followers.contains(currentUserId);
                          
                          if (isFollowing) {
                            await userProvider.unfollowUser(currentUserId, userId);
                          } else {
                            await userProvider.followUser(currentUserId, userId);
                          }
                        },
                        onMessage: !isCurrentUser ? () => _startConversation(context) : null,
                      ),
                    ),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        const TabBar(
                          tabs: [
                            Tab(icon: Icon(Icons.grid_on)),
                            Tab(icon: Icon(Icons.bookmark_border)),
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    StreamBuilder<List<PostModel>>(
                      stream: UserRepository.getUserPosts(userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final posts = snapshot.data ?? [];
                        if (posts.isEmpty) {
                          return const Center(child: Text('Henüz gönderi yok'));
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(1),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 1,
                            mainAxisSpacing: 1,
                          ),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            final firstMedia = post.mediaItems.first;
                            
                            return GestureDetector(
                              onTap: () {
                                // Post detail sayfası
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    firstMedia.url,
                                    fit: BoxFit.cover,
                                  ),
                                  if (firstMedia.isVideo)
                                    const Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  if (post.mediaItems.length > 1)
                                    const Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Icon(
                                        Icons.collections,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const Center(child: Text('Kaydedilen gönderiler')),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}