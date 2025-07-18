import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../services/firebase_service.dart';
import 'notification_repository.dart';
import 'hashtag_repository.dart'; // YENİ

class CommentRepository {
  static const _uuid = Uuid();

  static Future<void> addComment({
    required String postId,
    required String userId,
    required String username,
    required String text,
    String? userProfileImage,
  }) async {
    final comment = CommentModel(
      id: _uuid.v4(),
      postId: postId,
      userId: userId,
      username: username,
      userProfileImage: userProfileImage,
      text: text,
      createdAt: DateTime.now(),
      likes: [],
    );

    await FirebaseService.firestore
        .collection(FirebaseService.commentsCollection)
        .doc(comment.id)
        .set(comment.toJson());

    final postRef = FirebaseService.firestore.collection(FirebaseService.postsCollection).doc(postId);
    
    await postRef.update({
      'commentCount': FieldValue.increment(1),
    });

    // YENİ: Yorumdaki hashtag'leri işle
    // Yorumu, ilgili gönderiymiş gibi işleyerek hashtag'leri ana gönderiye bağlıyoruz.
    final postDocForHashtag = await postRef.get();
    if (postDocForHashtag.exists) {
        final postForHashtag = PostModel.fromJson(postDocForHashtag.data()!);
        // Geçici bir PostModel oluşturup caption yerine yorum metnini veriyoruz.
        final tempPostWithCommentText = PostModel(
            id: postForHashtag.id,
            userId: postForHashtag.userId,
            mediaItems: postForHashtag.mediaItems,
            caption: text, // Hashtag'leri yorum metninden al
            likes: postForHashtag.likes,
            createdAt: postForHashtag.createdAt
        );
        await HashtagRepository.processHashtags(tempPostWithCommentText);
    }


    // Yorum bildirimi oluşturma
    final postDoc = await postRef.get();
    if (postDoc.exists) {
      final post = PostModel.fromJson(postDoc.data()!);
      if (post.userId != userId) {
        final notification = NotificationModel(
          id: _uuid.v4(),
          userId: post.userId,
          type: NotificationType.comment,
          fromUserId: userId,
          postId: post.id,
          postImageUrl: post.mediaItems.first.url,
          commentText: text,
          timestamp: DateTime.now(),
        );
        await NotificationRepository.createNotification(notification);
      }
    }
  }

  static Stream<List<CommentModel>> getComments(String postId) {
    return FirebaseService.firestore
        .collection(FirebaseService.commentsCollection)
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommentModel.fromJson(doc.data()))
          .toList();
    });
  }

  static Future<void> deleteComment(String commentId, String postId) async {
    await FirebaseService.firestore
        .collection(FirebaseService.commentsCollection)
        .doc(commentId)
        .delete();

    await FirebaseService.firestore
        .collection(FirebaseService.postsCollection)
        .doc(postId)
        .update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  static Future<void> likeComment(String commentId, String likerUserId) async {
    final commentRef = FirebaseService.firestore.collection(FirebaseService.commentsCollection).doc(commentId);

    await commentRef.update({
      'likes': FieldValue.arrayUnion([likerUserId]),
    });

    // Yorum beğenme bildirimi
    final commentDoc = await commentRef.get();
    if (commentDoc.exists) {
      final comment = CommentModel.fromJson(commentDoc.data()!);
      if (comment.userId != likerUserId) {
        final postDoc = await FirebaseService.firestore.collection(FirebaseService.postsCollection).doc(comment.postId).get();
        final postImageUrl = postDoc.exists ? PostModel.fromJson(postDoc.data()!).mediaItems.first.url : null;
        
        final notification = NotificationModel(
          id: _uuid.v4(),
          userId: comment.userId,
          type: NotificationType.commentLike,
          fromUserId: likerUserId,
          postId: comment.postId,
          postImageUrl: postImageUrl,
          commentText: comment.text,
          timestamp: DateTime.now(),
        );
        await NotificationRepository.createNotification(notification);
      }
    }
  }

  static Future<void> unlikeComment(String commentId, String userId) async {
    await FirebaseService.firestore
        .collection(FirebaseService.commentsCollection)
        .doc(commentId)
        .update({
      'likes': FieldValue.arrayRemove([userId]),
    });
  }
}