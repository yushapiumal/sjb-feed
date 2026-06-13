import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:statelink/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhoto;
  final String userNic;
  final String userAddress;
  final String userDistrict;
  final String userGender;
  final String userBirthday;
  final String userElectorate;
  final String userGnd;
  final String userMobile;
  final String userWmobile;
  final String selectedLanguage;
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhoto,
    required this.userNic,
    required this.userAddress,
    required this.userDistrict,
    required this.userGender,
    required this.userBirthday,
    required this.userElectorate,
    required this.userGnd,
    required this.userMobile,
    required this.userWmobile,
    required this.selectedLanguage,
    required this.onLogout,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showQr = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryGreen, AppColors.secondaryGreen],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 60),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 43,
                    backgroundImage: widget.userPhoto.isNotEmpty
                        ? NetworkImage(widget.userPhoto)
                        : null,
                    backgroundColor: AppColors.accentOrange,
                    child: widget.userPhoto.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 46,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.userName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.userEmail,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Member ID card
          GestureDetector(
            onTap: () => setState(() => _showQr = !_showQr),
            child: Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.badge_outlined,
                            color: AppColors.accentOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'member_qr_id'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _showQr ? 'tap_to_hide'.tr() : 'tap_to_show'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          turns: _showQr ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primaryGreen,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                    // ✅ Animated expand/collapse
                    AnimatedCrossFade(
                      firstChild: const SizedBox(width: double.infinity),
                      secondChild: Column(
                        children: [
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 10),
                          Text(
                            'your_qr_code'.tr(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 15),
                          QrImageView(
                            data: widget.userId,
                            version: QrVersions.auto,
                            size: 150.0,
                            foregroundColor: AppColors.primaryGreen,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                      crossFadeState: _showQr
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                      sizeCurve: Curves.easeInOut,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Info tiles
          Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _profileTile(
                    Icons.person_outline_rounded,
                    'full_name'.tr(),
                    widget.userName,
                  ),
                  _profileTile(
                    Icons.badge_outlined,
                    'nic_number'.tr(),
                    widget.userNic.isNotEmpty ? widget.userNic : '—',
                  ),
                  _profileTile(
                    Icons.home_outlined,
                    'address'.tr(),
                    widget.userAddress.isNotEmpty ? widget.userAddress : '—',
                  ),
                  _profileTile(
                    Icons.location_on_outlined,
                    'district'.tr(),
                    widget.userDistrict.isNotEmpty ? widget.userDistrict : '—',
                  ),
                  _profileTile(
                    Icons.wc_rounded,
                    'gender'.tr(),
                    widget.userGender.isNotEmpty ? widget.userGender : '—',
                  ),
                  _profileTile(
                    Icons.cake_outlined,
                    'birthday'.tr(),
                    widget.userBirthday.isNotEmpty ? widget.userBirthday : '—',
                  ),
                  _profileTile(
                    Icons.how_to_vote_outlined,
                    'electoral_division'.tr(),
                    widget.userElectorate.isNotEmpty ? widget.userElectorate : '—',
                  ),
                  _profileTile(
                    Icons.location_city_outlined,
                    'grama_niladhari_division'.tr(),
                    widget.userGnd.isNotEmpty ? widget.userGnd : '—',
                  ),
                  _profileTile(
                    Icons.phone_android_outlined,
                    'mobile_number'.tr(),
                    widget.userMobile.isNotEmpty ? widget.userMobile : '—',
                  ),
                  _profileTile(
                    Icons.chat_outlined,
                    'whatsapp_number'.tr(),
                    widget.userWmobile.isNotEmpty ? widget.userWmobile : '—',
                  ),
                  _profileTile(
                    Icons.email_outlined,
                    'email_address'.tr(),
                    widget.userEmail.isNotEmpty ? widget.userEmail : '—',
                  ),
                  _profileTile(
                    Icons.language_outlined,
                    'language'.tr(),
                    widget.selectedLanguage,
                  ),
                ],
              ),
            ),
          ),
          // Logout button
          Transform.translate(
            offset: const Offset(0, -16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                  label: Text(
                    'logout'.tr(),
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _profileTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primaryGreen,
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  softWrap: true,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
