import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../services/firebase_service.dart';

class NotificationRepository {
  static const _uuid = Uuid();

  static Future<void> createNotification(NotificationModel notification) async {
    // Kullanıcının kendine bildirim göndermesini engelle
    if (notification.userId == notification.fromUserId) {
      return;
    }
    
    await FirebaseService.firestore
        .collection(FirebaseService.notificationsCollection)
        .doc(_uuid.v4()) // Benzersiz ID oluştur
        .set(notification.toJson());
  }

  static Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return FirebaseService.firestore
        .collection(FirebaseService.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data()))
            .toList());
  }

  static Future<void> markAsRead(String notificationId) async {
    await FirebaseService.firestore
        .collection(FirebaseService.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }
  
  static Future<void> markAllAsRead(String userId) async {
    final querySnapshot = await FirebaseService.firestore
        .collection(FirebaseService.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseService.firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}