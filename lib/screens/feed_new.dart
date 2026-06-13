import 'dart:async';
import 'dart:convert';
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
import 'package:statelink/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:statelink/api/sjb_api.dart';
import 'package:statelink/screens/news_page.dart';
import 'package:statelink/screens/notifications_page.dart';
import 'package:statelink/screens/donate_page.dart';
import 'package:statelink/screens/registration.dart';

import 'package:statelink/services/toast_util.dart';

import 'package:statelink/screens/feed_tab.dart';
import 'package:statelink/screens/profile_page.dart';

class FeedScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const FeedScreen({super.key, required this.userData});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late String userName = 'Guest User';
  String userEmail = '';
  String userPhoto = '';
  String userId = 'guest';
  String userNic = '';
  String userAddress = '';
  String userDistrict = '';
  String userGender = '';
  String userBirthday = '';
  String userInstitution = '';
  String userElectorate = '';
  String userGnd = '';
  String userMobile = '';
  String userWmobile = '';
  String userSocialFb = '';
  String userSocialX = '';
  String userContribute = '';
  String userReferrer = '';
  String userCandidate = '';
  String selectedLanguage = 'English';
  SharedPreferences? prefs;
  int _navIndex = 0;
  bool _navVisible = true;
  double _lastScrollOffset = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    userName = widget.userData['name'] ?? 'User';
    userEmail = widget.userData['email'] ?? '';
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
    // ✅ FIX: Always read the logged-in organizer's member_id from prefs first
    // and do NOT overwrite it with any newly registered member's data.
    userId = prefs?.getString('member_id') ?? 'guest';
    selectedLanguage = prefs?.getString('language') ?? 'English';

    try {
      final memberId = prefs?.getString('member_id');
      final token = prefs?.getString('token');

      if (memberId != null && memberId != 'guest') {
        // Use the Member ID Based API to load the logged-in user's profile
        final profileData = await ApiService.getUserMemberData(memberId);
        final profile = profileData['user'];

        if (profile != null) {
          setState(() {
            userNic = profile['nic'] ?? '';
            userAddress = profile['address'] ?? '';
            userDistrict = profile['district'] ?? '';
            userGender = profile['gender'] ?? '';
            userBirthday = profile['bd'] ?? '';
            userInstitution = profile['lginstitution'] ?? '';
            userElectorate = profile['electorate'] ?? '';
            userGnd = profile['gnDivision'] ?? '';
            userMobile = profile['mobile'] ?? '';
            userWmobile = profile['wmobile'] ?? '';
            userEmail = profile['email'] ?? '';
            userName = profile['fname'] ?? 'Guest User';

            if (profile['social'] != null) {
              userSocialFb = profile['social']['fb'] ?? '';
              userSocialX = profile['social']['x'] ?? '';
            }
            userContribute = profile['contribute'] ?? '';
            userReferrer = profile['referrer'] ?? '';
            userCandidate = profile['candidate']?.toString() ?? 'false';
          });

          // ✅ FIX: Only save the logged-in user's own data back to prefs.
          // This must NOT be called after registering another member.
          await prefs?.setString('fname', userName);
          await prefs?.setString('email', userEmail);
          await prefs?.setString('user_data', json.encode(profile));
        }
      } else if (token != null && token.isNotEmpty) {
        // Fallback to legacy profile if token exists but memberId is guest
        final profile = await ApiService.getUserProfile();
        final user = profile['user'];
        if (user != null) {
          setState(() {
            userName = user['fname'] ?? userName;
            userEmail = user['email'] ?? userEmail;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      ToastUtil.showError('failed_to_load_profile'.tr());
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveLanguage(String lang) async {
    await prefs?.setString('language', lang);
    Locale newLocale = lang == 'සිංහල'
        ? const Locale('si')
        : lang == 'தமிழ்'
        ? const Locale('ta')
        : const Locale('en');
    await context.setLocale(newLocale);
    if (mounted) setState(() => selectedLanguage = lang);
    Fluttertoast.showToast(msg: 'Language changed to $lang');
  }

  Future<void> _logoutUser() async {
    await prefs?.clear();
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logoutUser();
            },
            child: Text(
              'logout'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final exit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Exit App',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: const Text('Do you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (exit == true && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: _buildAppBar(),
        drawer: _buildDrawer(),
        body: Stack(
          children: [
            Column(
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
                  child: _navIndex == 1
                      ? const NewsPage()
                      : _navIndex == 2
                      ? const DonatePage()
                      : _navIndex == 3
                      ? RegistrationForm(registeredByUserId: userId)
                      : _navIndex == 4
                      ? ProfilePage(
                          userId: userId,
                          userName: userName,
                          userEmail: userEmail,
                          userPhoto: userPhoto,
                          userNic: userNic,
                          userAddress: userAddress,
                          userDistrict: userDistrict,
                          userGender: userGender,
                          userBirthday: userBirthday,
                          userElectorate: userElectorate,
                          userGnd: userGnd,
                          userMobile: userMobile,
                          userWmobile: userWmobile,
                          selectedLanguage: selectedLanguage,
                          onLogout: _showLogoutDialog,
                        )
                      : FeedTab(
                          userId: userId,
                          userName: userName,
                          userPhoto: userPhoto,
                          scrollController: _scrollController,
                        ),
                ),
              ],
            ),
            // Centered Arrow Tab to Open Drawer
            Positioned(
              left: 0,
              top: MediaQuery.of(context).size.height * 0.45,
              child: GestureDetector(
                onTap: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                child: Container(
                  width: 28,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(2, 2),
                      ),
                    ],
                    border: Border(
                      top: BorderSide(color: AppColors.primaryGreen.withOpacity(0.2), width: 1.5),
                      right: BorderSide(color: AppColors.primaryGreen.withOpacity(0.2), width: 1.5),
                      bottom: BorderSide(color: AppColors.primaryGreen.withOpacity(0.2), width: 1.5),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primaryGreen,
                      size: 22,
                    ),
                  ),
                ),
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
      title: Text(
        'sjb_feed_lanka'.tr(),
        style: GoogleFonts.inter(
          color: AppColors.primaryGreen,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textPrimary,
            size: 26,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ),
        ),
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
            accountName: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundImage: userPhoto.isNotEmpty
                  ? NetworkImage(userPhoto)
                  : null,
              backgroundColor: AppColors.accentOrange,
              child: userPhoto.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            decoration: const BoxDecoration(color: AppColors.primaryGreen),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text('home'.tr()),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: AppColors.primaryGreen),
            title: Text('refresh_data'.tr()),
            onTap: () {
              Navigator.pop(context);
              _initPrefs();
              Fluttertoast.showToast(msg: 'refresh_data'.tr());
            },
          ),
          ExpansionTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr()),
            children: ['English', 'සිංහල', 'தமிழ்']
                .map(
                  (lang) => ListTile(
                    title: Text(lang),
                    trailing: selectedLanguage == lang
                        ? const Icon(Icons.check, color: AppColors.primaryGreen)
                        : null,
                    onTap: () {
                      _saveLanguage(lang);
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text('settings'.tr()),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              'logout'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildTopNav() {
    final items = [
      {'icon': Icons.dynamic_feed_rounded, 'label':'feed'.tr()},
      {'icon': Icons.newspaper_rounded, 'label': 'news'.tr()},
      {'icon': Icons.volunteer_activism, 'label': 'donate'.tr()},
      {'icon': Icons.group, 'label': 'community'.tr()},
      {'icon': Icons.person_outline_rounded, 'label': 'profile'.tr()},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E6EB))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final sel = _navIndex == i;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (i == 3) {
                  // ✅ FIX: Push RegistrationForm and only call _initPrefs()
                  // when the result is `true` (member was successfully registered).
                  // This prevents the organizer's own profile from being
                  // overwritten with the newly registered member's token/data.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegistrationForm(
                        registeredByUserId: userId == 'guest' ? null : userId,
                      ),
                    ),
                  ).then((result) {
                    // result == true means a new member was successfully registered
                    if (result == true) {
                      _initPrefs();
                    }
                  });
                } else {
                  setState(() => _navIndex = i);
                }
              },
              child: Container(
                decoration: sel
                    ? const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primaryGreen,
                            width: 3,
                          ),
                        ),
                      )
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i]['icon'] as IconData,
                      color: sel
                          ? AppColors.primaryGreen
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i]['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel
                            ? AppColors.primaryGreen
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVerificationFlag() {
    if (prefs == null) {
      return const SizedBox.shrink();
    }
    final userDataJson = prefs!.getString('user_data');
    bool isSocial = false;
    if (userDataJson != null) {
      try {
        final decoded = json.decode(userDataJson);
        if (decoded['googleData'] != null || decoded['facebookData'] != null) {
          isSocial = true;
        }
      } catch (e) {
        debugPrint('Error decoding user_data: $e');
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSocial ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isSocial ? 'Verified' : 'Not Verified',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

