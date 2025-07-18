import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../data/repositories/reel_repository.dart';
import '../../../data/repositories/music_repository.dart';
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
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  bool _allowDuet = true;
  bool _allowRemix = true;
  
  List<MusicModel> _trendingMusic = [];
  List<MusicModel> _searchResults = [];
  MusicModel? _selectedMusic;

  @override
  void initState() {
    super.initState();
    _loadTrendingMusic();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickVideo();
    });
  }
  
  void _recordOriginalSound() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ses kayıt özelliği için record paketini ekleyin'),
      ),
    );
    // record: ^5.0.4 paketini pubspec.yaml'a ekleyin
    // Ses kayıt implementasyonu için RecordScreen oluşturun
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
      // Başlangıç müzikleri yoksa seed et
      await MusicRepository.seedInitialMusic();
      _loadTrendingMusic();
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

  @override
  void dispose() {
    _captionController.dispose();
    _searchController.dispose();
    _videoController?.dispose();
    super.dispose();
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
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Colors.blue)
                                : Text(
                                    '${music.useCount}',
                                    style: TextStyle(color: Colors.grey[600]),
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
                    ListTile(
                      leading: const Icon(Icons.mic, color: Colors.red),
                      title: const Text('Sesimi Kaydet'),
                      onTap: () {
                        Navigator.pop(context);
                        _recordOriginalSound();
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

      await ReelRepository.createReel(
        userId: userId,
        videoFile: _videoFile!,
        caption: _captionController.text.trim().isEmpty 
            ? null 
            : _captionController.text.trim(),
        audioId: _selectedMusic?.id,
        audioName: _selectedMusic?.name,
        artistName: _selectedMusic?.artist,
        allowDuet: _allowDuet,
        allowRemix: _allowRemix,
      );
      
      // Müzik kullanım sayısını artır
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
                // Video preview
                if (_videoController != null && _videoController!.value.isInitialized)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                
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
                          // Müzik seçimi
                          GestureDetector(
                            onTap: _showMusicPicker,
                            child: Container(
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
                                    _selectedMusic != null
                                        ? _selectedMusic!.artist.isNotEmpty
                                            ? '${_selectedMusic!.name} - ${_selectedMusic!.artist}'
                                            : _selectedMusic!.name
                                        : 'Müzik Seç',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
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
}