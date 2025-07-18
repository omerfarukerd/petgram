import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../services/firebase_service.dart';
import 'notification_repository.dart';

class MessageRepository {
  static const _uuid = Uuid();

  // HATA DÜZELTİLDİ: Conversation_model -> ConversationModel
  static Stream<List<ConversationModel>> getUserConversations(String userId) {
    return FirebaseService.firestore
        .collection(FirebaseService.conversationsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConversationModel.fromJson(doc.data()))
            .toList());
  }

  static Future<String> createConversation(List<String> participants) async {
    // Check if conversation exists
    final query = await FirebaseService.firestore
        .collection(FirebaseService.conversationsCollection)
        .where('participants', arrayContains: participants[0])
        .get();

    for (final doc in query.docs) {
      final conv = ConversationModel.fromJson(doc.data());
      if (conv.participants.length == participants.length &&
          conv.participants.toSet().containsAll(participants)) {
        return doc.id;
      }
    }

    // Create new conversation
    final docRef = FirebaseService.firestore
        .collection(FirebaseService.conversationsCollection)
        .doc();

    await docRef.set({
      'id': docRef.id,
      'participants': participants,
      'lastMessageTime': DateTime.now().toIso8601String(),
      'unreadCount': {},
      'lastSeen': {},
      'isGroup': participants.length > 2,
    });

    return docRef.id;
  }

  static Stream<List<MessageModel>> getMessages(String conversationId) {
    return FirebaseService.firestore
        .collection(FirebaseService.messagesCollection)
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data()))
            .toList());
  }

  static Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required MessageType type,
    String? text,
    List<String>? mediaUrls,
    String? replyToId,
  }) async {
    final batch = FirebaseService.firestore.batch();
    
    final messageRef = FirebaseService.firestore
        .collection(FirebaseService.messagesCollection)
        .doc(conversationId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      id: messageRef.id,
      conversationId: conversationId,
      senderId: senderId,
      type: type,
      text: text,
      mediaUrls: mediaUrls,
      timestamp: DateTime.now(),
      replyToId: replyToId,
    );

    batch.set(messageRef, message.toJson());
    
    final conversationRef = FirebaseService.firestore.collection(FirebaseService.conversationsCollection).doc(conversationId);
    batch.update(
      conversationRef,
      {
        'lastMessage': message.toJson(),
        'lastMessageTime': message.timestamp.toIso8601String(),
      },
    );

    await batch.commit();

    // Yeni mesaj bildirimi oluşturma
    final convDoc = await conversationRef.get();
    if (convDoc.exists) {
      final conversation = ConversationModel.fromJson(convDoc.data()!);
      for (final participantId in conversation.participants) {
        if (participantId != senderId) {
          final notification = NotificationModel(
            id: _uuid.v4(),
            userId: participantId,
            type: NotificationType.newMessage,
            fromUserId: senderId,
            timestamp: DateTime.now(),
          );
          await NotificationRepository.createNotification(notification);
        }
      }
    }
  }

  static Future<void> deleteMessage(String conversationId, String messageId) async {
    await FirebaseService.firestore
      .collection(FirebaseService.messagesCollection)
      .doc(conversationId)
      .collection('messages')
      .doc(messageId)
      .delete();
  }

  static Future<void> editMessage(String conversationId, String messageId, String newText) async {
    await FirebaseService.firestore
      .collection(FirebaseService.messagesCollection)
      .doc(conversationId)
      .collection('messages')
      .doc(messageId)
      .update({
        'text': newText,
        'isEdited': true,
        'editedAt': DateTime.now().toIso8601String(),
      });
  }

  static Future<void> markAsRead(String conversationId, String userId) async {
    final messagesQuery = await FirebaseService.firestore
        .collection(FirebaseService.messagesCollection)
        .doc(conversationId)
        .collection('messages')
        .where('readBy.$userId', isNull: true)
        .get();

    final batch = FirebaseService.firestore.batch();
    final readTimestamp = DateTime.now().toIso8601String();

    for (final doc in messagesQuery.docs) {
      batch.update(doc.reference, {'readBy.$userId': readTimestamp});
    }

    batch.update(
      FirebaseService.firestore.collection(FirebaseService.conversationsCollection).doc(conversationId),
      {'unreadCount.$userId': 0},
    );

    await batch.commit();
  }

  static Stream<Map<String, bool>> getTypingStatus(String conversationId) {
    return FirebaseService.firestore
        .collection(FirebaseService.typingCollection)
        .doc(conversationId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return {};
      final data = doc.data() as Map<String, dynamic>;
      final typing = <String, bool>{};
      
      data.forEach((userId, timestamp) {
        final time = DateTime.parse(timestamp as String);
        typing[userId] = DateTime.now().difference(time).inSeconds < 3;
      });
      
      return typing;
    });
  }

  static Future<void> setTypingStatus(
    String conversationId, 
    String userId, 
    bool isTyping,
  ) async {
    if (isTyping) {
      await FirebaseService.firestore
          .collection(FirebaseService.typingCollection)
          .doc(conversationId)
          .set({userId: DateTime.now().toIso8601String()}, SetOptions(merge: true));
    } else {
      await FirebaseService.firestore
          .collection(FirebaseService.typingCollection)
          .doc(conversationId)
          .update({userId: FieldValue.delete()});
    }
  }

  static Future<void> addReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    await FirebaseService.firestore
        .collection(FirebaseService.messagesCollection)
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.$userId': emoji});
  }

  static Future<void> removeReaction({
    required String conversationId,
    required String messageId,
    required String userId,
  }) async {
    await FirebaseService.firestore
        .collection(FirebaseService.messagesCollection)
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.$userId': FieldValue.delete()});
  }
}