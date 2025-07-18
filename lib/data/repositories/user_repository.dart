import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/notification_model.dart';
import '../services/firebase_service.dart';
import 'notification_repository.dart';

class UserRepository {
  static const _uuid = Uuid();

  static Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await FirebaseService.firestore
          .collection(FirebaseService.usersCollection)
          .doc(userId)
          .get();
          
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Kullanıcı bulunamadı: $e');
    }
  }

  // YENİ: Kullanıcı adına göre kullanıcı getiren fonksiyon
  static Future<UserModel?> getUserByUsername(String username) async {
    try {
      final querySnapshot = await FirebaseService.firestore
          .collection(FirebaseService.usersCollection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Kullanıcı adı ile arama hatası: $e');
      return null;
    }
  }

  static Future<List<UserModel>> getMultipleUsers(List<String> userIds) async {
    if (userIds.isEmpty) {
      return [];
    }
    try {
      final querySnapshot = await FirebaseService.firestore
          .collection(FirebaseService.usersCollection)
          .where(FieldPath.documentId, whereIn: userIds)
          .get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Kullanıcılar getirilemedi: $e');
    }
  }

  static Stream<UserModel?> getUserStream(String userId) {
    return FirebaseService.firestore
        .collection(FirebaseService.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    });
  }

  static Future<void> followUser(String currentUserId, String targetUserId) async {
    final batch = FirebaseService.firestore.batch();
    
    batch.update(
      FirebaseService.firestore
          .collection(FirebaseService.usersCollection)
          .doc(currentUserId),
      {
        'following': FieldValue.arrayUnion([targetUserId]),
      },
    );
    
    batch.update(
      FirebaseService.firestore
          .collection(FirebaseService.usersCollection)
          .doc(targetUserId),
      {
        'followers': FieldValue.arrayUnion([currentUserId]),
      },
    );
    
    await batch.commit();

    final notification = NotificationModel(
      id: _uuid.v4(),
      userId: targetUserId,
      type: NotificationType.follow,
      fromUserId: currentUserId,
      timestamp: DateTime.now(),
    );
    await NotificationRepository.createNotification(notification);
  }

  static Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final batch = FirebaseService.firestore.batch();
    
    batch.update(
      FirebaseService.firestore
          .collection(FirebaseService.usersCollection)
          .doc(currentUserId),
      {
        'following': FieldValue.arrayRemove([targetUserId]),
      },
    );
    
    batch.update(
      FirebaseService.firestore
          .collection(FirebaseService.usersCollection)
          .doc(targetUserId),
      {
        'followers': FieldValue.arrayRemove([currentUserId]),
      },
    );
    
    await batch.commit();
  }

  static Future<void> updateProfile({
    required String userId,
    String? username,
    String? bio,
    String? profileImageUrl,
  }) async {
    final updates = <String, dynamic>{};
    
    if (username != null) updates['username'] = username;
    if (bio != null) updates['bio'] = bio;
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
    
    if (updates.isNotEmpty) {
      await FirebaseService.firestore
          .collection(FirebaseService.usersCollection)
          .doc(userId)
          .update(updates);
    }
  }

  static Stream<List<UserModel>> searchUsers(String query) {
    if (query.isEmpty) return Stream.value([]);
    
    return FirebaseService.firestore
        .collection(FirebaseService.usersCollection)
        .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('username', isLessThan: query.toLowerCase() + 'z')
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    });
  }

  static Stream<List<PostModel>> getUserPosts(String userId) {
    return FirebaseService.firestore
        .collection(FirebaseService.postsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromJson(doc.data()))
          .toList();
    });
  }
}