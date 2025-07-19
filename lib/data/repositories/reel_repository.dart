import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/reel_model.dart';
import '../models/post_model.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import 'hashtag_repository.dart';

class ReelRepository {
  static const _uuid = Uuid();
  static const String reelsCollection = 'reels';

  static Future<void> createReel({
    required String userId,
    required File videoFile,
    String? caption,
    String? audioId,
    String? audioName,
    String? artistName,
    bool allowDuet = true,
    bool allowRemix = true,
    String? thumbnailUrl,
  }) async {
    try {
      // Video yükle
      final videoUrl = await StorageService.uploadMedia(videoFile, 'reels', true);
      
      final reel = ReelModel(
        id: _uuid.v4(),
        userId: userId,
        mediaItems: [MediaItem(url: videoUrl, isVideo: true,thumbnailUrl: thumbnailUrl,)],
        caption: caption,
        likes: [],
        createdAt: DateTime.now(),
        audioId: audioId,
        audioName: audioName,
        artistName: artistName,
        allowDuet: allowDuet,
        allowRemix: allowRemix,
      );
      
      // Firestore'a kaydet
      await FirebaseService.firestore
          .collection(reelsCollection)
          .doc(reel.id)
          .set(reel.toJson());

      // Post collection'a da ekle (keşfet için)
      await FirebaseService.firestore
          .collection(FirebaseService.postsCollection)
          .doc(reel.id)
          .set(reel.toJson());

      // Hashtag'leri işle
      if (caption != null) {
        await HashtagRepository.processHashtags(reel);
      }
    } catch (e) {
      throw Exception('Reel oluşturulamadı: $e');
    }
  }

  static Stream<List<ReelModel>> getReelsFeed() {
    return FirebaseService.firestore
        .collection(reelsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReelModel.fromJson(doc.data()))
          .toList();
    });
  }

  static Stream<List<ReelModel>> getUserReels(String userId) {
    return FirebaseService.firestore
        .collection(reelsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReelModel.fromJson(doc.data()))
          .toList();
    });
  }

  static Stream<List<ReelModel>> getReelsByAudio(String audioId) {
    return FirebaseService.firestore
        .collection(reelsCollection)
        .where('audioId', isEqualTo: audioId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReelModel.fromJson(doc.data()))
          .toList();
    });
  }

  static Future<void> likeReel(String reelId, String userId) async {
    await FirebaseService.firestore
        .collection(reelsCollection)
        .doc(reelId)
        .update({
      'likes': FieldValue.arrayUnion([userId]),
    });
    
    // Post collection'da da güncelle
    await FirebaseService.firestore
        .collection(FirebaseService.postsCollection)
        .doc(reelId)
        .update({
      'likes': FieldValue.arrayUnion([userId]),
    });
  }

  static Future<void> unlikeReel(String reelId, String userId) async {
    await FirebaseService.firestore
        .collection(reelsCollection)
        .doc(reelId)
        .update({
      'likes': FieldValue.arrayRemove([userId]),
    });
    
    // Post collection'da da güncelle
    await FirebaseService.firestore
        .collection(FirebaseService.postsCollection)
        .doc(reelId)
        .update({
      'likes': FieldValue.arrayRemove([userId]),
    });
  }

  static Future<void> deleteReel(String reelId) async {
    await FirebaseService.firestore
        .collection(reelsCollection)
        .doc(reelId)
        .delete();
    
    // Post collection'dan da sil
    await FirebaseService.firestore
        .collection(FirebaseService.postsCollection)
        .doc(reelId)
        .delete();
  }
}