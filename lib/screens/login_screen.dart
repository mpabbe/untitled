import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kDebugMode uchun
import 'dart:io';
import '../services/auth_service.dart';
import 'map_screen.dart';
import 'verifier_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'user_map_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  final _keyController = TextEditingController();
  bool _isLoading = false;
  String _selectedUserType = 'user'; // Default user

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
                        _buildUserTypeSelection(),
                        
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

  Widget _buildUserTypeSelection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            title: Text('Фойдаланувчи'),
            subtitle: Text('Колодецларни кўриш'),
            value: 'user',
            groupValue: _selectedUserType,
            onChanged: (value) => setState(() => _selectedUserType = value!),
          ),
          Divider(height: 1),
          RadioListTile<String>(
            title: Text('Администратор'),
            subtitle: Text('Тўлиқ бошқарув'),
            value: 'admin',
            groupValue: _selectedUserType,
            onChanged: (value) => setState(() => _selectedUserType = value!),
          ),
          Divider(height: 1),
          RadioListTile<String>(
            title: Text('Тасдиқловчи'),
            subtitle: Text('Материалларни тасдиқлаш'),
            value: 'verifier',
            groupValue: _selectedUserType,
            onChanged: (value) => setState(() => _selectedUserType = value!),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      bool success = false;
      
      if (_selectedUserType == 'user') {
        // User uchun _keyController ishlatish kerak, _passwordController emas
        success = await AuthService.loginAsUser(_keyController.text);
        if (success && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => UserMapScreen()),
          );
        }
      } else if (_selectedUserType == 'admin') {
        success = await AuthService.loginAsAdmin(_passwordController.text);
        if (success && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MapScreen()),
          );
        }
      } else {
        final verifierName = await AuthService.loginAsVerifier(_keyController.text);
        if (verifierName != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => VerifierScreen()),
          );
        }
      }

      if (!success && mounted) {
        _showError('Нотўғри маълумотлар');
      }
    } catch (e) {
      if (mounted) {
        _showError('Хатолик: $e');
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



