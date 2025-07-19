import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';

class PostProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<PostModel>> getFeedPosts() {
    return PostRepository.getFeedPosts();
  }

  Future<void> createPost({
    required String userId,
    required List<File> mediaFiles,
    required List<bool> isVideoList,
    String? caption,
    bool isAdoption = false,
    List<String?>? thumbnailUrls,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await PostRepository.createPost(
        userId: userId,
        mediaFiles: mediaFiles,
        isVideoList: isVideoList,
        caption: caption,
        isAdoption: isAdoption,
        thumbnailUrls: thumbnailUrls,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleLike(String postId, String userId, bool isLiked) async {
    try {
      if (isLiked) {
        await PostRepository.unlikePost(postId, userId);
      } else {
        await PostRepository.likePost(postId, userId);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}