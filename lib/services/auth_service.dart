import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _currentUserType;
  static String? _currentVerifierName;
  static String? _currentVerifierKey;

  // Admin login - improved with better error handling
  static Future<bool> loginAsAdmin(String password) async {
    try {
      print('DEBUG: Admin login attempt with password: "${password}"');
      print('DEBUG: Password length: ${password.length}');
      
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('admin')
          .get();
      
      print('DEBUG: Firestore document exists: ${doc.exists}');
      
      if (doc.exists) {
        final data = doc.data();
        print('DEBUG: Document data: $data');
        
        final storedPassword = data?['password'] as String?;
        print('DEBUG: Stored password: "${storedPassword}"');
        print('DEBUG: Stored password length: ${storedPassword?.length}');
        print('DEBUG: Password match: ${storedPassword == password}');
        
        if (storedPassword == password) {
          _currentUserType = 'admin';
          print('DEBUG: Admin login successful');
          return true;
        } else {
          print('DEBUG: Password mismatch!');
          print('DEBUG: Expected: "$storedPassword"');
          print('DEBUG: Received: "$password"');
        }
      } else {
        print('DEBUG: Admin document does not exist in Firestore!');
      }
      
      print('DEBUG: Admin login failed');
      return false;
    } catch (e) {
      print('DEBUG: Admin login error: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      return false;
    }
  }

  // Verifier login
  static Future<String?> loginAsVerifier(String key) async {
    try {
      final snapshot = await _firestore
          .collection('verifiers')
          .where('key', isEqualTo: key)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final verifierData = snapshot.docs.first.data();
        _currentUserType = 'verifier';
        _currentVerifierName = verifierData['name'];
        _currentVerifierKey = key;
        return verifierData['name'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Generate key for verifier
  static String generateVerifierKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return '000$random';
  }

  // Logout
  static void logout() {
    _currentUserType = null;
    _currentVerifierName = null;
    _currentVerifierKey = null;
  }

  // Getters
  static bool get isAdmin => _currentUserType == 'admin';
  static bool get isVerifier => _currentUserType == 'verifier';
  static String? get currentVerifierName => _currentVerifierName;
  static String? get currentUserType => _currentUserType;

  // Admin parolni yaratish yoki yangilash
  static Future<bool> createOrUpdateAdminPassword(String newPassword) async {
    try {
      print('DEBUG: Creating/updating admin password...');
      
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('admin')
          .set({
        'password': newPassword,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      
      print('DEBUG: Admin password created/updated successfully');
      return true;
    } catch (e) {
      print('DEBUG: Error creating admin password: $e');
      return false;
    }
  }

  // Admin parolni tekshirish va yaratish
  static Future<void> ensureAdminPasswordExists() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('admin')
          .get();
      
      if (!doc.exists) {
        print('DEBUG: Admin document not found, creating with default password...');
        await createOrUpdateAdminPassword('admin123'); // Default parol
        print('DEBUG: Default admin password created: admin123');
      } else {
        final data = doc.data();
        final password = data?['password'];
        print('DEBUG: Admin password exists: $password');
      }
    } catch (e) {
      print('DEBUG: Error ensuring admin password: $e');
    }
  }
}



