import 'dart:convert';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'package:statelink/screens/feed_new.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SocialLoginPage extends StatefulWidget {
  final String message;

  const SocialLoginPage({super.key, required this.message});

  @override
  State<SocialLoginPage> createState() => _SocialLoginPageState();
}

class _SocialLoginPageState extends State<SocialLoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
  );

  User? _firebaseUser;
  Map<String, dynamic>? _googleUserData;
  Map<String, dynamic>? _fbUserData;
  bool _isLoading = false;
  bool _checkingLogin = true;

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
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

      print("📌 GOOGLE FULL DATA: $data");

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
    // Login with Facebook
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: [
        'email',
        'public_profile',
      ],
    );

    if (result.status == LoginStatus.success) {
      // Get user data
      final fbData = await FacebookAuth.instance.getUserData(
        fields: "id,name,email,picture.width(600)",
      );

      print("📌 FACEBOOK FULL DATA: $fbData");

      setState(() {
        _fbUserData = fbData;
        _googleUserData = null; // if you have Google login
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
      print("Facebook Login Error: ${result.message}");
      _showSnack("Facebook login error: ${result.message ?? 'Unknown error'}");
    }
  } catch (e) {
    print("Facebook Login Failed (Exception): $e");
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.green)
            : (_firebaseUser == null ? _buildLoginUI() : _buildProfile()),
      ),
    );
  }
  Widget _buildLoginUI() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset('assets/images/loginbg.png', fit: BoxFit.cover),
          ),

          // Bottom Glass Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 600,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/sjb_plashbg.png'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.only(topRight: Radius.circular(60)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(60),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

                          // TITLE
                          const Text(
                            "Get Started",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 39, 116, 24),
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            "Join us as we work towards a smarter, fairer, and more connected Sri Lanka.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // GOOGLE BUTTON
                          _socialButton(
                            onTap: _signInWithGoogle,
                            icon: 'assets/images/google.webp',
                            text: 'Sign in with Google',
                            color: Colors.white,
                            textColor: Color.fromARGB(255, 39, 116, 24),
                            padding: 20,
                          ),

                          const SizedBox(height: 20),

                          // FACEBOOK BUTTON
                          _socialButton(
                            onTap: _signInWithFacebook,
                            icon: 'assets/images/fb.png',
                            text: 'Sign in with Facebook',
                            color: Colors.white,
                            textColor: Color.fromARGB(255, 39, 116, 24),
                            padding: 8,
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
    required Color color,
    required Color textColor,
    required double padding,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          minimumSize: const Size(double.infinity, 55),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(right: padding),
              child: Image.asset(icon, height: 25),
            ),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

    if (picture is Map &&
        picture["data"] != null &&
        picture["data"]["url"] != null) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(radius: 60, backgroundImage: NetworkImage(photoUrl)),
          const SizedBox(height: 20),

          Text(
            data["name"] ?? _firebaseUser?.displayName ?? "User",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),
          Text(
            data["email"] ?? _firebaseUser?.email ?? "",
            style: const TextStyle(fontSize: 16),
          ),

          if (data["gender"] != null) ...[
            const SizedBox(height: 10),
            Text("Gender: ${data["gender"]}"),
          ],

          if (data["birthday"] != null) ...[
            const SizedBox(height: 10),
            Text("Birthday: ${data["birthday"]}"),
          ],

          if (locationName != null) ...[
            const SizedBox(height: 10),
            Text("Location: $locationName"),
          ],

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () async {
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
              print("🚀 USER DATA TO PASS: $userData");

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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(200, 48),
            ),
            child: const Text(
              "go to Feed Screen",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}