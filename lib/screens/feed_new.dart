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
import 'package:statelink/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

const _stories = [
  {'label': 'Live',    'asset': 'assets/images/sjb1st.jpg'},
  {'label': 'Updates', 'asset': 'assets/images/sjb2.png'},
  {'label': 'Rally',   'asset': 'assets/images/sjb3.jpeg'},
];

class FeedScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const FeedScreen({super.key, required this.userData});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late String userId, userName, userEmail, userPhoto;
  late Timer _timer;
  String selectedLanguage = 'English';
  late SharedPreferences prefs;
  int _navIndex = 0;
  bool _navVisible = true;
  double _lastScrollOffset = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initPrefs();
    userName  = widget.userData['name']     ?? 'User';
    userEmail = widget.userData['email']    ?? '';
    userPhoto = widget.userData['photoUrl'] ?? '';
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PostProvider>(context, listen: false);
      provider.fetchPosts();
      _timer = Timer.periodic(const Duration(minutes: 30), (_) {
        if (!provider.isLoading && mounted) provider.fetchPosts();
      });
    });
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final diff = offset - _lastScrollOffset;
    if (diff > 6 && _navVisible) {
      setState(() => _navVisible = false);
    } else if (diff < -6 && !_navVisible) {
      setState(() => _navVisible = true);
    }
    _lastScrollOffset = offset;
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('member_id') ?? 'guest';
    selectedLanguage = prefs.getString('language') ?? 'English';
    if (mounted) setState(() {});
  }

  Future<void> _saveLanguage(String lang) async {
    await prefs.setString('language', lang);
    Locale newLocale = lang == 'සිංහල' ? const Locale('si') : lang == 'தமிழ்' ? const Locale('ta') : const Locale('en');
    await context.setLocale(newLocale);
    if (mounted) setState(() => selectedLanguage = lang);
    Fluttertoast.showToast(msg: 'Language changed to $lang');
  }

  Future<void> _logoutUser() async {
    await prefs.clear();
    final g = GoogleSignIn();
    if (await g.isSignedIn()) await g.signOut();
    await FacebookAuth.instance.logOut();
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/login');
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('logout'.tr()),
        content: const Text('logout_confirm').tr(),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          TextButton(onPressed: () { Navigator.pop(context); _logoutUser(); }, child: Text('logout'.tr(), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  void dispose() { _scrollController.dispose(); _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final exit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Exit App', style: TextStyle(fontWeight: FontWeight.w700)),
            content: const Text('Do you want to exit?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (exit == true && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: _buildAppBar(),
        drawer: _buildDrawer(),
        body: Column(
          children: [
            AnimatedSlide(
              offset: _navVisible ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: _navVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: _buildTopNav(),
              ),
            ),
            Expanded(
              child: Consumer<PostProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
            return RefreshIndicator(
              onRefresh: provider.fetchPosts,
              color: AppColors.accentOrange,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  _StoriesRow(),
                  const SizedBox(height: 6),
                  if (provider.posts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: Text('post_not_available'.tr(), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 15))),
                    )
                  else
                    ...provider.posts.asMap().entries.expand((e) {
                      final widgets = <Widget>[
                        PostCard(key: ValueKey(e.value.postId), post: e.value, userId: userId, userName: userName, userPhoto: userPhoto, provider: provider),
                      ];
                      if (e.key == 0) widgets.add(const _PromotedCampaignCard());
                      return widgets;
                    }),
                ],
              ),
            );
          },
        ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset('assets/images/lg.png', fit: BoxFit.contain),
      ),
      title: Text('SJB Sri Lanka', style: GoogleFonts.inter(color: AppColors.primaryGreen, fontWeight: FontWeight.w800, fontSize: 18)),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 26), onPressed: () {}),
        const SizedBox(width: 4),
      ],
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
            currentAccountPicture: CircleAvatar(
              backgroundImage: userPhoto.isNotEmpty ? NetworkImage(userPhoto) : null,
              backgroundColor: AppColors.accentOrange,
              child: userPhoto.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
            ),
            decoration: const BoxDecoration(color: AppColors.primaryGreen),
          ),
          ListTile(leading: const Icon(Icons.home), title: Text('home'.tr()), onTap: () => Navigator.pop(context)),
          ExpansionTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr()),
            children: ['English', 'සිංහල', 'தமிழ்'].map((lang) => ListTile(
              title: Text(lang),
              trailing: selectedLanguage == lang ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
              onTap: () { _saveLanguage(lang); Navigator.pop(context); },
            )).toList(),
          ),
          const Divider(),
          ListTile(leading: const Icon(Icons.settings), title: Text('settings'.tr()), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: Text('logout'.tr(), style: const TextStyle(color: Colors.red)), onTap: _showLogoutDialog),
        ],
      ),
    );
  }

  Widget _buildTopNav() {
    final items = [
      {'icon': Icons.dynamic_feed_rounded,  'label': 'Feed'},
      {'icon': Icons.newspaper_rounded,      'label': 'News'},
      {'icon': Icons.volunteer_activism,     'label': 'Donate'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E6EB))),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final sel = _navIndex == i;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _navIndex = i),
              child: Container(
                decoration: sel
                    ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.primaryGreen, width: 3)))
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(items[i]['icon'] as IconData, color: sel ? AppColors.primaryGreen : AppColors.textSecondary, size: 24),
                    const SizedBox(height: 3),
                    Text(items[i]['label'] as String, style: GoogleFonts.inter(fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? AppColors.primaryGreen : AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StoriesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: _stories.map((s) => Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Column(
            children: [
              Container(
                width: 62, height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryGreen, width: 2.5),
                  image: DecorationImage(image: AssetImage(s['asset']!), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 5),
              Text(s['label']!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _PromotedCampaignCard extends StatelessWidget {
  const _PromotedCampaignCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.accentOrange.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.volunteer_activism, color: AppColors.accentOrange, size: 22),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Support Our Mission', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                  Text('Promoted Campaign',   style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
            ),
            child: Column(children: [
              Text('Empower Change', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.accentOrange)),
              const SizedBox(height: 8),
              Text('Your contribution fuels our movement for a better Sri Lanka. Join 50,000+ donors today.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF92600A), height: 1.5)),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const LinearProgressIndicator(value: 0.65, minHeight: 8, backgroundColor: Color(0xFFE5C97E), valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange)),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('65% of goal reached', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                Text('LKR 2.5M to go',      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                  child: Text('Donate Now', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Feed post;
  final String userId, userName, userPhoto;
  final PostProvider provider;
  const PostCard({super.key, required this.post, required this.userId, required this.userName, required this.userPhoto, required this.provider});
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  double _likeScale = 1.0;

  void _animateLike() {
    setState(() => _likeScale = 1.35);
    Future.delayed(const Duration(milliseconds: 150), () { if (mounted) setState(() => _likeScale = 1.0); });
  }

  void _showCommentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        post: widget.post,
        userId: widget.userId,
        userName: widget.userName,
        userPhoto: widget.userPhoto,
        provider: widget.provider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post    = widget.post;
    final isLiked = post.likes.contains(widget.userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 6),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryGreen, width: 2.5)),
                  child: CircleAvatar(
                    radius: 21,
                    backgroundImage: widget.userPhoto.isNotEmpty ? NetworkImage(widget.userPhoto) : null,
                    backgroundColor: AppColors.accentOrange,
                    child: widget.userPhoto.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(widget.userName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: AppColors.primaryGreen, size: 15),
                    ]),
                    Row(children: [
                      Text('2 hours ago', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.circle, size: 3, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                      Text('Colombo', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                  ]),
                ),
                IconButton(icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary), onPressed: () {}),
              ],
            ),
          ),

          // Image
          if (post.imageUrl.isNotEmpty)
            Image.network(
              post.imageUrl, width: double.infinity, height: 240, fit: BoxFit.cover,
              loadingBuilder: (_, child, prog) => prog == null ? child : Container(height: 240, color: const Color(0xFFF0F2F5), child: const Center(child: CircularProgressIndicator(color: AppColors.accentOrange, strokeWidth: 2))),
              errorBuilder: (_, __, ___) => Container(height: 180, color: const Color(0xFFF0F2F5), child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48))),
            ),

          // Reactions count row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Stack(children: [
                  _reactionBubble(Icons.thumb_up_rounded, AppColors.primaryGreen),
                  Positioned(left: 16, child: _reactionBubble(Icons.favorite_rounded, Colors.red)),
                ]),
                const SizedBox(width: 28),
                Text('${post.likes.length} Reactions', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ]),
              GestureDetector(
                onTap: () => _showCommentsSheet(context),
                child: Text('${post.comments.length} Comments', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ),
            ]),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F5)),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(children: [
              // Like
              Expanded(child: InkWell(
                onTap: () { _animateLike(); widget.provider.likePost(post, widget.userId); },
                borderRadius: BorderRadius.circular(8),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnimatedScale(scale: _likeScale, duration: const Duration(milliseconds: 150), child: Icon(isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined, size: 20, color: isLiked ? AppColors.primaryGreen : AppColors.textSecondary)),
                  const SizedBox(width: 6),
                  Text(isLiked ? 'Liked' : 'Like', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isLiked ? AppColors.primaryGreen : AppColors.textSecondary)),
                ])),
              )),
              // Comment
              Expanded(child: InkWell(
                onTap: () => _showCommentsSheet(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('Comment', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ])),
              )),
              // Share
              Expanded(child: InkWell(
                onTap: () {
                  final shareText = widget.post.imageUrl.isNotEmpty
                      ? 'Check out this post from SJB Sri Lanka:\n\n${widget.post.imageUrl}'
                      : 'Check out this post from SJB Sri Lanka!';
                  Share.share(shareText, subject: 'SJB Sri Lanka');
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.primaryGreen, width: 1.5), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.share_rounded, size: 15, color: AppColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text('Share', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                  ]),
                ))),
              )),
            ]),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F5)),

          // Comment input tap row
          GestureDetector(
            onTap: () => _showCommentsSheet(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(children: [
                CircleAvatar(
                  radius: 17,
                  backgroundImage: widget.userPhoto.isNotEmpty ? NetworkImage(widget.userPhoto) : null,
                  backgroundColor: AppColors.primaryGreen,
                  child: widget.userPhoto.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 16) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(24)),
                    child: Text('Join the Conversation...', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reactionBubble(IconData icon, Color color) => Container(
    width: 24, height: 24,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
    child: Icon(icon, size: 13, color: Colors.white),
  );
}

// ─── Facebook-style Comments Bottom Sheet ────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final Feed post;
  final String userId, userName, userPhoto;
  final PostProvider provider;
  const _CommentsSheet({required this.post, required this.userId, required this.userName, required this.userPhoto, required this.provider});
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.provider.addComment(widget.post, widget.userId, text);
      _ctrl.clear();
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (_) {}
    finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.post.comments;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2)),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Comments', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
                  IconButton(icon: const Icon(Icons.close, size: 22, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F2F5)),
            // Comments list
            Expanded(
              child: comments.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFFD1D5DB)),
                      const SizedBox(height: 12),
                      Text('No comments yet.\nBe the first to comment!', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
                    ]))
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: comments.length,
                      itemBuilder: (_, i) {
                        final c = comments[i];
                        final initials = (c['userId'] ?? 'A').isNotEmpty ? (c['userId'] ?? 'A')[0].toUpperCase() : 'A';
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.accentOrange.withOpacity(0.2),
                              child: Text(initials, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(18)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(c['userId'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                                  const SizedBox(height: 3),
                                  Text(c['comment'] ?? '', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
                                ]),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10, top: 4),
                                child: Text('Just now', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                              ),
                            ])),
                          ]),
                        );
                      },
                    ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F2F5)),
            // Input bar
            Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 12),
              child: Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: widget.userPhoto.isNotEmpty ? NetworkImage(widget.userPhoto) : null,
                  backgroundColor: AppColors.primaryGreen,
                  child: widget.userPhoto.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 16) : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    suffixIcon: _sending
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen)))
                        : IconButton(icon: const Icon(Icons.send_rounded, color: AppColors.primaryGreen, size: 22), onPressed: _send),
                  ),
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
