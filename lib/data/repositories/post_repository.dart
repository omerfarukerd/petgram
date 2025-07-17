import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

class PostRepository {
  static const _uuid = Uuid();

  static Future<void> createPost({
    required String userId,
    required List<File> mediaFiles,
    required List<bool> isVideoList,
    String? caption,
    bool isAdoption = false,
  }) async {
    try {
      // Tüm medya dosyalarını yükle
      List<MediaItem> mediaItems = [];
      
      for (int i = 0; i < mediaFiles.length; i++) {
        final url = await StorageService.uploadMedia(
          mediaFiles[i], 
          'posts', 
          isVideoList[i]
        );
        mediaItems.add(MediaItem(url: url, isVideo: isVideoList[i]));
      }
      
      final post = PostModel(
        id: _uuid.v4(),
        userId: userId,
        mediaItems: mediaItems,
        caption: caption,
        likes: [],
        createdAt: DateTime.now(),
        isAdoption: isAdoption,
      );
      
      await FirebaseService.firestore
          .collection(FirebaseService.postsCollection)
          .doc(post.id)
          .set(post.toJson());
    } catch (e) {
      throw e;
    }
  }
  
  static Stream<List<PostModel>> getFeedPosts() {
    return FirebaseService.firestore
        .collection(FirebaseService.postsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromJson(doc.data()))
          .toList();
    });
  }
  
  static Future<void> likePost(String postId, String userId) async {
    await FirebaseService.firestore
        .collection(FirebaseService.postsCollection)
        .doc(postId)
        .update({
      'likes': FieldValue.arrayUnion([userId]),
    });
  }
  
  static Future<void> unlikePost(String postId, String userId) async {
    await FirebaseService.firestore
        .collection(FirebaseService.postsCollection)
        .doc(postId)
        .update({
      'likes': FieldValue.arrayRemove([userId]),
    });
  }
}