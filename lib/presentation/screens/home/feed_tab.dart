import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/story_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/message_provider.dart';
import '../../widgets/post/post_item.dart';
import '../../widgets/story/story_ring.dart';
import '../story/story_viewer_screen.dart';
import '../story/create_story_screen.dart';
import '../message/chat_list_screen.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  @override
  void initState() {
    super.initState();
    // MessageProvider'ı başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final messageProvider = context.read<MessageProvider>();
      
      if (authProvider.currentUser != null) {
        messageProvider.loadUserConversations(authProvider.currentUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid ?? 'test-user';
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetGram'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // Bildirimler
            },
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Story listesi
          SliverToBoxAdapter(
            child: Container(
              height: 110,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: StreamBuilder<List<StoryModel>>(
                stream: currentUser != null
                    ? StoryRepository.getFollowingStories(
                        currentUserId,
                        currentUser.following,
                      )
                    : Stream.value([]),
                builder: (context, storySnapshot) {
                  final stories = storySnapshot.data ?? [];
                  
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: stories.length + 1,
                    itemBuilder: (context, index) {
                      // İlk item her zaman current user
                      if (index == 0) {
                        final currentUserStory = stories.firstWhere(
                          (s) => s.userId == currentUserId,
                          orElse: () => StoryModel(
                            id: '',
                            userId: currentUserId,
                            items: [],
                            createdAt: DateTime.now(),
                          ),
                        );
                        
                        return FutureBuilder<UserModel?>(
                          future: UserRepository.getUser(currentUserId),
                          builder: (context, userSnapshot) {
                            final user = userSnapshot.data ?? UserModel(
                              uid: currentUserId,
                              email: '',
                              username: 'Sen',
                            );
                            
                            return StoryRing(
                              user: user,
                              story: currentUserStory.items.isNotEmpty ? currentUserStory : null,
                              isCurrentUser: true,
                              onTap: currentUserStory.items.isNotEmpty
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StoryViewerScreen(
                                            stories: [currentUserStory],
                                            initialIndex: 0,
                                          ),
                                        ),
                                      );
                                    }
                                  : () {},
                              onAddStory: () async {
                                final result = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CreateStoryScreen(),
                                  ),
                                );
                                
                                if (result == true && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Hikaye paylaşıldı!'),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      }
                      
                      // Diğer story'ler
                      final storyIndex = index - 1;
                      final otherStories = stories.where((s) => s.userId != currentUserId).toList();
                      
                      if (storyIndex >= otherStories.length) {
                        return const SizedBox();
                      }
                      
                      final story = otherStories[storyIndex];
                      
                      return FutureBuilder<UserModel?>(
                        future: UserRepository.getUser(story.userId),
                        builder: (context, userSnapshot) {
                          final user = userSnapshot.data;
                          if (user == null) return const SizedBox();
                          
                          return StoryRing(
                            user: user,
                            story: story,
                            isCurrentUser: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoryViewerScreen(
                                    stories: otherStories,
                                    initialIndex: storyIndex,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
          
          // Divider
          const SliverToBoxAdapter(
            child: Divider(height: 1),
          ),
          
          // Post listesi
          StreamBuilder<List<PostModel>>(
            stream: postProvider.getFeedPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Henüz gönderi yok')),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = snapshot.data![index];
                    final isLiked = post.likes.contains(currentUserId);

                    return PostItem(
                      post: post,
                      isLiked: isLiked,
                      onLike: () => postProvider.toggleLike(
                        post.id,
                        currentUserId,
                        isLiked,
                      ),
                    );
                  },
                  childCount: snapshot.data!.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}