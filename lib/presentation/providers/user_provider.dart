import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _selectedUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<UserModel?> getUserStream(String userId) {
    return UserRepository.getUserStream(userId);
  }

  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      await UserRepository.followUser(currentUserId, targetUserId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      await UserRepository.unfollowUser(currentUserId, targetUserId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? username,
    String? bio,
    File? profileImage,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? profileImageUrl;
      
      if (profileImage != null) {
        profileImageUrl = await StorageService.uploadImage(profileImage, 'profiles');
      }
      
      await UserRepository.updateProfile(
        userId: userId,
        username: username,
        bio: bio,
        profileImageUrl: profileImageUrl,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Stream<List<UserModel>> searchUsers(String query) {
    return UserRepository.searchUsers(query);
  }
}