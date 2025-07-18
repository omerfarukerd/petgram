import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class MusicModel {
  final String id;
  final String name;
  final String artist;
  final String? coverUrl;
  final String? audioUrl;
  final int useCount;
  final DateTime createdAt;
  final String? userId; // Müziği yükleyen kullanıcı
  final bool isOriginalSound; // Kullanıcının kendi parçası mı
  final bool isPrivate; // Sadece kendisi mi kullanabilir

  MusicModel({
    required this.id,
    required this.name,
    required this.artist,
    this.coverUrl,
    this.audioUrl,
    this.useCount = 0,
    required this.createdAt,
    this.userId,
    this.isOriginalSound = false,
    this.isPrivate = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'artist': artist,
    'coverUrl': coverUrl,
    'audioUrl': audioUrl,
    'useCount': useCount,
    'createdAt': createdAt.toIso8601String(),
    'userId': userId,
    'isOriginalSound': isOriginalSound,
    'isPrivate': isPrivate,
  };

  factory MusicModel.fromJson(Map<String, dynamic> json) => MusicModel(
    id: json['id'],
    name: json['name'],
    artist: json['artist'],
    coverUrl: json['coverUrl'],
    audioUrl: json['audioUrl'],
    useCount: json['useCount'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    userId: json['userId'],
    isOriginalSound: json['isOriginalSound'] ?? false,
    isPrivate: json['isPrivate'] ?? false,
  );
}

class MusicRepository {
  static const String musicCollection = 'music';

  static Stream<List<MusicModel>> getUserMusic(String userId) {
    return FirebaseService.firestore
        .collection(musicCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MusicModel.fromJson(doc.data()))
            .toList());
  }

  static Stream<List<MusicModel>> getAvailableMusic(String currentUserId) {
    return FirebaseService.firestore
        .collection(musicCollection)
        .where('isPrivate', isEqualTo: false)
        .orderBy('useCount', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final publicMusic = snapshot.docs
          .map((doc) => MusicModel.fromJson(doc.data()))
          .toList();
      
      // Kullanıcının özel müziklerini de ekle
      return FirebaseService.firestore
          .collection(musicCollection)
          .where('userId', isEqualTo: currentUserId)
          .where('isPrivate', isEqualTo: true)
          .get()
          .then((privateSnapshot) {
        final privateMusic = privateSnapshot.docs
            .map((doc) => MusicModel.fromJson(doc.data()))
            .toList();
        return [...publicMusic, ...privateMusic];
      });
    })
    .asyncExpand((future) => Stream.fromFuture(future));
  }

  static Future<List<MusicModel>> getTrendingMusic() async {
    final snapshot = await FirebaseService.firestore
        .collection(musicCollection)
        .orderBy('useCount', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => MusicModel.fromJson(doc.data()))
        .toList();
  }

  static Future<List<MusicModel>> searchMusic(String query) async {
    if (query.isEmpty) return [];
    
    final snapshot = await FirebaseService.firestore
        .collection(musicCollection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .limit(20)
        .get();

    final artistSnapshot = await FirebaseService.firestore
        .collection(musicCollection)
        .where('artist', isGreaterThanOrEqualTo: query)
        .where('artist', isLessThan: query + 'z')
        .limit(20)
        .get();

    final results = <MusicModel>{};
    for (final doc in snapshot.docs) {
      results.add(MusicModel.fromJson(doc.data()));
    }
    for (final doc in artistSnapshot.docs) {
      results.add(MusicModel.fromJson(doc.data()));
    }

    return results.toList();
  }

  static Future<void> incrementUseCount(String musicId) async {
    await FirebaseService.firestore
        .collection(musicCollection)
        .doc(musicId)
        .update({
      'useCount': FieldValue.increment(1),
    });
  }

  static Future<MusicModel?> getMusic(String musicId) async {
    final doc = await FirebaseService.firestore
        .collection(musicCollection)
        .doc(musicId)
        .get();

    if (doc.exists && doc.data() != null) {
      return MusicModel.fromJson(doc.data()!);
    }
    return null;
  }

  // Başlangıç müzikleri (ilk kurulum için)
  static Future<void> seedInitialMusic() async {
    final initialMusic = [
      MusicModel(
        id: 'original',
        name: 'Orijinal Ses',
        artist: '',
        createdAt: DateTime.now(),
      ),
      MusicModel(
        id: '1',
        name: 'Flowers',
        artist: 'Miley Cyrus',
        createdAt: DateTime.now(),
      ),
      MusicModel(
        id: '2',
        name: 'Unholy',
        artist: 'Sam Smith',
        createdAt: DateTime.now(),
      ),
      MusicModel(
        id: '3',
        name: 'As It Was',
        artist: 'Harry Styles',
        createdAt: DateTime.now(),
      ),
      MusicModel(
        id: '4',
        name: 'Anti-Hero',
        artist: 'Taylor Swift',
        createdAt: DateTime.now(),
      ),
    ];

    final batch = FirebaseService.firestore.batch();
    for (final music in initialMusic) {
      final ref = FirebaseService.firestore
          .collection(musicCollection)
          .doc(music.id);
      batch.set(ref, music.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}