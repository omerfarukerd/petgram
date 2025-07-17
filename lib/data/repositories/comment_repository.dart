import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/comment_model.dart';
import '../services/firebase_service.dart';

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

    // Update post comment count
    await FirebaseService.firestore
        .collection(FirebaseService.postsCollection)
        .doc(postId)
        .update({
      'commentCount': FieldValue.increment(1),
    });
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

  static Future<void> likeComment(String commentId, String userId) async {
    await FirebaseService.firestore
        .collection(FirebaseService.commentsCollection)
        .doc(commentId)
        .update({
      'likes': FieldValue.arrayUnion([userId]),
    });
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