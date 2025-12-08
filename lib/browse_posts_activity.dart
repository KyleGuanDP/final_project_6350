import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'new_post_activity.dart';

class BrowsePostsActivity extends StatelessWidget {
  const BrowsePostsActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Posts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 跳转到发帖页，等发帖完成再回来
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewPostActivity()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').snapshots(),
        builder: (context, snapshot) {
          // 👉 1. 有错误先看错误
          if (snapshot.hasError) {
            return Center(child: Text('出错了: ${snapshot.error}'));
          }

          // 👉 2. 看一下有没有连上
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 👉 3. 临时打印一下当前 docs 长度
          final docs = snapshot.data?.docs ?? [];
          print('当前拿到的帖子数量: ${docs.length}');

          if (docs.isEmpty) {
            return const Center(child: Text('还没有任何帖子'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] ?? ''),
                subtitle: Text(
                  '\$${data['price'] ?? ''}\n${data['description'] ?? ''}',
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
