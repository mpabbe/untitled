import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'platform_service.dart';
import '../models/detected_material.dart';
import 'package:path/path.dart' as path;

typedef ProgressCallback = void Function(double progress, String message);

class MaterialDetectionService {
  static const String _windowsLocalApiUrl = 'http://localhost:5001';
  static Process? _pythonProcess;
  static bool _isStartingApi = false;
  
  // Progress callback type
  
  // URL dan rasm orqali detection with progress
  Future<List<DetectedMaterial>> detectMaterialsFromImage(
    String imageUrl, {
    ProgressCallback? onProgress,
  }) async {
    try {
      print('🔍 Material detection from URL: $imageUrl');
      
      onProgress?.call(0.05, 'Python API tekshirilmoqda...');
      
      // Python API ni ishga tushirish
      final apiStarted = await _startPythonApiIfNeeded();
      if (!apiStarted) {
        print('❌ Python API ishga tushmadi, mock data qaytarish...');
        onProgress?.call(1.0, 'Mock data qaytarildi');
        return _getMockMaterials();
      }
      
      onProgress?.call(0.1, 'API ga so\'rov yuborilmoqda...');
      
      // API ga URL yuborish
      final response = await http.post(
        Uri.parse('$_windowsLocalApiUrl/detect_materials'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_url': imageUrl,
          'language': 'ru',
          'detection_mode': 'enhanced',
          'return_confidence': 'true',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessionId = data['session_id'];
        
        if (sessionId != null) {
          // Progress tracking
          await _trackProgress(sessionId, onProgress);
        }
        
        return _processDetectionResult(data);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      print('❌ Detection xatolik: $e');
      onProgress?.call(1.0, 'Xatolik: Mock data qaytarildi');
      return _getMockMaterials();
    }
  }
  
  // Progress tracking
  Future<void> _trackProgress(String sessionId, ProgressCallback? onProgress) async {
    if (onProgress == null) return;
    
    for (int i = 0; i < 30; i++) { // 30 sekund maksimal
      try {
        final response = await http.get(
          Uri.parse('$_windowsLocalApiUrl/progress/$sessionId')
        ).timeout(Duration(seconds: 2));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final progress = (data['progress'] ?? 0.0) / 100.0;
          final message = data['message'] ?? '';
          final status = data['status'] ?? 'processing';
          
          onProgress(progress, message);
          
          if (status == 'completed' || status == 'error') {
            break;
          }
        }
        
        await Future.delayed(Duration(milliseconds: 500));
      } catch (e) {
        print('Progress tracking error: $e');
        break;
      }
    }
  }
  
  // File dan detection with progress
  Future<List<DetectedMaterial>> detectMaterialsFromFile(
    File imageFile, {
    ProgressCallback? onProgress,
  }) async {
    return await detectMaterials(imageFile, onProgress: onProgress);
  }

  // Python API mavjudligini tekshirish
  Future<bool> isPythonApiAvailable() async {
    if (!PlatformService.isWindows) return false;
    return await _checkApiHealth();
  }
  
  // Python API ni avtomatik ishga tushirish
  Future<bool> _startPythonApiIfNeeded() async {
    if (!PlatformService.isWindows) return false;
    if (_isStartingApi) return false;
    
    // API allaqachon ishlayotganini tekshirish
    if (await _checkApiHealth()) {
      return true;
    }
    
    try {
      _isStartingApi = true;
      print('🚀 Python API ni avtomatik ishga tushirish...');
      
      // Python fayl yo'lini topish
      final currentDir = Directory.current.path;
      final pythonScript = path.join(currentDir, 'material_detection_api.py');
      
      if (!File(pythonScript).existsSync()) {
        print('❌ Python script topilmadi: $pythonScript');
        return false;
      }
      
      // Python API ni ishga tushirish (detached mode)
      _pythonProcess = await Process.start(
        'python',
        [pythonScript],
        workingDirectory: currentDir,
        mode: ProcessStartMode.detached,
        runInShell: true,
      );
      
      print('⏳ Python API ishga tushmoqda...');
      
      // API tayyor bo'lishini kutish (15 sekund)
      for (int i = 0; i < 15; i++) {
        await Future.delayed(Duration(seconds: 1));
        if (await _checkApiHealth()) {
          print('✅ Python API muvaffaqiyatli ishga tushdi!');
          return true;
        }
        print('⏳ Kutish... ${i + 1}/15');
      }
      
      print('❌ Python API 15 sekund ichida ishga tushmadi');
      return false;
      
    } catch (e) {
      print('❌ Python API ishga tushirishda xatolik: $e');
      return false;
    } finally {
      _isStartingApi = false;
    }
  }
  
  // API health check
  Future<bool> _checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_windowsLocalApiUrl/health')
      ).timeout(Duration(seconds: 2));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Main detection method with progress
  Future<List<DetectedMaterial>> detectMaterials(
    File imageFile, {
    ProgressCallback? onProgress,
  }) async {
    try {
      print('🔍 Material detection boshlandi...');
      print('📁 File path: ${imageFile.path}');
      print('📊 File size: ${await imageFile.length()} bytes');
      
      onProgress?.call(0.05, 'Python API tekshirilmoqda...');
      
      // Python API ni ishga tushirish
      final apiStarted = await _startPythonApiIfNeeded();
      if (!apiStarted) {
        print('❌ Python API ishga tushmadi, mock data qaytarish...');
        onProgress?.call(1.0, 'Mock data qaytarildi');
        return _getMockMaterials();
      }
      
      print('✅ Python API tayyor');
      onProgress?.call(0.1, 'Fayl yuborilmoqda...');
      
      // API ga fayl yuborish
      final request = http.MultipartRequest(
        'POST', 
        Uri.parse('$_windowsLocalApiUrl/detect_materials')
      );
      
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      request.fields['language'] = 'ru';
      request.fields['detection_mode'] = 'enhanced';
      request.fields['return_confidence'] = 'true';
      
      print('📤 Request yuborilmoqda...');
      print('🔗 URL: $_windowsLocalApiUrl/detect_materials');
      print('📋 Fields: ${request.fields}');
      
      final response = await request.send().timeout(Duration(seconds: 60));
      final responseBody = await response.stream.bytesToString();

      print('📥 Response keldi:');
      print('📊 Status code: ${response.statusCode}');
      print('📄 Response body length: ${responseBody.length}');
      print('📝 Response body: ${responseBody.substring(0, responseBody.length > 500 ? 500 : responseBody.length)}...');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(responseBody);
          print('✅ JSON parse muvaffaqiyatli');
          print('🔍 Data keys: ${data.keys.toList()}');
          print('✨ Success: ${data['success']}');
          
          if (data['materials'] != null) {
            print('📦 Materials count: ${(data['materials'] as List).length}');
          }
          
          final sessionId = data['session_id'];
          
          if (sessionId != null) {
            print('🆔 Session ID: $sessionId');
            // Progress tracking
            await _trackProgress(sessionId, onProgress);
          }
          
          final result = _processDetectionResult(data);
          print('🎯 Final result: ${result.length} materials');
          return result;
        } catch (e) {
          print('❌ JSON parse error: $e');
          print('📄 Raw response: $responseBody');
          throw Exception('JSON parse error: $e');
        }
      } else {
        print('❌ HTTP Error ${response.statusCode}');
        print('📄 Error body: $responseBody');
        throw Exception('HTTP ${response.statusCode}: $responseBody');
      }
      
    } catch (e) {
      print('❌ Detection xatolik: $e');
      print('📍 Stack trace: ${StackTrace.current}');
      onProgress?.call(1.0, 'Xatolik: Mock data qaytarildi');
      return _getMockMaterials();
    }
  }
  
  // API javobini qayta ishlash
  List<DetectedMaterial> _processDetectionResult(Map<String, dynamic> data) {
    print('🔄 Processing detection result...');
    print('📊 Data: $data');
    
    if (data['success'] != true) {
      final error = data['error'] ?? 'Noma\'lum xatolik';
      print('❌ API error: $error');
      throw Exception('API xatolik qaytardi: $error');
    }
    
    final materialsData = data['materials'] as List? ?? [];
    print('📦 Materials data length: ${materialsData.length}');
    
    final result = materialsData.map((material) {
      print('🔧 Processing material: $material');
      
      return DetectedMaterial(
        name: material['name'] ?? 'Noma\'lum material',
        size: material['size'] ?? 'Standart',
        quantity: material['quantity'] ?? 1,
        isMainComponent: material['category'] == 'main_component',
        category: material['category'] ?? 'other',
        unit: material['unit'] ?? 'dona',
        confidence: (material['confidence'] ?? 0.0).toDouble(),
        notes: (material['notes'] as List?)?.cast<String>() ?? [],
      );
    }).toList();
    
    print('✅ Processed ${result.length} materials');
    return result;
  }
  
  // Test materiallari
  List<DetectedMaterial> _getMockMaterials() {
    return [
      DetectedMaterial(
        name: 'Труба ПНД',
        size: 'Ø110мм',
        quantity: 5,
        unit: 'дона',
        confidence: 0.85,
        notes: ['Mock ma\'lumot'],
      ),
      DetectedMaterial(
        name: 'Муфта соединительная',
        size: 'Ø110мм',
        quantity: 3,
        unit: 'дона',
        confidence: 0.92,
        notes: ['Mock ma\'lumot'],
      ),
    ];
  }
  
  // App yopilganda Python process ni to'xtatish
  static void stopPythonApi() {
    if (_pythonProcess != null) {
      print('🛑 Python API ni to\'xtatish...');
      _pythonProcess!.kill();
      _pythonProcess = null;
    }
  }
}


