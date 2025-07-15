import 'package:flutter/material.dart';
import '../models/building.dart';
import '../models/material_item.dart';
import '../services/firebase_service.dart';
import '../services/material_service.dart';

import '../models/building.dart';
import '../models/material_item.dart';
import '../services/firebase_service.dart';
import '../services/material_service.dart';

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
  final _regionNameController = TextEditingController();
  final _schemeUrlController = TextEditingController();
  final _kolodetsConditionController = TextEditingController();
  final _commentController = TextEditingController(); // Yangi izoh controller
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

  // Data from Firebase
  List<MaterialItem> _materials = [];
  List<String> _builders = [];
  final MaterialService _materialService = MaterialService();

  // Static data
  final _tasdiqlovchilar = ['Алишер Каримов', 'Шахноз Иброҳимова', 'Бобур Раҳимов'];
  final _kolodetsStatusList = ['Бор', 'Йўқ'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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
    _regionNameController.dispose();
    _schemeUrlController.dispose();
    _commentController.dispose(); // Yangi controller dispose
    
    for (final controller in _imageUrlControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingMaterials = true;
      _isLoadingBuilders = true;
    });

    try {
      final results = await Future.wait([
        _materialService.getMaterials(),
        _materialService.getBuilders(),
      ]);

      setState(() {
        _materials = results[0] as List<MaterialItem>;
        _builders = results[1] as List<String>;
        _isLoadingMaterials = false;
        _isLoadingBuilders = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMaterials = false;
        _isLoadingBuilders = false;
      });
      _showErrorSnackBar('Маълумотларни юклашда хатолик: $e');
    }
  }

  void _addImageUrlField() {
    setState(() {
      _imageUrlControllers.add(TextEditingController());
    });
  }

  void _removeImageUrlField(int index) {
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
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
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

  bool _validateMaterialSelections() {
    // Check required materials
    for (int i = 0; i < _selectedRequiredMaterials.length; i++) {
      if (_selectedRequiredMaterials[i] == null) {
        _showErrorSnackBar('Барча керакли материалларни танланг');
        return false;
      }
      if (_requiredQuantityControllers[i].text.trim().isEmpty) {
        _showErrorSnackBar('Барча керакли материаллар учун миқдор киритинг');
        return false;
      }
    }
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

    setState(() => _isSaving = true);

    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final imageUrls = _imageUrlControllers
          .map((controller) => controller.text.trim())
          .where((url) => url.isNotEmpty)
          .toList();

      final requiredMaterialsData = <Map<String, dynamic>>[];
      final availableMaterialsData = <Map<String, dynamic>>[];

      // Process required materials
      for (int i = 0; i < _selectedRequiredMaterials.length; i++) {
        final materialId = _selectedRequiredMaterials[i];
        final quantity = _requiredQuantityControllers[i].text.trim();
        final size = _requiredSizeControllers[i].text.trim();

        if (materialId != null && quantity.isNotEmpty) {
          final materialName = _getMaterialNameById(materialId);
          final materialUnit = _getMaterialUnitById(materialId);
          final parsedQuantity = double.tryParse(quantity) ?? 0;

          if (parsedQuantity > 0) {
            requiredMaterialsData.add({
              'materialId': materialId,
              'materialName': materialName,
              'quantity': parsedQuantity.toString(),
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

          if (parsedQuantity > 0) {
            availableMaterialsData.add({
              'materialId': materialId,
              'materialName': materialName,
              'quantity': parsedQuantity.toString(),
              'unit': materialUnit,
              'size': size.isNotEmpty ? size : null,
              'addedAt': DateTime.now().toIso8601String(),
            });
          }
        }
      }

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
        regionName: _locationNameController.text.trim(), // locationName ni regionName sifatida ishlatish
        verificationPerson: _selectedVerificationPerson,
        kolodetsStatus: _selectedKolodetsStatus,
        builders: _selectedBuilders.isNotEmpty ? _selectedBuilders : null, // builder o'rniga builders
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

      await FirebaseService.saveBuilding(building);

      setState(() => _isSaving = false);
      _showSuccessSnackBar('Бино муваффақиятли қўшилди');
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Хатолик: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Бино қўшиш'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              SizedBox(height: 24),
              _buildMaterialsSection(),
              SizedBox(height: 24),
              _buildImagesSection(),
              SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Асосий маълумотлар',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

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

            // Region Name
            TextFormField(
              controller: _regionNameController,
              decoration: InputDecoration(
                labelText: 'Ҳудуд номи *',
                prefixIcon: Icon(Icons.map),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ҳудуд номини киритинг';
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
              items: _tasdiqlovchilar.map((person) => DropdownMenuItem(
                value: person,
                child: Text(person),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVerificationPerson = value;
                });
              },
              validator: (value) {
                if (value == null) {
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

            // Scheme URL
            TextFormField(
              controller: _schemeUrlController,
              decoration: InputDecoration(
                labelText: 'Схема URL',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
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

  Widget _buildMaterialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequiredMaterialsSection(),
        SizedBox(height: 24),
        _buildAvailableMaterialsSection(),
      ],
    );
  }

  Widget _buildRequiredMaterialsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Керакли материаллар',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            ...List.generate(_selectedRequiredMaterials.length, (index) {
              return _buildRequiredMaterialRow(index);
            }),

            SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _addRequiredMaterial,
                icon: Icon(Icons.add),
                label: Text('Керакли материал қўшиш'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableMaterialsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Мавжуд материаллар (автоматик)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Бу материаллар керакли материаллар асосида автоматик қўшилади. Миқдор ва ўлчамни киритинг.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            SizedBox(height: 16),

            ...List.generate(_selectedAvailableMaterials.length, (index) {
              return _buildAvailableMaterialRow(index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredMaterialRow(int index) {
    final materialId = _selectedRequiredMaterials[index];
    final materialUnit = materialId != null ? _getMaterialUnitById(materialId) : 'дона';

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: materialId,
                decoration: InputDecoration(
                  hintText: 'Материал танланг',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                items: [
                  if (_isLoadingMaterials)
                    DropdownMenuItem(value: null, child: Text('Юкланмоқда...'))
                  else ...[
                    ..._materials.map((material) => DropdownMenuItem(
                      value: material.id,
                      child: Text('${material.name} (${material.unit})'),
                    )),
                    DropdownMenuItem(
                      value: 'add_new',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Янги материал қўшиш', style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                  ],
                ],
                onChanged: _isLoadingMaterials ? null : (value) {
                  if (value == 'add_new') {
                    _showAddMaterialDialog(index);
                  } else {
                    setState(() {
                      _selectedRequiredMaterials[index] = value;
                      if (index < _selectedAvailableMaterials.length) {
                        _selectedAvailableMaterials[index] = value;
                      }
                    });
                  }
                },
              ),
            ),
            SizedBox(width: 12),

            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _requiredSizeControllers[index],
                decoration: InputDecoration(
                  hintText: 'Ўлчам',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
            ),
            SizedBox(width: 12),

            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _requiredQuantityControllers[index],
                      decoration: InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  SizedBox(width: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      materialUnit,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),

            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _selectedRequiredMaterials.length > 1 ? () => _removeRequiredMaterial(index) : null,
              tooltip: 'Ўчириш',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableMaterialRow(int index) {
    final materialId = _selectedAvailableMaterials[index];
    final materialUnit = materialId != null ? _getMaterialUnitById(materialId) : 'дона';
    final materialName = materialId != null ? _getMaterialNameById(materialId) : 'Материал танланг';

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  materialName,
                  style: TextStyle(
                    color: materialId != null ? Colors.black : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),

            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _availableSizeControllers[index],
                decoration: InputDecoration(
                  hintText: 'Ўлчам',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
            ),
            SizedBox(width: 12),

            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _availableQuantityControllers[index],
                      decoration: InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  SizedBox(width: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      materialUnit,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),

            Container(
              width: 40,
              child: Icon(Icons.lock, color: Colors.grey.shade400, size: 16),
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
      elevation: 2,
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
                  'Расмлар',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            ...List.generate(_imageUrlControllers.length, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _imageUrlControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Расм URL ${index + 1}',
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (_imageUrlControllers.length > 1) ...[
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeImageUrlField(index),
                      ),
                    ],
                  ],
                ),
              );
            }),

            Center(
              child: ElevatedButton.icon(
                onPressed: _addImageUrlField,
                icon: Icon(Icons.add_photo_alternate),
                label: Text('Расм қўшиш'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
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
}

