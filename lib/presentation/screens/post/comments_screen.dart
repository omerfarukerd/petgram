import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/caption_parser.dart'; // YENİ
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
    FocusScope.of(context).unfocus(); // Klavyeyi kapat
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
                  padding: const EdgeInsets.only(top: 8),
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
                      // GÜNCELLENDİ: CaptionParser kullanıldı
                      title: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                              text: '${comment.username} ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            // Yorum metni parser ile işleniyor
                            ...CaptionParser(comment.text, context).parseText(),
                          ],
                        ),
                      ),
                      subtitle: Text(
                        _getTimeAgo(comment.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SafeArea(
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
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    
    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}hft';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}g';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}s';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}d';
    } else {
      return 'Şimdi';
    }
  }
}