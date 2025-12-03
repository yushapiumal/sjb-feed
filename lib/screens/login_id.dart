import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:statelink/api/sjb_api.dart';
import 'package:statelink/screens/logn_fb&google.dart';
import 'package:statelink/screens/registration.dart';
import 'package:statelink/screens/unitls/commonWidget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _membershipIdController = TextEditingController();

Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => isLoading = true);

  final body = {'membership_id': _membershipIdController.text};

  try {
    final res = await ApiService.login(body);
    if (!mounted) return;

    bool success = res is Map && res['status'] == 'success';
    String message = (res is Map && res['message'] != null) ? res['message'].toString() : '';

    if (success) {
   context.go('/social_login', extra: message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server error')),
    );
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomSheetMinHeight = 500;
    final double loginLabelTopOffset = screenHeight - bottomSheetMinHeight - 50;
    final double logoImageAlignment = screenHeight - bottomSheetMinHeight - 200;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset('assets/images/loginbg.png', fit: BoxFit.cover),
          ),
              Positioned(
            top: logoImageAlignment,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),    
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.asset(
                      "assets/images/loader.gif",
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'login'.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: bottomSheetMinHeight),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/sjb_plashbg.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 30,
                    ),
                    // color: Colors.black.withOpacity(0.1),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 50),
                          CustomTextField(
                            label: 'membership_id'.tr(),
                            controller: _membershipIdController,
                            isPassword: false,
                            // icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your Membership ID";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 40),

                          // Next Button
                          Container(
                            width: 200,
                            alignment: Alignment.center,
                            child: CommonButton(
                              text: 'next'.tr(),
                              isLoading: isLoading,
                              backgroundColor: Colors.white,
                              textColor: const Color.fromARGB(255, 39, 116, 24),
                              borderRadius: 14,
                              height: 52,
                              onPressed: isLoading ? null : _login,
                            ),
                          ),

                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              context.go('/register');
                            },
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "haven't_account".tr(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'go_member_page'.tr(),
                                    style: GoogleFonts.poppins(
                                      color: const Color.fromARGB(
                                        255,
                                        26,
                                        104,
                                        28,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
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
}