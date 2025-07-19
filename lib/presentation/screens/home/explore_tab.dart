import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/hashtag_repository.dart';
import '../../widgets/post/explore_grid_item.dart';
import '../post/post_detail_screen.dart';
import '../../profile/profile_screen.dart';
import '../hashtag/hashtag_feed_screen.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchType = 'all'; // 'all', 'users', 'posts', 'tags'
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
            
            // Arama tipi seçici
            if (_searchQuery.isNotEmpty)
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Tümü')),
                    ButtonSegment(value: 'users', label: Text('Kullanıcılar')),
                    ButtonSegment(value: 'posts', label: Text('Gönderiler')),
                    ButtonSegment(value: 'tags', label: Text('Etiketler')),
                  ],
                  selected: {_searchType},
                  onSelectionChanged: (Set<String> selected) {
                    setState(() {
                      _searchType = selected.first;
                    });
                  },
                ),
              ),
            
            const SizedBox(height: 8),
            
            // İçerik
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildExploreContent()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreContent() {
    return Column(
      children: [
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
        
        // Trending hashtags
        StreamBuilder<List<String>>(
          stream: HashtagRepository.getTrendingHashtags(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            
            return Container(
              height: 32,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final tag = snapshot.data![index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HashtagFeedScreen(hashtag: tag),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(color: Colors.blue, fontSize: 13),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        
        // Post grid
        Expanded(
          child: StreamBuilder<List<PostModel>>(
            stream: PostRepository.getFeedPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Henüz gönderi yok'));
              }

              var posts = snapshot.data!;
              
              // Kategori filtresi
              if (_selectedCategory != 'all') {
                posts = posts.where((post) {
                  return post.caption?.toLowerCase().contains(_selectedCategory) ?? false;
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
                      isLarge: (index % 7 == 0),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return ListView(
      children: [
        // Kullanıcı sonuçları
        if (_searchType == 'all' || _searchType == 'users')
          StreamBuilder<List<UserModel>>(
            stream: UserRepository.searchUsers(_searchQuery),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              
              final users = snapshot.data!.take(5).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kullanıcılar', style: Theme.of(context).textTheme.titleMedium),
                        if (snapshot.data!.length > 5)
                          TextButton(
                            onPressed: () {
                              setState(() => _searchType = 'users');
                            },
                            child: const Text('Tümünü Gör'),
                          ),
                      ],
                    ),
                  ),
                  if (_searchType == 'all')
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _buildUserCard(user);
                        },
                      ),
                    )
                  else
                    ...users.map((user) => _buildUserTile(user)),
                  const Divider(),
                ],
              );
            },
          ),
        
        // Hashtag sonuçları
        if (_searchType == 'all' || _searchType == 'tags')
          FutureBuilder<List<String>>(
            future: _searchHashtags(_searchQuery),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              
              final tags = snapshot.data!.take(5).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Etiketler', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  ...tags.map((tag) => ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.tag, color: Colors.blue),
                    ),
                    title: Text('#$tag'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HashtagFeedScreen(hashtag: tag),
                        ),
                      );
                    },
                  )),
                  const Divider(),
                ],
              );
            },
          ),
        
        // Post sonuçları
        if (_searchType == 'all' || _searchType == 'posts')
          StreamBuilder<List<PostModel>>(
            stream: PostRepository.getFeedPosts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              var posts = snapshot.data!.where((post) {
                return post.caption?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
              }).toList();
              
              if (posts.isEmpty) return const SizedBox.shrink();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Gönderiler', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: posts.length > 9 ? 9 : posts.length,
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
                        child: ExploreGridItem(post: post),
                      );
                    },
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: user.uid),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(user.username[0].toUpperCase())
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              user.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
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
      subtitle: user.bio != null ? Text(user.bio!, maxLines: 1) : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: user.uid),
          ),
        );
      },
    );
  }

  Future<List<String>> _searchHashtags(String query) async {
    // Basit bir hashtag araması
    final allTags = ['köpek', 'kedi', 'kuş', 'pet', 'hayvansever', 'pati', 'dost'];
    return allTags.where((tag) => tag.contains(query.toLowerCase())).toList();
  }
}