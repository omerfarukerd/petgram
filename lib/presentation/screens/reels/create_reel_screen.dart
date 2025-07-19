import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/repositories/reel_repository.dart';
import '../../../data/repositories/music_repository.dart';
import '../../../data/services/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../music/user_music_upload_screen.dart';

class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({super.key});

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  final _captionController = TextEditingController();
  final _searchController = TextEditingController();
  File? _videoFile;
  File? _thumbnailFile;
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isLoading = false;
  bool _allowDuet = true;
  bool _allowRemix = true;
  
  List<MusicModel> _trendingMusic = [];
  List<MusicModel> _searchResults = [];
  MusicModel? _selectedMusic;
  
  // Edit özellikleri
  double _playbackSpeed = 1.0;
  String _selectedFilter = 'none';
  double _startTrim = 0.0;
  double _endTrim = 1.0;
  
  // Zoom/Pan özellikleri
  double _scale = 1.0;
  Offset _position = Offset.zero;
  Offset _basePosition = Offset.zero;
  double _baseScale = 1.0;
  
  List<TextOverlay> _textOverlays = [];

  @override
  void initState() {
    super.initState();
    _loadTrendingMusic();
    _audioPlayer = AudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickVideo();
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    _searchController.dispose();
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingMusic() async {
    try {
      final music = await MusicRepository.getTrendingMusic();
      setState(() {
        _trendingMusic = music;
        if (music.isNotEmpty) {
          _selectedMusic = music.firstWhere(
            (m) => m.id == 'original',
            orElse: () => music.first,
          );
        }
      });
    } catch (e) {
      await MusicRepository.seedInitialMusic();
      _loadTrendingMusic();
    }
  }

  Future<void> _playMusic(MusicModel music) async {
    if (music.audioUrl == null) return;
    
    try {
      await _audioPlayer?.stop();
      await _audioPlayer?.setUrl(music.audioUrl!);
      await _audioPlayer?.setLoopMode(LoopMode.one);
      await _audioPlayer?.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Müzik çalınamadı: $e')),
      );
    }
  }

  Future<void> _searchMusic(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    final results = await MusicRepository.searchMusic(query);
    setState(() => _searchResults = results);
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (source == null && mounted) {
      Navigator.pop(context);
      return;
    }

    final pickedFile = await picker.pickVideo(
      source: source!,
      maxDuration: const Duration(seconds: 60),
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
      _initializeVideo();
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  void _initializeVideo() {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(_videoFile!)
      ..initialize().then((_) {
        setState(() {});
        _videoController!.play();
        _videoController!.setLooping(true);
      });
  }

  Future<String?> _processVideo() async {
    if (_videoFile == null || _videoController == null) return null;
    
    // Zoom/Pan veya Trim uygulanmamışsa orijinal dosyayı döndür
    if (_scale == 1.0 && _position == Offset.zero && 
        _startTrim == 0.0 && _endTrim == 1.0) {
      return _videoFile!.path;
    }

    setState(() => _isLoading = true);
    
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      final videoSize = _videoController!.value.size;
      final duration = _videoController!.value.duration;
      
      // FFmpeg komutunu oluştur
      String ffmpegCommand = '-i "${_videoFile!.path}"';
      
      // Trim
      if (_startTrim > 0.0 || _endTrim < 1.0) {
        final startTime = duration.inSeconds * _startTrim;
        final endTime = duration.inSeconds * _endTrim;
        ffmpegCommand += ' -ss $startTime -to $endTime';
      }
      
      // Crop (zoom/pan için)
      if (_scale > 1.0 || _position != Offset.zero) {
        final cropWidth = videoSize.width / _scale;
        final cropHeight = videoSize.height / _scale;
        final cropX = (videoSize.width - cropWidth) / 2 - (_position.dx * 2);
        final cropY = (videoSize.height - cropHeight) / 2 - (_position.dy * 2);
        
        ffmpegCommand += ' -vf "crop=$cropWidth:$cropHeight:$cropX:$cropY"';
      }
      
      // Output ayarları
      ffmpegCommand += ' -c:v libx264 -preset fast -crf 22 -c:a copy "$outputPath"';
      
      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        throw Exception('Video işleme başarısız');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video işleme hatası: $e')),
      );
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditTools() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Düzenleme Araçları', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  // Zoom/Pan Reset
                  if (_scale > 1.0 || _position != Offset.zero)
                    ListTile(
                      leading: const Icon(Icons.crop_free),
                      title: const Text('Zoom/Pan Sıfırla'),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() {
                            _scale = 1.0;
                            _position = Offset.zero;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  
                  // Hız ayarı
                  ListTile(
                    leading: const Icon(Icons.speed),
                    title: const Text('Oynatma Hızı'),
                    subtitle: Slider(
                      value: _playbackSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 6,
                      label: '${_playbackSpeed}x',
                      onChanged: (value) {
                        setState(() {
                          _playbackSpeed = value;
                          _videoController?.setPlaybackSpeed(value);
                        });
                      },
                    ),
                  ),
                  const Divider(),
                  
                  // Filtreler
                  const Text('Filtreler', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterOption('none', 'Normal'),
                        _buildFilterOption('gray', 'Siyah Beyaz'),
                        _buildFilterOption('sepia', 'Sepya'),
                        _buildFilterOption('vintage', 'Vintage'),
                        _buildFilterOption('bright', 'Parlak'),
                      ],
                    ),
                  ),
                  const Divider(),
                  
                  // Kırpma
                  ListTile(
                    leading: const Icon(Icons.content_cut),
                    title: const Text('Video Kırp'),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: RangeSlider(
                            values: RangeValues(_startTrim, _endTrim),
                            onChanged: (values) {
                              setState(() {
                                _startTrim = values.start;
                                _endTrim = values.end;
                              });
                            },
                          ),
                        ),
                        Text('${(_endTrim - _startTrim) * 60 ~/ 1}s'),
                      ],
                    ),
                  ),
                  const Divider(),
                  
                  // Metin ekle
                  ListTile(
                    leading: const Icon(Icons.text_fields),
                    title: const Text('Metin Ekle'),
                    trailing: const Icon(Icons.add),
                    onTap: _addTextOverlay,
                  ),
                  
                  // Sticker ekle
                  ListTile(
                    leading: const Icon(Icons.emoji_emotions),
                    title: const Text('Sticker Ekle'),
                    trailing: const Icon(Icons.add),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sticker özelliği yakında')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filter);
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTextOverlay() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        return AlertDialog(
          title: const Text('Metin Ekle'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Metninizi yazın...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  setState(() {
                    _textOverlays.add(TextOverlay(
                      text: textController.text,
                      position: const Offset(0.5, 0.5),
                    ));
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectThumbnail() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Kapak Seç', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeriden'),
                      onPressed: () async {
                        Navigator.pop(context);
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setState(() {
                            _thumbnailFile = File(picked.path);
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.videocam),
                      label: const Text('Videodan'),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mevcut kare thumbnail olarak ayarlandı')),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMusicPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              const Text(
                'Müzik Seç',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Müzik ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: _searchMusic,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _searchResults.isNotEmpty
                            ? _searchResults.length
                            : _trendingMusic.length,
                        itemBuilder: (context, index) {
                          final music = _searchResults.isNotEmpty
                              ? _searchResults[index]
                              : _trendingMusic[index];
                          final isSelected = _selectedMusic?.id == music.id;
                          
                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: music.coverUrl != null
                                  ? Image.network(music.coverUrl!, fit: BoxFit.cover)
                                  : const Icon(Icons.music_note),
                            ),
                            title: Text(music.name),
                            subtitle: music.artist.isNotEmpty
                                ? Text(music.artist)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _audioPlayer?.playing == true && _selectedMusic?.id == music.id
                                        ? Icons.pause_circle
                                        : Icons.play_circle,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () async {
                                    if (_audioPlayer?.playing == true && _selectedMusic?.id == music.id) {
                                      await _audioPlayer?.pause();
                                    } else {
                                      setState(() => _selectedMusic = music);
                                      await _playMusic(music);
                                    }
                                  },
                                ),
                                if (isSelected)
                                  const Icon(Icons.check, color: Colors.green),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _selectedMusic = music;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
                      title: const Text('Yeni Müzik Ekle'),
                      onTap: () async {
                        Navigator.pop(context);
                        final newMusic = await Navigator.push<MusicModel>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserMusicUploadScreen(),
                          ),
                        );
                        if (newMusic != null) {
                          setState(() {
                            _selectedMusic = newMusic;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createReel() async {
    if (_videoFile == null) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid ?? 'test-user';

      // Video processing
      final processedVideoPath = await _processVideo();
      final videoToUpload = processedVideoPath != null 
          ? File(processedVideoPath) 
          : _videoFile!;

      // Thumbnail upload
      String? thumbnailUrl;
      if (_thumbnailFile != null) {
        thumbnailUrl = await StorageService.uploadImage(_thumbnailFile!, 'reel_thumbnails');
      }

      await ReelRepository.createReel(
        userId: userId,
        videoFile: videoToUpload,
        caption: _captionController.text.trim().isEmpty 
            ? null 
            : _captionController.text.trim(),
        audioId: _selectedMusic?.id,
        audioName: _selectedMusic?.name,
        artistName: _selectedMusic?.artist,
        allowDuet: _allowDuet,
        allowRemix: _allowRemix,
        thumbnailUrl: thumbnailUrl,
      );
      
      // Geçici dosyayı temizle
      if (processedVideoPath != null && processedVideoPath != _videoFile!.path) {
        try {
          await File(processedVideoPath).delete();
        } catch (_) {}
      }
      
      if (_selectedMusic != null && _selectedMusic!.id != 'original') {
        await MusicRepository.incrementUseCount(_selectedMusic!.id);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reel paylaşıldı!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reel Oluştur'),
        actions: [
          TextButton(
            onPressed: _isLoading || _videoFile == null ? null : _createReel,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Paylaş',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: _videoFile == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                // Video preview with zoom/pan
                if (_videoController != null && _videoController!.value.isInitialized)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onScaleStart: (details) {
                          _baseScale = _scale;
                          _basePosition = _position;
                        },
                        onScaleUpdate: (details) {
                          setState(() {
                            // Zoom
                            _scale = (_baseScale * details.scale).clamp(1.0, 3.0);
                            
                            // Pan
                            if (_scale > 1.0) {
                              final delta = details.focalPointDelta;
                              _position = _basePosition + delta;
                              
                              // Sınırları hesapla
                              final maxX = (constraints.maxWidth * (_scale - 1)) / (2 * _scale);
                              final maxY = (constraints.maxHeight * (_scale - 1)) / (2 * _scale);
                              
                              _position = Offset(
                                _position.dx.clamp(-maxX, maxX),
                                _position.dy.clamp(-maxY, maxY),
                              );
                            } else {
                              _position = Offset.zero;
                            }
                          });
                        },
                        onDoubleTap: () {
                          setState(() {
                            if (_scale > 1.0) {
                              _scale = 1.0;
                              _position = Offset.zero;
                            } else {
                              _scale = 2.0;
                            }
                          });
                        },
                        child: Container(
                          color: Colors.black,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRect(
                                child: Transform(
                                  transform: Matrix4.identity()
                                    ..translate(_position.dx, _position.dy)
                                    ..scale(_scale),
                                  alignment: Alignment.center,
                                  child: ColorFiltered(
                                    colorFilter: _getColorFilter(_selectedFilter),
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: _videoController!.value.size.width,
                                        height: _videoController!.value.size.height,
                                        child: VideoPlayer(_videoController!),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Zoom indicator
                              if (_scale > 1.0)
                                Positioned(
                                  top: 50,
                                  right: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_scale.toStringAsFixed(1)}x',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                
                // Text overlays
                ..._textOverlays.map((overlay) => Positioned(
                  left: overlay.position.dx * MediaQuery.of(context).size.width - 50,
                  top: overlay.position.dy * MediaQuery.of(context).size.height - 25,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        final size = MediaQuery.of(context).size;
                        overlay.position = Offset(
                          (overlay.position.dx + details.delta.dx / size.width).clamp(0.0, 1.0),
                          (overlay.position.dy + details.delta.dy / size.height).clamp(0.0, 1.0),
                        );
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _textOverlays.remove(overlay);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        overlay.text,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                )),
                
                // Controls overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Araç çubuğu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.music_note, color: Colors.white),
                                onPressed: _showMusicPicker,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white),
                                onPressed: _showEditTools,
                              ),
                              IconButton(
                                icon: const Icon(Icons.image, color: Colors.white),
                                onPressed: _selectThumbnail,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Müzik seçimi
                          if (_selectedMusic != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.music_note,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedMusic!.artist.isNotEmpty
                                        ? '${_selectedMusic!.name} - ${_selectedMusic!.artist}'
                                        : _selectedMusic!.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          
                          // Açıklama
                          TextField(
                            controller: _captionController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Açıklama ekle...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Duet/Remix ayarları
                          Row(
                            children: [
                              Expanded(
                                child: SwitchListTile(
                                  title: const Text(
                                    'Duet\'e izin ver',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  value: _allowDuet,
                                  onChanged: (value) {
                                    setState(() => _allowDuet = value);
                                  },
                                  activeColor: Colors.blue,
                                ),
                              ),
                              Expanded(
                                child: SwitchListTile(
                                  title: const Text(
                                    'Remix\'e izin ver',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  value: _allowRemix,
                                  onChanged: (value) {
                                    setState(() => _allowRemix = value);
                                  },
                                  activeColor: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  ColorFilter _getColorFilter(String filter) {
    switch (filter) {
      case 'gray':
        return const ColorFilter.mode(Colors.grey, BlendMode.saturation);
      case 'sepia':
        return const ColorFilter.mode(Colors.brown, BlendMode.modulate);
      case 'vintage':
        return const ColorFilter.mode(Colors.amber, BlendMode.modulate);
      case 'bright':
        return const ColorFilter.mode(Colors.white, BlendMode.softLight);
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    }
  }
}

class TextOverlay {
  String text;
  Offset position;

  TextOverlay({required this.text, required this.position});
}