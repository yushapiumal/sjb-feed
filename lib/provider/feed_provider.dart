import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:statelink/screens/old_feed/model/feed_model.dart';

class PostProvider with ChangeNotifier {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Feed> posts = [];
  bool isLoading = false;


  Future<void> fetchPosts() async {
    isLoading = true;
    notifyListeners();

    try {
      final ListResult result = await storage.ref('posts').listAll();
      final List<Feed> tempPosts = [];

      for (var ref in result.items) {
        final url = await ref.getDownloadURL();
        final doc = await firestore.collection('posts').doc(ref.name).get();
        if (!doc.exists) {
          await firestore.collection('posts').doc(ref.name).set({
            'storagePath': ref.fullPath,
            'likes': [],
            'comments': [],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        final feed = Feed.fromFirestore(doc.exists ? doc : await firestore.collection('posts').doc(ref.name).get(), url);
        tempPosts.add(feed);
      }

      posts = tempPosts;
    } catch (e) {
      debugPrint("Error fetching posts: $e");
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