import 'package:flutter/material.dart';
import 'package:pet_gram/data/models/post_model.dart';
import 'package:pet_gram/data/repositories/hashtag_repository.dart';
import 'package:pet_gram/presentation/widgets/post/post_item.dart';
import 'package:provider/provider.dart';
import 'package:pet_gram/presentation/providers/post_provider.dart';
import 'package:pet_gram/presentation/providers/auth_provider.dart';

class HashtagFeedScreen extends StatelessWidget {
  final String hashtag;

  const HashtagFeedScreen({super.key, required this.hashtag});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('#$hashtag'),
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: HashtagRepository.getPostsForHashtag(hashtag),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bu etiketle ilgili gönderi bulunamadı.'));
          }

          final posts = snapshot.data!;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final isLiked = post.likes.contains(currentUserId);
              return PostItem(
                post: post,
                isLiked: isLiked,
                onLike: () {
                  context.read<PostProvider>().toggleLike(post.id, currentUserId, isLiked);
                },
              );
            },
          );
        },
      ),
    );
  }
}