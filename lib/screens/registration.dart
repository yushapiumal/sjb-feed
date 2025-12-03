import 'dart:ui';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:statelink/api/sjb_api.dart';
import 'package:statelink/screens/login_id.dart';
import 'package:statelink/screens/unitls/text_util.dart';
import 'package:statelink/screens/unitls/commonWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;
  bool isLoading = false;

  bool agreeTerms = false;
  bool agreeConditions = false;

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _whatsAppController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _connectController = TextEditingController();

  // Dropdown values
  String? _selectedDay;
  String? _selectedMonth;
  String? _selectedYear;
  String? _selectedDistrict;
  String? _selectedElectoralDivision;
  String? _selectedGramaNiladhari;

  // Dropdown items
  List<String> districts = [];
  List<String> electoralDivisions = [];
  List<String> gramaNiladhariDivisions = [];

  final List<String> days = List.generate(31, (i) => (i + 1).toString());
  final List<String> months = List.generate(12, (i) => (i + 1).toString());
  final List<String> years = List.generate(101, (i) => (2025 - i).toString());
  bool showTerms = false;

  String? _dayError;
  String? _monthError;
  String? _yearError;
  String? _districError;
  String? _rdError;
  String? _gnError;
  String? agreeTermsError;

  bool valid = true;

  Future<void> _fetchDropdownData() async {
    setState(() => isLoading = true);
    try {
      final fetched = await ApiService.getDistricts();
      setState(() {
        districts = fetched;
        electoralDivisions = [];
        gramaNiladhariDivisions = [];
        _selectedDistrict = null;
        _selectedElectoralDivision = null;
        _selectedGramaNiladhari = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('failed_load_dropdown'.tr(args: ['Districts']))),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchElectoralDivisions(String district) async {
    if (district.isEmpty) {
      setState(() {
        electoralDivisions = [];
        _selectedElectoralDivision = null;
        gramaNiladhariDivisions = [];
        _selectedGramaNiladhari = null;
      });
      return;
    }
    setState(() => isLoading = true);
    try {
      final fetched = await ApiService.getEDivisions(district);
      setState(() {
        electoralDivisions = fetched;
        _selectedElectoralDivision = null;
        gramaNiladhariDivisions = [];
        _selectedGramaNiladhari = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'failed_load_dropdown'.tr(args: ['Electoral Divisions']),
          ),
        ),
      );
      setState(() {
        electoralDivisions = [];
        _selectedElectoralDivision = null;
        gramaNiladhariDivisions = [];
        _selectedGramaNiladhari = null;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchGNDivisions(String division) async {
    if (division.isEmpty) {
      setState(() => gramaNiladhariDivisions = []);
      return;
    }
    setState(() => isLoading = true);
    try {
      final fetched = await ApiService.getGNDivisions(division);
      setState(() => gramaNiladhariDivisions = fetched);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'failed_load_dropdown'.tr(args: ['Grama Niladhari Divisions']),
          ),
        ),
      );
      setState(() => gramaNiladhariDivisions = []);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!agreeTerms) {
      setState(
        () => agreeTermsError = 'Please agree to the Terms & Conditions',
      );
      return;
    } else {
      setState(() => agreeTermsError = null);
    }

    setState(() {
      _districError = _selectedDistrict == null
          ? 'Please select a district'
          : null;
      _rdError = _selectedElectoralDivision == null
          ? 'Please select a E.D'
          : null;
      _gnError = _selectedGramaNiladhari == null ? 'Please select a G.N' : null;
    });

    if (_districError != null || _rdError != null || _gnError != null) return;

    // Prepare request body
    final body = {
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'birthday': '$_selectedYear-$_selectedMonth-$_selectedDay',
      'address': _addressController.text,
      'district': _selectedDistrict,
      'electoral_division': _selectedElectoralDivision,
      'grama_niladhari_division': _selectedGramaNiladhari,
      'whatsapp_number': _whatsAppController.text,
      'mobile_number': _mobileController.text,
      'email': _emailController.text,
      'connect_message': _connectController.text,
    };

    setState(() => isLoading = true);

   Future<void> saveMemberId(String memberId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('member_id', memberId);
}
try {
  final res = await ApiService.registerUser(body);
  bool success = res is Map && res['status'] == 'success';

  if (success) {
    setState(() => isLoading = false);

    final memberId = res['body']?['member_id']?.toString();

    if (memberId != null) {
      await saveMemberId(memberId);   
    }
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_done, size: 64, color: Colors.green),
              const SizedBox(height: 12),
              const Text(
                'Registration Successful',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you! Your Member ID: $memberId',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/login');
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Registration failed')));
  }


    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _nextPageStage() {
    if (isLoading) return;

    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _dayError = _selectedDay == null ? 'Please select a day' : null;
      _monthError = _selectedMonth == null ? 'Please select a month' : null;
      _yearError = _selectedYear == null ? 'Please select a year' : null;
    });

    if (_dayError != null || _monthError != null || _yearError != null) {
      valid = false;
    }

    if (!valid) return;

    if (_currentPage == 0) {
      setState(() => _currentPage = 1);
    }
  }

  void _backPageStage() {
    if (_currentPage == 1) {
      setState(() => _currentPage = 0);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'please_enter_email'.tr();
    }
    final emailRegExp = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (!emailRegExp.hasMatch(value)) {
      return 'invalid_email'.tr();
    }
    return null;
  }

  static final _phoneFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) return oldValue;

    if (digits.length <= 3) {
      return TextEditingValue(text: digits);
    } else if (digits.length <= 10) {
      final part1 = digits.substring(0, 3);
      final part2 = digits.substring(3);
      return TextEditingValue(text: '$part1-$part2');
    }
    return oldValue;
  });

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'please_enter_phone'.tr();
    }
    final clean = value.replaceAll('-', '');
    if (clean.length != 10) {
      return 'phone_must_be_10_digits'.tr();
    }
    return null;
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
                // icon: Icons.person,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomTextField(
                label: 'last_name'.tr(),
                controller: _lastNameController,
                isPassword: false,
                // icon: Icons.person,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'birthday'.tr(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  child: _dropdownField(
                    'day'.tr(),
                    days,
                    (v) => setState(() {
                      _selectedDay = v;
                      _dayError = null;
                    }),
                    errorText: _dayError,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  fit: FlexFit.tight,
                  child: _dropdownField(
                    'month'.tr(),
                    months,
                    (v) => setState(() {
                      _selectedMonth = v;
                      _monthError = null;
                    }),
                    errorText: _monthError,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  fit: FlexFit.tight,
                  child: _dropdownField(
                    'year'.tr(),
                    years,
                    (v) => setState(() {
                      _selectedYear = v;
                      _yearError = null;
                    }),
                    errorText: _yearError,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        CustomTextField(
          label: 'address'.tr(),
          controller: _addressController,
          isPassword: false,
          //icon: Icons.home,
        ),

        const SizedBox(height: 20),
        CustomTextField(
          label: 'whatsapp_number'.tr(),
          controller: _whatsAppController,
          isPassword: false,
          inputFormatters: [_phoneFormatter],
          validator: _validatePhone,
          // icon: Icons.message,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'mobile_number'.tr(),
          controller: _mobileController,
          isPassword: false,
          inputFormatters: [_phoneFormatter],
          validator: _validatePhone,
          // icon: Icons.phone_android,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'email'.tr(),
          controller: _emailController,
          isPassword: false,
          validator: _validateEmail,
          // icon: Icons.email,
        ),

        const SizedBox(height: 20),

        const SizedBox(height: 20),
        Align(
          alignment: Alignment.bottomRight,

          child: CommonButton(
            text: "Next".tr(),
            isLoading: isLoading,
            onPressed: _nextPageStage,
            backgroundColor: Colors.white,
            textColor: const Color.fromARGB(255, 12, 104, 15),
            width: 200,
          ),
        ),
      ],
    );
  }

  Widget _buildPageTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _dropdownField(
                  'district'.tr(),
                  districts,
                  (value) {
                    setState(() {
                      _selectedDistrict = value;
                      if (value != null) _fetchElectoralDivisions(value);
                      _districError = null;
                    });
                  },
                  errorText: _districError, // 👈 shows outside
                ),
                if (isLoading && districts.isEmpty)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _dropdownField('electoral_division'.tr(), electoralDivisions, (
                  value,
                ) {
                  setState(() {
                    _selectedElectoralDivision = value;
                    if (value != null) _fetchGNDivisions(value);
                    _rdError = null;
                  });
                }, errorText: _rdError),
                if (isLoading && electoralDivisions.isEmpty)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                ),
                if (isLoading && gramaNiladhariDivisions.isEmpty)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'contribute'.tr(),
          controller: _connectController,
          isPassword: false,
          // icon: Icons.message,
          maxLines: 3,
        ),
        const SizedBox(height: 10),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Terms and Conditions",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: agreeTerms,
                  onChanged: (v) {
                    setState(() {
                      agreeTerms = v!;
                      agreeTermsError = null; // clear error on change
                    });
                  },
                  checkColor: Colors.black,
                  activeColor: Colors.white,
                ),
                Expanded(
                  child: SizedBox(
                    height: 100, // fixed height
                    child: TextField(
                      controller: TextEditingController(
                        text:
                            ''' I accept the membership terms and conditions and the Constitution of Samagi Jana Balavegaya. I wish the Party to communicate with me by phone, SMS, email, and other means. I am above 15 years of age and not a member of any other political party.
                      ''',
                      ),
                      readOnly: true,
                      scrollPhysics: const AlwaysScrollableScrollPhysics(),
                      expands: true,
                      maxLines: null,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (agreeTermsError != null)
              Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 2),
                child: Text(
                  agreeTermsError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _dropdownField(
    String hint,
    List<String> items,
    Function(String?) onChanged, {
    String? errorText, // external error text
  }) {
    debugPrint('Dropdown hint: $hint');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (errorText != null)
                  ? Colors.red
                  : Colors.black.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField2<String>(
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.only(top: 8),
                border: InputBorder.none,
              ),
              hint: Text(
                hint,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: items.isEmpty ? null : onChanged,
              dropdownStyleData: const DropdownStyleData(
                maxHeight: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.white,
                ),
              ),
              iconStyleData: const IconStyleData(
                icon: Icon(Icons.arrow_drop_down, color: Colors.black),
              ),
            ),
          ),
        ),

        // 🟥 The error text OUTSIDE the dropdown box
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

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/images/loginbg.png'),
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 170, left: 18),
              child: Text(
                'registration_form'.tr(),
                style: GoogleFonts.poppins(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
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
                  topRight: Radius.circular(30),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 30,
                    ),
                    // color: Colors.black.withOpacity(0.1),
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
                                ? _buildPageOne()
                                : _buildPageTwo(),
                            const SizedBox(height: 40),
                            if (_currentPage == 1)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: CommonButton(
                                      text: "Back".tr(),
                                      // isLoading: isLoading,
                                      onPressed: _backPageStage,
                                      backgroundColor: const Color.fromARGB(
                                        172,
                                        66,
                                        136,
                                        9,
                                      ),
                                      textColor: Colors.white,
                                      width: 200,
                                    ),
                                  ),

                                  SizedBox(width: 120),

                                  Expanded(
                                    child: CommonButton(
                                      text: "Submit",
                                      isLoading: isLoading,
                                      onPressed: isLoading
                                          ? null
                                          : () => _submitForm(),
                                      backgroundColor: Colors.white,
                                      textColor: const Color.fromARGB(
                                        255,
                                        12,
                                        104,
                                        15,
                                      ),
                                      width: 200,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
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
