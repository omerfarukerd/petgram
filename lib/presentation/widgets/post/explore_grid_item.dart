import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/post_model.dart';

class ExploreGridItem extends StatelessWidget {
  final PostModel post;
  final bool isLarge;

  const ExploreGridItem({
    super.key,
    required this.post,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final firstMedia = post.mediaItems.first;
    
    return AspectRatio(
      aspectRatio: isLarge ? 1/2 : 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Medya
          CachedNetworkImage(
            imageUrl: firstMedia.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            ),
          ),
          
          // Gradient overlay (hover effect için)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
          
          // İkonlar
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                if (firstMedia.isVideo)
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                if (post.mediaItems.length > 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.collections,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          
          // Beğeni ve yorum sayısı (büyük itemlar için)
          if (isLarge)
            Positioned(
              bottom: 8,
              left: 8,
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likes.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.comment,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}