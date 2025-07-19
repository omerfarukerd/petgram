import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/story_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _captionController = TextEditingController();
  final _searchController = TextEditingController();
  File? _mediaFile;
  bool _isVideo = false;
  bool _isLoading = false;
  VideoPlayerController? _videoController;
  
  // Story editing
  final List<StoryOverlay> _overlays = [];
  Color _textColor = Colors.white;
  double _textSize = 24;
  String _fontFamily = 'Default';
  
  // Drawing
  bool _isDrawing = false;
  List<DrawingPoints?> _drawingPoints = [];
  Color _drawColor = Colors.white;
  double _strokeWidth = 3.0;
  
  // Location
  String? _currentLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickMedia();
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    _searchController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    if (!mounted) return;
    
    final picker = ImagePicker();
    
    final choice = await showModalBottomSheet<String>(
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
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera (Fotoğraf)'),
              onTap: () => Navigator.pop(context, 'camera_photo'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Kamera (Video)'),
              onTap: () => Navigator.pop(context, 'camera_video'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (choice == null && mounted) {
      Navigator.pop(context);
      return;
    }

    XFile? pickedFile;
    
    switch (choice) {
      case 'camera_photo':
        pickedFile = await picker.pickImage(source: ImageSource.camera);
        _isVideo = false;
        break;
      case 'camera_video':
        pickedFile = await picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(seconds: 30),
        );
        _isVideo = true;
        break;
      case 'gallery':
        final mediaChoice = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Medya Türü'),
            content: const Text('Fotoğraf mı video mu seçmek istersiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Fotoğraf'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Video'),
              ),
            ],
          ),
        );
        
        if (mediaChoice == null) break;
        
        if (mediaChoice) {
          pickedFile = await picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(seconds: 30),
          );
          _isVideo = true;
        } else {
          pickedFile = await picker.pickImage(source: ImageSource.gallery);
          _isVideo = false;
        }
        break;
    }

    if (pickedFile != null && mounted) {
      setState(() {
        _mediaFile = File(pickedFile!.path);
      });
      
      if (_isVideo) {
        _initializeVideo();
      }
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  void _initializeVideo() {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(_mediaFile!)
      ..initialize().then((_) {
        setState(() {});
        _videoController!.play();
        _videoController!.setLooping(true);
      });
  }

  void _addText() {
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        Color selectedColor = _textColor;
        String selectedFont = _fontFamily;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: const Text('Metin Ekle', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    style: TextStyle(
                      color: selectedColor,
                      fontFamily: selectedFont == 'Default' ? null : selectedFont,
                    ),
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Metninizi yazın...',
                      hintStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Color picker
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _textColors.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = _textColors[index];
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: _textColors[index],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == _textColors[index]
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Font picker
                  DropdownButton<String>(
                    value: selectedFont,
                    dropdownColor: Colors.black87,
                    style: const TextStyle(color: Colors.white),
                    items: _fontFamilies.map((font) {
                      return DropdownMenuItem(
                        value: font,
                        child: Text(font),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedFont = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () {
                    if (textController.text.isNotEmpty) {
                      setState(() {
                        _overlays.add(StoryOverlay(
                          type: OverlayType.text,
                          text: textController.text,
                          position: const Offset(0.5, 0.5),
                          color: selectedColor,
                          size: _textSize,
                          fontFamily: selectedFont,
                        ));
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Ekle', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addSticker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DefaultTabController(
          length: 4,
          child: Column(
            children: [
              const TabBar(
                labelColor: Colors.black,
                tabs: [
                  Tab(text: 'Emoji'),
                  Tab(text: 'Konum'),
                  Tab(text: 'Mention'),
                  Tab(text: 'Müzik'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Emoji tab
                    GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _stickerEmojis.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _overlays.add(StoryOverlay(
                                type: OverlayType.sticker,
                                text: _stickerEmojis[index],
                                position: const Offset(0.5, 0.5),
                                size: 48,
                              ));
                            });
                            Navigator.pop(context);
                          },
                          child: Center(
                            child: Text(
                              _stickerEmojis[index],
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        );
                      },
                    ),
                    // Location tab
                    _buildLocationTab(),
                    // Mention tab
                    _buildMentionTab(),
                    // Music tab
                    _buildMusicTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationTab() {
    return FutureBuilder<Position?>(
      future: _getCurrentLocation(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_currentLocation != null)
              ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(_currentLocation!),
                onTap: () {
                  setState(() {
                    _overlays.add(StoryOverlay(
                      type: OverlayType.location,
                      text: _currentLocation!,
                      position: const Offset(0.5, 0.5),
                      size: 16,
                    ));
                  });
                  Navigator.pop(context);
                },
              ),
            const Divider(),
            // Popüler konumlar
            ..._popularLocations.map((location) => ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(location),
              onTap: () {
                setState(() {
                  _overlays.add(StoryOverlay(
                    type: OverlayType.location,
                    text: location,
                    position: const Offset(0.5, 0.5),
                    size: 16,
                  ));
                });
                Navigator.pop(context);
              },
            )),
          ],
        );
      },
    );
  }

  Widget _buildMentionTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Kullanıcı ara...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: UserRepository.searchUsers(_searchController.text),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final user = snapshot.data![index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.profileImageUrl != null
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      child: user.profileImageUrl == null
                          ? Text(user.username[0].toUpperCase())
                          : null,
                    ),
                    title: Text(user.username),
                    onTap: () {
                      setState(() {
                        _overlays.add(StoryOverlay(
                          type: OverlayType.mention,
                          text: '@${user.username}',
                          position: const Offset(0.5, 0.5),
                          size: 16,
                          data: {'userId': user.uid},
                        ));
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMusicTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _sampleMusic.map((music) => ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.music_note),
        ),
        title: Text(music['title']!),
        subtitle: Text(music['artist']!),
        onTap: () {
          setState(() {
            _overlays.add(StoryOverlay(
              type: OverlayType.music,
              text: '♪ ${music['title']} - ${music['artist']}',
              position: const Offset(0.5, 0.9),
              size: 14,
              data: music,
            ));
          });
          Navigator.pop(context);
        },
      )).toList(),
    );
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested != LocationPermission.whileInUse &&
            requested != LocationPermission.always) {
          return null;
        }
      }
      
      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentLocation = '${place.locality}, ${place.country}';
        });
      }
      
      return position;
    } catch (e) {
      return null;
    }
  }

  void _toggleDrawing() {
    setState(() {
      _isDrawing = !_isDrawing;
    });
  }

  void _showDrawingTools() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Çizim Araçları', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            // Color picker
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _drawColors.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _drawColor = _drawColors[index];
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _drawColors[index],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _drawColor == _drawColors[index]
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Stroke width
            Row(
              children: [
                const Text('Kalınlık:'),
                Expanded(
                  child: Slider(
                    value: _strokeWidth,
                    min: 1,
                    max: 10,
                    onChanged: (value) {
                      setState(() {
                        _strokeWidth = value;
                      });
                    },
                  ),
                ),
                Text(_strokeWidth.toStringAsFixed(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _recordOriginalSound() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ses kayıt özelliği geçici olarak devre dışı'),
        backgroundColor: Colors.orange,
      ),
    );
    // Ses kayıt özelliği record paketi Linux sorunu nedeniyle geçici olarak devre dışı
    // TODO: record paketi güncellendiğinde tekrar etkinleştir
  }

  Future<void> _createStory() async {
    if (_mediaFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid ?? 'test-user';

      // Convert overlays to StorySticker
      final stickers = _overlays.map((overlay) {
        String type = 'text';
        switch (overlay.type) {
          case OverlayType.sticker:
            type = 'emoji';
            break;
          case OverlayType.location:
            type = 'location';
            break;
          case OverlayType.mention:
            type = 'mention';
            break;
          case OverlayType.music:
            type = 'music';
            break;
          default:
            type = 'text';
        }
        
        return StorySticker(
          type: type,
          data: {
            'text': overlay.text,
            'color': overlay.color?.value.toString(),
            'size': overlay.size,
            'fontFamily': overlay.fontFamily,
            ...?overlay.data,
          },
          x: overlay.position.dx,
          y: overlay.position.dy,
          scale: 1.0,
          rotation: 0.0,
        );
      }).toList();

      await StoryRepository.createOrUpdateStory(
        userId: userId,
        mediaFile: _mediaFile!,
        isVideo: _isVideo,
        caption: _captionController.text.trim().isEmpty 
            ? null 
            : _captionController.text.trim(),
        stickers: stickers,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Media preview
          if (_mediaFile != null)
            _isVideo && _videoController != null
                ? _videoController!.value.isInitialized
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator())
                : Image.file(
                    _mediaFile!,
                    fit: BoxFit.cover,
                  ),
          
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),
          
          // Drawing layer
          if (_isDrawing)
            Positioned.fill(
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _drawingPoints.add(DrawingPoints(
                      points: details.localPosition,
                      paint: Paint()
                        ..color = _drawColor
                        ..strokeWidth = _strokeWidth
                        ..strokeCap = StrokeCap.round,
                    ));
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _drawingPoints.add(DrawingPoints(
                      points: details.localPosition,
                      paint: Paint()
                        ..color = _drawColor
                        ..strokeWidth = _strokeWidth
                        ..strokeCap = StrokeCap.round,
                    ));
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _drawingPoints.add(null);
                  });
                },
                child: CustomPaint(
                  painter: DrawingPainter(points: _drawingPoints),
                ),
              ),
            ),
          
          // Overlays (text and stickers)
          if (!_isDrawing)
            ..._overlays.map((overlay) => Positioned(
              left: overlay.position.dx * MediaQuery.of(context).size.width - 50,
              top: overlay.position.dy * MediaQuery.of(context).size.height - 25,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final size = MediaQuery.of(context).size;
                    overlay.position = Offset(
                      (overlay.position.dx + details.delta.dx / size.width)
                          .clamp(0.0, 1.0),
                      (overlay.position.dy + details.delta.dy / size.height)
                          .clamp(0.0, 1.0),
                    );
                  });
                },
                onLongPress: () {
                  setState(() {
                    _overlays.remove(overlay);
                  });
                },
                child: _buildOverlayWidget(overlay),
              ),
            )),
          
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.text_fields, color: Colors.white),
                        onPressed: _isDrawing ? null : _addText,
                      ),
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.white),
                        onPressed: _isDrawing ? null : _addSticker,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.draw,
                          color: _isDrawing ? Colors.orange : Colors.white,
                        ),
                        onPressed: _toggleDrawing,
                      ),
                      if (_isDrawing)
                        IconButton(
                          icon: const Icon(Icons.palette, color: Colors.white),
                          onPressed: _showDrawingTools,
                        ),
                      if (_isDrawing)
                        IconButton(
                          icon: const Icon(Icons.undo, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              if (_drawingPoints.isNotEmpty) {
                                _drawingPoints.removeLast();
                                // Remove until we find null (end of stroke)
                                while (_drawingPoints.isNotEmpty && 
                                       _drawingPoints.last != null) {
                                  _drawingPoints.removeLast();
                                }
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom controls
          if (!_isDrawing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Caption input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _captionController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Açıklama ekle...',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Share button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createStory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Hikayeni Paylaş',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
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

  Widget _buildOverlayWidget(StoryOverlay overlay) {
    switch (overlay.type) {
      case OverlayType.text:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            overlay.text,
            style: TextStyle(
              color: overlay.color,
              fontSize: overlay.size,
              fontWeight: FontWeight.bold,
              fontFamily: overlay.fontFamily == 'Default' ? null : overlay.fontFamily,
            ),
          ),
        );
        
      case OverlayType.sticker:
        return Text(
          overlay.text,
          style: TextStyle(fontSize: overlay.size),
        );
        
      case OverlayType.location:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                overlay.text,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: overlay.size,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
        
      case OverlayType.mention:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.pink],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            overlay.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: overlay.size,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        
      case OverlayType.music:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_note, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                overlay.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: overlay.size,
                ),
              ),
            ],
          ),
        );
    }
  }
}

// Helper classes
enum OverlayType { text, sticker, location, mention, music }

class StoryOverlay {
  final OverlayType type;
  final String text;
  Offset position;
  final Color? color;
  final double size;
  final String? fontFamily;
  final Map<String, dynamic>? data;

  StoryOverlay({
    required this.type,
    required this.text,
    required this.position,
    this.color,
    required this.size,
    this.fontFamily,
    this.data,
  });
}

class DrawingPoints {
  final Offset points;
  final Paint paint;

  DrawingPoints({required this.points, required this.paint});
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoints?> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i]!.points,
          points[i + 1]!.points,
          points[i]!.paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

// Constants
final List<String> _stickerEmojis = [
  '😍', '😂', '🥰', '😎', '🔥', '❤️', '👏', '🎉',
  '😭', '😊', '🤔', '👍', '🙏', '💯', '✨', '🌟',
  '🐶', '🐱', '🐰', '🐭', '🐹', '🦊', '🐻', '🐼',
  '🌈', '☀️', '🌙', '⭐', '☁️', '⛅', '🌤️', '🌞',
  '🎵', '🎶', '🎤', '🎧', '🎼', '🎹', '🥁', '🎸',
  '📸', '📷', '🎥', '📹', '🎬', '🎞️', '📽️', '🎪',
];

final List<Color> _textColors = [
  Colors.white,
  Colors.black,
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.blue,
  Colors.cyan,
  Colors.green,
  Colors.yellow,
  Colors.orange,
];

final List<Color> _drawColors = [
  Colors.white,
  Colors.black,
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.yellow,
  Colors.purple,
  Colors.orange,
  Colors.pink,
  Colors.cyan,
];

final List<String> _fontFamilies = [
  'Default',
  'Roboto',
  'Poppins',
  'Montserrat',
  'Pacifico',
  'Dancing Script',
];

final List<String> _popularLocations = [
  'İstanbul, Türkiye',
  'Ankara, Türkiye',
  'İzmir, Türkiye',
  'Antalya, Türkiye',
  'Bursa, Türkiye',
];

final List<Map<String, String>> _sampleMusic = [
  {'title': 'Flowers', 'artist': 'Miley Cyrus'},
  {'title': 'Unholy', 'artist': 'Sam Smith'},
  {'title': 'As It Was', 'artist': 'Harry Styles'},
  {'title': 'Anti-Hero', 'artist': 'Taylor Swift'},
  {'title': 'Calm Down', 'artist': 'Rema'},
];