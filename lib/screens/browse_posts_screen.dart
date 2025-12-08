import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/post.dart';
import 'new_post_screen.dart';
import 'post_detail_screen.dart';
import 'login_screen.dart';

enum PostFilter { all, mine }

class BrowsePostsScreen extends StatefulWidget {
  const BrowsePostsScreen({super.key});

  @override
  State<BrowsePostsScreen> createState() => _BrowsePostsScreenState();
}

class _BrowsePostsScreenState extends State<BrowsePostsScreen> {
  PostFilter _filter = PostFilter.all;

  Stream<List<Post>> _postsStream() {
    final user = FirebaseAuth.instance.currentUser;
    final base = FirebaseFirestore.instance.collection('posts');

    if (_filter == PostFilter.all) {
      // 所有貼文：直接用 orderBy
      return base.orderBy('createdAt', descending: true).snapshots().map((
        snapshot,
      ) {
        return snapshot.docs
            .map((doc) => Post.fromMap(doc.id, doc.data()))
            .toList();
      });
    }

    // Mine：只看自己的，不用 orderBy，回來後在本地 sort
    if (user == null) {
      // 沒登入理論上不會進來這裡，這裡防禦一下
      return const Stream.empty();
    }

    return base.where('userId', isEqualTo: user.uid).snapshots().map((
      snapshot,
    ) {
      final list = snapshot.docs
          .map((doc) => Post.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 最新在前
      return list;
    });
  }

  Future<void> _navigateToNewPost(BuildContext context) async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const NewPostScreen()));

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New post added!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deletePost(Post post) async {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user != null && user.uid == post.userId;

    if (!isOwner) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('只能刪除自己發布的貼文')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除貼文'),
        content: const Text('確定要刪除這則貼文嗎？圖片也會一起刪除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final storage = FirebaseStorage.instance;

      // 刪 Storage 圖片
      for (int i = 0; i < post.imageUrls.length; i++) {
        final ref = storage
            .ref()
            .child('posts')
            .child(post.id)
            .child('image_$i.jpg');
        try {
          await ref.delete();
        } catch (e) {
          // 沒這張圖就算了
          debugPrint('storage delete ignore: $e');
        }
      }

      // 刪 Firestore 文檔
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已刪除貼文')));
    } catch (e) {
      if (!mounted) return;
      debugPrint('delete failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('刪除失敗: $e')));
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Posts'),
        actions: [
          Center(
            child: Text(
              user?.email ?? '',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 顶部过滤：全部 / 我的
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text('Filter:'),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == PostFilter.all,
                  onSelected: (_) {
                    setState(() {
                      _filter = PostFilter.all;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Mine'),
                  selected: _filter == PostFilter.mine,
                  onSelected: (_) {
                    setState(() {
                      _filter = PostFilter.mine;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: _postsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return const Center(
                    child: Text('暫時還沒有任何貼文', textAlign: TextAlign.center),
                  );
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final isOwner = user != null && user.uid == post.userId;

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
                        trailing: isOwner
                            ? IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deletePost(post),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToNewPost(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
