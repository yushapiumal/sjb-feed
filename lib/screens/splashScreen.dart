import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:statelink/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Locale selectedLocale = const Locale('en');

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, String>> splashScreens = [
    {
      'title': 'welcome_title',
      'description': 'welcome_desc',
      'image': 'assets/images/21.png',
    },
    // {
    //   'title': 'engage_title',
    //   'description': 'engage_desc',
    //   'image': 'assets/images/sjb2.png',
    // },
    // {
    //   'title': 'join_title',
    //   'description': 'join_desc',
    //   'image': 'assets/images/21.png',
    // },
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'si':
        return 'සිංහල';
      case 'ta':
        return 'தமிழ்';
      default:
        return 'English';
    }
  }

  void _nextPage() {
    if (_currentPage < splashScreens.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/login');
    }
  }

  void _changeLanguage(Locale locale) async {
    await context.setLocale(locale);
    setState(() {
      selectedLocale = locale;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
  }

  void _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String code = prefs.getString('languageCode') ?? 'en';
    setState(() {
      selectedLocale = Locale(code);
    });
    await context.setLocale(selectedLocale);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryGreen,
              AppColors.secondaryGreen,
              const Color(0xFF043D33),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative background circles
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentOrange.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: screenHeight * 0.3,
                left: -60,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                right: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentOrange.withOpacity(0.04),
                  ),
                ),
              ),

              // Main content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Top bar: Logo + Language
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // App logo
                            Image.asset(
                              'assets/images/lg.png',
                              width: 44,
                              height: 44,
                            ),
                            // Language pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    getLanguageName(selectedLocale),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      popupMenuTheme: PopupMenuThemeData(
                                        color: Colors.white,
                                        surfaceTintColor: Colors.white,
                                        shadowColor: Colors.black26,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                    child: PopupMenuButton<Locale>(
                                      icon: const Icon(Icons.language, color: Colors.white, size: 20),
                                      padding: EdgeInsets.zero,
                                      onSelected: _changeLanguage,
                                      itemBuilder: (BuildContext context) => const [
                                        PopupMenuItem(value: Locale('en'), child: Text('English')),
                                        PopupMenuItem(value: Locale('si'), child: Text('සිංහල')),
                                        PopupMenuItem(value: Locale('ta'), child: Text('தமிழ்')),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // PageView — vertically stacked: image on top, text below
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (int page) {
                            setState(() => _currentPage = page);
                          },
                          itemCount: splashScreens.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Image — centered and prominent
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25),
                                          blurRadius: 40,
                                          offset: const Offset(0, 16),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: Image.asset(
                                        splashScreens[index]['image']!,
                                        width: screenWidth * 0.52,
                                        height: screenWidth * 0.52,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 36),

                                  // Title
                                  Text(
                                    splashScreens[index]['title']!.tr(),
                                    style: GoogleFonts.inter(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(height: 14),

                                  // Description
                                  Text(
                                    splashScreens[index]['description']!.tr(),
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: Colors.white.withOpacity(0.75),
                                      height: 1.6,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          splashScreens.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPage == index
                                  ? AppColors.accentOrange
                                  : Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Next / Get Started Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: GestureDetector(
                          onTap: _nextPage,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.accentOrange, Color(0xFFE09800)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentOrange.withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _currentPage == splashScreens.length - 1
                                    ? 'get_started'.tr()
                                    : 'next'.tr(),
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Skip text
                      if (_currentPage < splashScreens.length - 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text(
                              "Skip",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                      SizedBox(height: _currentPage < splashScreens.length - 1 ? 24 : 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
