import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:statelink/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _role;
  List<Map<String, dynamic>> _groups = [];

  User? get user => _user;
  String? get role => _role;
  List<Map<String, dynamic>> get groups => _groups;
  bool get isGlobalAdmin => _role == 'admin';

  final AuthService _authService = AuthService();

  Future<void> signUp(String email, String password, String role, String name) async {
    _user = await _authService.signUp(email, password, role, name);
    _role = role;
    _groups = await _authService.getUserGroups(_user!.uid);
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _user = await _authService.signIn(email, password);
    _role = await _authService.getUserRole(_user!.uid);
    _groups = await _authService.getUserGroups(_user!.uid);
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _role = null;
    _groups = [];
    notifyListeners();
  }

  Future<void> saveFCMToken(String token) async {
    if (_user != null) {
      await _authService.saveFCMToken(_user!.uid, token);
    }
  }

  // Future<String> createGroup(String name, String description) async {
  //   final groupId = await _authService.createGroup(name, description, _user!.uid);
  //   _groups = await _authService.getUserGroups(_user!.uid);
  //   notifyListeners();
  //   return groupId;
  // }

  // Future<void> joinGroup(String groupId) async {
  //   await _authService.joinGroup(groupId, _user!.uid);
  //   _groups = await _authService.getUserGroups(_user!.uid);
  //   notifyListeners();
  // }

  // Future<void> addUserToGroup(String groupId, String userEmail) async {
  //   await _authService.addUserToGroup(groupId, userEmail, _user!.uid);
  //   _groups = await _authService.getUserGroups(_user!.uid);
  //   notifyListeners();
  // }

  Future<bool> isGroupAdmin(String groupId) async {
    return await _authService.isGroupAdmin(groupId, _user!.uid);
  }
}