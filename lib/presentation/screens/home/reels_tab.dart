import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/reel_model.dart';
import '../../../data/repositories/reel_repository.dart';
import '../../providers/auth_provider.dart';
import '../reels/reels_viewer_screen.dart';

class ReelsTab extends StatelessWidget {
  const ReelsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid ?? 'test-user';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reels'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ReelModel>>(
        stream: ReelRepository.getReelsFeed(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Henüz reel yok'),
            );
          }

          final reels = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(1),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: 9 / 16,
            ),
            itemCount: reels.length,
            itemBuilder: (context, index) {
              final reel = reels[index];
              
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReelsViewerScreen(
                        initialReels: reels,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video thumbnail
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: Image.network(
                          reel.mediaItems.first.url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 40,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                    // Beğeni sayısı
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${reel.likes.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}