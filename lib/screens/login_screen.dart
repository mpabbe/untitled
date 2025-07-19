import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kDebugMode uchun
import 'dart:io';
import '../services/auth_service.dart';
import 'map_screen.dart';
import 'verifier_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  final _keyController = TextEditingController();
  bool _isLoading = false;
  String _selectedUserType = 'admin';

  @override
  void initState() {
    super.initState();
    
    // Windows platform check
    print('DEBUG: Platform: ${Platform.operatingSystem}');
    print('DEBUG: Is Windows: ${Platform.isWindows}');
    
    // Admin parolni tekshirish va yaratish
    _ensureAdminSetup();
    
    // Check internet connection
    _checkConnectivity();
  }

  Future<void> _ensureAdminSetup() async {
    try {
      print('DEBUG: Ensuring admin setup...');
      await AuthService.ensureAdminPasswordExists();
    } catch (e) {
      print('DEBUG: Error in admin setup: $e');
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      print('DEBUG: Checking internet connectivity...');
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('DEBUG: Internet connection available');
      }
    } catch (e) {
      print('DEBUG: No internet connection: $e');
      if (mounted) {
        _showError('Интернет алоқаси йўқ');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 500;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade400, Colors.blue.shade800],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: isTablet ? 400 : (isMobile ? screenWidth * 0.9 : screenWidth * 0.8),
                margin: EdgeInsets.all(isMobile ? 16 : 32),
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_city, 
                          size: isMobile ? 48 : 64, 
                          color: Colors.blue
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Text(
                          'Колодец Бошқаруви',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24, 
                            fontWeight: FontWeight.bold
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isMobile ? 24 : 32),
                        
                        // User type selection
                        Column(
                          children: [
                            RadioListTile<String>(
                              title: Text('Админ'),
                              value: 'admin',
                              groupValue: _selectedUserType,
                              onChanged: (value) => setState(() => _selectedUserType = value!),
                              contentPadding: EdgeInsets.zero,
                            ),
                            RadioListTile<String>(
                              title: Text('Тасдиқловчи'),
                              value: 'verifier',
                              groupValue: _selectedUserType,
                              onChanged: (value) => setState(() => _selectedUserType = value!),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Input field
                        TextFormField(
                          controller: _selectedUserType == 'admin' ? _passwordController : _keyController,
                          decoration: InputDecoration(
                            labelText: _selectedUserType == 'admin' ? 'Парол' : 'Калит',
                            prefixIcon: Icon(_selectedUserType == 'admin' ? Icons.lock : Icons.key),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: isMobile ? 12 : 16
                            ),
                          ),
                          obscureText: _selectedUserType == 'admin',
                          enabled: !_isLoading,
                        ),
                        
                        SizedBox(height: isMobile ? 20 : 24),
                        
                        // Test ma'lumotlari (faqat debug mode'da)
                        if (kDebugMode) 
                          Container(
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🔧 Test Ma\'lumotlari:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Admin parol: admin123',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        _passwordController.text = 'admin123';
                                        setState(() => _selectedUserType = 'admin');
                                      },
                                      child: Text('Admin parolni to\'ldirish'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await AuthService.createOrUpdateAdminPassword('admin123');
                                        _showError('Admin parol yangilandi: admin123');
                                      },
                                      child: Text('Parolni yaratish'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        
                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: isMobile ? 45 : 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Кириш',
                                    style: TextStyle(fontSize: isMobile ? 16 : 18),
                                  ),
                          ),
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
    );
  }

  Future<void> _login() async {
    if (_selectedUserType == 'admin' && _passwordController.text.isEmpty) {
      _showError('Парол киритинг');
      return;
    }
    
    if (_selectedUserType == 'verifier' && _keyController.text.isEmpty) {
      _showError('Калит киритинг');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('DEBUG: Login attempt - User type: $_selectedUserType');
      
      if (_selectedUserType == 'admin') {
        print('DEBUG: Attempting admin login...');
        final success = await AuthService.loginAsAdmin(_passwordController.text);
        print('DEBUG: Login result: $success');
        
        if (success) {
          print('DEBUG: Navigating to MapScreen...');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MapScreen()),
            );
          }
        } else {
          print('DEBUG: Login failed - showing error');
          if (mounted) {
            _showError('Нотўғри парол');
          }
        }
      } else {
        print('DEBUG: Attempting verifier login...');
        final verifierName = await AuthService.loginAsVerifier(_keyController.text);
        if (verifierName != null) {
          print('DEBUG: Verifier login successful, navigating...');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => VerifierScreen()),
            );
          }
        } else {
          print('DEBUG: Verifier login failed');
          if (mounted) {
            _showError('Нотўғри калит ёки фаол эмас');
          }
        }
      }
    } catch (e) {
      print('DEBUG: Login exception: $e');
      print('DEBUG: Exception type: ${e.runtimeType}');
      print('DEBUG: Stack trace: ${StackTrace.current}');
      if (mounted) {
        _showError('Хатолик юз берди: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    print('DEBUG: Showing error: $message');
    
    if (!mounted) {
      print('DEBUG: Widget not mounted, cannot show error');
      return;
    }
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('DEBUG: Error showing snackbar: $e');
      // Fallback: show dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Хатолик'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}









