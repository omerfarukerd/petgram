import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../data/models/post_model.dart';
import '../../screens/post/comments_screen.dart';

class PostItem extends StatefulWidget {
  final PostModel post;
  final bool isLiked;
  final VoidCallback onLike;

  const PostItem({
    super.key,
    required this.post,
    required this.isLiked,
    required this.onLike,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  late PageController _pageController;
  int _currentIndex = 0;
  List<VideoPlayerController?> _videoControllers = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeVideoControllers();
  }

  void _initializeVideoControllers() {
    _videoControllers = List.generate(
      widget.post.mediaItems.length,
      (index) {
        if (widget.post.mediaItems[index].isVideo) {
          final controller = VideoPlayerController.networkUrl(
              Uri.parse(widget.post.mediaItems[index].url));
          controller.initialize().then((_) {
            if (mounted) setState(() {});
            if (index == 0) controller.play();
          });
          controller.setLooping(true);
          return controller;
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _videoControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    
    // Video kontrolü
    for (int i = 0; i < _videoControllers.length; i++) {
      if (_videoControllers[i] != null) {
        if (i == index) {
          _videoControllers[i]!.play();
        } else {
          _videoControllers[i]!.pause();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media carousel
          SizedBox(
            height: 400,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: widget.post.mediaItems.length,
                  itemBuilder: (context, index) {
                    final media = widget.post.mediaItems[index];
                    
                    return GestureDetector(
                      onTap: () {
                        if (media.isVideo && _videoControllers[index] != null) {
                          setState(() {
                            final controller = _videoControllers[index]!;
                            controller.value.isPlaying 
                                ? controller.pause() 
                                : controller.play();
                          });
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: [
                          if (media.isVideo)
                            _videoControllers[index] != null && 
                            _videoControllers[index]!.value.isInitialized
                                ? FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _videoControllers[index]!.value.size.width,
                                      height: _videoControllers[index]!.value.size.height,
                                      child: VideoPlayer(_videoControllers[index]!),
                                    ),
                                  )
                                : Container(
                                    color: Colors.black12,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                          else
                            Image.network(
                              media.url,
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
                          // Play icon for paused videos
                          if (media.isVideo && 
                              _videoControllers[index] != null &&
                              _videoControllers[index]!.value.isInitialized &&
                              !_videoControllers[index]!.value.isPlaying)
                            const Icon(
                              Icons.play_circle_outline,
                              size: 64,
                              color: Colors.white,
                            ),
                        ],
                      ),
                    );
                  },
                ),
                // Sayaç
                if (widget.post.mediaItems.length > 1)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentIndex + 1}/${widget.post.mediaItems.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                // Nokta göstergeleri
                if (widget.post.mediaItems.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.post.mediaItems.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentIndex == index
                                ? Colors.blue
                                : Colors.grey.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Interaction buttons
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        widget.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: widget.isLiked ? Colors.red : null,
                      ),
                      onPressed: widget.onLike,
                    ),
                    Text('${widget.post.likes.length} beğeni'),
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentsScreen(postId: widget.post.id),
                          ),
                        );
                      },
                    ),
                    Text('${widget.post.commentCount} yorum'),
                    const Spacer(),
                    if (widget.post.isAdoption)
                      const Chip(label: Text('Sahiplenme')),
                  ],
                ),
                if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(widget.post.caption!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}