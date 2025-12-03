import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:statelink/screens/old_feed/login_1.dart';
import 'package:statelink/screens/login_id.dart';
import 'package:easy_localization/easy_localization.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Locale selectedLocale = const Locale('en');


  // 👇 Add your images here for each splash page
  final List<Map<String, String>> splashScreens = [
    {
      'title': 'welcome_title',
      'description': 'welcome_desc',
      'image': 'assets/images/21.png',
    },
    {
      'title': 'engage_title',
      'description': 'engage_desc',
      'image': 'assets/images/sjb2.png',
    },
    {
      'title': 'join_title',
      'description': 'join_desc',
      'image': 'assets/images/21.png',
    },
  ];

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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
     context.go('/login');
    }
  }

 void _changeLanguage(Locale locale) async {
  await context.setLocale(locale);

  setState(() {
    selectedLocale = locale;     // update current selected language
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/sjb_plashbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.topLeft,
                  margin: const EdgeInsets.only(top: 100),
                  child: Text(
                    splashScreens[_currentPage]['title']!.tr(),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: splashScreens.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      right: 20,
                                      top: 60,
                                    ),
                                    child: Text(
                                      splashScreens[index]['description']!.tr(),
                                      style: GoogleFonts.abel(
                                        fontSize: 18,
                                        color: Colors.black,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: MediaQuery.of(context).size.width * 0.15,
                                    right: -MediaQuery.of(context).size.width * 0.25,
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.9,
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(120),
                                            child: Image.asset(
                                              splashScreens[index]['image']!,
                                              width: MediaQuery.of(context).size.width * 0.6,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    splashScreens.length,
                    (index) => Container(
                      margin: const EdgeInsets.all(4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    SizedBox(width: 130),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 50),
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            _currentPage == splashScreens.length - 1
                                ? 'get_started'.tr()
                                : 'next'.tr(),
                            style: GoogleFonts.abel(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 50),
                        child: Image.asset(
                          'assets/images/lg.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        Positioned(
  top: 40,
  right: 20,
  child: Row(
    children: [
      Text(
        getLanguageName(selectedLocale),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(width: 6),
Theme(
  data: Theme.of(context).copyWith(
    popupMenuTheme: const PopupMenuThemeData(
      color: Colors.white,        // background color
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black26,
    ),
  ),
  child: PopupMenuButton<Locale>(
    icon: const Icon(Icons.language, color: Colors.black, size: 30),
    onSelected: _changeLanguage,
    itemBuilder: (BuildContext context) => const [
      PopupMenuItem(
        value: Locale('en'),
        child: Text('English'),
      ),
      PopupMenuItem(
        value: Locale('si'),
        child: Text('සිංහල'),
      ),
      PopupMenuItem(
        value: Locale('ta'),
        child: Text('தமிழ்'),
      ),
    ],
  ),
)

    ],
  ),
)

          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
