import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final List<File> _mediaFiles = [];
  final List<bool> _isVideoList = [];
  final List<VideoPlayerController> _videoControllers = [];
  bool _isAdoption = false;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  Future<void> _pickMedia() async {
    if (_mediaFiles.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En fazla 10 medya ekleyebilirsiniz')),
      );
      return;
    }

    final picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeriden Seç (Çoklu)'),
            onTap: () async {
              Navigator.pop(context);
              final pickedFiles = await picker.pickMultiImage();
              if (pickedFiles.isNotEmpty) {
                for (var file in pickedFiles) {
                  if (_mediaFiles.length < 10) {
                    setState(() {
                      _mediaFiles.add(File(file.path));
                      _isVideoList.add(false);
                    });
                  }
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Video Seç'),
            onTap: () async {
              Navigator.pop(context);
              final pickedFile = await picker.pickVideo(
                source: ImageSource.gallery,
                maxDuration: const Duration(seconds: 60),
              );
              if (pickedFile != null && _mediaFiles.length < 10) {
                setState(() {
                  _mediaFiles.add(File(pickedFile.path));
                  _isVideoList.add(true);
                });
                _initializeVideo(_mediaFiles.length - 1);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Kamera'),
            onTap: () async {
              Navigator.pop(context);
              final pickedFile = await picker.pickImage(source: ImageSource.camera);
              if (pickedFile != null && _mediaFiles.length < 10) {
                setState(() {
                  _mediaFiles.add(File(pickedFile.path));
                  _isVideoList.add(false);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  void _initializeVideo(int index) {
    final controller = VideoPlayerController.file(_mediaFiles[index]);
    controller.initialize().then((_) {
      setState(() {});
      controller.setLooping(true);
      if (index == _currentIndex) {
        controller.play();
      }
    });
    _videoControllers.add(controller);
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
      _isVideoList.removeAt(index);
      if (index < _videoControllers.length) {
        _videoControllers[index].dispose();
        _videoControllers.removeAt(index);
      }
      if (_currentIndex >= _mediaFiles.length && _mediaFiles.isNotEmpty) {
        _currentIndex = _mediaFiles.length - 1;
      }
    });
  }

  Future<void> _createPost() async {
    if (_mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir medya seçin')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    await postProvider.createPost(
      userId: authProvider.currentUser?.uid ?? 'test-user',
      mediaFiles: _mediaFiles,
      isVideoList: _isVideoList,
      caption: _captionController.text.trim(),
      isAdoption: _isAdoption,
    );

    if (postProvider.error == null) {
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(postProvider.error!)),
        );
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    for (var controller in _videoControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Gönderi'),
        actions: [
          TextButton(
            onPressed: postProvider.isLoading ? null : _createPost,
            child: postProvider.isLoading
                ? const CircularProgressIndicator()
                : const Text('Paylaş'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Media carousel
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _mediaFiles.isEmpty
                  ? GestureDetector(
                      onTap: _pickMedia,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 60),
                          Text('Fotoğraf veya Video Seç'),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() => _currentIndex = index);
                            // Video kontrolü
                            for (int i = 0; i < _videoControllers.length; i++) {
                              if (i == index) {
                                _videoControllers[i].play();
                              } else {
                                _videoControllers[i].pause();
                              }
                            }
                          },
                          itemCount: _mediaFiles.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                _isVideoList[index]
                                    ? index < _videoControllers.length &&
                                            _videoControllers[index].value.isInitialized
                                        ? FittedBox(
                                            fit: BoxFit.cover,
                                            child: SizedBox(
                                              width: _videoControllers[index].value.size.width,
                                              height: _videoControllers[index].value.size.height,
                                              child: VideoPlayer(_videoControllers[index]),
                                            ),
                                          )
                                        : const Center(child: CircularProgressIndicator())
                                    : Image.file(_mediaFiles[index], fit: BoxFit.cover),
                                // Silme butonu
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    radius: 16,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                      onPressed: () => _removeMedia(index),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        // Sayfa göstergeleri
                        if (_mediaFiles.length > 1)
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _mediaFiles.length,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentIndex == index
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Medya ekleme butonu
                        if (_mediaFiles.length < 10)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.add, color: Colors.white),
                                onPressed: _pickMedia,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            if (_mediaFiles.isNotEmpty)
              Text(
                '${_mediaFiles.length}/10',
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                hintText: 'Açıklama yazın...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Sahiplendirme İlanı'),
              value: _isAdoption,
              onChanged: (value) => setState(() => _isAdoption = value),
            ),
          ],
        ),
      ),
    );
  }
}