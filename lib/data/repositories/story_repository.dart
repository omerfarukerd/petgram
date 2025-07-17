import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/story_model.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

class StoryRepository {
  static const _uuid = Uuid();
  static const String storiesCollection = 'stories';

  // Story oluştur/güncelle
  static Future<void> createOrUpdateStory({
    required String userId,
    required File mediaFile,
    required bool isVideo,
    String? caption,
    List<StorySticker>? stickers,
  }) async {
    try {
      // Medya yükle
      final mediaUrl = await StorageService.uploadMedia(
        mediaFile, 
        'stories', 
        isVideo
      );

      // Yeni story item
      final storyItem = StoryItem(
        id: _uuid.v4(),
        mediaUrl: mediaUrl,
        isVideo: isVideo,
        caption: caption,
        stickers: stickers,
        createdAt: DateTime.now(),
      );

      // Kullanıcının aktif story'sini kontrol et
      final storyDoc = await FirebaseService.firestore
          .collection(storiesCollection)
          .doc(userId)
          .get();

      if (storyDoc.exists && storyDoc.data() != null) {
        // Mevcut story'ye ekle
        final existingStory = StoryModel.fromJson(storyDoc.data()!);
        
        if (!existingStory.isExpired) {
          final updatedItems = [...existingStory.items, storyItem];
          
          await FirebaseService.firestore
              .collection(storiesCollection)
              .doc(userId)
              .update({
            'items': updatedItems.map((e) => e.toJson()).toList(),
          });
          return;
        }
      }

      // Yeni story oluştur
      final newStory = StoryModel(
        id: userId,
        userId: userId,
        items: [storyItem],
        createdAt: DateTime.now(),
      );

      await FirebaseService.firestore
          .collection(storiesCollection)
          .doc(userId)
          .set(newStory.toJson());
    } catch (e) {
      throw Exception('Story oluşturulamadı: $e');
    }
  }

  // Story'leri getir (takip edilenler)
  static Stream<List<StoryModel>> getFollowingStories(
    String currentUserId,
    List<String> followingIds,
  ) {
    // Kendini ve takip ettiklerini dahil et
    final userIds = [currentUserId, ...followingIds];
    
    if (userIds.isEmpty) return Stream.value([]);

    return FirebaseService.firestore
        .collection(storiesCollection)
        .where('userId', whereIn: userIds.take(10).toList()) // Firestore limit
        .where('expiresAt', isGreaterThan: DateTime.now().toIso8601String())
        .snapshots()
        .map((snapshot) {
      final stories = snapshot.docs
          .map((doc) => StoryModel.fromJson(doc.data()))
          .where((story) => story.isActive)
          .toList();
      
      // Önce kendi story'n, sonra diğerleri
      stories.sort((a, b) {
        if (a.userId == currentUserId) return -1;
        if (b.userId == currentUserId) return 1;
        // Görülmemiş story'ler önce
        final aViewed = a.viewers.contains(currentUserId);
        final bViewed = b.viewers.contains(currentUserId);
        if (aViewed && !bViewed) return 1;
        if (!aViewed && bViewed) return -1;
        return b.createdAt.compareTo(a.createdAt);
      });
      
      return stories;
    });
  }

  // Story görüntüleme
  static Future<void> viewStory(String storyUserId, String viewerUserId) async {
    if (storyUserId == viewerUserId) return; // Kendi story'ni görüntüleme sayılmaz
    
    await FirebaseService.firestore
        .collection(storiesCollection)
        .doc(storyUserId)
        .update({
      'viewers': FieldValue.arrayUnion([viewerUserId]),
    });
  }

  // Story'e tepki
  static Future<void> reactToStory(
    String storyUserId,
    String storyItemId,
    String reactorUserId,
    String emoji,
  ) async {
    final reaction = StoryReaction(
      emoji: emoji,
      timestamp: DateTime.now(),
    );

    final storyDoc = await FirebaseService.firestore
        .collection(storiesCollection)
        .doc(storyUserId)
        .get();

    if (storyDoc.exists && storyDoc.data() != null) {
      final story = StoryModel.fromJson(storyDoc.data()!);
      final itemIndex = story.items.indexWhere((item) => item.id == storyItemId);
      
      if (itemIndex != -1) {
        story.items[itemIndex].reactions[reactorUserId] = reaction;
        
        await FirebaseService.firestore
            .collection(storiesCollection)
            .doc(storyUserId)
            .update({
          'items': story.items.map((e) => e.toJson()).toList(),
        });
      }
    }
  }

  // Story silme
  static Future<void> deleteStoryItem(String userId, String itemId) async {
    final storyDoc = await FirebaseService.firestore
        .collection(storiesCollection)
        .doc(userId)
        .get();

    if (storyDoc.exists && storyDoc.data() != null) {
      final story = StoryModel.fromJson(storyDoc.data()!);
      story.items.removeWhere((item) => item.id == itemId);
      
      if (story.items.isEmpty) {
        // Tüm story'yi sil
        await FirebaseService.firestore
            .collection(storiesCollection)
            .doc(userId)
            .delete();
      } else {
        // Güncelle
        await FirebaseService.firestore
            .collection(storiesCollection)
            .doc(userId)
            .update({
          'items': story.items.map((e) => e.toJson()).toList(),
        });
      }
    }
  }

  // Highlight oluştur
  static Future<void> createHighlight({
    required String userId,
    required String title,
    required List<StoryItem> items,
  }) async {
    final highlight = StoryModel(
      id: _uuid.v4(),
      userId: userId,
      items: items,
      createdAt: DateTime.now(),
      isHighlight: true,
      highlightTitle: title,
    );

    await FirebaseService.firestore
        .collection('highlights')
        .doc(highlight.id)
        .set(highlight.toJson());
  }

  // Highlight'ları getir
  static Stream<List<StoryModel>> getUserHighlights(String userId) {
    return FirebaseService.firestore
        .collection('highlights')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StoryModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Expired story'leri temizle (Cloud Function'da çalışmalı)
  static Future<void> cleanupExpiredStories() async {
    final expiredStories = await FirebaseService.firestore
        .collection(storiesCollection)
        .where('expiresAt', isLessThan: DateTime.now().toIso8601String())
        .get();

    final batch = FirebaseService.firestore.batch();
    
    for (final doc in expiredStories.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}