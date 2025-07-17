import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/post_repository.dart';
import '../../widgets/post/explore_grid_item.dart';
import '../post/post_detail_screen.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';

  final List<String> _categories = [
    'all',
    'köpek',
    'kedi',
    'kuş',
    'balık',
    'hamster',
    'tavşan',
    'sürüngen',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _calculateTrendScore(PostModel post) {
    final hoursSincePost = DateTime.now().difference(post.createdAt).inHours + 1;
    final engagement = (post.likes.length * 0.3) + (post.commentCount * 0.5);
    return engagement / hoursSincePost;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Arama çubuğu
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            
            // Kategori filtreleri
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        category == 'all' ? 'Tümü' : category.toUpperCase(),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Post grid
            Expanded(
              child: StreamBuilder<List<PostModel>>(
                stream: PostRepository.getFeedPosts(), // TODO: Trending posts
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Henüz gönderi yok'));
                  }

                  // Filtreleme ve sıralama
                  var posts = snapshot.data!;
                  
                  // Kategori filtresi
                  if (_selectedCategory != 'all') {
                    posts = posts.where((post) {
                      return post.caption?.toLowerCase().contains(_selectedCategory) ?? false;
                    }).toList();
                  }
                  
                  // Arama filtresi
                  if (_searchQuery.isNotEmpty) {
                    posts = posts.where((post) {
                      return post.caption?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
                    }).toList();
                  }
                  
                  // Trend score'a göre sırala
                  posts.sort((a, b) {
                    final scoreA = _calculateTrendScore(a);
                    final scoreB = _calculateTrendScore(b);
                    return scoreB.compareTo(scoreA);
                  });

                  return MasonryGridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(
                                post: post,
                                posts: posts,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: ExploreGridItem(
                          post: post,
                          // Her 7. item büyük olsun
                          isLarge: (index % 7 == 0),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}