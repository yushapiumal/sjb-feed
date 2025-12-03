import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:statelink/provider/feed_provider.dart';
import 'package:statelink/screens/old_feed/model/feed_model.dart';
import 'logn_fb&google.dart';

// Facebook Blue Color
const Color facebookBlue = Color(0xFF1877F2);

class FeedScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const FeedScreen({super.key, required this.userData});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late String userId, userName, userEmail, userPhoto;
  late Timer _timer;
  String selectedLanguage = 'sinhala';
  late SharedPreferences prefs;
  String? memberId;

  @override
  @override
  void initState() {
    super.initState();
    _initPrefs();
    userName = widget.userData['name'] ?? 'User';
    userEmail = widget.userData['email'] ?? 'user@example.com';
    userPhoto = widget.userData['photoUrl'] ??
        'https://www.vecteezy.com/vector-art/24766958-default-male-avatar-profile-icon-social-media-user-vector';

    _loadLanguage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PostProvider>(context, listen: false);
      provider.fetchPosts();
      _timer = Timer.periodic(const Duration(minutes: 30), (_) {
        if (!provider.isLoading && mounted) provider.fetchPosts();
      });
    });
  }
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => selectedLanguage = prefs.getString('language') ?? 'English');
    }
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    memberId = prefs.getString('member_id');
     userId = memberId.toString();
    if (mounted) setState(() {});
  }


Future<void> _saveLanguage(String lang) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language', lang);

  // Convert language names to locale codes
  Locale newLocale;

  if (lang == "English") {
    newLocale = const Locale('en');
  } else if (lang == "සිංහල") {
    newLocale = const Locale('si');
  } else if (lang == "தமிழ்") {
    newLocale = const Locale('ta');
  } else {
    newLocale = const Locale('en');
  }

  // 🔥 IMPORTANT: Update app language
  await context.setLocale(newLocale);

  if (mounted) {
    setState(() => selectedLanguage = lang);
  }

  Fluttertoast.showToast(
    msg: 'Language changed to $lang',
    toastLength: Toast.LENGTH_SHORT,
  );
}


  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

Future<void> _logoutUser() async {
  try {
    if (prefs.containsKey('memberId')) {
      final memberId = prefs.getString('memberId');
      print("Member ID before clearing: $memberId");
    }
    await prefs.clear();
    final googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }
    await FacebookAuth.instance.logOut();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      context.go('/login', extra: "Logged out"); // extra can pass message
    }
  } catch (e, stackTrace) {
    print("Logout error: $e");
    print(stackTrace);
  }
}


  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:  Text("logout".tr()),
        content: const Text('logout_confirm').tr(),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child:  Text("cancel".tr())),
          TextButton(onPressed: () => {Navigator.pop(context), _logoutUser()}, child:  Text("logout".tr(), style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('feed_topic'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/images/loginbg.png"), fit: BoxFit.cover),
          ),
        ),
        // actions: const [
        //   IconButton(icon: Icon(Icons.search, color: Colors.white), onPressed: null),
        //   IconButton(icon: Icon(Icons.messenger_outline, color: Colors.white), onPressed: null),
        // ],
      ),
      drawer: _buildDrawer(),
      body: Consumer<PostProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator(color: facebookBlue));
          if (provider.posts.isEmpty) {
            return Center(child: Text('post_not_available'.tr(), style: TextStyle(color: Colors.grey[600], fontSize: 16)));
          }

          return RefreshIndicator(
            onRefresh: provider.fetchPosts,
            color: facebookBlue,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: provider.posts.length,
              itemBuilder: (context, index) {
                final post = provider.posts[index];
                return PostCard(
                  key: ValueKey(post.hashCode), // Use hashCode instead of non-existent `id`
                  post: post,
                  userId: userId,
                  userName: userName,
                  userPhoto: userPhoto,
                  provider: provider,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(backgroundImage: NetworkImage(userPhoto)),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("assets/images/loginbg.png"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
              ),
            ),
          ),
          ListTile(leading: const Icon(Icons.home), title:  Text('home'.tr()), onTap: () => Navigator.pop(context)),
          ExpansionTile(
            leading: const Icon(Icons.language),
            title:  Text('language'.tr()),
            children: ['English', 'සිංහල', 'தமிழ்'].map((lang) => ListTile(
              title: Text(lang),
              trailing: selectedLanguage == lang ? Icon(Icons.check, color: facebookBlue) : null,
              onTap: () { _saveLanguage(lang); Navigator.pop(context); },
            )).toList(),
          ),
          const Divider(),
          ListTile(leading: const Icon(Icons.settings), title:  Text('settings'.tr()), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title:  Text('logout'.tr(), style: TextStyle(color: Colors.red)), onTap: _showLogoutDialog),
        ],
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Feed post;
  final String userId, userName, userPhoto;
  final PostProvider provider;

  const PostCard({
    super.key,
    required this.post,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.provider,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  bool _isCommentsVisible = false;
  late TextEditingController _commentController;
  bool _isCommenting = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleComments() {
    setState(() => _isCommentsVisible = !_isCommentsVisible);
    if (_isCommentsVisible) {
      // scroll to bottom after short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isCommenting = true);
    try {
      await widget.provider.addComment(widget.post, widget.userId, text);
      _commentController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Comment added successfully")),
      );

      // scroll to the new comment
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to post comment")),
      );
    } finally {
      if (mounted) setState(() => _isCommenting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isLiked = post.likes.contains(widget.userId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(backgroundImage: NetworkImage(widget.userPhoto), radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ),

          // Post Image
          if (post.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(post.imageUrl, width: double.infinity, height: 300, fit: BoxFit.cover),
            ),

          // Likes & Comments Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.thumb_up, size: 16, color: const Color.fromARGB(255, 8, 136, 36)),
                  const SizedBox(width: 4),
                  Text("${post.likes.length}", style: const TextStyle(fontWeight: FontWeight.w500)),
                ]),
                Text("${post.comments.length} Comment${post.comments.length != 1 ? 's' : ''}", style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),

          const Divider(height: 1),

          // Like & Comment Buttons
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => widget.provider.likePost(post, widget.userId),
                  icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, color: isLiked ? const Color.fromARGB(255, 8, 136, 36) : Colors.grey[700]),
                  label: Text(isLiked ? "Liked" : "Like", style: TextStyle(color: isLiked ? const Color.fromARGB(255, 8, 136, 36) : Colors.grey[700])),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: _toggleComments,
                  icon: Icon(Icons.comment_outlined, color: _isCommentsVisible ?  const Color.fromARGB(255, 8, 136, 36) : Colors.grey[700]),
                  label: Text("Comment", style: TextStyle(color: _isCommentsVisible ? const Color.fromARGB(255, 8, 136, 36) : Colors.grey[700])),
                ),
              ),
            ],
          ),

          // Smooth Animated Comments Section
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isCommentsVisible
                ? SizedBox(
                    height: 250,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: post.comments.length,
                            itemBuilder: (context, index) {
                              final c = post.comments[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(radius: 14, child: Text(c['userId']?[0].toUpperCase() ?? 'A')),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(18)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(c['userId'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const SizedBox(height: 2),
                                            Text(c['comment']),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        // Fixed Add Comment Box
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CircleAvatar(backgroundImage: NetworkImage(widget.userPhoto), radius: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  decoration: InputDecoration(
                                    hintText: "Write a comment...",
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    suffixIcon: _isCommenting
                                        ? const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : IconButton(
                                            icon: Icon(Icons.send, color: const Color.fromARGB(255, 8, 136, 36)),
                                            onPressed: _addComment,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
