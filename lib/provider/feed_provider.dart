import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:statelink/screens/old_feed/model/feed_model.dart';

class PostProvider with ChangeNotifier {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Feed> posts = [];
  bool isLoading = false;
  String errorMessage = '';

  Future<void> fetchPosts() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      // Read posts directly from Firestore — Firebase Storage is NOT used
      // Each Firestore document must have an 'imageUrl' field with a direct image URL
      final QuerySnapshot snapshot =
          await firestore.collection('posts').get();

      final List<Feed> tempPosts = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String url = (data['imageUrl'] ?? '').toString().trim();

        if (url.isEmpty) {
          debugPrint(
            "⚠️  Post [${doc.id}] skipped — add an 'imageUrl' field in Firestore for this document.",
          );
          continue;
        }

        tempPosts.add(Feed.fromFirestore(doc, url));
      }

      posts = tempPosts;

      if (posts.isEmpty) {
        errorMessage =
            'No posts found.\nAdd an imageUrl field to each document in the Firestore posts collection.';
      }
    } catch (e) {
      errorMessage = 'Failed to load posts.';
      debugPrint("❌ Error fetching posts: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  /// Like or unlike a post
  Future<void> likePost(Feed post, String userId) async {
    final postRef = firestore.collection('posts').doc(post.postId);
    if (post.likes.contains(userId)) {
      post.likes.remove(userId);
    } else {
      post.likes.add(userId);
    }

    await postRef.update({'likes': post.likes});
    notifyListeners();
  }

 
Future<void> addComment(Feed post, String userId, String commentText) async {
  if (commentText.trim().isEmpty) return;

  final postRef = firestore.collection('posts').doc(post.postId);

  final newComment = {
    'userId': userId,
    'comment': commentText.trim(),
    //'timestamp': FieldValue.serverTimestamp(),
  };

  try {
    await postRef.set({
      'comments': FieldValue.arrayUnion([newComment]),
    }, SetOptions(merge: true));

    post.comments.add({
      'userId': userId,
      'comment': commentText.trim(),
    });

    notifyListeners();
  } catch (e, s) {
    debugPrint('Comment error: $e');
    debugPrint('Stack: $s');
  }
}
}