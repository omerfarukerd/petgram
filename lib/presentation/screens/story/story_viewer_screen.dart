import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/message_model.dart'; // YENİ İMPORT
import '../../../data/repositories/story_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../message/forward_message_screen.dart'; // YENİ İMPORT

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  Timer? _timer;
  
  int _currentStoryIndex = 0;
  int _currentItemIndex = 0;
  VideoPlayerController? _videoController;
  bool _isPaused = false;
  
  // User info cache
  final Map<String, UserModel> _userCache = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    
    _currentStoryIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentStoryIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    _loadStory();
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _timer?.cancel();
    _progressController.dispose();
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadStory() {
    if (_currentStoryIndex >= widget.stories.length) {
      Navigator.of(context).pop();
      return;
    }

    final story = widget.stories[_currentStoryIndex];
    final item = story.items[_currentItemIndex];
    
    // Mark as viewed
    final currentUserId = Provider.of<AuthProvider>(context, listen: false)
        .currentUser?.uid ?? '';
    StoryRepository.viewStory(story.userId, currentUserId);
    
    // Load user info
    _loadUserInfo(story.userId);
    
    // Setup media
    if (item.isVideo) {
      _setupVideo(item.mediaUrl);
    } else {
      _startTimer(item.duration);
    }
  }

  void _setupVideo(String videoUrl) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _videoController!.play();
        _startTimer(_videoController!.value.duration.inSeconds);
      });
  }

  void _startTimer(int duration) {
    _timer?.cancel();
    _progressController.duration = Duration(seconds: duration);
    _progressController.forward(from: 0);
    
    _timer = Timer(Duration(seconds: duration), _nextItem);
  }

  void _nextItem() {
    final story = widget.stories[_currentStoryIndex];
    
    if (_currentItemIndex < story.items.length - 1) {
      setState(() {
        _currentItemIndex++;
      });
      _loadStory();
    } else {
      _nextStory();
    }
  }

  void _previousItem() {
    if (_currentItemIndex > 0) {
      setState(() {
        _currentItemIndex--;
      });
      _loadStory();
    } else {
      _previousStory();
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < widget.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
        _currentItemIndex = 0;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadStory();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
        _currentItemIndex = 0;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadStory();
    }
  }

  void _pauseStory() {
    setState(() {
      _isPaused = true;
    });
    _timer?.cancel();
    _progressController.stop();
    _videoController?.pause();
  }

  void _resumeStory() {
    setState(() {
      _isPaused = false;
    });
    _progressController.forward();
    _videoController?.play();
    
    final remaining = _progressController.duration!.inMilliseconds -
        (_progressController.value * _progressController.duration!.inMilliseconds);
    _timer = Timer(Duration(milliseconds: remaining.toInt()), _nextItem);
  }

  Future<void> _loadUserInfo(String userId) async {
    if (!_userCache.containsKey(userId)) {
      final user = await UserRepository.getUser(userId);
      if (user != null && mounted) {
        setState(() {
          _userCache[userId] = user;
        });
      }
    }
  }

  // YENİ: Hikayeyi paylaşma fonksiyonu
  void _shareStory(BuildContext context) {
    final story = widget.stories[_currentStoryIndex];
    final storyItem = story.items[_currentItemIndex];
    final user = _userCache[story.userId];

    final messageToShare = MessageModel(
      id: '',
      conversationId: '',
      senderId: '',
      type: MessageType.storyReply, // Story paylaşımı bir nevi story yanıtıdır.
      timestamp: DateTime.now(),
      sharedContentId: story.id, 
      sharedContentImageUrl: storyItem.mediaUrl,
      sharedContentText: "${user?.username ?? 'Birinin'}'in hikayesine göz at",
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForwardMessageScreen(messageToForward: messageToShare),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return const SizedBox();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < width * 0.3) {
            _previousItem();
          } else {
             _nextItem();
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          children: [
            // Story content
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              itemBuilder: (context, storyIndex) {
                if (storyIndex != _currentStoryIndex) {
                  return const SizedBox();
                }
                
                final story = widget.stories[storyIndex];
                final item = story.items[_currentItemIndex];
                
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Media
                    if (item.isVideo && _videoController != null)
                      _videoController!.value.isInitialized
                          ? FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _videoController!.value.size.width,
                                height: _videoController!.value.size.height,
                                child: VideoPlayer(_videoController!),
                              ),
                            )
                          : const Center(child: CircularProgressIndicator())
                    else
                      Image.network(
                        item.mediaUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                          stops: const [0.0, 0.2, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            // Top bar
            SafeArea(
              child: Column(
                children: [
                  // Progress bars
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: List.generate(
                        widget.stories[_currentStoryIndex].items.length,
                        (index) => Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: LinearProgressIndicator(
                              value: index < _currentItemIndex
                                  ? 1.0
                                  : index == _currentItemIndex
                                      ? _progressController.value
                                      : 0.0,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // User info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: _userCache[widget.stories[_currentStoryIndex].userId]
                                      ?.profileImageUrl !=
                                  null
                              ? NetworkImage(
                                  _userCache[widget.stories[_currentStoryIndex].userId]!
                                      .profileImageUrl!)
                              : null,
                          child: _userCache[widget.stories[_currentStoryIndex].userId]
                                      ?.profileImageUrl ==
                                  null
                              ? Text(
                                  _userCache[widget.stories[_currentStoryIndex].userId]
                                          ?.username[0]
                                          .toUpperCase() ??
                                      '?',
                                  style: const TextStyle(fontSize: 14),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userCache[widget.stories[_currentStoryIndex].userId]
                                        ?.username ??
                                    'Yükleniyor...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getTimeAgo(widget.stories[_currentStoryIndex].createdAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Caption
            if (widget.stories[_currentStoryIndex].items[_currentItemIndex].caption != null)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: Text(
                  widget.stories[_currentStoryIndex].items[_currentItemIndex].caption!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Bottom actions
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white70),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Mesaj gönder...',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onSubmitted: (text) {
                              // DM gönder
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white),
                        onPressed: () {
                          // Story'yi beğen
                        },
                      ),
                      // GÜNCELLENDİ: Paylaş Butonu
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () => _shareStory(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Pause indicator
            if (_isPaused)
              const Center(
                child: Icon(
                  Icons.pause,
                  color: Colors.white,
                  size: 80,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    
    if (difference.inHours < 1) {
      return '${difference.inMinutes}d önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s önce';
    } else {
      return '${difference.inDays}g önce';
    }
  }
}