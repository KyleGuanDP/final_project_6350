import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String title;
  final double price;
  final String description;
  final List<String> imageUrls;
  final String? userId;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrls,
    required this.createdAt,
    this.userId,
  });

  factory Post.fromMap(String id, Map<String, dynamic> data) {
    final createdRaw = data['createdAt'];

    DateTime createdAt;
    if (createdRaw is Timestamp) {
      createdAt = createdRaw.toDate();
    } else if (createdRaw is DateTime) {
      createdAt = createdRaw;
    } else {
      createdAt = DateTime.now();
    }

    return Post(
      id: id,
      title: data['title'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String? ?? '',
      imageUrls: (data['imageUrls'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      userId: data['userId'] as String?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'description': description,
      'imageUrls': imageUrls,
      'userId': userId,
      'createdAt': createdAt,
    };
  }
}
