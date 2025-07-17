import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../providers/auth_provider.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    await CommentRepository.addComment(
      postId: widget.postId,
      userId: user?.uid ?? 'test-user',
      username: user?.username ?? 'Test User',
      text: _commentController.text.trim(),
      userProfileImage: user?.profileImageUrl,
    );

    _commentController.clear();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid ?? 'test-user';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yorumlar'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: CommentRepository.getComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return const Center(
                    child: Text('Henüz yorum yok'),
                  );
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isLiked = comment.likes.contains(currentUserId);
                    final isOwner = comment.userId == currentUserId;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comment.userProfileImage != null
                            ? NetworkImage(comment.userProfileImage!)
                            : null,
                        child: comment.userProfileImage == null
                            ? Text(comment.username[0].toUpperCase())
                            : null,
                      ),
                      title: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: comment.username,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(text: comment.text),
                          ],
                        ),
                      ),
                      subtitle: Text(
                        _getTimeAgo(comment.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: isLiked ? Colors.red : null,
                            ),
                            onPressed: () {
                              if (isLiked) {
                                CommentRepository.unlikeComment(comment.id, currentUserId);
                              } else {
                                CommentRepository.likeComment(comment.id, currentUserId);
                              }
                            },
                          ),
                          if (isOwner)
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () {
                                CommentRepository.deleteComment(comment.id, widget.postId);
                              },
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Yorum ekle...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    
    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}h önce';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}g önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}s önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}d önce';
    } else {
      return 'Şimdi';
    }
  }
}