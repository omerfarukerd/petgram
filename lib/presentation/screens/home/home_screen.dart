import 'package:flutter/material.dart';
import 'package:pet_gram/presentation/screens/reels/create_reel_screen.dart';
import 'package:pet_gram/presentation/screens/story/create_story_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_texts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import 'feed_tab.dart';
import 'explore_tab.dart';
import 'profile_tab.dart';
import 'reels_tab.dart';
import '../post/create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const FeedTab(),
    const ExploreTab(),
    const Center(child: Text('Ekle')),
    const ReelsTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _showCreateOptions();
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: AppTexts.home),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: AppTexts.explore),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: AppTexts.add),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Reels'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: AppTexts.profile),
        ],
      ),
    );
  }

  void _showCreateOptions() {
    showModalBottomSheet(
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
              leading: const Icon(Icons.grid_on),
              title: const Text('Gönderi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Reel'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateReelScreen()),
                );
                if (result == true && mounted) {
                  setState(() => _currentIndex = 3); // Reels tab'a git
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_toggle_off),
              title: const Text('Hikaye'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateStoryScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}