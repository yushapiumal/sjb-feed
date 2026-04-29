import 'dart:convert';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:statelink/screens/feed_new.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:statelink/theme/app_theme.dart';

class SocialLoginPage extends StatefulWidget {
  final String message;

  const SocialLoginPage({super.key, required this.message});

  @override
  State<SocialLoginPage> createState() => _SocialLoginPageState();
}

class _SocialLoginPageState extends State<SocialLoginPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '912364213375-3bv7e3tng3aket5umnr7q6qnboajqds9.apps.googleusercontent.com',
    scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
  );

  User? _firebaseUser;
  Map<String, dynamic>? _googleUserData;
  Map<String, dynamic>? _fbUserData;
  bool _isLoading = false;
  bool _checkingLogin = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final logged = prefs.getBool('is_logged_in') ?? false;
    if (logged) {
      final userJson = prefs.getString('user_data');
      Map<String, dynamic> userData = {};
      if (userJson != null) {
        try {
          userData = jsonDecode(userJson) as Map<String, dynamic>;
        } catch (_) {}
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home', extra: userData);
      });
      return;
    }
    if (mounted) {
      setState(() {
        _checkingLogin = false;
      });
    }
  }

  Future<void> _saveUserToPrefs(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_data', jsonEncode(userData));
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _showSnack("Google sign-in cancelled");
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final url = Uri.parse(
        "https://www.googleapis.com/oauth2/v2/userinfo?access_token=${googleAuth.accessToken}",
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      setState(() {
        _firebaseUser = userCredential.user;
        _googleUserData = data;
        _fbUserData = null;
      });

      _showSnack("Signed in with Google");

      final Map<String, dynamic> userData = {
        "firebaseUid": _firebaseUser?.uid,
        "name": data["name"] ?? _firebaseUser?.displayName,
        "email": data["email"] ?? _firebaseUser?.email,
        "photoUrl": data["picture"] ?? _firebaseUser?.photoURL,
        "googleData": _googleUserData,
        "facebookData": _fbUserData,
      };

      await _saveUserToPrefs(userData);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home', extra: userData);
      });
    } catch (e) {
      _showSnack("Google login failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final fbData = await FacebookAuth.instance.getUserData(
          fields: "id,name,email,picture.width(600)",
        );

        setState(() {
          _fbUserData = fbData;
          _googleUserData = null;
        });

        _showSnack("Signed in with Facebook");

        final String? photoUrl = (fbData["picture"] is Map &&
                fbData["picture"]["data"] != null &&
                fbData["picture"]["data"]["url"] != null)
            ? fbData["picture"]["data"]["url"]
            : null;

        final Map<String, dynamic> userData = {
          "name": fbData["name"],
          "email": fbData["email"],
          "photoUrl": photoUrl,
          "facebookData": _fbUserData,
          "googleData": _googleUserData,
        };
        await _saveUserToPrefs(userData);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/home', extra: userData);
        });
      } else if (result.status == LoginStatus.cancelled) {
        _showSnack("Facebook login cancelled");
      } else {
        _showSnack("Facebook login error: ${result.message ?? 'Unknown error'}");
      }
    } catch (e) {
      _showSnack("Facebook login failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLogin) {
      return Scaffold(
        backgroundColor: AppColors.primaryGreen,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accentOrange),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: _isLoading
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primaryGreen, const Color(0xFF043D33)],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.accentOrange),
                ),
              )
            : (_firebaseUser == null ? _buildLoginUI() : _buildProfile()),
      ),
    );
  }

  Widget _buildLoginUI() {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryGreen,
                  AppColors.secondaryGreen,
                  const Color(0xFF043D33),
                ],
              ),
            ),
          ),

          // Decorative elements
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentOrange.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // Gift animation in upper area
          Positioned(
            top: MediaQuery.of(context).size.height * 0.12,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: Image.asset(
                  "assets/images/loader.gif",
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Bottom login card
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Title
                          Text(
                            "Get Started",
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryGreen,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "Join us as we work towards a smarter, fairer, and more connected Sri Lanka.",
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Google Button
                          _socialButton(
                            onTap: _signInWithGoogle,
                            icon: 'assets/images/google.webp',
                            text: 'Sign in with Google',
                            bgColor: Colors.white,
                            textColor: AppColors.textPrimary,
                            borderColor: const Color(0xFFE4E6EB),
                            iconPadding: 16,
                          ),

                          const SizedBox(height: 16),

                          // Facebook Button
                          _socialButton(
                            onTap: _signInWithFacebook,
                            icon: 'assets/images/fb.png',
                            text: 'Sign in with Facebook',
                            bgColor: const Color(0xFF1877F2),
                            textColor: Colors.white,
                            borderColor: const Color(0xFF1877F2),
                            iconPadding: 8,
                          ),

                          const SizedBox(height: 24),

                          // Divider with text
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "or",
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Center(
                            child: Text(
                              "Continue with your social account\nto access the feed",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton({
    required VoidCallback onTap,
    required String icon,
    required String text,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
    required double iconPadding,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(right: iconPadding),
              child: Image.asset(icon, height: 24),
            ),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final data = _googleUserData ?? _fbUserData ?? {};

    final dynamic picture = data["picture"];

    String photoUrl;

    if (picture is Map && picture["data"] != null && picture["data"]["url"] != null) {
      photoUrl = picture["data"]["url"];
    } else if (picture is String) {
      photoUrl = picture;
    } else {
      photoUrl = _firebaseUser?.photoURL ?? "https://via.placeholder.com/150";
    }

    String? locationName;
    if (data["location"] != null) {
      if (data["location"] is Map && data["location"]["name"] != null) {
        locationName = data["location"]["name"];
      } else if (data["location"] is String) {
        locationName = data["location"];
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryGreen,
              AppColors.secondaryGreen,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accentOrange, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: NetworkImage(photoUrl),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    data["name"] ?? _firebaseUser?.displayName ?? "User",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    data["email"] ?? _firebaseUser?.email ?? "",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),

                  if (data["gender"] != null) ...[
                    const SizedBox(height: 8),
                    Text("Gender: ${data["gender"]}", style: TextStyle(color: Colors.white70)),
                  ],

                  if (data["birthday"] != null) ...[
                    const SizedBox(height: 8),
                    Text("Birthday: ${data["birthday"]}", style: TextStyle(color: Colors.white70)),
                  ],

                  if (locationName != null) ...[
                    const SizedBox(height: 8),
                    Text("Location: $locationName", style: TextStyle(color: Colors.white70)),
                  ],

                  const SizedBox(height: 36),

                  // Go to Feed Button
                  GestureDetector(
                    onTap: () async {
                      final Map<String, dynamic> userData = {
                        "firebaseUid": _firebaseUser?.uid,
                        "name": data["name"] ?? _firebaseUser?.displayName,
                        "email": data["email"] ?? _firebaseUser?.email,
                        "photoUrl": photoUrl,
                        "gender": data["gender"],
                        "birthday": data["birthday"],
                        "location": locationName,
                        "googleData": _googleUserData,
                        "facebookData": _fbUserData,
                      };

                      setState(() => _isLoading = true);
                      try {
                        await _saveUserToPrefs(userData);
                        if (!mounted) return;
                        context.go('/home', extra: userData);
                      } catch (e) {
                        _showSnack("Failed to proceed: $e");
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    child: Container(
                      width: 240,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accentOrange, Color(0xFFE09800)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentOrange.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "Go to Feed",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}