import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post.dart';
import 'new_post_screen.dart';
import 'post_detail_screen.dart';

class BrowsePostsScreen extends StatelessWidget {
  const BrowsePostsScreen({super.key});

  // 从 Firestore 订阅 posts 列表
  Stream<List<Post>> _postsStream() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Post.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // 跳转到 NewPost，返回 true 表示发帖成功
  Future<void> _navigateToNewPost(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const NewPostScreen(),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New post added!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatTime(DateTime dt) {
    // 简单一点：显示年月日和时间
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Posts'),
      ),
      body: StreamBuilder<List<Post>>(
        stream: _postsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const Center(
              child: Text(
                '暫時還沒有任何貼文，點右下角 + 來發第一則吧！',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  title: Text(post.title),
                  subtitle: Text(
                    '\$${post.price.toStringAsFixed(2)}\n'
                    '${post.description}\n'
                    '${_formatTime(post.createdAt)}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(post: post),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToNewPost(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
