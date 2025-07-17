import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_texts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import 'feed_tab.dart';
import 'explore_tab.dart';
import 'profile_tab.dart';
import '../post/create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const FeedTab(), // onMessagesTap parametresini kaldırdık
    const ExploreTab(),
    const Center(child: Text('Ekle')),
    const Center(child: Text('Sahiplenme')),
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreatePostScreen()),
            );
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: AppTexts.home),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: AppTexts.explore),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: AppTexts.add),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: AppTexts.adoption),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: AppTexts.profile),
        ],
      ),
    );
  }
}