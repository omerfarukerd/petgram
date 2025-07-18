import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _notificationsSubscription;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void getUserNotifications(String userId) {
    _isLoading = true;
    notifyListeners();
    
    _notificationsSubscription?.cancel();
    _notificationsSubscription = NotificationRepository.getUserNotifications(userId).listen((notifications) {
      _notifications = notifications;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await NotificationRepository.markAsRead(notificationId);
      // Yerel state'i de güncelleyerek anında yansıma sağla
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          type: _notifications[index].type,
          fromUserId: _notifications[index].fromUserId,
          postId: _notifications[index].postId,
          postImageUrl: _notifications[index].postImageUrl,
          commentText: _notifications[index].commentText,
          isRead: true, // Okundu olarak işaretle
          timestamp: _notifications[index].timestamp,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> markAllAsRead(String userId) async {
    try {
      await NotificationRepository.markAllAsRead(userId);
      // Yerel state'i de güncelle
      for (var i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
           _notifications[i] = NotificationModel(
            id: _notifications[i].id,
            userId: _notifications[i].userId,
            type: _notifications[i].type,
            fromUserId: _notifications[i].fromUserId,
            postId: _notifications[i].postId,
            postImageUrl: _notifications[i].postImageUrl,
            commentText: _notifications[i].commentText,
            isRead: true, // Okundu olarak işaretle
            timestamp: _notifications[i].timestamp,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}