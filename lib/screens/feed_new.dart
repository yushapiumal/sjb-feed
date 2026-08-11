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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String userToken = '';
  String userRole = '';
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

  // Dynamic Navigation & WebView Configurations
  String hostedFeedUrl = 'https://sjb-feed.onrender.com/'; // fallback default
  WebViewController? _webViewController;
  List<Map<String, dynamic>> topNavItems = [];
  List<Map<String, dynamic>> drawerItems = [];
  bool isConfigLoading = true;

  final List<Map<String, dynamic>> defaultTopNavItems = [
    {'icon': 'dynamic_feed', 'label_en': 'Feed', 'label_si': 'පුවත්', 'label_ta': 'ஊட்டம்', 'action_index': 0},
    {'icon': 'newspaper', 'label_en': 'News', 'label_si': 'පුවත්පත්', 'label_ta': 'செய்திகள்', 'action_index': 1},
    {'icon': 'volunteer_activism', 'label_en': 'Donate', 'label_si': 'ආධාර', 'label_ta': 'நன்கொடை', 'action_index': 2},
    {'icon': 'group', 'label_en': 'Community', 'label_si': 'සමූහය', 'label_ta': 'சமூகம்', 'action_index': 3},
    {'icon': 'person', 'label_en': 'Profile', 'label_si': 'ගිණුම', 'label_ta': 'சுයවිவரம்', 'action_index': 4},
  ];

  final List<Map<String, dynamic>> defaultDrawerItems = [
    {'icon': 'home', 'title_en': 'Home', 'title_si': 'මුල් පිටුව', 'title_ta': 'முகப்பு', 'action': 'home'},
    {'icon': 'refresh', 'title_en': 'Refresh Data', 'title_si': 'යාවත්කාලීන කරන්න', 'title_ta': 'தரவை புதுப்பி', 'action': 'refresh'},
    {'icon': 'language', 'title_en': 'Language', 'title_si': 'භාෂාව', 'title_ta': 'மொழி', 'action': 'language'},
    {'icon': 'settings', 'title_en': 'Settings', 'title_si': 'සැකසුම්', 'title_ta': 'அமைப்புகள்', 'action': 'settings'},
    {'icon': 'logout', 'title_en': 'Logout', 'title_si': 'පිටවීම', 'title_ta': 'வெளியேறு', 'action': 'logout'},
  ];

  IconData getIconFromString(String iconName) {
    switch (iconName) {
      case 'dynamic_feed':
        return Icons.dynamic_feed_rounded;
      case 'newspaper':
        return Icons.newspaper_rounded;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'group':
        return Icons.group;
      case 'person':
        return Icons.person_outline_rounded;
      case 'home':
        return Icons.home;
      case 'refresh':
        return Icons.refresh;
      case 'language':
        return Icons.language;
      case 'settings':
        return Icons.settings;
      case 'logout':
        return Icons.logout;
      case 'help':
        return Icons.help;
      case 'info':
        return Icons.info;
      default:
        return Icons.help_outline;
    }
  }

  String getLocalizedLabel(Map<String, dynamic> item) {
    final labelKey = item['label_key'] ?? item['title_key'];
    if (labelKey != null && labelKey.toString().isNotEmpty) {
      return labelKey.toString().tr();
    }
    final langCode = context.locale.languageCode;
    final localized = item['label_$langCode'] ?? item['title_$langCode'];
    if (localized != null && localized.toString().isNotEmpty) {
      return localized.toString();
    }
    final defaultLabel = item['label_en'] ?? item['title_en'] ?? item['label'] ?? item['title'] ?? '';
    return defaultLabel.toString();
  }

  Future<void> _fetchAppConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('navigation')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          hostedFeedUrl = data['hosted_feed_url']?.toString() ?? '';
          if (data['top_nav_items'] != null) {
            topNavItems = List<Map<String, dynamic>>.from(data['top_nav_items']);
          } else {
            topNavItems = defaultTopNavItems;
          }
          if (data['drawer_items'] != null) {
            drawerItems = List<Map<String, dynamic>>.from(data['drawer_items']);
          } else {
            drawerItems = defaultDrawerItems;
          }
          isConfigLoading = false;
        });
      } else {
        _setFallbackConfig();
      }
    } catch (e) {
      debugPrint("Error fetching app config: $e");
      _setFallbackConfig();
    }
    _initWebViewController();
  }

  void _setFallbackConfig() {
    setState(() {
      topNavItems = defaultTopNavItems;
      drawerItems = defaultDrawerItems;
      isConfigLoading = false;
    });
  }

  void _initWebViewController() {
    if (kIsWeb) return;
    if (hostedFeedUrl.isEmpty) return;
    
    String url = hostedFeedUrl;
    final langCode = context.locale.languageCode;
    final queryStr = 'userId=${Uri.encodeComponent(userId)}'
        '&userName=${Uri.encodeComponent(userName)}'
        '&userPhoto=${Uri.encodeComponent(userPhoto)}'
        '&token=${Uri.encodeComponent(userToken)}'
        '&role=${Uri.encodeComponent(userRole)}'
        '&mobile=${Uri.encodeComponent(userMobile)}'
        '&lang=$langCode';
    if (url.contains('?')) {
      url = '$url&$queryStr';
    } else {
      url = '$url?$queryStr';
    }

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF0F2F5))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint("WebView loading progress: $progress%");
          },
          onPageStarted: (String url) {
            debugPrint("WebView page started loading: $url");
          },
          onPageFinished: (String url) {
            debugPrint("WebView page finished loading: $url");
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView resource error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

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
    userToken = prefs?.getString('token') ?? '';
    userRole = prefs?.getString('role') ?? '';
    userMobile = prefs?.getString('mobile_number') ?? '';

    // Synchronize language selected in splash screen
    final langCode = prefs?.getString('languageCode');
    if (langCode != null) {
      final newLocale = Locale(langCode);
      if (context.locale != newLocale) {
        await context.setLocale(newLocale);
        selectedLanguage = langCode == 'si' ? 'සිංහල' : langCode == 'ta' ? 'தமிழ்' : 'English';
      }
    }

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
    await _fetchAppConfig();
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
        appBar: kIsWeb ? _buildAppBar() : null,
        drawer: kIsWeb ? _buildDrawer() : null,
        body: Stack(
          children: [
            Column(
              children: [
                if (kIsWeb)
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
                  child: isConfigLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentOrange,
                          ),
                        )
                      : _navIndex == 1
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
                      : kIsWeb
                          ? FeedTab(
                              userId: userId,
                              userName: userName,
                              userPhoto: userPhoto,
                              scrollController: _scrollController,
                            )
                          : _webViewController != null
                              ? SafeArea(
                                  bottom: false,
                                  child: WebViewWidget(controller: _webViewController!),
                                )
                              : const SizedBox.shrink(),
                ),
              ],
            ),
            if (kIsWeb)
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
          if (isConfigLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            )
          else
            ...drawerItems.map((item) {
              final iconName = item['icon']?.toString() ?? '';
              final action = item['action']?.toString() ?? '';
              final title = getLocalizedLabel(item);
              final iconColor = action == 'logout' ? Colors.red : AppColors.primaryGreen;
              final textColor = action == 'logout' ? Colors.red : AppColors.textPrimary;

              if (action == 'language') {
                return ExpansionTile(
                  leading: Icon(getIconFromString(iconName), color: iconColor),
                  title: Text(title, style: TextStyle(color: textColor)),
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
                );
              }

              return ListTile(
                leading: Icon(getIconFromString(iconName), color: iconColor),
                title: Text(title, style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  if (action == 'home') {
                    setState(() => _navIndex = 0);
                  } else if (action == 'refresh') {
                    _initPrefs();
                    Fluttertoast.showToast(msg: 'refresh_data'.tr());
                  } else if (action == 'logout') {
                    _showLogoutDialog();
                  } else if (action == 'settings') {
                    // Custom action for settings
                  }
                },
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTopNav() {
    if (isConfigLoading) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

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
        children: List.generate(topNavItems.length, (i) {
          final item = topNavItems[i];
          final iconName = item['icon']?.toString() ?? '';
          final label = getLocalizedLabel(item);
          final actionIndex = item['action_index'] as int? ?? i;
          
          final sel = _navIndex == actionIndex;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (actionIndex == 3) {
                  // Push RegistrationForm and only call _initPrefs() when result is true
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegistrationForm(
                        registeredByUserId: userId == 'guest' ? null : userId,
                      ),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _initPrefs();
                    }
                  });
                } else {
                  setState(() => _navIndex = actionIndex);
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
                      getIconFromString(iconName),
                      color: sel
                          ? AppColors.primaryGreen
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
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

