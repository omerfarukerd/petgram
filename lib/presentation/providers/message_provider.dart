import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/presence_repository.dart';
import '../../data/services/firebase_service.dart';

class MessageProvider extends ChangeNotifier {
  List<ConversationModel> _conversations = [];
  List<MessageModel> _currentMessages = [];
  Map<String, bool> _typingUsers = {};
  Map<String, bool> _onlineStatus = {};
  String? _currentConversationId;
  StreamSubscription? _conversationsSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _presenceSubscription;
  bool _isLoading = false;
  String? _error;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get currentMessages => _currentMessages;
  Map<String, bool> get typingUsers => _typingUsers;
  Map<String, bool> get onlineStatus => _onlineStatus;
  String? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadUserConversations(String userId) {
    _conversationsSubscription?.cancel();
    _conversationsSubscription = MessageRepository
        .getUserConversations(userId)
        .listen((conversations) {
      _conversations = conversations;
      notifyListeners();
    });

    // Online status takibi - switchMap yerine asyncExpand kullanıldı
    _presenceSubscription?.cancel();
    _presenceSubscription = Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) async {
      final allUserIds = <String>{};
      for (final conv in _conversations) {
        allUserIds.addAll(conv.participants.where((id) => id != userId));
      }
      return allUserIds.toList();
    })
        .where((ids) => ids.isNotEmpty)
        .asyncExpand((ids) => PresenceRepository.getMultipleUsersPresence(ids))
        .listen((status) {
      _onlineStatus = status;
      notifyListeners();
    });
  }

  Future<String> createOrGetConversation(List<String> participants) async {
    _isLoading = true;
    notifyListeners();

    try {
      final conversationId = await MessageRepository.createConversation(participants);
      _currentConversationId = conversationId;
      _error = null;
      return conversationId;
    } catch (e) {
      _error = e.toString();
      return '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadMessages(String conversationId) {
    _currentConversationId = conversationId;
    _messagesSubscription?.cancel();
    _messagesSubscription = MessageRepository
        .getMessages(conversationId)
        .listen((messages) {
      _currentMessages = messages;
      notifyListeners();
    });

    _typingSubscription?.cancel();
    _typingSubscription = MessageRepository
        .getTypingStatus(conversationId)
        .listen((typing) {
      _typingUsers = typing;
      notifyListeners();
    });
  }

  Future<void> sendMessage({
    required String senderId,
    required MessageType type,
    String? text,
    List<String>? mediaUrls,
    String? replyToId,
  }) async {
    if (_currentConversationId == null) return;

    try {
      await MessageRepository.sendMessage(
        conversationId: _currentConversationId!,
        senderId: senderId,
        type: type,
        text: text,
        mediaUrls: mediaUrls,
        replyToId: replyToId,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markMessagesAsRead(String userId) async {
    if (_currentConversationId == null) return;

    try {
      await MessageRepository.markAsRead(_currentConversationId!, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> setTypingStatus(String userId, bool isTyping) async {
    if (_currentConversationId == null) return;

    try {
      await MessageRepository.setTypingStatus(
        _currentConversationId!,
        userId,
        isTyping,
      );
    } catch (e) {
      // Typing status hataları sessizce handle edilir
    }
  }

  Future<void> updateGroupInfo(String conversationId, String groupName, String adminId) async {
    await FirebaseService.firestore
        .collection(FirebaseService.conversationsCollection)
        .doc(conversationId)
        .update({
      'groupName': groupName,
      'adminId': adminId,
    });
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _presenceSubscription?.cancel();
    super.dispose();
  }
}