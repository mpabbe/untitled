import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/building.dart';
import '../models/detected_material.dart';
import '../models/material_item.dart';
import '../services/firebase_service.dart';
import '../services/material_service.dart';
import '../services/material_detection_service.dart';
import 'map_picker_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/platform_service.dart';

class AddBuildingScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const AddBuildingScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<AddBuildingScreen> createState() => _AddBuildingScreenState();
}

class _AddBuildingScreenState extends State<AddBuildingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic form controllers
  final _serialNumberController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _uniqueNameController = TextEditingController();
  final _schemeUrlController = TextEditingController();
  final _kolodetsConditionController = TextEditingController();
  final _commentController = TextEditingController();
  final List<TextEditingController> _imageUrlControllers = [TextEditingController()];

  // Dropdown selections
  String? _selectedVerificationPerson;
  String? _selectedKolodetsStatus;
  BuildingStatus _selectedStatus = BuildingStatus.notStarted;
  List<String> _selectedBuilders = []; // String? _selectedBuilder o'rniga List<String>

  // Required materials system - Always defined materials needed for construction
  final List<String?> _selectedRequiredMaterials = [null];
  final List<TextEditingController> _requiredQuantityControllers = [TextEditingController()];
  final List<TextEditingController> _requiredSizeControllers = [TextEditingController()];
  
  // Available materials system - Materials placed on construction site
  final List<String?> _selectedAvailableMaterials = [null];
  final List<TextEditingController> _availableQuantityControllers = [TextEditingController()];
  final List<TextEditingController> _availableSizeControllers = [TextEditingController()];

  // State variables
  bool _isSaving = false;
  bool _isLoadingMaterials = true;
  bool _isLoadingBuilders = true;
  bool _isLoadingVerifiers = true;
  bool _isDetecting = false;
  String _detectionStatus = '';
  double _uploadProgress = 0.0;

  // Data from Firebase
  List<MaterialItem> _materials = [];
  List<String> _builders = [];
  List<String> _verifiers = [];
  final MaterialService _materialService = MaterialService();

  // Static data - faqat kolodets status qoladi
  final _kolodetsStatusList = ['Бор', 'Йўқ'];

  List<Map<String, dynamic>> _savedImages = [];
  bool _showSavedImages = false;

  // Class variables'ga qo'shamiz
  String? _detectedImageUrl;
  File? _detectedImageFile;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Bitta metod orqali barcha ma'lumotlarni yuklash
    _loadSavedImages(); // Saqlangan rasmlarni yuklash
  }

  // Saqlangan rasmlarni yuklash
  Future<void> _loadSavedImages() async {
    try {
      final images = await FirebaseService.getSavedImages();
      setState(() {
        _savedImages = images;
      });
    } catch (e) {
      print('Error loading saved images: $e');
    }
  }

  // Saqlangan rasmni tanlash
  void _selectSavedImage(String imageUrl) {
    setState(() {
      _imageUrlControllers.add(TextEditingController(text: imageUrl));
    });
    
    // Usage count'ni oshirish
    FirebaseService.incrementImageUsage(imageUrl);
    
    _showSuccessSnackBar('Расм қўшилди');
  }

  @override
  void dispose() {
    // Required materials controllers
    for (final controller in _requiredQuantityControllers) {
      controller.dispose();
    }
    for (final controller in _requiredSizeControllers) {
      controller.dispose();
    }
    
    // Available materials controllers
    for (final controller in _availableQuantityControllers) {
      controller.dispose();
    }
    for (final controller in _availableSizeControllers) {
      controller.dispose();
    }
    
    // Other controllers
    _uniqueNameController.dispose();
    _schemeUrlController.dispose();
    _commentController.dispose();
    
    for (final controller in _imageUrlControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingMaterials = true;
      _isLoadingBuilders = true;
      _isLoadingVerifiers = true;
    });

    try {
      final results = await Future.wait([
        _materialService.getMaterials(),
        _materialService.getBuilders(),
        _materialService.getVerifiers(),
      ]);

      setState(() {
        _materials = results[0] as List<MaterialItem>;
        _builders = results[1] as List<String>;
        _verifiers = results[2] as List<String>;
        _isLoadingMaterials = false;
        _isLoadingBuilders = false;
        _isLoadingVerifiers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMaterials = false;
        _isLoadingBuilders = false;
        _isLoadingVerifiers = false;
      });
      _showErrorSnackBar('Маълумотларни юклашда хатолик: $e');
    }
  }

  // void _addImageUrlField() {
  //   setState(() {
  //     _imageUrlControllers.add(TextEditingController());
  //   });
  // }

  void _removeImageUrl(int index) {
    if (_imageUrlControllers.length > 1) {
      setState(() {
        _imageUrlControllers[index].dispose();
        _imageUrlControllers.removeAt(index);
      });
    }
  }

  void _addRequiredMaterial() {
    setState(() {
      _selectedRequiredMaterials.add(null);
      _requiredQuantityControllers.add(TextEditingController());
      _requiredSizeControllers.add(TextEditingController());
      
      // Автоматик мавжуд материалларга ҳам қўшиш
      _selectedAvailableMaterials.add(null);
      _availableQuantityControllers.add(TextEditingController());
      _availableSizeControllers.add(TextEditingController());
    });
  }

  void _removeRequiredMaterial(int index) {
    if (_selectedRequiredMaterials.length > 1) {
      setState(() {
        _selectedRequiredMaterials.removeAt(index);
        _requiredQuantityControllers[index].dispose();
        _requiredQuantityControllers.removeAt(index);
        _requiredSizeControllers[index].dispose();
        _requiredSizeControllers.removeAt(index);
        
        // Мавжуд материаллардан ҳам ўчириш
        if (index < _selectedAvailableMaterials.length) {
          _selectedAvailableMaterials.removeAt(index);
          _availableQuantityControllers[index].dispose();
          _availableQuantityControllers.removeAt(index);
          _availableSizeControllers[index].dispose();
          _availableSizeControllers.removeAt(index);
        }
      });
    }
  }

  void _showInfoSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  String _getMaterialNameById(String materialId) {
    final material = _materials.firstWhere(
      (m) => m.id == materialId,
      orElse: () => MaterialItem(id: '', name: 'Номаълум', unit: ''),
    );
    return material.name;
  }

  String _getMaterialUnitById(String materialId) {
    final material = _materials.firstWhere(
      (m) => m.id == materialId,
      orElse: () => MaterialItem(id: '', name: '', unit: 'дона'),
    );
    return material.unit;
  }

  String _getMaterialDefaultSize(String? materialId) {
    if (materialId == null) return '';
    
    // Agar shu material boshqa qatorda ishlatilgan bo'lsa, o'sha o'lchamni qaytarish
    for (int i = 0; i < _selectedRequiredMaterials.length; i++) {
      if (_selectedRequiredMaterials[i] == materialId && _requiredSizeControllers[i].text.isNotEmpty) {
        return _requiredSizeControllers[i].text;
      }
    }
    
    // Aks holda bo'sh string qaytarish
    return '';
  }

  bool _validateMaterialSelections() {
    // Check required materials
    final selectedMaterialIds = <String>[];
    
    for (int i = 0; i < _selectedRequiredMaterials.length; i++) {
      final materialId = _selectedRequiredMaterials[i];
      final quantity = _requiredQuantityControllers[i].text.trim();
      
      if (materialId != null && quantity.isNotEmpty) {
        final parsedQuantity = double.tryParse(quantity);
        if (parsedQuantity == null || parsedQuantity <= 0) {
          _showErrorSnackBar('${i + 1}-қатордаги сон нотўғри');
          return false;
        }
        
        // Allow duplicate materials - remove this check
        // selectedMaterialIds.add(materialId);
      }
    }

    // Check available materials
    for (int i = 0; i < _selectedAvailableMaterials.length; i++) {
      final materialId = _selectedAvailableMaterials[i];
      final quantity = _availableQuantityControllers[i].text.trim();
      
      if (materialId != null && quantity.isNotEmpty) {
        final parsedQuantity = double.tryParse(quantity);
        if (parsedQuantity == null || parsedQuantity < 0) {
          _showErrorSnackBar('${i + 1}-қатордаги мавжуд материал сони нотўғри');
          return false;
        }
      }
    }
    
    print('Material validation passed'); // Debug
    return true;
  }

  MaterialStatus _calculateMaterialStatus(
    List<Map<String, dynamic>> requiredMaterialsData,
    List<Map<String, dynamic>> availableMaterialsData,
  ) {
    if (requiredMaterialsData.isEmpty) return MaterialStatus.complete;

    final requiredMaterials = <String, double>{};
    final availableMaterials = <String, double>{};

    // Group required materials by ID + size
    for (final material in requiredMaterialsData) {
      final materialId = material['materialId'] as String;
      final size = material['size']?.toString() ?? '';
      final key = '$materialId|$size'; // Combine ID and size
      final quantity = double.tryParse(material['quantity'].toString()) ?? 0;
      requiredMaterials[key] = (requiredMaterials[key] ?? 0) + quantity;
    }

    // Group available materials by ID + size
    for (final material in availableMaterialsData) {
      final materialId = material['materialId'] as String;
      final size = material['size']?.toString() ?? '';
      final key = '$materialId|$size'; // Combine ID and size
      final quantity = double.tryParse(material['quantity'].toString()) ?? 0;
      availableMaterials[key] = (availableMaterials[key] ?? 0) + quantity;
    }

    bool hasShortage = false;
    bool hasCritical = false;

    // Check each required material
    for (final entry in requiredMaterials.entries) {
      final key = entry.key;
      final requiredQty = entry.value;
      final availableQty = availableMaterials[key] ?? 0;

      // Agar kerakli > mavjud bo'lsa - kamchillik
      if (requiredQty > availableQty) {
        hasShortage = true;
        if (availableQty < requiredQty * 0.5) {
          hasCritical = true;
        }
      }
    }

    if (hasCritical) return MaterialStatus.critical;
    if (hasShortage) return MaterialStatus.shortage;
    return MaterialStatus.complete;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateMaterialSelections()) return;

    setState(() => _isSaving = true);

    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final List<String> imageUrls = [];

      final List<Map<String, dynamic>> requiredMaterialsData = [];
      final List<Map<String, dynamic>> availableMaterialsData = [];

      // Process required materials
      for (int i = 0; i < _selectedRequiredMaterials.length; i++) {
        final materialId = _selectedRequiredMaterials[i];
        final quantity = _requiredQuantityControllers[i].text.trim();
        final size = _requiredSizeControllers[i].text.trim();

        if (materialId != null && quantity.isNotEmpty) {
          final materialName = _getMaterialNameById(materialId);
          final materialUnit = _getMaterialUnitById(materialId);
          final parsedQuantity = double.tryParse(quantity) ?? 0;

          print('Processing required material $i: ID=$materialId, Name=$materialName, Quantity=$quantity, Size=$size'); // Debug

          if (parsedQuantity > 0) {
            requiredMaterialsData.add({
              'materialId': materialId,
              'materialName': materialName,
              'quantity': quantity, // String sifatida saqlash
              'unit': materialUnit,
              'size': size.isNotEmpty ? size : null,
            });
          }
        }
      }

      // Process available materials
      for (int i = 0; i < _selectedAvailableMaterials.length; i++) {
        final materialId = _selectedAvailableMaterials[i];
        final quantity = _availableQuantityControllers[i].text.trim();
        final size = _availableSizeControllers[i].text.trim();

        if (materialId != null && quantity.isNotEmpty) {
          final materialName = _getMaterialNameById(materialId);
          final materialUnit = _getMaterialUnitById(materialId);
          final parsedQuantity = double.tryParse(quantity) ?? 0;

          print('Processing available material $i: ID=$materialId, Name=$materialName, Quantity=$quantity, Size=$size'); // Debug

          if (parsedQuantity > 0) {
            availableMaterialsData.add({
              'materialId': materialId,
              'materialName': materialName,
              'quantity': quantity, // String sifatida saqlash
              'unit': materialUnit,
              'size': size.isNotEmpty ? size : null,
              'addedAt': DateTime.now().toIso8601String(),
            });
          }
        }
      }

      print('Final required materials data: $requiredMaterialsData'); // Debug
      print('Final available materials data: $availableMaterialsData'); // Debug

      // Calculate material status
      final materialStatus = _calculateMaterialStatus(
        requiredMaterialsData,
        availableMaterialsData,
      );

      final building = Building(
        id: id,
        latitude: widget.latitude,
        longitude: widget.longitude,
        uniqueName: _serialNumberController.text.trim(),
        regionName: _locationNameController.text.trim(),
        verificationPerson: null, // Always null when creating
        kolodetsStatus: _selectedKolodetsStatus,
        builders: _selectedBuilders.isNotEmpty ? _selectedBuilders : null,
        schemeUrl: _schemeUrlController.text.trim().isEmpty
            ? null
            : _schemeUrlController.text.trim(),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        images: imageUrls,
        customData: {},
        requiredMaterials: requiredMaterialsData,
        availableMaterials: availableMaterialsData,
        materialStatus: materialStatus,
        status: _selectedStatus,
        createdAt: DateTime.now(),
      );

      print('Building object created: ${building.toJson()}'); // Debug

      await FirebaseService.saveBuilding(building);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Бино муваффақиятли қўшилди'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving building: $e'); // Debug
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Хатолик: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Бино қўшиш'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          final isMobile = constraints.maxWidth < 500;
          
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform info - responsive
                  _buildPlatformInfo(isMobile),
                  SizedBox(height: isMobile ? 16 : 20),
                  
                  // Basic info section - responsive layout
                  if (isTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildBasicInfoSection(isMobile)),
                        SizedBox(width: 20),
                        Expanded(flex: 3, child: _buildMaterialsSection(isMobile)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildBasicInfoSection(isMobile),
                        SizedBox(height: 20),
                        _buildMaterialsSection(isMobile),
                      ],
                    ),
                  
                  SizedBox(height: isMobile ? 16 : 20),
                  _buildImagesSection(),
                  
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildSaveButton(isMobile),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlatformInfo(bool isMobile) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PlatformService.isWindows ? Colors.blue.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PlatformService.isWindows ? Colors.blue.shade200 : Colors.orange.shade200
        ),
      ),
      child: Row(
        children: [
          Icon(
            PlatformService.isWindows ? Icons.computer : Icons.phone_android,
            color: PlatformService.isWindows ? Colors.blue : Colors.orange,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform: ${PlatformService.platformName}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  PlatformService.isWindows 
                    ? 'AI материал аниқлаш (Python API)'
                    : 'Қўлда материал киритиш режими',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (PlatformService.isWindows)
            FutureBuilder<bool>(
              future: MaterialDetectionService().isPythonApiAvailable(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  );
                }
                
                final isAvailable = snapshot.data ?? false;
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAvailable ? 'AI Ready' : 'AI Offline',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Асосий маълумотлар',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            
            // Serial Number
            TextFormField(
              controller: _serialNumberController,
              decoration: const InputDecoration(
                labelText: 'Колодец серия рақами *',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Колодец серия рақамини киритинг';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Location Name
            TextFormField(
              controller: _locationNameController,
              decoration: InputDecoration(
                labelText: 'Жой номи *',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Жой номини киритинг';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Verification person dropdown
            DropdownButtonFormField<String>(
              value: _selectedVerificationPerson,
              decoration: InputDecoration(
                labelText: 'Тасдиқловчи *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              items: [
                if (_isLoadingVerifiers)
                  DropdownMenuItem(value: null, child: Text('Юкланмоқда...'))
                else ...[
                  ..._verifiers.map((person) => DropdownMenuItem(
                    value: person,
                    child: Text(person),
                  )),
                  // DropdownMenuItem(
                  //   value: 'add_new_verifier',
                  //   child: Row(
                  //     children: [
                  //       Icon(Icons.add, size: 16, color: Colors.green),
                  //       SizedBox(width: 8),
                  //       Text('Янги тасдиқловчи қўшиш', style: TextStyle(color: Colors.green)),
                  //     ],
                  //   ),
                  // ),
                ],
              ],
              onChanged: _isLoadingVerifiers ? null : (value) {
                if (value == 'add_new_verifier') {
                  _showAddVerifierDialog();
                } else {
                  setState(() {
                    _selectedVerificationPerson = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value == 'add_new_verifier') {
                  return 'Тасдиқловчини танланг';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Kolodets status
            DropdownButtonFormField<String>(
              value: _selectedKolodetsStatus,
              decoration: InputDecoration(
                labelText: 'Колодец ҳолати *',
                prefixIcon: Icon(Icons.water_drop),
                border: OutlineInputBorder(),
              ),
              items: _kolodetsStatusList.map((status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedKolodetsStatus = value;
                  // Agar kolodets "Йўқ" bo'lsa, status "Бошланмаган" qilish
                  if (value == 'Йўқ') {
                    _selectedStatus = BuildingStatus.notStarted;
                  }
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Колодец ҳолатини танланг';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Building status - faqat kolodets "Бор" bo'lsa ko'rsatish
            if (_selectedKolodetsStatus == 'Бор')
              DropdownButtonFormField<BuildingStatus>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Лойиҳа ҳолати',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                items: BuildingStatus.values.map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(_getStatusText(status)),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value ?? BuildingStatus.notStarted;
                  });
                },
              ),
            if (_selectedKolodetsStatus == 'Бор')
              SizedBox(height: 16),

            // Builders section - bir nechta quruvchi
            _buildBuildersSection(),
            SizedBox(height: 16),

            // Scheme URL section - to'liq tuzatilgan
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _schemeUrlController,
                    enabled: !_isDetecting,
                    decoration: InputDecoration(
                      labelText: 'Схема расми URL',
                      prefixIcon: Icon(Icons.image),
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com/scheme.jpg',
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: (_schemeUrlController.text.trim().isNotEmpty && !_isDetecting)
                      ? _detectMaterialsFromScheme
                      : null,
                  icon: _isDetecting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.auto_awesome, size: 18),
                  label: Text(_isDetecting ? 'Ишламоқда...' : 'URL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: !_isDetecting ? _detectMaterialsFromFile : null,
                  icon: _isDetecting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.file_upload, size: 18),
                  label: Text(_isDetecting ? 'Ишламоқда...' : 'Файл'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            _buildProgressIndicator(), // Progress indicator qo'shish
            SizedBox(height: 16),

            // Comment field
            TextFormField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Изоҳ',
                hintText: 'Қўшимча маълумотлар, эслатмалар...',
                prefixIcon: Icon(Icons.comment),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.newline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsSection(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Icon(Icons.construction, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Материаллар',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Spacer(),
                // Quick stats
                if (_selectedRequiredMaterials.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedRequiredMaterials.length} материал',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Scheme URL input with AI detectio

            // Progress indicator
            if (_isDetecting) ...[
              const SizedBox(height: 12),
              _buildProgressIndicator(),
            ],

            // Image preview section
            if (_detectedImageUrl != null || _detectedImageFile != null) ...[
              const SizedBox(height: 16),
              _buildDetectedImagePreview(),
            ],

            const SizedBox(height: 20),

            // Quick add buttons for common materials
            _buildQuickAddButtons(),

            const SizedBox(height: 16),

            // Materials table
            if (_selectedRequiredMaterials.isNotEmpty) ...[
              _buildMaterialsTable(),
            ] else ...[
              _buildEmptyMaterialsState(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExcelStyleMaterialRow(int index) {
    final materialId = _selectedRequiredMaterials[index];
    final materialUnit = materialId != null ? _getMaterialUnitById(materialId) : 'дона';

    // Remove duplicate check completely - allow unlimited duplicates

    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            // Material nomi - Autocomplete bilan
            Expanded(
              flex: 4,
              child: Autocomplete<MaterialItem>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _materials;
                  }
                  // Allow all materials - no duplicate filtering
                  final filteredMaterials = _materials.where((material) =>
                    material.name.toLowerCase().contains(textEditingValue.text.toLowerCase())
                  ).toList();
                  return filteredMaterials;
                },
                displayStringForOption: (MaterialItem option) => option.name,
                fieldViewBuilder: (context, textEditingController, focusNode, onEditingComplete) {

                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Материал номи',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      border: OutlineInputBorder(),
                      // Remove error text for duplicates
                    ),
                    onSubmitted: (value) {
                      // Enter bosilganda yangi qator qo'shish
                      if (index == _selectedRequiredMaterials.length - 1) {
                        _addRequiredMaterial();
                      }
                    },
                  );
                },
                onSelected: (MaterialItem selection) {
                  setState(() {
                    _selectedRequiredMaterials[index] = selection.id;
                    _selectedAvailableMaterials[index] = selection.id;

                    // O'lcham va birlikni avtomatik to'ldirish
                    final size = _getMaterialDefaultSize(selection.id);
                    if (size.isNotEmpty) {
                      _requiredSizeControllers[index].text = size;
                      _availableSizeControllers[index].text = size;
                    }

                    // Agar oxirgi qator bo'lsa, yangi qator qo'shish
                    if (index == _selectedRequiredMaterials.length - 1) {
                      _addRequiredMaterial();
                    }
                  });
                },
              ),
            ),

            SizedBox(width: 8),

            // O'lcham
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _requiredSizeControllers[index],
                decoration: InputDecoration(
                  hintText: 'Ўлчам',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // Available materials'dagi o'lchamni ham yangilash
                  if (index < _availableSizeControllers.length) {
                    _availableSizeControllers[index].text = value;
                  }
                },
                onFieldSubmitted: (value) {
                  if (index == _selectedRequiredMaterials.length - 1) {
                    _addRequiredMaterial();
                  }
                },
              ),
            ),

            SizedBox(width: 8),

            // Kerakli miqdor
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _requiredQuantityControllers[index],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Сони',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (value) {
                  if (index == _selectedRequiredMaterials.length - 1) {
                    _addRequiredMaterial();
                  }
                },
              ),
            ),



            SizedBox(width: 8),

            // Birlik
            Container(
              width: 60,
              child: Text(
                materialUnit,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(width: 8),

            // Mavjud miqdor
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _availableQuantityControllers[index],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Мавжуд',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (value) {
                  if (index == _selectedRequiredMaterials.length - 1) {
                    _addRequiredMaterial();
                  }
                },
              ),
            ),

            SizedBox(width: 8),

            // Delete button
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: _selectedRequiredMaterials.length > 1
                  ? () => _removeRequiredMaterial(index)
                  : null,
              padding: EdgeInsets.all(4),
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  void _addMaterial() {
    // DELETE THIS METHOD - replaced by _addRequiredMaterial and _addAvailableMaterial
  }

  void _removeMaterial(int index) {
    // DELETE THIS METHOD - replaced by _removeRequiredMaterial and _removeAvailableMaterial
  }

  Future<void> _showAddMaterialDialog(int index) async {
    final nameController = TextEditingController();
    final unitController = TextEditingController(text: 'дона');
    bool isLoading = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Янги материал қўшиш'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Материал номи *',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                enabled: !isLoading,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: unitController,
                decoration: InputDecoration(
                  labelText: 'Ўлчов бирлиги *',
                  border: OutlineInputBorder(),
                ),
                enabled: !isLoading,
              ),
              if (isLoading) ...[
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Қўшилмоқда...'),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context, false),
              child: Text('Бекор қилиш'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final name = nameController.text.trim();
                final unit = unitController.text.trim();

                if (name.isEmpty) {
                  _showErrorSnackBar('Материал номини киритинг');
                  return;
                }

                if (unit.isEmpty) {
                  _showErrorSnackBar('Ўлчов бирлигини киритинг');
                  return;
                }

                setDialogState(() => isLoading = true);

                try {
                  final exists = await _materialService.materialExists(name);
                  if (exists) {
                    _showErrorSnackBar('Бу материал аллақачон мавжуд');
                    setDialogState(() => isLoading = false);
                    return;
                  }

                  final newMaterial = MaterialItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    unit: unit,
                  );

                  await _materialService.addMaterial(newMaterial);

                  final materials = await _materialService.getMaterials(forceRefresh: true);
                  setState(() {
                    _materials = materials;
                    // Don't reference _selectedMaterials - this is old code
                  });

                  Navigator.pop(context, true);
                  _showSuccessSnackBar('Материал муваффақиятли қўшилди');
                } catch (e) {
                  _showErrorSnackBar('Хатолик: $e');
                  setDialogState(() => isLoading = false);
                }
              },
              child: Text('Қўшиш'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialStatusIndicator(int index) {
    // This function is no longer needed with the new structure
    // Remove it completely or update for new structure
    return SizedBox.shrink(); // Placeholder - remove this method
  }

  Widget _buildImagesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Расм URL лари',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(height: 16),

            // Only URL input fields, no file upload
            ..._imageUrlControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;

              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Расм URL киритинг',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.link),
                        ),
                        onChanged: (value) => _saveImageUrl(value),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeImageUrl(index),
                    ),
                  ],
                ),
              );
            }).toList(),

            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _imageUrlControllers.add(TextEditingController());
                });
              },
              icon: Icon(Icons.add),
              label: Text('URL қўшиш'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 48 : 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSaving
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Сақланмоқда...'),
                ],
              )
            : Text(
                'Сақлаш',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  String _getStatusText(BuildingStatus status) {
    switch (status) {
      case BuildingStatus.notStarted:
        return 'Бошланмаган';
      case BuildingStatus.inProgress:
        return 'Жараёнда';
      case BuildingStatus.completed:
        return 'Тугалланган';
      case BuildingStatus.paused:
        return 'Тўхтатилган';
      default:
        return 'Номаълум';
    }
  }

  Widget _buildBuildersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Қурувчилар',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),

        // Mavjud quruvchilar
        ..._selectedBuilders.asMap().entries.map((entry) {
          final index = entry.key;
          final builder = entry.value;

          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.construction, color: Colors.blue, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    builder,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red, size: 20),
                  onPressed: () => _removeBuilder(index),
                  tooltip: 'Ўчириш',
                ),
              ],
            ),
          );
        }).toList(),

        // Yangi quruvchi qo'shish
        Container(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showAddBuilderDialog,
            icon: Icon(Icons.add, color: Colors.blue),
            label: Text(
              'Қурувчи қўшиш',
              style: TextStyle(color: Colors.blue),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _removeBuilder(int index) {
    setState(() {
      _selectedBuilders.removeAt(index);
    });
  }

  Future<void> _showAddBuilderDialog() async {
    String? selectedBuilder;
    final builderController = TextEditingController();
    bool isAddingNew = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Қурувчи қўшиш'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isAddingNew) ...[
                Text('Мавжуд қурувчини танланг:'),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedBuilder,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.construction, color: Colors.blue),
                  ),
                  items: _builders
                      .where((builder) => !_selectedBuilders.contains(builder))
                      .map((builder) => DropdownMenuItem(
                            value: builder,
                            child: Text(builder),
                          ))
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedBuilder = value),
                ),
                SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => setDialogState(() => isAddingNew = true),
                  icon: Icon(Icons.add),
                  label: Text('Янги қурувчи яратиш'),
                ),
              ] else ...[
                Text('Янги қурувчи номини киритинг:'),
                SizedBox(height: 12),
                TextFormField(
                  controller: builderController,
                  decoration: InputDecoration(
                    labelText: 'Қурувчи номи',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.construction, color: Colors.blue),
                  ),
                  autofocus: true,
                ),
                SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => setDialogState(() => isAddingNew = false),
                  icon: Icon(Icons.arrow_back),
                  label: Text('Орқага'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Бекор қилиш'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (isAddingNew) {
                  final builderName = builderController.text.trim();
                  if (builderName.isNotEmpty) {
                    try {
                      await _materialService.addBuilder(builderName);
                      setState(() {
                        _builders.add(builderName);
                        _selectedBuilders.add(builderName);
                      });
                      Navigator.pop(context);
                      _showSuccessSnackBar('Қурувчи қўшилди');
                    } catch (e) {
                      _showErrorSnackBar('Хатолик: $e');
                    }
                  }
                } else if (selectedBuilder != null) {
                  setState(() {
                    _selectedBuilders.add(selectedBuilder!);
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(isAddingNew ? 'Яратиш' : 'Қўшиш'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddVerifierDialog() async {
    final verifierController = TextEditingController();
    bool isLoading = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_add, color: Colors.green),
              SizedBox(width: 8),
              Text('Янги тасдиқловчи қўшиш'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: verifierController,
                decoration: InputDecoration(
                  labelText: 'Тасдиқловчи исми *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, color: Colors.green),
                  hintText: 'Масалан: Алишер Каримов',
                ),
                autofocus: true,
                enabled: !isLoading,
                textCapitalization: TextCapitalization.words,
              ),
              if (isLoading) ...[
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Firestore\'га сақланмоқда...'),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context, false),
              child: Text('Бекор қилиш'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final verifierName = verifierController.text.trim();

                if (verifierName.isEmpty) {
                  _showErrorSnackBar('Тасдиқловчи исмини киритинг');
                  return;
                }

                if (verifierName.length < 3) {
                  _showErrorSnackBar('Исм камида 3 та ҳарфдан иборат бўлиши керак');
                  return;
                }

                setDialogState(() => isLoading = true);

                try {
                  print('Checking if verifier exists: $verifierName'); // Debug
                  final exists = await _materialService.verifierExists(verifierName);
                  print('Verifier exists: $exists'); // Debug

                  if (exists) {
                    _showErrorSnackBar('Бу тасдиқловчи аллақачон мавжуд');
                    setDialogState(() => isLoading = false);
                    return;
                  }

                  print('Adding verifier to Firestore: $verifierName'); // Debug
                  await _materialService.addVerifier(verifierName);
                  print('Verifier added successfully'); // Debug

                  print('Refreshing verifiers list...'); // Debug
                  final verifiers = await _materialService.getVerifiers(forceRefresh: true);
                  print('Updated verifiers list: $verifiers'); // Debug

                  setState(() {
                    _verifiers = verifiers;
                    _selectedVerificationPerson = verifierName;
                  });

                  Navigator.pop(context, true);
                  _showSuccessSnackBar('Тасдиқловчи муваффақиятли қўшилди: $verifierName');
                } catch (e) {
                  print('Error adding verifier: $e'); // Debug
                  _showErrorSnackBar('Хатолик: $e');
                  setDialogState(() => isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Firestore\'га қўшиш'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteMaterialFromSuggestion(MaterialItem material) async {
    // Materialning qurulishlarda ishlatilganini tekshirish
    bool isUsed = await _checkMaterialUsage(material.id);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Диққат!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ушбу материални ўчирмоқчимисиз?\n'
              '${material.name} (${material.unit})',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            if (isUsed)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Бу материал қурилишларда ишлатилган! Ўчириш хавфли!',
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            if (!isUsed)
              Text('Бу амал орқага қайтарилмайди.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Бекор қилиш'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Ўчириш', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteMaterialFromList(material);
    }
  }

  Future<bool> _checkMaterialUsage(String materialId) async {
    try {
      // Firebase'dan materialning ishlatilganini tekshirish
      final buildingsRef = FirebaseFirestore.instance.collection('buildings');
      final snapshot = await buildingsRef
          .where('requiredMaterials', arrayContains: {'materialId': materialId})
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking material usage: $e');
      return false;
    }
  }

  Future<void> _deleteMaterialFromList(MaterialItem material) async {
    try {
      // Firebase'dan o'chirish
      await _materialService.deleteMaterial(material.id);

      // Local list'dan o'chirish
      setState(() {
        _materials.removeWhere((m) => m.id == material.id);

        // Agar bu material hozirda tanlangan bo'lsa, uni bekor qilish
        for (int i = 0; i < _selectedRequiredMaterials.length; i++) {
          if (_selectedRequiredMaterials[i] == material.id) {
            _selectedRequiredMaterials[i] = null;
            _selectedAvailableMaterials[i] = null;
          }
        }
      });

      _showSuccessSnackBar('Материал ўчирилди: ${material.name}');
    } catch (e) {
      _showErrorSnackBar('Хатолик: $e');
    }
  }

  Future<void> _detectMaterialsFromScheme() async {
    final schemeUrl = _schemeUrlController.text.trim();
    if (schemeUrl.isEmpty) {
      _showErrorSnackBar('Схема URL киритинг');
      return;
    }

    if (!mounted) return;

    setState(() => _isDetecting = true);

    try {
      print('Starting material detection from scheme: $schemeUrl');

      final detectedMaterials = await MaterialDetectionService().detectMaterialsFromImage(schemeUrl);

      if (!mounted) return;

      print('Detection completed. Found ${detectedMaterials.length} materials');

      // Rasm URL'ни saqlash
      setState(() {
        _detectedImageUrl = schemeUrl;
        _detectedImageFile = null;
      });

      if (detectedMaterials.isEmpty) {
        _showErrorSnackBar('Схемада материаллар топилмади');
        return;
      }

      _showDetectedMaterialsDialog(detectedMaterials);

    } catch (e) {
      if (!mounted) return;

      print('Error in material detection: $e');
      _showErrorSnackBar('Хатолик: $e');
    } finally {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  void _showApiErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('API Хатолиги'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Google Vision API фаоллаштирилмаган.'),
            SizedBox(height: 16),
            Text('Қуйидаги қадамларни бажаринг:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('1. Google Cloud Console\'га киринг'),
            Text('2. APIs & Services > Library'),
            Text('3. Cloud Vision API\'ни топинг'),
            Text('4. ENABLE тугмасини босинг'),
            Text('5. Бир неча дақиқа кутинг'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Тушундим'),
          ),
        ],
      ),
    );
  }

  // Dialog'ни to'liq qayta yozish - Navigator lock'siz
  void _showDetectedMaterialsDialog(List<DetectedMaterial> materials) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              PlatformService.isWindows ? Icons.smart_toy : Icons.preview,
              color: PlatformService.isWindows ? Colors.blue : Colors.orange,
            ),
            SizedBox(width: 8),
            Text(
              PlatformService.isWindows
                ? 'AI аниқлаган материаллар'
                : 'Материаллар preview',
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              if (PlatformService.isAndroid)
                Container(
                  padding: EdgeInsets.all(8),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '📱 Android режимида материалларни қўлда таҳрирлаш мумкин',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: PlatformService.isWindows
                            ? Colors.blue.shade100
                            : Colors.orange.shade100,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(material.name),
                        subtitle: Text('${material.size} • ${material.quantity} ${material.unit}'),
                        trailing: PlatformService.isAndroid
                          ? IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _editMaterialInDialog(material, index),
                            )
                          : Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Бекор қилиш'),
          ),
          ElevatedButton(
            onPressed: () {
              _addDetectedMaterials(materials);
              Navigator.pop(context);
            },
            child: Text(
              PlatformService.isWindows ? 'AI натижаларни қўшиш' : 'Материалларни қўшиш'
            ),
          ),
        ],
      ),
    );
  }

  void _editMaterialInDialog(DetectedMaterial material, int index) {
    // Android uchun material edit dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Материални таҳрирлаш'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: material.name,
              decoration: InputDecoration(labelText: 'Материал номи'),
              onChanged: (value) => material.name = value,
            ),
            SizedBox(height: 16),
            TextFormField(
              initialValue: material.size,
              decoration: InputDecoration(labelText: 'Ўлчам'),
              onChanged: (value) => material.size = value,
            ),
            SizedBox(height: 16),
            TextFormField(
              initialValue: material.quantity.toString(),
              decoration: InputDecoration(labelText: 'Миқдор'),
              keyboardType: TextInputType.number,
              onChanged: (value) => material.quantity = int.tryParse(value) ?? 1,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Бекор қилиш'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Сақлаш'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyDetectedMaterials(dynamic materialsData) async {
    List<DetectedMaterial> materials;

    // Dialog'dan qaytgan ma'lumotni tekshirish
    if (materialsData is List<DetectedMaterial>) {
      materials = materialsData;
    } else if (materialsData is List) {
      materials = materialsData.cast<DetectedMaterial>();
    } else {
      _showErrorSnackBar('Материаллар маълумотида хатолик');
      return;
    }

    if (materials.isEmpty) {
      _showErrorSnackBar('Қўшиш учун материал танланмади');
      return;
    }

    try {
      // Har bir aniqlangan material uchun
      for (final detectedMaterial in materials) {
        // Mavjud materiallar ro'yxatidan qidirish
        MaterialItem? existingMaterial = _materials.firstWhere(
          (m) => m.name.toLowerCase().contains(detectedMaterial.name.toLowerCase()),
          orElse: () => MaterialItem(id: '', name: '', unit: ''),
        );

        // Agar material topilmasa, yangi yaratish
        if (existingMaterial.id.isEmpty) {
          final newMaterial = MaterialItem(
            id: DateTime.now().millisecondsSinceEpoch.toString() + materials.indexOf(detectedMaterial).toString(),
            name: detectedMaterial.name,
            unit: 'дона',
          );

          // Firebase'ga qo'shish
          await _materialService.addMaterial(newMaterial);

          setState(() {
            _materials.add(newMaterial);
          });

          existingMaterial = newMaterial;
        }

        // Yangi qator qo'shish
        setState(() {
          _selectedRequiredMaterials.add(existingMaterial!.id);
          _requiredQuantityControllers.add(
            TextEditingController(text: detectedMaterial.quantity.toString())
          );
          _requiredSizeControllers.add(
            TextEditingController(text: detectedMaterial.size)
          );

          // Available materials uchun ham
          _selectedAvailableMaterials.add(existingMaterial.id);
          _availableQuantityControllers.add(TextEditingController());
          _availableSizeControllers.add(
            TextEditingController(text: detectedMaterial.size)
          );
        });
      }

      _showSuccessSnackBar('${materials.length} та материал қўшилди');

    } catch (e) {
      print('Error applying detected materials: $e');
      _showErrorSnackBar('Материалларни қўшишда хатолик: $e');
    }
  }

  // MaterialItem? _findMatchingMaterial(String detectedName) {
  //   // Fuzzy matching - o'xshash nomlarni topish
  //   final normalizedDetected = detectedName.toLowerCase().trim();

  //   for (final material in _materials) {
  //     final normalizedMaterial = material.name.toLowerCase().trim();

  //     // To'liq mos kelish
  //     if (normalizedMaterial == normalizedDetected) {
  //       return material;
  //     }

  //     // Qisman mos kelish
  //     if (normalizedMaterial.contains(normalizedDetected) ||
  //         normalizedDetected.contains(normalizedMaterial)) {
  //       return material;
  //     }
  //   }

  //   return null;
  // }

  Future<MaterialItem?> _createNewMaterial(String name) async {
    try {
      final newMaterial = MaterialItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        unit: 'дона', // Default unit
      );

      await _materialService.addMaterial(newMaterial);

      // Local list'ni yangilash
      setState(() {
        _materials.add(newMaterial);
      });

      return newMaterial;
    } catch (e) {
      print('Error creating new material: $e');
      return null;
    }
  }

  // File'dan material detection
  Future<void> _detectMaterialsFromFile() async {
    if (!mounted) return;

    setState(() => _isDetecting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty || !mounted) {
        setState(() => _isDetecting = false);
        return;
      }

      final file = File(result.files.single.path!);
      print('Selected file: ${file.path}');

      final detectedMaterials = await MaterialDetectionService().detectMaterialsFromFile(file);

      if (!mounted) return;

      print('Detection completed. Found ${detectedMaterials.length} materials');

      // File'ni saqlash
      setState(() {
        _detectedImageFile = file;
        _detectedImageUrl = null;
      });

      if (detectedMaterials.isEmpty) {
        _showErrorSnackBar('Расмда материаллар топилмади');
        return;
      }

      _showDetectedMaterialsDialog(detectedMaterials);

    } catch (e) {
      if (!mounted) return;

      print('Error in file material detection: $e');
      _showErrorSnackBar('Хатолик: $e');
    } finally {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  // Progress indicator widget
  Widget _buildProgressIndicator() {
    if (!_isDetecting) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _detectionStatus.isEmpty ? 'AI материалларни аниқламоқда...' : _detectionStatus,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_uploadProgress > 0 && _uploadProgress < 1) ...[
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.blue.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 4),
            Text(
              '${(_uploadProgress * 100).toInt()}% тайёр',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Detected image preview widget
  Widget _buildDetectedImagePreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'AI таҳлил қилинган расм',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _detectedImageUrl = null;
                      _detectedImageFile = null;
                    });
                  },
                  icon: Icon(Icons.close, size: 20, color: Colors.red),
                  tooltip: 'Ёпиш',
                ),
              ],
            ),
          ),

          // Image
          GestureDetector(
            onTap: _showFullScreenDetectedImage,
            child: Container(
              width: double.infinity,
              height: 200,
              child: _detectedImageFile != null
                  ? Image.file(
                      _detectedImageFile!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red, size: 32),
                                SizedBox(height: 8),
                                Text('Расм юкланмади'),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Image.network(
                      _detectedImageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red, size: 32),
                                SizedBox(height: 8),
                                Text('Расм юкланмади'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Info
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Расмни босиб катта кўриш мумкин. AI нотўғри аниқлаган бўлса, қўлда қўшинг.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Full screen image view
  void _showFullScreenDetectedImage() {
    if (_detectedImageUrl == null && _detectedImageFile == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              'AI таҳлил қилинган расм',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: _detectedImageFile != null
                  ? Image.file(
                      _detectedImageFile!,
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      _detectedImageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.error, color: Colors.white, size: 64);
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // Quick add buttons for common materials
Widget _buildQuickAddButtons() {
  final commonMaterials = [
    {'name': 'Задвижка', 'size': 'Ø300мм', 'icon': Icons.settings, 'color': Colors.red},
    {'name': 'Муфта фла.', 'size': 'Ø300мм', 'icon': Icons.link, 'color': Colors.blue},
    {'name': 'Тройник', 'size': 'Ø300x300мм', 'icon': Icons.call_split, 'color': Colors.green},
    {'name': 'Заглушка фла.', 'size': 'Ø300мм', 'icon': Icons.block, 'color': Colors.orange},
    {'name': 'Переход', 'size': 'Ø400x300мм', 'icon': Icons.transform, 'color': Colors.purple},
    {'name': 'Отвод', 'size': 'Ø300мм', 'icon': Icons.turn_right, 'color': Colors.teal},
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.flash_on, color: Colors.amber, size: 20),
          SizedBox(width: 8),
          Text(
            'Тез қўшиш:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
          ),
        ],
      ),
      SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: commonMaterials.map((material) {
          return ActionChip(
            avatar: Icon(
              material['icon'] as IconData,
              size: 16,
              color: material['color'] as Color,
            ),
            label: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material['name'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  material['size'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            onPressed: () => _addQuickMaterial(
              material['name'] as String,
              material['size'] as String,
            ),
            backgroundColor: (material['color'] as Color).withOpacity(0.1),
            side: BorderSide(color: (material['color'] as Color).withOpacity(0.3)),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          );
        }).toList(),
      ),
    ],
  );
}

// Materials table
Widget _buildMaterialsTable() {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        // Table header
        Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Материал номи',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  'Ўлчам',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  'Керакли',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  'Мавжуд',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              SizedBox(width: 40), // For delete button
            ],
          ),
        ),

        // Material rows
        ...List.generate(_selectedRequiredMaterials.length, (index) {
          return _buildExcelStyleMaterialRow(index);
        }),

        // Add new row button
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: TextButton.icon(
            onPressed: _addRequiredMaterial,
            icon: Icon(Icons.add, color: Colors.blue),
            label: Text(
              'Янги материал қўшиш',
              style: TextStyle(color: Colors.blue),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

// Empty state for materials
Widget _buildEmptyMaterialsState() {
  return Container(
    padding: EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
    ),
    child: Column(
      children: [
        Icon(
          Icons.construction,
          size: 64,
          color: Colors.grey.shade400,
        ),
        SizedBox(height: 16),
        Text(
          'Материаллар қўшилмаган',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'AI орқали автоматик аниқлаш ёки қўлда қўшиш',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _addRequiredMaterial,
              icon: Icon(Icons.add),
              label: Text('Қўлда қўшиш'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Focus on scheme URL input
                FocusScope.of(context).requestFocus(FocusNode());
                _schemeUrlController.clear();
              },
              icon: Icon(Icons.auto_awesome),
              label: Text('AI аниқлаш'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: BorderSide(color: Colors.green),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// Add quick material method
void _addQuickMaterial(String materialName, String materialSize) {
  // Find or create material
  MaterialItem? existingMaterial = _materials.firstWhere(
    (m) => m.name.toLowerCase().contains(materialName.toLowerCase()),
    orElse: () => MaterialItem(id: '', name: '', unit: ''),
  );

  if (existingMaterial.id.isEmpty) {
    // Create new material
    final newMaterial = MaterialItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: materialName,
      unit: 'дона',
    );

    setState(() {
      _materials.add(newMaterial);
      existingMaterial = newMaterial;
    });
  }

  // Add to lists
  setState(() {
    _selectedRequiredMaterials.add(existingMaterial!.id);
    _requiredQuantityControllers.add(TextEditingController(text: '1'));
    _requiredSizeControllers.add(TextEditingController(text: materialSize));

    _selectedAvailableMaterials.add(existingMaterial!.id);
    _availableQuantityControllers.add(TextEditingController());
    _availableSizeControllers.add(TextEditingController(text: materialSize));
  });

  _showSuccessSnackBar('$materialName қўшилди');
}

void _addDetectedMaterials(List<DetectedMaterial> materials) async {
  if (materials.isEmpty) {
    _showErrorSnackBar('Қўшиш учун материал танланмади');
    return;
  }

  try {
    print('Adding ${materials.length} detected materials...');

    // Har bir aniqlangan material uchun
    for (final detectedMaterial in materials) {
      // Mavjud materiallar ro'yxatidan qidirish
      MaterialItem? existingMaterial = _findMatchingMaterial(detectedMaterial.name);

      // Agar material topilmasa, yangi yaratish
      if (existingMaterial == null) {
        print('Creating new material: ${detectedMaterial.name}');

        final newMaterial = MaterialItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              materials.indexOf(detectedMaterial).toString(),
          name: detectedMaterial.name,
          unit: detectedMaterial.unit,
        );

        // Firebase'ga qo'shish
        await _materialService.addMaterial(newMaterial);

        setState(() {
          _materials.add(newMaterial);
        });

        existingMaterial = newMaterial;
      }

      // Yangi qator qo'shish
      setState(() {
        // Required materials
        _selectedRequiredMaterials.add(existingMaterial!.id);
        _requiredQuantityControllers.add(
          TextEditingController(text: detectedMaterial.quantity.toString())
        );
        _requiredSizeControllers.add(
          TextEditingController(text: detectedMaterial.size)
        );

        // Available materials (bo'sh qiymatlar bilan)
        _selectedAvailableMaterials.add(existingMaterial.id);
        _availableQuantityControllers.add(TextEditingController(text: '0'));
        _availableSizeControllers.add(
          TextEditingController(text: detectedMaterial.size)
        );
      });

      print('Added material: ${detectedMaterial.name} - ${detectedMaterial.quantity} ${detectedMaterial.unit}');
    }

    // Success message
    final platformText = PlatformService.isWindows ? 'AI аниқлаган' : 'Танланган';
    _showSuccessSnackBar('$platformText ${materials.length} та материал қўшилди');

    // Scroll to bottom to show new materials
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        Scrollable.ensureVisible(
          context,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

  } catch (e) {
    print('Error adding detected materials: $e');
    _showErrorSnackBar('Материалларни қўшишда хатолик: $e');
  }
}

MaterialItem? _findMatchingMaterial(String detectedName) {
  // Fuzzy matching - o'xshash nomlarni topish
  final normalizedDetected = detectedName.toLowerCase().trim();

  for (final material in _materials) {
    final normalizedMaterial = material.name.toLowerCase().trim();

    // To'liq mos kelish
    if (normalizedMaterial == normalizedDetected) {
      return material;
    }

    // Qisman mos kelish (50% dan ko'p mos kelishi kerak)
    if (normalizedMaterial.contains(normalizedDetected) ||
        normalizedDetected.contains(normalizedMaterial)) {
      return material;
    }

    // Keyword matching for common materials
    final keywords = [
      'труба', 'трубопровод', 'pipe', 'quvur',
      'муфта', 'тройник', 'отвод', 'переход', 'заглушка', 'фланец',
      'задвижка', 'вентиль', 'кран', 'клапан',
      'бетон', 'железобетон', 'кольца', 'плита', 'блок',
      'арматура', 'сетка', 'стержень', 'проволока'
    ];

    for (final keyword in keywords) {
      if (normalizedMaterial.contains(keyword) && normalizedDetected.contains(keyword)) {
        return material;
      }
    }
  }

  return null;
}

// Fayl tanlash va URL sifatida saqlash
Future<void> _pickAndSaveImageFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      // Faylni local path sifatida saqlash
      final localPath = file.path;

      // URL controller ga qo'shish
      setState(() {
        _imageUrlControllers.add(TextEditingController(text: localPath));
      });

      // Firebase ga saqlash
      await FirebaseService.saveImageUrl(
        localPath,
        originalFileName: fileName,
        fileSize: await file.length(),
        uploadService: 'local_file',
      );

      _showSuccessSnackBar('Файл қўшилди: $fileName');
    }
  } catch (e) {
    _showErrorSnackBar('Файл танлашда хатолик: $e');
  }
}

// URL qo'shish
void _addImageUrlField() {
  setState(() {
    _imageUrlControllers.add(TextEditingController());
  });
}

// URL saqlash
Future<void> _saveImageUrl(String url) async {
  if (url.trim().isNotEmpty) {
    await FirebaseService.saveImageUrl(
      url.trim(),
      uploadService: 'manual_url',
    );
  }
}
}
