import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:statelink/api/sjb_api.dart';
import 'package:statelink/screens/login_id.dart';
import 'package:statelink/screens/unitls/text_util.dart';
import 'package:statelink/screens/unitls/commonWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:statelink/theme/app_theme.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:statelink/services/toast_util.dart';

class RegistrationForm extends StatefulWidget {
  /// When non-null, this registration was initiated by a logged-in member.
  /// The value is their member_id. A location checkbox will be shown only in this case.
  final String? registeredByUserId;

  const RegistrationForm({super.key, this.registeredByUserId});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;
  bool isLoading = false;
  bool isRegistering = false;
  bool _isCheckingUser = false;

  bool agreeTerms = false;
  bool agreeConditions = false;

  // ── Step 0 state ──────────────────────────────────────────────────────────────
  bool _otpSentToWa = false;
  bool _isVerifyingOtp = false;
  final TextEditingController _step0OtpController = TextEditingController();
  String? _nicErrorStep0;
  String? _waErrorStep0;
  String? _otpErrorStep0;
  String _verifiedWaOtp = '';
  String _verifiedWaOtpToken = '';

  // ── Location (only used when registeredByUserId != null) ──────────────────
  bool _useLocation = false;
  bool _fetchingLocation = false;
  double? _latitude;
  double? _longitude;
  String? _locationError;

  // ── WhatsApp country code (captured from IntlPhoneField) ──────────────────
  String _whatsappCountryCode = '+94';

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _whatsAppController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _connectController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();

  // Dropdown values
  String? _selectedDay;
  String? _selectedMonth;
  String? _selectedYear;
  DateTime? _selectedBirthday;
  String? _selectedDistrict;
  String? _selectedDsDivision;
  String? _selectedElectoralDivision;
  String? _selectedGramaNiladhari;

  // Raw membership API data (localized)
  List<Map<String, dynamic>> _electoratesRaw = [];
  List<Map<String, dynamic>> _dsDivisionsRaw = [];
  List<Map<String, dynamic>> _gnsRaw = [];

  // Dropdown items
  List<String> districts = [];
  List<String> dsDivisions = [];
  List<String> electoralDivisions = [];
  List<String> gramaNiladhariDivisions = [];

  String _langKey() {
    final code = context.locale.languageCode.toLowerCase();
    if (code == 'si' || code == 'ta' || code == 'en') return code;
    return 'en';
  }

  String _pickLocalizedName(Map<String, dynamic> item) {
    final key = _langKey();
    final v = item[key] ?? item['en'] ?? item.values.first;
    return (v ?? '').toString();
  }

  // ── Location helpers ───────────────────────────────────────────────────────

  Future<void> _fetchLocation() async {
    setState(() {
      _fetchingLocation = true;
      _locationError = null;
      _latitude = null;
      _longitude = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationError = 'location_services_disabled'.tr());
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationError = 'location_permission_denied'.tr());
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(
          () => _locationError = 'location_permission_denied_forever'.tr(),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    } catch (e) {
      setState(
        () => _locationError = 'failed_get_location'.tr(args: [e.toString()]),
      );
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  // ── Dropdown fetch helpers ─────────────────────────────────────────────────

  Future<void> _fetchDropdownData() async {
    debugPrint('[Registration] Fetching districts...');
    setState(() => isLoading = true);
    try {
      final fetched = await ApiService.getDistricts();
      debugPrint('[Registration] Districts fetched: ${fetched.length}');
      setState(() {
        districts = fetched;
        dsDivisions = [];
        electoralDivisions = [];
        gramaNiladhariDivisions = [];
        _electoratesRaw = [];
        _dsDivisionsRaw = [];
        _gnsRaw = [];
        _selectedDistrict = null;
        _selectedDsDivision = null;
        _selectedElectoralDivision = null;
        _selectedGramaNiladhari = null;
      });
    } catch (e) {
      debugPrint('[Registration] Failed to fetch districts: $e');
      ToastUtil.showError('failed_load_dropdown'.tr(args: ['Districts']));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchDsDivisions(String district) async {
    if (district.isEmpty) {
      setState(() {
        dsDivisions = [];
        _selectedDsDivision = null;
        _dsDivisionsRaw = [];
        gramaNiladhariDivisions = [];
        _selectedGramaNiladhari = null;
        _gnsRaw = [];
      });
      return;
    }

    debugPrint('[Registration] Fetching DS divisions for district: $district');
    setState(() => isLoading = true);
    try {
      final fetched = await ApiService.getDsDivisions(district);
      debugPrint('[Registration] DS divisions fetched: ${fetched.length}');
      setState(() {
        _dsDivisionsRaw = fetched;
        dsDivisions = fetched.map(_pickLocalizedName).toList();
        _selectedDsDivision = null;
        gramaNiladhariDivisions = [];
        _selectedGramaNiladhari = null;
        _gnsRaw = [];
      });
    } catch (e) {
      debugPrint('[Registration] Failed to fetch DS divisions: $e');
      ToastUtil.showError('failed_load_dropdown'.tr(args: ['DS Divisions']));
      setState(() {
        dsDivisions = [];
        _selectedDsDivision = null;
        _dsDivisionsRaw = [];
        gramaNiladhariDivisions = [];
        _selectedGramaNiladhari = null;
        _gnsRaw = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchElectoralDivisions(String district) async {
    if (district.isEmpty) {
      setState(() {
        electoralDivisions = [];
        _selectedElectoralDivision = null;
        _electoratesRaw = [];
      });
      return;
    }

    debugPrint('[Registration] Fetching electorates for district: $district');
    setState(() => isLoading = true);
    try {
      final fetched = await ApiService.getElectorates(district);
      debugPrint('[Registration] Electorates fetched: ${fetched.length}');
      setState(() {
        _electoratesRaw = fetched;
        electoralDivisions = fetched.map(_pickLocalizedName).toList();
        _selectedElectoralDivision = null;
      });
    } catch (e) {
      debugPrint('[Registration] Failed to fetch electorates: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('failed_load_dropdown'.tr(args: ['Electorates'])),
        ),
      );
      setState(() {
        electoralDivisions = [];
        _selectedElectoralDivision = null;
        _electoratesRaw = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchGNDivisions(String division) async {
    if (division.isEmpty) {
      setState(() {
        gramaNiladhariDivisions = [];
        _gnsRaw = [];
      });
      return;
    }

    final raw = _dsDivisionsRaw.firstWhere(
      (m) => _pickLocalizedName(m) == division,
      orElse: () => const <String, dynamic>{},
    );
    final dsNameForApi = (raw['en'] ?? division).toString();

    debugPrint(
      '[Registration] Fetching GN divisions for division: $division (api dsName: $dsNameForApi)',
    );
    setState(() => isLoading = true);
    try {
      final fetched =
          await ApiService.getGNDivisionsByElectorate(dsNameForApi);
      debugPrint('[Registration] GN divisions fetched: ${fetched.length}');
      setState(() {
        _gnsRaw = fetched;
        gramaNiladhariDivisions = fetched
            .map((m) => (m['GN_Name'] ?? m['gn_name'] ?? '').toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
      });
    } catch (e) {
      debugPrint('[Registration] Failed to fetch GN divisions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'failed_load_dropdown'.tr(args: ['Grama Niladhari Divisions']),
          ),
        ),
      );
      setState(() {
        gramaNiladhariDivisions = [];
        _gnsRaw = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ── OTP flow (Step 2 mobile OTP) ───────────────────────────────────────────

  Future<void> _onRegisterPressed() async {
    if (!_formKey.currentState!.validate()) return;

    if (!agreeTerms) {
      setState(
        () => agreeTermsError = 'agree_terms_error'.tr(),
      );
      return;
    }

    setState(() {
      _dayError = _selectedDay == null ? 'please_select_date'.tr() : null;
      _monthError = _selectedMonth == null ? 'please_select_date'.tr() : null;
      _yearError = _selectedYear == null ? 'please_select_date'.tr() : null;
      _districError =
          _selectedDistrict == null ? 'please_select_district'.tr() : null;
      _dsError =
          _selectedDsDivision == null ? 'please_select_ds'.tr() : null;
      _rdError = _selectedElectoralDivision == null
          ? 'please_select_electoral'.tr()
          : null;
      _gnError =
          _selectedGramaNiladhari == null ? 'please_select_gn'.tr() : null;
    });

    if (_dayError != null ||
        _monthError != null ||
        _yearError != null ||
        _districError != null ||
        _dsError != null ||
        _rdError != null ||
        _gnError != null) {
      ToastUtil.showError('fill_all_fields'.tr());
      return;
    }

    // Validate location when registering another member and checkbox is ticked
    if (widget.registeredByUserId != null &&
        _useLocation &&
        _latitude == null) {
      ToastUtil.showError('wait_location'.tr());
      return;
    }

    String mobileNumber = _mobileController.text.replaceAll('-', '');

    if (mobileNumber.isEmpty) {
      ToastUtil.showError('please_enter_mobile'.tr());
      return;
    }

    if (mobileNumber.length != 10) {
      ToastUtil.showError('phone_must_be_10_digits'.tr());
      return;
    }

    if (_verifiedWaOtp.length != 6) {
      ToastUtil.showError('please_enter_otp'.tr());
      return;
    }

    await _submitRegistrationWithOtp(_verifiedWaOtp);
  }

  Future<void> _submitRegistrationWithOtp(String otp) async {
    if (otp.length != 6) {
      ToastUtil.showError('enter_valid_6_digit_otp'.tr());
      return;
    }

    setState(() => isRegistering = true);

    final prefs = await SharedPreferences.getInstance();
    final savedNic = prefs.getString('saved_nic') ?? _nicController.text.trim();

    String formattedBirthday =
        '${_selectedDay!.padLeft(2, '0')}/${_selectedMonth!.padLeft(2, '0')}/$_selectedYear';

    String mobileNumber = _mobileController.text.replaceAll('-', '');
    String whatsappNumber = _whatsAppController.text.replaceAll('-', '');

    final body = <String, dynamic>{
      'verifiedToken': _verifiedWaOtpToken,
      'fname': _firstNameController.text.trim(),
      'lname': _lastNameController.text.trim(),
      'bd': formattedBirthday,
      'address': _addressController.text.trim(),
      'district': _selectedDistrict,
      'electorate': _selectedElectoralDivision,
      'dsDivision': _selectedDsDivision,
      'gnDivision': _selectedGramaNiladhari,
      'wmobile': whatsappNumber,
      'mobile': mobileNumber,
      'nic': savedNic,
      'email': _emailController.text.trim(),
      'fb': 'Facebook Profile not provided',
      'x': 'X handle not provided',
      'contribute': _connectController.text.isNotEmpty
          ? _connectController.text
          : 'No contribution details provided',
      'terms_conditions': agreeTerms ? 'membership_terms_text'.tr() : '',
      'email_updates': '',
      'lang': _langKey(),
      'referrer': '',
      'candidate': 'false',
    };

    if (widget.registeredByUserId != null) {
      body['registeredBy'] = widget.registeredByUserId;
      if (_useLocation && _latitude != null && _longitude != null) {
        body['latitude'] = _latitude.toString();
        body['longitude'] = _longitude.toString();
      }
    }

    try {
      final res = await ApiService.registerMember(body);

      if (res['status'] == 'success') {
        final token = res['data']?['token'];
        final user = res['data']?['user'];

        // Only save token when SELF registering
        if (widget.registeredByUserId == null && token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          if (user != null && user['id'] != null) {
            await prefs.setString('member_id', user['id'].toString());
          }
        }

        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_done,
                        size: 64, color: AppColors.primaryGreen),
                    const SizedBox(height: 12),
                    Text('registration_successful'.tr(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                        'thanks_joining'
                            .tr(args: [user?['id']?.toString() ?? 'N/A']),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (widget.registeredByUserId != null) {
                          Navigator.of(context).pop(true);
                        } else {
                          context.go('/home');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen),
                      child: Text('ok'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          final isAlready = res['message'].toString().toLowerCase().contains('already');
          ToastUtil.showError(
              isAlready ? 'registration_already'.tr() : 'registration_failed'.tr());
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError('registration_failed'.tr());
      }
    } finally {
      if (mounted) setState(() => isRegistering = false);
    }
  }

  // ── Validation helpers ─────────────────────────────────────────────────────

  final List<String> days = List.generate(31, (i) => (i + 1).toString());
  final List<String> months = List.generate(12, (i) => (i + 1).toString());
  final List<String> years = List.generate(101, (i) => (2025 - i).toString());

  String? _dayError;
  String? _monthError;
  String? _yearError;
  String? _districError;
  String? _dsError;
  String? _rdError;
  String? _gnError;
  String? agreeTermsError;
  String? _mobileError;

  bool valid = true;

  void _nextPageStage() {
    if (isLoading) return;
    valid = true;
    final formValid = _formKey.currentState!.validate();

    setState(() {
      _dayError = _selectedDay == null ? 'please_select_date'.tr() : null;
      _monthError = _selectedMonth == null ? 'please_select_date'.tr() : null;
      _yearError = _selectedYear == null ? 'please_select_date'.tr() : null;

      if (_currentPage == 1) {
        final mob = _mobileController.text.replaceAll('-', '');
        if (mob.isEmpty) {
          _mobileError = 'please_enter_mobile'.tr();
        } else if (mob.length != 10) {
          _mobileError = 'phone_must_be_10_digits'.tr();
        } else {
          _mobileError = null;
        }
      }
    });

    if (_dayError != null ||
        _monthError != null ||
        _yearError != null ||
        _mobileError != null) {
      valid = false;
    }

    if (!formValid || !valid) return;

    if (_currentPage == 1) {
      setState(() => _currentPage = 2);
    }
  }

  void _backPageStage() {
    if (_currentPage == 2) {
      setState(() => _currentPage = 1);
    } else if (_currentPage == 1) {
      setState(() => _currentPage = 0);
    }
  }

  // ── Step 0 navigation ──────────────────────────────────────────────────────

  void _onNextFromStep0() {
    final nic = _nicController.text.trim();
    final wa = _whatsAppController.text.replaceAll('-', '');

    setState(() {
      _nicErrorStep0 = _validateNIC(nic);
      if (wa.isEmpty) {
        _waErrorStep0 = 'please_enter_phone'.tr();
      } else if (wa.length != 10) {
        _waErrorStep0 = 'phone_must_be_10_digits'.tr();
      } else {
        _waErrorStep0 = null;
      }
    });

    if (_nicErrorStep0 != null || _waErrorStep0 != null) return;

    _sendWaOtp(nic, wa);
  }

  Future<void> _sendWaOtp(String nic, String wa) async {
    setState(() => _isCheckingUser = true);
    try {
      final response = await ApiService.sendRegistrationOtp(
        wa,
        _whatsappCountryCode,
        nic: nic,
      );
      debugPrint('[Registration] sendOTP response: $response');

      final data = response['data'];
      final status = data?['status'] ?? '';
      final message = data?['message'] ?? response['message'] ?? '';

      if (status == 'error' ||
          message.toString().toLowerCase().contains('already exists') ||
          message.toString().toLowerCase().contains('already registered')) {
        if (mounted) {
          final isAlready = message.toString().toLowerCase().contains('already');
          ToastUtil.showError(
              isAlready ? 'registration_already'.tr() : 'otp_send_failed'.tr());
        }
      } else {
        if (mounted) {
          ToastUtil.showSuccess('otp_sent_mobile'.tr());
          setState(() {
            _otpSentToWa = true;
            _step0OtpController.clear();
          });
        }
      }
    } catch (e) {
      debugPrint('[Registration] sendOTP error: $e');
      if (mounted) {
        ToastUtil.showError('otp_send_failed'.tr());
      }
    } finally {
      if (mounted) setState(() => _isCheckingUser = false);
    }
  }

  Future<void> _verifyWaOtp() async {
    final otp = _step0OtpController.text.trim();
    if (otp.length != 6) {
      setState(() => _otpErrorStep0 = 'enter_valid_6_digit_otp'.tr());
      return;
    }
    setState(() {
      _otpErrorStep0 = null;
      _isVerifyingOtp = true;
    });

    final wa = _whatsAppController.text.replaceAll('-', '');
    try {
      final res = await ApiService.verifyRegistrationOtp(
        wa,
        _whatsappCountryCode,
        otp,
      );
      debugPrint('[Registration] verifyOTP response: $res');

      final status = res['status'] ?? res['data']?['status'];
      final success = res['success'] ?? res['data']?['success'];

      if (status == 'success' || success == true) {
        if (mounted) {
          ToastUtil.showSuccess('otp_verified'.tr());
          
          // Save NIC to local storage and store verified OTP
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_nic', _nicController.text.trim());
          _verifiedWaOtp = otp;
          _verifiedWaOtpToken = res['data']?['token'] ?? res['token'] ?? '';

          setState(() => _currentPage = 1);
        }
      } else {
        if (mounted) {
          setState(() => _otpErrorStep0 = 'invalid_otp'.tr());
        }
      }
    } catch (e) {
      debugPrint('[Registration] verifyOTP error: $e');
      if (mounted)
        setState(
            () => _otpErrorStep0 = 'otp_verification_failed_retry'.tr());
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  void _showBirthdayPicker(BuildContext context) {
    final initial = _selectedBirthday ?? DateTime(2000, 1, 1);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: 320,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'cancel'.tr(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'done'.tr(),
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  primaryColor: AppColors.accentOrange,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      color: AppColors.accentOrange,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initial,
                  maximumDate: DateTime.now(),
                  minimumDate: DateTime(1900),
                  onDateTimeChanged: (date) {
                    setState(() {
                      _selectedBirthday = date;
                      _selectedDay = date.day.toString();
                      _selectedMonth = date.month.toString();
                      _selectedYear = date.year.toString();
                      _dayError = null;
                      _monthError = null;
                      _yearError = null;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'please_enter_email'.tr();
    final emailRegExp = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (!emailRegExp.hasMatch(value)) return 'invalid_email'.tr();
    return null;
  }

  static final _phoneFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) return oldValue;
    if (digits.length <= 3) return TextEditingValue(text: digits);
    if (digits.length <= 10) {
      final part1 = digits.substring(0, 3);
      final part2 = digits.substring(3);
      return TextEditingValue(text: '$part1-$part2');
    }
    return oldValue;
  });

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'please_enter_phone'.tr();
    final clean = value.replaceAll('-', '');
    if (clean.length != 10) return 'phone_must_be_10_digits'.tr();
    return null;
  }

  String? _validateNIC(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'please_enter_nic'.tr();
    }
    final cleanNic = value.trim().replaceAll(RegExp(r'[^0-9Vv]'), '');

    if (cleanNic.length == 10) {
      final regex = RegExp(r'^\d{9}[VvXx]$');
      if (!regex.hasMatch(value.trim())) {
        return 'invalid_nic_format'.tr();
      }
    } else if (cleanNic.length == 12) {
      final regex = RegExp(r'^\d{12}$');
      if (!regex.hasMatch(cleanNic)) {
        return 'invalid_nic_format'.tr();
      }
    } else {
      return 'nic_must_be_10_or_12_digits'.tr();
    }
    return null;
  }

  // ── Page builders ──────────────────────────────────────────────────────────

  Widget _buildPageZero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'enter_nic_wa'.tr(),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // ── NIC Field ────────────────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _nicErrorStep0 != null
                      ? Colors.red
                      : Colors.grey.shade300,
                ),
              ),
              child: TextFormField(
                controller: _nicController,
                textInputAction: TextInputAction.next,
                enabled: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'nic_number'.tr(),
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.credit_card_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 14),
                onChanged: (_) {
                  setState(() {
                    _nicErrorStep0 = null;
                    _verifiedWaOtp = '';
                    _verifiedWaOtpToken = '';
                    _otpSentToWa = false;
                  });
                },
              ),
            ),
            if (_nicErrorStep0 != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Text(
                  _nicErrorStep0!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),

        const SizedBox(height: 20),

        // ── WhatsApp Number Field ────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntlPhoneField(
              controller: _whatsAppController,
              keyboardType: TextInputType.phone,
              inputFormatters: [_phoneFormatter],
              textInputAction: TextInputAction.done,
              enabled: true,
              disableLengthCheck: true,
              initialCountryCode: 'LK',
              onCountryChanged: (country) {
                setState(() {
                  _whatsappCountryCode = '+${country.dialCode}';
                  _verifiedWaOtp = '';
                  _verifiedWaOtpToken = '';
                  _otpSentToWa = false;
                });
              },
              onChanged: (phone) {
                setState(() {
                  _waErrorStep0 = null;
                  _verifiedWaOtp = '';
                  _verifiedWaOtpToken = '';
                  _otpSentToWa = false;
                });
              },
              onSubmitted: (_) {
                if (_verifiedWaOtp.isNotEmpty) {
                  setState(() => _currentPage = 1);
                } else if (!_otpSentToWa) {
                  _onNextFromStep0();
                }
              },
              decoration: InputDecoration(
                labelText: 'whatsapp_number'.tr(),
                labelStyle: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _waErrorStep0 != null ? Colors.red : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _waErrorStep0 != null ? Colors.red : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
                errorText: _waErrorStep0,
                errorStyle: GoogleFonts.inter(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                'wa_must_be_10_digits'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),

        // ── Inline OTP field (shown after OTP is sent) ───────────────────────
        if (_otpSentToWa) ...[
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _otpErrorStep0 != null
                        ? Colors.red
                        : Colors.grey.shade300,
                  ),
                ),
                child: TextField(
                  controller: _step0OtpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  autofocus: true,
                  style: const TextStyle(fontSize: 22, letterSpacing: 8),
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: 'enter_otp_hint'.tr(),
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (_) {
                    if (_otpErrorStep0 != null) {
                      setState(() => _otpErrorStep0 = null);
                    }
                  },
                  onSubmitted: (_) => _verifyWaOtp(),
                ),
              ),
              if (_otpErrorStep0 != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Text(
                    _otpErrorStep0!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 6),
                child: Text(
                  'sent_otp_to'.tr(args: [_whatsAppController.text]),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 30),

        // ── Primary button: "Next" → "Verify OTP" ───────────────────────────
        CommonButton(
          text: (_otpSentToWa && _verifiedWaOtp.isEmpty) ? 'verify_otp' : 'next',
          isLoading: _isCheckingUser || _isVerifyingOtp,
          onPressed: (_isCheckingUser || _isVerifyingOtp)
              ? null
              : (_otpSentToWa && _verifiedWaOtp.isEmpty)
                  ? _verifyWaOtp
                  : _verifiedWaOtp.isNotEmpty
                      ? () => setState(() => _currentPage = 1)
                      : _onNextFromStep0,
          backgroundColor: AppColors.primaryGreen,
          textColor: Colors.white,
          width: double.infinity,
        ),

        // ── Resend OTP link (only when OTP field is visible) ─────────────────
        if (_otpSentToWa) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: (_isCheckingUser || _isVerifyingOtp)
                  ? null
                  : () {
                      final nic = _nicController.text.trim();
                      final wa =
                          _whatsAppController.text.replaceAll('-', '');
                      _sendWaOtp(nic, wa);
                    },
              child: Text(
                'send_otp'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.accentOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
        if (widget.registeredByUserId == null)
          Center(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                children: [
                  TextSpan(text: 'have_account_login'.tr()),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'login_link'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPageOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'first_name'.tr(),
                controller: _firstNameController,
                isPassword: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomTextField(
                label: 'last_name'.tr(),
                controller: _lastNameController,
                isPassword: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => _showBirthdayPicker(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (_dayError != null)
                        ? Colors.red
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedBirthday != null
                            ? '${_selectedDay!.padLeft(2, '0')}/${_selectedMonth!.padLeft(2, '0')}/$_selectedYear'
                            : 'birthday'.tr(),
                        style: GoogleFonts.inter(
                          color: _selectedBirthday != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentOrange,
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: AppColors.accentOrange,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (_dayError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Text(
                    _dayError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'address'.tr(),
          controller: _addressController,
          isPassword: false,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'email_address'.tr(),
          controller: _emailController,
          isPassword: false,
          validator: _validateEmail,
        ),
        const SizedBox(height: 20),
        // Mobile Number
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntlPhoneField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              inputFormatters: [_phoneFormatter],
              textInputAction: TextInputAction.next,
              enabled: true,
              disableLengthCheck: true,
              initialCountryCode: 'LK',
              onChanged: (phone) {
                final mob = _mobileController.text.replaceAll('-', '');
                setState(() {
                  if (mob.isEmpty) {
                    _mobileError = 'please_enter_mobile'.tr();
                  } else if (mob.length != 10) {
                    _mobileError = 'phone_must_be_10_digits'.tr();
                  } else {
                    _mobileError = null;
                  }
                });
              },
              decoration: InputDecoration(
                labelText: 'mobile_number'.tr(),
                labelStyle: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _mobileError != null ? Colors.red : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _mobileError != null ? Colors.red : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
                errorText: _mobileError,
                errorStyle: GoogleFonts.inter(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                'phone_must_be_10_digits'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        CommonButton(
          text: 'next',
          isLoading: isLoading,
          onPressed: _nextPageStage,
          backgroundColor: AppColors.primaryGreen,
          textColor: Colors.white,
          width: double.infinity,
        ),
        const SizedBox(height: 16),
        CommonButton(
          text: 'back',
          onPressed: _backPageStage,
          backgroundColor: AppColors.backgroundLight,
          textColor: AppColors.textPrimary,
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildPageTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // District
        Stack(
          children: [
            _dropdownField(
              'district'.tr(),
              districts,
              (value) {
                setState(() {
                  _selectedDistrict = value;
                  _selectedDsDivision = null;
                  dsDivisions = [];
                  _dsDivisionsRaw = [];
                  _selectedElectoralDivision = null;
                  electoralDivisions = [];
                  _selectedGramaNiladhari = null;
                  gramaNiladhariDivisions = [];
                  _gnsRaw = [];
                  if (value != null) {
                    _fetchDsDivisions(value);
                    _fetchElectoralDivisions(value);
                  }
                  _districError = null;
                });
              },
              errorText: _districError,
              value: _selectedDistrict,
            ),
            if (isLoading && districts.isEmpty)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // DS Division
        Stack(
          children: [
            _dropdownField(
              'ds_division'.tr(),
              dsDivisions,
              (value) {
                setState(() {
                  _selectedDsDivision = value;
                  _selectedGramaNiladhari = null;
                  gramaNiladhariDivisions = [];
                  _gnsRaw = [];
                  if (value != null) _fetchGNDivisions(value);
                  _dsError = null;
                });
              },
              errorText: _dsError,
              value: _selectedDsDivision,
            ),
            if (isLoading && dsDivisions.isEmpty)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Electoral Division
        Stack(
          children: [
            _dropdownField(
              'electoral_division'.tr(),
              electoralDivisions,
              (value) => setState(() {
                _selectedElectoralDivision = value;
                _rdError = null;
              }),
              errorText: _rdError,
              value: _selectedElectoralDivision,
            ),
            if (isLoading && electoralDivisions.isEmpty)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Grama Niladhari Division
        Stack(
          children: [
            _dropdownField(
              'grama_niladhari_division'.tr(),
              gramaNiladhariDivisions,
              (v) => setState(() {
                _selectedGramaNiladhari = v;
                _gnError = null;
              }),
              errorText: _gnError,
              value: _selectedGramaNiladhari,
            ),
            if (isLoading && gramaNiladhariDivisions.isEmpty)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Contribution field
        CustomTextField(
          label: 'contribute'.tr(),
          controller: _connectController,
          isPassword: false,
          maxLines: 3,
        ),
        const SizedBox(height: 10),

        // Terms & Conditions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: agreeTermsError != null ? Colors.red : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: agreeTerms,
                    activeColor: AppColors.primaryGreen,
                    onChanged: (v) {
                      setState(() {
                        agreeTerms = v!;
                        agreeTermsError = null;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      "terms_conditions_title".tr(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: TextField(
                  controller: TextEditingController(
                    text: 'membership_terms_text'.tr(),
                  ),
                  readOnly: true,
                  scrollPhysics: const AlwaysScrollableScrollPhysics(),
                  expands: true,
                  maxLines: null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (agreeTermsError != null)
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 4),
            child: Text(
              agreeTermsError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),

        // ── Location checkbox (ONLY when registering another member) ─────────
        if (widget.registeredByUserId != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _useLocation,
                      activeColor: AppColors.primaryGreen,
                      onChanged: (v) {
                        setState(() {
                          _useLocation = v!;
                          if (_useLocation) {
                            _fetchLocation();
                          } else {
                            _latitude = null;
                            _longitude = null;
                            _locationError = null;
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        'attach_location'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_useLocation) ...[
                  const SizedBox(height: 6),
                  if (_fetchingLocation)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'getting_location'.tr(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_locationError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _locationError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: _fetchLocation,
                            child: Text(
                              'tap_retry'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_latitude != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primaryGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Lat: ${_latitude!.toStringAsFixed(5)}, Lng: ${_longitude!.toStringAsFixed(5)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _fetchLocation,
                            child: const Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Send OTP Button
        CommonButton(
          text: isRegistering ? 'registering' : 'register',
          isLoading: isRegistering,
          onPressed: isRegistering ? null : _onRegisterPressed,
          backgroundColor: AppColors.primaryGreen,
          textColor: Colors.white,
          width: double.infinity,
        ),

        const SizedBox(height: 16),

        // Back button
        CommonButton(
          text: "back",
          onPressed: _backPageStage,
          backgroundColor: AppColors.backgroundLight,
          textColor: AppColors.textPrimary,
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _dropdownField(
    String hint,
    List<String> items,
    Function(String?) onChanged, {
    String? errorText,
    String? value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (items.isEmpty && !isLoading && (hint == 'district'.tr())) {
              _fetchDropdownData();
            }
            if (items.isEmpty &&
                !isLoading &&
                (hint == 'grama_niladhari_division'.tr())) {
              final selected = _selectedDsDivision;
              if (selected != null && selected.isNotEmpty) {
                _fetchGNDivisions(selected);
              }
            }
          },
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (errorText != null) ? Colors.red : Colors.grey.shade300,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField2<String>(
                value: value,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.only(top: 8),
                  border: InputBorder.none,
                ),
                hint: Text(
                  hint,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                items: items
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: items.isEmpty ? null : (value) => onChanged(value),
                dropdownStyleData: const DropdownStyleData(
                  maxHeight: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Colors.white,
                  ),
                ),
                iconStyleData: const IconStyleData(
                  icon: SizedBox(
                    width: 28,
                    height: 28,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(
                            color: AppColors.textSecondary,
                            width: 1.2,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),
      ],
    );
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _whatsAppController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _connectController.dispose();
    _nicController.dispose();
    _step0OtpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentPage == 2) {
          setState(() => _currentPage = 1);
        } else if (_currentPage == 1) {
          setState(() => _currentPage = 0);
        } else {
          if (widget.registeredByUserId != null) {
            Navigator.of(context).pop();
          } else {
            context.go('/login');
          }
        }
      },
      child: Scaffold(
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

            // Decorative circle
            Positioned(
              top: -50,
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

            // Title
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.72 + 12,
              left: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.registeredByUserId != null
                        ? 'add_new_member'.tr()
                        : 'registration_form'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    widget.registeredByUserId != null
                        ? 'register_represent'.tr()
                        : 'join_the_movement'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // White card
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.72,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 24,
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 30,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _currentPage == 0
                              ? _buildPageZero()
                              : _currentPage == 1
                                  ? _buildPageOne()
                                  : _buildPageTwo(),
                        ],
                      ),
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
}


