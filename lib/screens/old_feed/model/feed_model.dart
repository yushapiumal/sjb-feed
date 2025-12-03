import 'package:cloud_firestore/cloud_firestore.dart';

class Feed {
  final String postId;
  final String storagePath; // path in Firebase Storage
  final String imageUrl; // downloaded URL
  List<String> likes;
  List<Map<String, dynamic>> comments;

  Feed({
    required this.postId,
    required this.storagePath,
    required this.imageUrl,
    required this.likes,
    required this.comments,
  });

factory Feed.fromFirestore(DocumentSnapshot doc, String imageUrl) {
  final data = doc.data() as Map<String, dynamic>;
  return Feed(
    postId: doc.id,
    storagePath: data['storagePath'] ?? '',
    imageUrl: imageUrl,
    likes: List<String>.from(data['likes'] ?? []),

    comments: (data['comments'] as List<dynamic>? ?? [])
        .map((c) => {
              'userId': c['userId'] ?? '',
              'comment': c['comment'] ?? '',
              'timestamp': c['timestamp'] ?? Timestamp.now(),
            })
        .toList(),
  );
}

}