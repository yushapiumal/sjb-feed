import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://fc5c89a1-1fff-4fda-a8c1-5d786e9b6a36.mock.pstmn.io";




//login api 
  static Future<Map<String, dynamic>> login(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    print('login status: ${response.statusCode}');
    print('LoginUser body: ${response.body}');

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      return data;
    } else {
      throw Exception(data['message'] ?? 'login failed');
    }
  }

  // Fetch districts
  static Future<List<String>> getDistricts() async {
    final response = await http.get(Uri.parse('$baseUrl/districts'));

    print('getDistricts status: ${response.statusCode}');
    print('getDistricts body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return List<String>.from(data['districts'] ?? []);
      } else {
        throw Exception(data['message'] ?? 'Failed to load districts');
      }
    } else {
      throw Exception('Server Error: ${response.statusCode}');
    }
  }



  // Fetch electoral divisions for a district
  static Future<List<String>> getEDivisions(String district) async {
    final response = await http.post(
      Uri.parse('$baseUrl/electoral-divisions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'district': district}),
    );

    print('getEDivisions for district "$district" status: ${response.statusCode}');
    print('getEDivisions body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        if (data['electoral-divisions'] != null) {
          return List<String>.from(data['electoral-divisions']);
        } else if (data['data'] != null) {
          return List<String>.from(data['data']);
        } else {
          print('No electoral divisions found in response for district "$district"');
          return [];
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to load electoral divisions');
      }
    } else {
      throw Exception('Server Error: ${response.statusCode}');
    }
  }



  // Fetch Grama Niladhari divisions for an electoral division
  static Future<List<String>> getGNDivisions(String electoralDivision) async {
    print('Fetching GN Divisions for electoral division: $electoralDivision');

    final response = await http.post(
      Uri.parse('$baseUrl/gn-divisions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'electoral_division': electoralDivision}),
    );

    print('getGNDivisions for electoral division "$electoralDivision" status: ${response.statusCode}');
    print('getGNDivisions body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['gn_divisions'] != null) {
        return List<String>.from(data['gn_divisions']);
      } else if (data['data'] != null) {
        return List<String>.from(data['data']);
      } else {
        print('No Grama Niladhari divisions found in response for electoral division "$electoralDivision"');
        return [];
      }
    } else {
      throw Exception('Server Error: ${response.statusCode}');
    }
  }

  // Submit registration
  static Future<Map<String, dynamic>> registerUser(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    print('registerUser status: ${response.statusCode}');
    print('registerUser body: ${response.body}');

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }
}