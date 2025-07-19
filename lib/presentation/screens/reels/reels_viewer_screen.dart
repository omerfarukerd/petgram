import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:pet_gram/data/models/post_model.dart';
import 'package:pet_gram/data/models/user_model.dart';
import 'package:pet_gram/data/repositories/user_repository.dart';

class ReelsViewerScreen extends StatefulWidget {
  final List<PostModel> initialReels;
  final int initialIndex;

  const ReelsViewerScreen({
    super.key,
    required this.initialReels,
    this.initialIndex = 0,
  });

  @override
  State<ReelsViewerScreen> createState() => _ReelsViewerScreenState();
}

class _ReelsViewerScreenState extends State<ReelsViewerScreen> {
  late PageController _pageController;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.initialReels.length,
        itemBuilder: (context, index) {
          final reel = widget.initialReels[index];
          return ReelVideoPlayer(reel: reel);
        },
      ),
    );
  }
}

class ReelVideoPlayer extends StatefulWidget {
  final PostModel reel;

  const ReelVideoPlayer({super.key, required this.reel});

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  late VideoPlayerController _videoController;
  Future<UserModel?>? _userFuture;
  bool _isPlaying = true;
  String? _thumbnailUrl;


  @override
  void initState() {
    super.initState();
    _userFuture = UserRepository.getUser(widget.reel.userId);
     _thumbnailUrl = widget.reel.mediaItems.first.thumbnailUrl;
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.reel.mediaItems.first.url),
    )..initialize().then((_) {
        _videoController.play();
        _videoController.setLooping(true);
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }
  
  void _togglePlayPause() {
    setState(() {
      if (_videoController.value.isPlaying) {
        _videoController.pause();
        _isPlaying = false;
      } else {
        _videoController.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoController.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            )
          else if (_thumbnailUrl != null)
  Image.network(
    _thumbnailUrl!,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    },
  )
else
  const Center(child: CircularProgressIndicator(color: Colors.white)),
            
          if (!_isPlaying)
            const Center(
              child: Icon(
                Icons.play_arrow,
                color: Colors.white70,
                size: 80,
              ),
            ),
            
          // YENİ: Arayüz Katmanı
          _buildOverlay(),
        ],
      ),
    );
  }

  // YENİ: Tüm arayüz elemanlarını içeren Widget
  Widget _buildOverlay() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Sol taraf: Kullanıcı bilgileri ve açıklama
              Expanded(
                child: _buildReelInfo(),
              ),
              // Sağ taraf: Eylem butonları
              _buildActionButtons(),
            ],
          ),
        ],
      ),
    );
  }

  // YENİ: Sol taraftaki bilgi alanı
  Widget _buildReelInfo() {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: user?.profileImageUrl != null
                    ? NetworkImage(user!.profileImageUrl!)
                    : null,
                  child: user?.profileImageUrl == null
                    ? Text(user?.username[0].toUpperCase() ?? '?')
                    : null,
                ),
                const SizedBox(width: 8),
                Text(
                  user?.username ?? 'kullanıcı',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [Shadow(blurRadius: 2)],
                  ),
                ),
              ],
            ),
            if (widget.reel.caption != null && widget.reel.caption!.isNotEmpty)
              const SizedBox(height: 8),
            if (widget.reel.caption != null && widget.reel.caption!.isNotEmpty)
              Text(
                widget.reel.caption!,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 2)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        );
      }
    );
  }

  // YENİ: Sağ taraftaki eylem butonları
  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(icon: Icons.favorite, text: widget.reel.likes.length.toString(), onPressed: () {}),
        const SizedBox(height: 16),
        _buildActionButton(icon: Icons.comment, text: widget.reel.commentCount.toString(), onPressed: () {}),
        const SizedBox(height: 16),
        _buildActionButton(icon: Icons.send, onPressed: () {}),
        const SizedBox(height: 16),
        _buildActionButton(icon: Icons.more_vert, onPressed: () {}),
      ],
    );
  }

  // YENİ: Eylem butonu oluşturan yardımcı widget
  Widget _buildActionButton({required IconData icon, String? text, required VoidCallback onPressed}) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 30),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
        ),
        if (text != null)
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
      ],
    );
  }
}