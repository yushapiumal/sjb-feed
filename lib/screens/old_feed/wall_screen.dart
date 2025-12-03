// lib/screens/wall_screen.dart
import 'package:any_link_preview/any_link_preview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:statelink/screens/old_feed/model/feed_model.dart';
import 'package:statelink/screens/old_feed/model/group.dart';
import 'package:statelink/screens/old_feed/model/post.dart';
import 'package:statelink/screens/old_feed/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class WallScreen extends StatefulWidget {
  final String groupId;
  const WallScreen({super.key, required this.groupId});

  @override
  State<WallScreen> createState() => _WallScreenState();
}

class _WallScreenState extends State<WallScreen> {
  final _instructionController = TextEditingController();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  Future<void> _notifyAdmins(String postId, String userId) async {
    await http.post(
      Uri.parse('http://your-backend-url:3000/sendNotification'),
      body: {'postId': postId, 'userId': userId, 'groupId': widget.groupId},
    );
  }

  @override
  void dispose() {
    _instructionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showMembersDialog(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Group Members'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: group.members.length,
            itemBuilder: (ctx, index) {
              final uid = group.members[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(title: Text('Loading...'));
                  }
                  final userData = snapshot.data?.data() as Map<String, dynamic>?;
                  return ListTile(
                    title: Text(userData?['name'] ?? userData?['email'] ?? 'Unknown User'),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user!;

    return FutureBuilder<bool>(
      future: authProvider.isGroupAdmin(widget.groupId),
      builder: (context, adminSnapshot) {
        if (!adminSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final isGroupAdmin = adminSnapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get(),
          builder: (context, groupSnapshot) {
            if (groupSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!groupSnapshot.hasData || !groupSnapshot.data!.exists) {
              return const Center(child: Text('Group not found'));
            }
            final group = Group.fromMap(groupSnapshot.data!.data() as Map<String, dynamic>, widget.groupId);

            return Scaffold(
              appBar: AppBar(
                title: Text(group.name),
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.yellow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.group),
                    onPressed: () => _showMembersDialog(context, group),
                  ),
                ],
              ),
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.yellow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('groups')
                            .doc(widget.groupId)
                            .collection('posts')
                            .orderBy('createdAt', descending: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: SpinKitFadingCircle(color: Colors.blue));
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: const Center(
                                child: Text(
                                  'No posts yet: ask your admin to share some',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final doc = snapshot.data!.docs[index];
                              final post = Post.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                              bool hasReacted = post.reactions.contains(user.uid);

                              if (post.createdBy.isEmpty) {
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Unknown Sender',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              post.createdAt != null
                                                  ? DateFormat('HH:mm').format(post.createdAt!.toDate())
                                                  : 'Unknown Time',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (post.link.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: AnyLinkPreview(
                                            link: post.link,
                                            boxShadow: const [],
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          post.instruction,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      if (post.link.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              ElevatedButton(
                                                onPressed: hasReacted
                                                    ? null
                                                    : () async {
                                                        await launchUrl(Uri.parse(post.link));
                                                        await FirebaseFirestore.instance
                                                            .collection('groups')
                                                            .doc(widget.groupId)
                                                            .collection('posts')
                                                            .doc(post.id)
                                                            .update({
                                                          'reactions': FieldValue.arrayUnion([user.uid]),
                                                        });
                                                        await _notifyAdmins(post.id, user.uid);
                                                      },
                                                child: Text(hasReacted ? 'Followed' : 'Follow Instruction'),
                                              ),
                                              Text(
                                                '${post.reactions.length} Reactions',
                                                style: const TextStyle(color: Colors.grey),
                                              ),
                                              if (isGroupAdmin)
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () async {
                                                    await FirebaseFirestore.instance
                                                        .collection('groups')
                                                        .doc(widget.groupId)
                                                        .collection('posts')
                                                        .doc(post.id)
                                                        .delete();
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Post deleted')),
                                                    );
                                                  },
                                                ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.2);
                              }

                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(post.createdBy).get(),
                                builder: (ctx, userSnapshot) {
                                  String senderName = 'Unknown';
                                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                    senderName = userData?['name'] ?? userData?['email'] ?? 'Unknown';
                                  }
                                  final createdAt = post.createdAt?.toDate() ?? DateTime.now();
                                  final formattedTime = DateFormat('HH:mm').format(createdAt);

                                  return Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                senderName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                formattedTime,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (post.link.isNotEmpty)
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                            child: AnyLinkPreview(
                                              link: post.link,
                                              boxShadow: const [],
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            post.instruction,
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        if (post.link.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: hasReacted
                                                      ? null
                                                      : () async {
                                                          await launchUrl(Uri.parse(post.link));
                                                          await FirebaseFirestore.instance
                                                              .collection('groups')
                                                              .doc(widget.groupId)
                                                              .collection('posts')
                                                              .doc(post.id)
                                                              .update({
                                                            'reactions': FieldValue.arrayUnion([user.uid]),
                                                          });
                                                          await _notifyAdmins(post.id, user.uid);
                                                        },
                                                  child: Text(hasReacted ? 'Followed' : 'Follow Instruction'),
                                                ),
                                                Text(
                                                  '${post.reactions.length} Reactions',
                                                  style: const TextStyle(color: Colors.grey),
                                                ),
                                                if (isGroupAdmin)
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () async {
                                                      await FirebaseFirestore.instance
                                                          .collection('groups')
                                                          .doc(widget.groupId)
                                                          .collection('posts')
                                                          .doc(post.id)
                                                          .delete();
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Post deleted')),
                                                      );
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.2);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (isGroupAdmin)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.white.withOpacity(0.8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _instructionController,
                                decoration: InputDecoration(
                                  labelText: 'Type a message or paste a link',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                maxLines: null,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      if (_instructionController.text.isNotEmpty) {
                                        setState(() => _isLoading = true);
                                        // Extract URL from text
                                        final text = _instructionController.text;
                                        final urlReg = RegExp(r'(https?://\S+)');
                                        final match = urlReg.firstMatch(text);
                                        final link = match?.group(0) ?? '';
                                        await FirebaseFirestore.instance
                                            .collection('groups')
                                            .doc(widget.groupId)
                                            .collection('posts')
                                            .add({
                                          'groupId': widget.groupId,
                                          'link': link,
                                          'instruction': _instructionController.text,
                                          'reactions': [],
                                          'createdBy': user.uid,
                                          'createdAt': Timestamp.now(),
                                        });
                                        _instructionController.clear();
                                        setState(() => _isLoading = false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Post shared successfully')),
                                        );
                                        _scrollToBottom();
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}