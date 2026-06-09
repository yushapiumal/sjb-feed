import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:statelink/api/sjb_api.dart';
import 'package:statelink/screens/logn_fb&google.dart';
import 'package:statelink/screens/registration.dart';
import 'package:statelink/screens/unitls/commonWidget.dart';
import 'package:statelink/theme/app_theme.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool isPhoneConfirmed = false;
  bool otpFieldVisible = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
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
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Clean mobile number for API (remove +94, leading 0, and non-digits)
  String _getCleanMobileNumber() {
    String clean = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (clean.startsWith('94')) {
      clean = clean.substring(2);
    } else if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }

    return clean;
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "confirm_phone".tr(),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            "confirm_phone_msg".tr(args: [_phoneController.text]),
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "edit".tr(),
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendOtp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "correct".tr(),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendOtp() async {
    setState(() => isLoading = true);

    try {
      String mobileNumber = _getCleanMobileNumber();

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📱 SEND LOGIN OTP');
      print('📤 Mobile: $mobileNumber, Country: +94');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final res = await ApiService.sendLoginOtp(mobileNumber, '+94');

      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          isPhoneConfirmed = true;
          otpFieldVisible = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('otp_sent_success'.tr())),
        );

        // Auto focus OTP field
        FocusScope.of(context).nextFocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('otp_send_failed'.tr())),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('otp_send_failed'.tr())),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _verifyOtpAndLogin() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_enter_6_digit_otp'.tr())),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String mobileNumber = _getCleanMobileNumber();

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ VERIFY LOGIN OTP');
      print('📤 Mobile: $mobileNumber, OTP: ${_otpController.text}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final res = await ApiService.verifyLoginOtp(
        mobileNumber,
        _otpController.text.trim(),
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final inner = res['data'];

        final prefs = await SharedPreferences.getInstance();

        // Save token
        if (inner?['token'] != null) {
          await prefs.setString('token', inner['token']);
        }

        // Save user data
        final user = inner?['user'];
        if (user != null) {
          await prefs.setString('member_id', user['id']?.toString() ?? '');
          await prefs.setString('mobile_number', user['mobileNumber']?.toString() ?? '');
          await prefs.setString('fname', user['fname']?.toString() ?? '');
          await prefs.setString('email', user['email']?.toString() ?? '');
          await prefs.setString('role', user['role']?.toString() ?? '');
        }

        String message = 'login_success'.tr();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        context.go('/home', extra: {'message': message});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('verification_failed'.tr()),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString().toLowerCase();
      String errorMsg = 'verification_failed'.tr();
      if (errStr.contains('invalid') || errStr.contains('otp')) {
        errorMsg = 'invalid_otp'.tr();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'si':
        return 'සිංහල';
      case 'ta':
        return 'தமிழ்';
      default:
        return 'English';
    }
  }

  void _changeLanguage(Locale locale) async {
    await context.setLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    
    // Also save under key 'language' to keep feed_new.dart updated
    String langName = 'English';
    if (locale.languageCode == 'si') {
      langName = 'සිංහල';
    } else if (locale.languageCode == 'ta') {
      langName = 'தமிழ்';
    }
    await prefs.setString('language', langName);
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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

          // Language selector
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getLanguageName(context.locale),
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
          ),

          // Decorative circles
          Positioned(
            top: -80,
            left: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentOrange.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Logo and title
          Positioned(
            top: MediaQuery.of(context).size.height * 0.12,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(80),
                    child: Image.asset(
                      "assets/images/loader.gif",
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Bottom card
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.50,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "welcome_back".tr(),
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "enter_mobile".tr(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Phone Field
                          IntlPhoneField(
                            controller: _phoneController,
                            disableLengthCheck: true,
                            initialCountryCode: 'LK',
                            enabled: !isPhoneConfirmed,
                            decoration: InputDecoration(
                              labelText: 'mobile_number'.tr(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundLight,
                            ),
                            validator: (value) {
                              if (value == null || value.number.isEmpty) {
                                return "please_enter_mobile".tr();
                              }
                              final digits = value.number.replaceAll(RegExp(r'\D'), '');
                              if (digits.length != 10) {
                                return "phone_must_be_10_digits".tr();
                              }
                              return null;
                            },
                          ),

                          if (otpFieldVisible) ...[
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'otp_code'.tr(),
                              controller: _otpController,
                              isPassword: false,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "please_enter_otp".tr();
                                }
                                if (value.length != 6) {
                                  return "otp_must_be_6_digits".tr();
                                }
                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Action Button
                          Center(
                            child: GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : (otpFieldVisible ? _verifyOtpAndLogin : _handleNext),
                              child: Container(
                                width: 220,
                                padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          otpFieldVisible ? 'verify_login'.tr() : 'next'.tr(),
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: () => context.go('/register'),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "haven't_account".tr(),
                                      style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'go_member_page'.tr(),
                                      style: GoogleFonts.inter(
                                        color: AppColors.primaryGreen,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
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