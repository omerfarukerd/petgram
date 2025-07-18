import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post_model.dart';
import '../services/firebase_service.dart';

class HashtagRepository {
  // Metinden hashtag'leri çıkaran yardımcı fonksiyon
  static List<String> extractHashtags(String text) {
    final RegExp regex = RegExp(r"#(\w+)");
    return regex.allMatches(text).map((m) => m.group(1)!.toLowerCase()).toList();
  }

  // Bir gönderi oluşturulduğunda veya güncellendiğinde hashtag'leri işler
  static Future<void> processHashtags(PostModel post) async {
    if (post.caption == null) return;

    final hashtags = extractHashtags(post.caption!);
    if (hashtags.isEmpty) return;

    final batch = FirebaseService.firestore.batch();
    final now = Timestamp.now();

    for (final tag in hashtags) {
      final hashtagRef = FirebaseService.firestore.collection('hashtags').doc(tag);
      
      // GÜNCELLENDİ: Trend takibi için yeni alanları güncelle
      batch.set(
        hashtagRef, 
        {
          'tag': tag,
          'postCount': FieldValue.increment(1),
          'recentPostCount': FieldValue.increment(1), // Son kullanım sayacını artır
          'lastUsed': now, // Son kullanım zamanını güncelle
        }, 
        SetOptions(merge: true)
      );
      
      final postInHashtagRef = hashtagRef.collection('posts').doc(post.id);
      batch.set(postInHashtagRef, {'createdAt': post.createdAt});
    }

    await batch.commit();
  }

  // YENİ: Yükselen trenddeki hashtag'leri getiren fonksiyon
  static Stream<List<String>> getTrendingHashtags() {
    final twentyFourHoursAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24)));
    
    return FirebaseService.firestore
        .collection('hashtags')
        .where('lastUsed', isGreaterThanOrEqualTo: twentyFourHoursAgo)
        .orderBy('lastUsed', descending: true)
        .orderBy('recentPostCount', descending: true)
        .limit(10) // İlk 10 trendi al
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Bir hashtag'e ait gönderileri getirir
  static Stream<List<PostModel>> getPostsForHashtag(String tag) {
    return FirebaseService.firestore
        .collection('hashtags')
        .doc(tag.toLowerCase())
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return [];
          
          final postIds = snapshot.docs.map((doc) => doc.id).toList();
          
          final postsSnapshot = await FirebaseService.firestore
              .collection(FirebaseService.postsCollection)
              .where(FieldPath.documentId, whereIn: postIds)
              .get();
          
          // Gönderileri createdAt zamanına göre sırala
          var posts = postsSnapshot.docs
              .map((doc) => PostModel.fromJson(doc.data()))
              .toList();
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return posts;
        });
  }
}