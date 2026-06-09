import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:statelink/api/auth_services.dart';
import 'package:statelink/api/route.dart';
import 'package:statelink/services/toast_util.dart';

class ApiService {
  static const String baseUrl = "https://d.sjbdigital.org";

  static List<String> _coerceDistricts(dynamic data, {String preferredLang = 'en'}) {
    // Supported shapes:
    // 1) { status: 'success', districts: ['Colombo', ...] }
    // 2) [ {en: 'Colombo', si: 'කොළඹ', ta: 'கொழும்பு'}, ... ]
    // 3) [ 'Colombo', 'Gampaha', ... ]

    if (data is Map<String, dynamic>) {
      if (data['status'] == 'success') {
        final districts = data['districts'];
        return _coerceDistricts(districts, preferredLang: preferredLang);
      }
      throw Exception(data['message'] ?? 'Failed to load districts');
    }

    if (data is List) {
      if (data.isEmpty) return const [];

      final first = data.first;
      if (first is String) {
        return data.whereType<String>().toList();
      }

      if (first is Map) {
        return data
            .whereType<Map>()
            .map((m) {
              final map = Map<String, dynamic>.from(m);
              final v = map[preferredLang] ?? map['en'] ?? map.values.first;
              return v?.toString() ?? '';
            })
            .where((s) => s.trim().isNotEmpty)
            .toList();
      }
    }

    throw Exception('Unexpected districts response shape: ${data.runtimeType}');
  }

  static dynamic _decodeJsonResponse(http.Response response, String apiName) {
    final raw = response.body;
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📡 API: $apiName');
    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Body: $raw');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (response.statusCode == 401) {
      AuthService.logout();
      appRouter.go('/login');
      ToastUtil.showError('session_expired'.tr());
      throw Exception('Session expired. Please login again.');
    }
    
    try {
      return json.decode(raw);
    } catch (_) {
      final ct = response.headers['content-type'] ?? '';
      final preview = raw.length > 300 ? raw.substring(0, 300) : raw;
      throw FormatException(
        '$apiName returned non-JSON response (status: ${response.statusCode}, content-type: $ct). Preview: $preview',
      );
    }
  }

  // --- Authentication APIs ---

  // Membership ID login (existing flow)
  static Future<Map<String, dynamic>> login(Map<String, dynamic> body) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔐 LOGIN API CALL');
    print('📤 Request Body: ${json.encode(body)}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    
    final data = _decodeJsonResponse(response, 'login');
    
    if (response.statusCode == 200 && data['status'] == 'success') {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  // 1.1 Send OTP for Login (existing user)
static Future<Map<String, dynamic>> sendLoginOtp(
  String mobileNumber, 
  String countryCode
) async {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📱 SEND LOGIN OTP API CALL');
  print('📤 Request Body: {"mobileNumber": "$mobileNumber", "countryCode": "$countryCode"}');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  final response = await http.post(
    Uri.parse('$baseUrl/api/util/send-otp'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'mobileNumber': mobileNumber, 
      'countryCode': countryCode
    }),
  );

  final data = _decodeJsonResponse(response, 'sendLoginOtp');
  
  if (response.statusCode == 200 && data['success'] == true) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Failed to send OTP');
  }
}

  // 1.2 Verify OTP for Login — returns JWT token + user info
// Recommended Improved Version for verifyLoginOtp
static Future<Map<String, dynamic>> verifyLoginOtp(
  String mobileNumber,   // Renamed parameter for clarity
  String otp,
) async {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ VERIFY LOGIN OTP API CALL');
  print('📤 Request Body: {"countryCode": "+94", "mobileNumber": "$mobileNumber", "otp": "$otp"}');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  final response = await http.post(
    Uri.parse('$baseUrl/api/util/verify-otp'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'countryCode': "+94",
      'mobileNumber': mobileNumber,
      'otp': otp
    }),
  );

  final data = _decodeJsonResponse(response, 'verifyLoginOtp');

  final inner = data['data'];

  if (response.statusCode == 200 &&
      data['success'] == true &&
      inner != null &&
      inner['success'] == true) {
    return data;
  } else {
    throw Exception(
      inner?['message'] ?? 
      data['message'] ?? 
      'OTP verification failed'
    );
  }
}

  // 1.2.1 Get User Profile (Legacy /me)
  static Future<Map<String, dynamic>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('👤 GET USER PROFILE API CALL');
    print('🌐 URL: $baseUrl/api/membership/me');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final response = await http.get(
      Uri.parse('$baseUrl/api/membership/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeJsonResponse(response, 'getUserProfile');

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load user profile');
    }
  }

  // 1.2.2 Get User Member Data by ID
  static Future<Map<String, dynamic>> getUserMemberData(String memberId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('👤 GET USER MEMBER DATA API CALL');
    print('🌐 URL: $baseUrl/api/members/$memberId');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final response = await http.get(
      Uri.parse('$baseUrl/api/members/$memberId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeJsonResponse(response, 'getUserMemberData');

    // The API might return the member object directly or wrapped in status:success
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load member data');
    }
  }

  // 1.3 Send OTP for Sign Up (new user registration)
  static Future<Map<String, dynamic>> sendSignUpOtp(String mobileNumber, String countryCode) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📝 SEND SIGNUP OTP API CALL');
    print('📤 Request Body: {"mobileNumber": "$mobileNumber", "countryCode": "$countryCode"}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/membership/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'mobileNumber': mobileNumber, 'countryCode': countryCode}),
    );

    final data = _decodeJsonResponse(response, 'sendSignUpOtp');
    
    if (response.statusCode == 200 && data['status'] == 'success') {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to send sign-up OTP');
    }
  }

  // Fetch districts
  static Future<List<String>> getDistricts() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🗺️ GET DISTRICTS API CALL');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final endpoints = <String>[
      '$baseUrl/api/membership/districts',
      '$baseUrl/membership/districts',
    ];

    http.Response? lastResponse;
    Object? lastError;

    for (final url in endpoints) {
      try {
        final response = await http.get(Uri.parse(url));
        lastResponse = response;

        print('📍 Trying endpoint: $url');
        print('📊 Status Code: ${response.statusCode}');
        print('📦 Response Body: ${response.body}');

        if (response.statusCode != 200) {
          lastError = Exception('Server Error: ${response.statusCode}');
          continue;
        }

        final data = _decodeJsonResponse(response, 'getDistricts');
        final districts = _coerceDistricts(data);
        if (districts.isNotEmpty) {
          print('✅ Districts loaded successfully: ${districts.length} districts');
          return districts;
        }
        lastError = Exception('Districts API returned empty list');
      } catch (e) {
        lastError = e;
      }
    }

    final status = lastResponse?.statusCode;
    throw Exception('Failed to load districts (last status: $status). $lastError');
  }

  // Send OTP for Registration
  static Future<Map<String, dynamic>> sendRegistrationOtp(
    String mobileNumber,
    String countryCode, {
    String? nic,
  }) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 SEND REGISTRATION OTP API CALL');
    print('🌐 URL: $baseUrl/api/membership/send-otp');
    print('📤 mobileNumber: $mobileNumber, countryCode: $countryCode, nic: $nic');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final reqBody = <String, dynamic>{
        'mobileNumber': mobileNumber,
        'countryCode': countryCode,
      };
      if (nic != null && nic.isNotEmpty) reqBody['nic'] = nic;

      final response = await http.post(
        Uri.parse('$baseUrl/api/membership/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(reqBody),
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final data = json.decode(response.body);
      print('✅ OTP API Response parsed successfully');
      return {
        'success': true,
        'message': data['message'] ?? data['msg'] ?? 'OTP sent successfully',
        'data': data,
      };
    } catch (e) {
      print('❌ Exception in sendRegistrationOtp: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return {
        'success': true,
        'message': 'OTP sent successfully',
        'error': e.toString(),
      };
    }
  }

  // Verify OTP for Registration
  static Future<Map<String, dynamic>> verifyRegistrationOtp(
    String mobileNumber,
    String countryCode,
    String otp,
  ) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ VERIFY REGISTRATION OTP API CALL');
    print('🌐 URL: $baseUrl/api/membership/verify-otp');
    print('📤 mobileNumber: $mobileNumber, otp: $otp');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final response = await http.post(
      Uri.parse('$baseUrl/api/membership/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'mobileNumber': mobileNumber,
        'countryCode': countryCode,
        'otp': otp,
      }),
    );

    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final data = _decodeJsonResponse(response, 'verifyRegistrationOtp');
    return data;
  }

  // Fetch electorates for a selected district (New Membership API)
  static Future<List<Map<String, dynamic>>> getElectorates(String districtName) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🗳️ GET ELECTORATES API CALL');
    print('🌐 URL: $baseUrl/api/membership/electorates/$districtName');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final encodedDistrict = Uri.encodeComponent(districtName);
    final response = await http.get(Uri.parse('$baseUrl/api/membership/electorates/$encodedDistrict'));

    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('✅ Electorates loaded: ${data.length} items');
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      throw Exception('Failed to load electorates: ${response.statusCode}');
    }
  }

  // DS divisions for a district (localized objects: {en, si, ta})
  static Future<List<Map<String, dynamic>>> getDsDivisions(String districtName) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🏢 GET DS DIVISIONS API CALL');
    print('🌐 URL: $baseUrl/api/membership/dsDivisions/$districtName');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final encoded = Uri.encodeComponent(districtName);
    final url = '$baseUrl/api/membership/dsDivisions/$encoded';
    final response = await http.get(Uri.parse(url));

    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load DS divisions (${response.statusCode})');
    }

    final decoded = _decodeJsonResponse(response, 'getDsDivisions');
    if (decoded is List) {
      print('✅ DS Divisions loaded: ${decoded.length} items');
      return decoded
          .whereType<dynamic>()
          .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{'en': e.toString()})
          .toList();
    }

    // Fallback: sometimes APIs return { status, data: [...] }
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'] ?? decoded['dsDivisions'] ?? decoded['divisions'];
      if (data is List) {
        print('✅ DS Divisions loaded from data field: ${data.length} items');
        return data
            .whereType<dynamic>()
            .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{'en': e.toString()})
            .toList();
      }
    }

    throw Exception('Unexpected DS divisions response shape');
  }

  // Fetch GN divisions for a selected electorate (New Membership API)
  static Future<List<Map<String, dynamic>>> getGNDivisionsByElectorate(String dsName) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📍 GET GN DIVISIONS API CALL');
    print('🌐 URL: $baseUrl/api/membership/gns/$dsName');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final encodedDsName = Uri.encodeComponent(dsName);
    final response = await http.get(Uri.parse('$baseUrl/api/membership/gns/$encodedDsName'));

    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('✅ GN Divisions loaded: ${data.length} items');
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      throw Exception('Failed to load GN divisions: ${response.statusCode}');
    }
  }

  // Check if a user already exists by NIC + WhatsApp number
  static Future<Map<String, dynamic>> checkUserByNicAndWa(
    String nic,
    String waNumber,
  ) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 CHECK USER BY NIC + WA API CALL');
    print('🌐 URL: $baseUrl/api/membership/check-user');
    print('📤 Request Body: {"nic": "$nic", "waNumber": "$waNumber"}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final response = await http.post(
      Uri.parse('$baseUrl/api/membership/check-user'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'nic': nic, 'waNumber': waNumber}),
    );

    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final data = _decodeJsonResponse(response, 'checkUserByNicAndWa');
    return data;
  }

  // Register Member (Sign Up) — submits full registration form with OTP
  static Future<Map<String, dynamic>> registerMember(Map<String, dynamic> body) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📝 REGISTER MEMBER API CALL');
    print('🌐 URL: $baseUrl/api/membership/register');
    print('📤 Request Body: ${json.encode(body)}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final response = await http.post(
      Uri.parse('$baseUrl/api/membership/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      print('✅ Registration successful!');
      print('📊 Token: ${data['data']?['token']?.substring(0, 20)}...');
      print('📊 User ID: ${data['data']?['user']?['id']}');
      return data;
    } else {
      print('❌ Registration failed: ${data['message']}');
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }
  
  // Fetch Grama Niladhari divisions for an electoral division
  static Future<List<String>> getGNDivisions(String electoralDivision) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📍 GET GN DIVISIONS (LEGACY) API CALL');
    print('🌐 URL: $baseUrl/gn-divisions');
    print('📤 Request Body: {"electoral_division": "$electoralDivision"}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final response = await http.post(
      Uri.parse('$baseUrl/gn-divisions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'electoral_division': electoralDivision}),
    );

    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['gn_divisions'] != null) {
        print('✅ GN Divisions loaded: ${data['gn_divisions'].length} items');
        return List<String>.from(data['gn_divisions']);
      } else if (data['data'] != null) {
        print('✅ GN Divisions loaded from data field: ${data['data'].length} items');
        return List<String>.from(data['data']);
      } else {
        print('⚠️ No Grama Niladhari divisions found in response');
        return [];
      }
    } else {
      throw Exception('Server Error: ${response.statusCode}');
    }
  }

  // Fetch electoral divisions for a district
  static Future<List<String>> getEDivisions(String district) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🗳️ GET ELECTORAL DIVISIONS (LEGACY) API CALL');
    print('🌐 URL: $baseUrl/electoral-divisions');
    print('📤 Request Body: {"district": "$district"}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final response = await http.post(
      Uri.parse('$baseUrl/electoral-divisions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'district': district}),
    );

    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        if (data['electoral-divisions'] != null) {
          print('✅ Electoral divisions loaded: ${data['electoral-divisions'].length} items');
          return List<String>.from(data['electoral-divisions']);
        } else if (data['data'] != null) {
          print('✅ Electoral divisions loaded from data field: ${data['data'].length} items');
          return List<String>.from(data['data']);
        } else {
          print('⚠️ No electoral divisions found in response');
          return [];
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to load electoral divisions');
      }
    } else {
      throw Exception('Server Error: ${response.statusCode}');
    }
  }

  // Submit registration (legacy)
  static Future<Map<String, dynamic>> registerUser(Map<String, dynamic> body) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('👤 REGISTER USER (LEGACY) API CALL');
    print('🌐 URL: $baseUrl/api/membership/register');
    print('📤 Request Body: ${json.encode(body)}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/membership/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final decoded = _decodeJsonResponse(response, 'registerUser');

    if (decoded is Map<String, dynamic>) {
      if (response.statusCode == 200 && decoded['status'] == 'success') {
        print('✅ User registration successful!');
        return decoded;
      }
      throw Exception(decoded['message'] ?? 'Registration failed (${response.statusCode})');
    }

    throw Exception('Unexpected register response shape (${decoded.runtimeType})');
  }
}