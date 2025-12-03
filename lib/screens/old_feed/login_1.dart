import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:statelink/screens/old_feed/auth_provider.dart';
import 'package:statelink/screens/old_feed/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen1 extends StatefulWidget {
  const LoginScreen1({super.key});

  @override
  State<LoginScreen1> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen1> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  String _role = 'user';
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _nameError;

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm Password is required';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Validate all fields
  bool _validateFields() {
    setState(() {
      _nameError = _isSignUp ? _validateName(_nameController.text) : null;
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
      if (_isSignUp) {
        _confirmPasswordError = _validateConfirmPassword(
            _confirmPasswordController.text, _passwordController.text);
      } else {
        _confirmPasswordError = null;
      }
    });
    return _nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        (_isSignUp ? _confirmPasswordError == null : true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 250.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Welcome to StateLink',
                      style: GoogleFonts.abel(fontSize: 28, fontWeight: FontWeight.bold),
                    )
                        .animate()
                        .fadeIn(duration: 1000.ms)
                        .slideY(begin: -0.2),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.white.withOpacity(0.1),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isSignUp) ...[
                                  TextField(
                                    controller: _nameController,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Poppins',
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Name',
                                      labelStyle: const TextStyle(
                                        color: Colors.black54,
                                        fontFamily: 'Poppins',
                                      ),
                                      filled: true,
                                      fillColor:
                                          Colors.grey[200]?.withOpacity(0.8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            const BorderSide(color: Colors.grey),
                                      ),
                                      errorText: _nameError,
                                      errorStyle: const TextStyle(
                                        color: Colors.redAccent,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _nameError = _validateName(value);
                                      });
                                    },
                                  )
                                      .animate()
                                      .fadeIn(delay: 800.ms)
                                      .slideX(begin: -0.1),
                                  const SizedBox(height: 16),
                                ],
                                TextField(
                                  controller: _emailController,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: const TextStyle(
                                      color: Colors.black54,
                                      fontFamily: 'Poppins',
                                    ),
                                    filled: true,
                                    fillColor:
                                        Colors.grey[200]?.withOpacity(0.8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: Colors.grey),
                                    ),
                                    errorText: _emailError,
                                    errorStyle: const TextStyle(
                                      color: Colors.redAccent,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _emailError = _validateEmail(value);
                                    });
                                  },
                                )
                                    .animate()
                                    .fadeIn(delay: 1000.ms)
                                    .slideX(begin: -0.1),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _passwordController,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: const TextStyle(
                                      color: Colors.black54,
                                      fontFamily: 'Poppins',
                                    ),
                                    filled: true,
                                    fillColor:
                                        Colors.grey[200]?.withOpacity(0.8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: Colors.grey),
                                    ),
                                    errorText: _passwordError,
                                    errorStyle: const TextStyle(
                                      color: Colors.redAccent,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  obscureText: true,
                                  onChanged: (value) {
                                    setState(() {
                                      _passwordError = _validatePassword(value);
                                      if (_isSignUp) {
                                        _confirmPasswordError =
                                            _validateConfirmPassword(
                                                _confirmPasswordController.text,
                                                value);
                                      }
                                    });
                                  },
                                )
                                    .animate()
                                    .fadeIn(delay: 1200.ms)
                                    .slideX(begin: 0.1),
                                if (_isSignUp) ...[
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _confirmPasswordController,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Poppins',
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      labelStyle: const TextStyle(
                                        color: Colors.black54,
                                        fontFamily: 'Poppins',
                                      ),
                                      filled: true,
                                      fillColor:
                                          Colors.grey[200]?.withOpacity(0.8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            const BorderSide(color: Colors.grey),
                                      ),
                                      errorText: _confirmPasswordError,
                                      errorStyle: const TextStyle(
                                        color: Colors.redAccent,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    obscureText: true,
                                    onChanged: (value) {
                                      setState(() {
                                        _confirmPasswordError =
                                            _validateConfirmPassword(
                                                value, _passwordController.text);
                                      });
                                    },
                                  )
                                      .animate()
                                      .fadeIn(delay: 1400.ms)
                                      .slideX(begin: -0.1),
                                  const SizedBox(height: 16),
                                  DropdownButton<String>(
                                    value: _role,
                                    dropdownColor:
                                        Colors.white.withOpacity(0.8),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Poppins',
                                    ),
                                    onChanged: (value) =>
                                        setState(() => _role = value!),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'user',
                                        child: Text(
                                          'User',
                                          style:
                                              TextStyle(fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'admin',
                                        child: Text(
                                          'Admin',
                                          style:
                                              TextStyle(fontFamily: 'Poppins'),
                                        ),
                                      ),
                                    ],
                                  ).animate().fadeIn(delay: 1600.ms),
                                ],
                                const SizedBox(height: 16),
                                if (!_isSignUp)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: () async {
                                        if (_emailController.text.isEmpty ||
                                            _validateEmail(_emailController.text) !=
                                                null) {
                                          setState(() {
                                            _emailError = _validateEmail(
                                                _emailController.text);
                                          });
                                          return;
                                        }
                                        setState(() => _isLoading = true);
                                        final authProvider =
                                            Provider.of<AuthProvider>(context,
                                                listen: false);
                                        try {
                                          await authProvider.sendPasswordResetEmail(
                                              _emailController.text);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Password reset email sent. Check your inbox.')),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.toString())),
                                          );
                                        } finally {
                                          setState(() => _isLoading = false);
                                        }
                                      },
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ).animate().fadeIn(delay: 1400.ms),
                                  ),
                                const SizedBox(height: 24),
                                if (_isLoading)
                                  const CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.green),
                                  ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          setState(() => _isSignUp = !_isSignUp),
                                      child: Text(
                                        _isSignUp
                                            ? 'Switch to Sign In'
                                            : 'Switch to Sign Up',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ).animate().fadeIn(delay: 600.ms),
                                    const SizedBox(width: 16),
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (!_validateFields()) return;
                                        setState(() => _isLoading = true);
                                        final authProvider =
                                            Provider.of<AuthProvider>(context,
                                                listen: false);
                                        try {
                                          if (_isSignUp) {
                                            await authProvider.signUp(
                                              _emailController.text,
                                              _passwordController.text,
                                              _role,
                                              _nameController.text,
                                            );
                                          } else {
                                            await authProvider.signIn(
                                              _emailController.text,
                                              _passwordController.text,
                                            );
                                          }
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const HomeScreen(),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.toString())),
                                          );
                                        } finally {
                                          setState(() => _isLoading = false);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: const EdgeInsets.all(0),
                                        shape: const CircleBorder(),
                                        fixedSize: const Size(80, 80),
                                      ),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.green, Colors.yellow],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _isSignUp ? 'Sign Up' : 'Sign In',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.arrow_forward,
                                              color: Colors.black,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.8, 0.8)),
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
            ),
          ],
        ),
      ),
    );
  }
}


