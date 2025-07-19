import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import 'notification_repository.dart';
import 'hashtag_repository.dart';

class PostRepository {
  static const _uuid = Uuid();

  static Future<void> createPost({
    required String userId,
    required List<File> mediaFiles,
    required List<bool> isVideoList,
    String? caption,
    bool isAdoption = false,
    List<String?>? thumbnailUrls, 
  }) async {
    try {
      List<MediaItem> mediaItems = [];
      
      for (int i = 0; i < mediaFiles.length; i++) {
        final url = await StorageService.uploadMedia(
          mediaFiles[i], 
          'posts', 
          isVideoList[i]
        );
        mediaItems.add(MediaItem(url: url, isVideo: isVideoList[i],thumbnailUrl: thumbnailUrls?[i], ));
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

      // Gönderideki hashtag'leri işle
      await HashtagRepository.processHashtags(post);

    } catch (e) {
      throw e;
    }
  }

  // YENİ: Gönderiyi/Reels'i silme fonksiyonu
  static Future<void> deletePost(String postId) async {
    // Not: İdeal olarak, bir gönderi silindiğinde ona bağlı tüm verilerin
    // (yorumlar, beğeniler, bildirimler, hashtag kayıtları) silinmesi gerekir.
    // Bu işlem genellikle atomik olması için bir Cloud Function ile yapılır.
    // Şimdilik sadece gönderinin kendisini siliyoruz.
    await FirebaseService.firestore
        .collection(FirebaseService.postsCollection)
        .doc(postId)
        .delete();
  }

  // YENİ: Gönderi/Reels açıklamasını güncelleme fonksiyonu
  static Future<void> updatePostCaption(String postId, String newCaption) async {
    final postRef = FirebaseService.firestore.collection(FirebaseService.postsCollection).doc(postId);
    final postDoc = await postRef.get();
    
    if (postDoc.exists) {
      final oldCaption = PostModel.fromJson(postDoc.data()!).caption ?? '';
      
      // Hashtag'leri güncelle (eskiyi sil, yeniyi ekle mantığı)
      // Bu işlem daha da geliştirilebilir, şimdilik basit tutulmuştur.
      final oldHashtags = HashtagRepository.extractHashtags(oldCaption);
      final newHashtags = HashtagRepository.extractHashtags(newCaption);
      
      // TODO: Sadece değişen hashtag'ler için işlem yapmak daha verimli olur.
      // Şimdilik basitçe eski post'u hashtag'lerden çıkarıp yenisini ekliyoruz.
      
      await postRef.update({'caption': newCaption});
      
      // Güncellenmiş post modeli ile hashtag'leri yeniden işle
      final updatedPost = PostModel.fromJson((await postRef.get()).data()!);
      await HashtagRepository.processHashtags(updatedPost);
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
  
  static Future<void> likePost(String postId, String likerUserId) async {
    final postRef = FirebaseService.firestore.collection(FirebaseService.postsCollection).doc(postId);

    await postRef.update({
      'likes': FieldValue.arrayUnion([likerUserId]),
    });

    final postDoc = await postRef.get();
    if (postDoc.exists) {
      final post = PostModel.fromJson(postDoc.data()!);
      if (post.userId != likerUserId) {
        final notification = NotificationModel(
          id: _uuid.v4(),
          userId: post.userId,
          type: NotificationType.like,
          fromUserId: likerUserId,
          postId: post.id,
          postImageUrl: post.mediaItems.first.url,
          timestamp: DateTime.now(),
        );
        await NotificationRepository.createNotification(notification);
      }
    }
  }
  
  static Future<void> unlikePost(String postId, String unlikerUserId) async {
    final postRef = FirebaseService.firestore.collection(FirebaseService.postsCollection).doc(postId);
    
    await postRef.update({
      'likes': FieldValue.arrayRemove([unlikerUserId]),
    });

    final postDoc = await postRef.get();
    if (postDoc.exists) {
      final post = PostModel.fromJson(postDoc.data()!);
      final notificationQuery = await FirebaseService.firestore
          .collection(FirebaseService.notificationsCollection)
          .where('userId', isEqualTo: post.userId)
          .where('fromUserId', isEqualTo: unlikerUserId)
          .where('postId', isEqualTo: postId)
          .where('type', isEqualTo: NotificationType.like.name)
          .get();

      for (final doc in notificationQuery.docs) {
        await doc.reference.delete();
      }
    }
  }
}