import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/repositories/music_repository.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/firebase_service.dart';
import '../../providers/auth_provider.dart';

class UserMusicUploadScreen extends StatefulWidget {
  const UserMusicUploadScreen({super.key});

  @override
  State<UserMusicUploadScreen> createState() => _UserMusicUploadScreenState();
}

class _UserMusicUploadScreenState extends State<UserMusicUploadScreen> {
  final _nameController = TextEditingController();
  final _artistController = TextEditingController();
  final _audioUrlController = TextEditingController();
  File? _coverImage;
  File? _audioFile;
  bool _isLoading = false;
  bool _isOriginalSound = true;
  bool _isPrivate = false;
  static const _uuid = Uuid();
  
  // Upload method
  String _uploadMethod = 'url'; // 'url', 'file', 'record'

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioFile = File(result.files.single.path!);
      });
    }
  }
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _coverImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadMusic() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Müzik adı gerekli')),
      );
      return;
    }

    if (_uploadMethod == 'url' && _audioUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Müzik URL\'si gerekli')),
      );
      return;
    }

    if (_uploadMethod == 'file' && _audioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Müzik dosyası seçin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid ?? '';
      final username = authProvider.currentUser?.username ?? 'Kullanıcı';
      
      // Cover varsa yükle
      String? coverUrl;
      if (_coverImage != null) {
        coverUrl = await StorageService.uploadImage(_coverImage!, 'music_covers');
      }

      // Müzik URL'si
      String? audioUrl;
      if (_uploadMethod == 'url') {
        audioUrl = _audioUrlController.text.trim();
      } else if (_uploadMethod == 'file' && _audioFile != null) {
        // Dosyayı Firebase Storage'a yükle
        audioUrl = await StorageService.uploadMedia(_audioFile!, 'music', false);
      }

      // Müzik bilgilerini kaydet
      final music = MusicModel(
        id: _uuid.v4(),
        name: _nameController.text.trim(),
        artist: _isOriginalSound 
            ? (_artistController.text.trim().isEmpty ? username : _artistController.text.trim())
            : _artistController.text.trim(),
        audioUrl: audioUrl,
        coverUrl: coverUrl,
        createdAt: DateTime.now(),
        userId: userId,
        isOriginalSound: _isOriginalSound,
        isPrivate: _isPrivate,
      );

      await FirebaseService.firestore
          .collection(MusicRepository.musicCollection)
          .doc(music.id)
          .set(music.toJson());

      if (mounted) {
        Navigator.pop(context, music);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Müzik başarıyla eklendi!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müzik Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload method selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Müzik Ekleme Yöntemi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMethodCard(
                          'url',
                          Icons.link,
                          'URL',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMethodCard(
                          'file',
                          Icons.upload_file,
                          'Dosya',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMethodCard(
                          'record',
                          Icons.mic,
                          'Kayıt',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Music info
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Müzik Adı *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _artistController,
              decoration: InputDecoration(
                labelText: _isOriginalSound ? 'Sanatçı Adı (Opsiyonel)' : 'Sanatçı Adı',
                border: const OutlineInputBorder(),
                helperText: _isOriginalSound ? 'Boş bırakırsanız kullanıcı adınız kullanılır' : null,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // URL input (if URL method selected)
            if (_uploadMethod == 'url') ...[
              TextField(
                controller: _audioUrlController,
                decoration: const InputDecoration(
                  labelText: 'Müzik URL\'si *',
                  border: OutlineInputBorder(),
                  helperText: 'MP3 veya ses dosyası URL\'si',
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // File upload info
            if (_uploadMethod == 'file') ...[
              OutlinedButton.icon(
                onPressed: _pickAudioFile,
                icon: const Icon(Icons.audio_file),
                label: Text(_audioFile != null ? 'Müzik Seçildi' : 'Müzik Dosyası Seç'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              if (_audioFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _audioFile!.path.split('/').last,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 16),
            ],
            
            // Record info
            if (_uploadMethod == 'record') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(height: 8),
                    const Text(
                      'Ses kaydı için record paketi gerekli',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'pubspec.yaml\'a ekleyin:\nrecord: ^5.0.4',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Cover image
            OutlinedButton.icon(
              onPressed: _pickCoverImage,
              icon: const Icon(Icons.image),
              label: Text(_coverImage != null ? 'Kapak Seçildi' : 'Kapak Görseli (Opsiyonel)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            if (_coverImage != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 100,
                child: Image.file(_coverImage!, fit: BoxFit.cover),
              ),
            
            const SizedBox(height: 24),
            
            // Options
            SwitchListTile(
              title: const Text('Kendi Parçam'),
              subtitle: const Text('Bu müziği kendiniz mi ürettiniz?'),
              value: _isOriginalSound,
              onChanged: (value) => setState(() => _isOriginalSound = value),
            ),
            
            SwitchListTile(
              title: const Text('Özel'),
              subtitle: const Text('Sadece siz kullanabilirsiniz'),
              value: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value),
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _isLoading || 
                  (_uploadMethod == 'url' && _audioUrlController.text.isEmpty) ||
                  (_uploadMethod == 'file' && _audioFile == null) ||
                  (_uploadMethod == 'record')
                  ? null 
                  : _uploadMusic,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Müziği Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(String method, IconData icon, String label) {
    final isSelected = _uploadMethod == method;
    
    return GestureDetector(
      onTap: () => setState(() => _uploadMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _artistController.dispose();
    _audioUrlController.dispose();
    super.dispose();
  }
}