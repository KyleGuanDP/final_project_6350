import 'package:flutter/material.dart';

import '../models/post.dart';
import 'image_view_screen.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.1,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post Detail',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Title =====
            _sectionTitle('Title'),
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 22),

            // ===== Price =====
            _sectionTitle('Price'),
            Text(
              '\$${post.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 22),

            // ===== Description =====
            _sectionTitle('Description'),
            Text(
              post.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 32),

            // ===== Images =====
            _sectionTitle('Images'),

            if (post.imageUrls.isEmpty)
              const Text(
                'This post has no images yet.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: post.imageUrls.map((url) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ImageViewScreen(imageUrl: url),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        width: 115,
                        height: 115,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
