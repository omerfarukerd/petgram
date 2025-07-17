import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class PresenceRepository {
  static const String presenceCollection = 'presence';
  
  static Future<void> updatePresence(String userId, bool isOnline) async {
    await FirebaseService.firestore
        .collection(presenceCollection)
        .doc(userId)
        .set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  static Stream<Map<String, dynamic>> getUserPresence(String userId) {
    return FirebaseService.firestore
        .collection(presenceCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data() ?? {'isOnline': false});
  }

  static Stream<Map<String, bool>> getMultipleUsersPresence(List<String> userIds) {
    if (userIds.isEmpty) return Stream.value({});
    
    return FirebaseService.firestore
        .collection(presenceCollection)
        .where(FieldPath.documentId, whereIn: userIds)
        .snapshots()
        .map((snapshot) {
      final presence = <String, bool>{};
      for (final doc in snapshot.docs) {
        presence[doc.id] = doc.data()['isOnline'] ?? false;
      }
      return presence;
    });
  }
}