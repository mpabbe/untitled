import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:untitled/screens/map_screen.dart';
import 'firebase_options.dart';
import 'services/material_detection_service.dart';
import 'models/detected_material.dart';
import 'dart:io';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Material Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MaterialDetectionScreen extends StatefulWidget {
  @override
  _MaterialDetectionScreenState createState() => _MaterialDetectionScreenState();
}

class _MaterialDetectionScreenState extends State<MaterialDetectionScreen> {
  final MaterialDetectionService _detectionService = MaterialDetectionService();
  List<DetectedMaterial> _detectedMaterials = [];
  File? _selectedImage;
  bool _isLoading = false;
  String _statusMessage = 'Rasm tanlang va materiallarni aniqlang';

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'bmp'],
      );

      if (result != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
          _detectedMaterials.clear();
          _statusMessage = 'Rasm tanlandi. "Materiallarni Aniqlash" tugmasini bosing';
        });
      }
    } catch (e) {
      _showError('Rasm tanlashda xatolik: $e');
    }
  }

  Future<void> _detectMaterials() async {
    if (_selectedImage == null) {
      _showError('Iltimos, avval rasm tanlang!');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'AI materiallarni aniqlamoqda...';
    });

    try {
      final materials = await _detectionService.detectMaterialsFromFile(_selectedImage!);
      
      setState(() {
        _detectedMaterials = materials;
        _isLoading = false;
        _statusMessage = '${materials.length} ta material aniqlandi';
      });

      if (materials.isEmpty) {
        _showError('Hech qanday material aniqlanmadi');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Xatolik yuz berdi';
      });
      _showError('Material aniqlashda xatolik: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'AI Material Detection',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Image Selection Section
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_selectedImage != null) ...[
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ] else ...[
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 64, color: Colors.grey[400]),
                              SizedBox(height: 8),
                              Text(
                                'Rasm tanlanmagan',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(Icons.photo_library),
                            label: Text('Rasm Tanlash'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _detectMaterials,
                            icon: _isLoading 
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(Icons.search),
                            label: Text(_isLoading ? 'Aniqlanmoqda...' : 'Materiallarni Aniqlash'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Results Section
            if (_detectedMaterials.isNotEmpty) ...[
              Text(
                'Aniqlangan Materiallar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
              
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _detectedMaterials.length,
                itemBuilder: (context, index) {
                  final material = _detectedMaterials[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Icon(
                          Icons.construction,
                          color: Colors.blue[700],
                        ),
                      ),
                      title: Text(
                        material.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ishonch: ${(material.confidence * 100).toStringAsFixed(1)}%'),
                          if (material.description.isNotEmpty)
                            Text(
                              material.description,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: material.confidence > 0.8 ? Colors.green[100] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          material.confidence > 0.8 ? 'Yuqori' : 'O\'rta',
                          style: TextStyle(
                            color: material.confidence > 0.8 ? Colors.green[700] : Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
