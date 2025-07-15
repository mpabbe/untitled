import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/building.dart';
import 'map_picker_screen.dart';
import '../services/material_service.dart';
import '../services/firebase_service.dart';

class BuildingDetailScreen extends StatefulWidget {
  final Building building;

  BuildingDetailScreen({required this.building});

  @override
  _BuildingDetailScreenState createState() => _BuildingDetailScreenState();
}

class _BuildingDetailScreenState extends State<BuildingDetailScreen> {
  late Building _building;
  bool _isEditing = false;
  bool _isSaving = false;
  
  // Controllers
  late TextEditingController _uniqueNameController;
  late TextEditingController _regionNameController;
  late TextEditingController _schemeUrlController;
  
  // Material controllers for editing
  List<TextEditingController> _availableQuantityControllers = [];
  List<TextEditingController> _availableSizeControllers = [];
  
  // Selected values
  String? _selectedBuilder;
  String? _selectedInspector;
  String? _selectedKolodetsStatus;
  late BuildingStatus _selectedStatus;
  
  // Firebase data
  final MaterialService _materialService = MaterialService();
  List<String> _builders = [];
  bool _isLoadingBuilders = false;

  @override
  void initState() {
    super.initState();
    _building = widget.building;
    _initializeControllers();
    _loadBuilders();
  }
  
  void _initializeControllers() {
    _uniqueNameController = TextEditingController(text: _building.uniqueName);
    _regionNameController = TextEditingController(text: _building.regionName);
    _schemeUrlController = TextEditingController(text: _building.schemeUrl ?? '');
    
    _selectedBuilder = _building.builder;
    _selectedInspector = _building.verificationPerson;
    _selectedKolodetsStatus = _building.kolodetsStatus;
    _selectedStatus = _building.status;
    
    // Initialize material controllers
    _initializeMaterialControllers();
  }
  
  void _initializeMaterialControllers() {
    _availableQuantityControllers.clear();
    _availableSizeControllers.clear();
    
    // Create controllers based on required materials
    final availableMaterialsMap = <String, Map<String, dynamic>>{};
    for (final material in _building.availableMaterials) {
      availableMaterialsMap[material['materialId']] = material;
    }
    
    for (final requiredMaterial in _building.requiredMaterials) {
      final materialId = requiredMaterial['materialId'];
      final availableMaterial = availableMaterialsMap[materialId];
      
      _availableQuantityControllers.add(
        TextEditingController(text: availableMaterial?['quantity']?.toString() ?? '0')
      );
      _availableSizeControllers.add(
        TextEditingController(text: availableMaterial?['size']?.toString() ?? '')
      );
    }
  }
  
  Future<void> _loadBuilders() async {
    setState(() => _isLoadingBuilders = true);
    try {
      _builders = await _materialService.getBuilders();
      setState(() => _isLoadingBuilders = false);
    } catch (e) {
      setState(() => _isLoadingBuilders = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қурувчиларни юклашда хатолик: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_building.uniqueName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing) ...[
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() => _isEditing = false);
                _initializeControllers();
              },
            ),
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _isSaving ? null : _saveChanges,
            ),
          ],
        ],
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 800;
                return SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusHeader(),
                      SizedBox(height: 20),
                      
                      if (isWideScreen)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildBasicInfo()),
                            SizedBox(width: 20),
                            Expanded(flex: 3, child: _buildMaterialsInfo()),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildBasicInfo(),
                            SizedBox(height: 20),
                            _buildMaterialsInfo(),
                          ],
                        ),
                      
                      SizedBox(height: 20),
                      _buildSchemeSection(),
                      
                      if (_building.images.isNotEmpty) ...[
                        SizedBox(height: 20),
                        _buildImagesSection(),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(_building.status).withOpacity(0.1),
            _getStatusColor(_building.status).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(_building.status).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(_building.status),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              _getStatusIcon(_building.status),
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Лойиҳа ҳолати',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  _getStatusText(_building.status),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(_building.status),
                  ),
                ),
              ],
            ),
          ),
          if (_building.materialStatus != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getMaterialStatusColor(_building.materialStatus!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getMaterialStatusColor(_building.materialStatus!).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getMaterialStatusIcon(_building.materialStatus!),
                    size: 16,
                    color: _getMaterialStatusColor(_building.materialStatus!),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Материал: ${_getMaterialStatusText(_building.materialStatus!)}',
                    style: TextStyle(
                      color: _getMaterialStatusColor(_building.materialStatus!),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Асосий маълумотлар',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          
          _buildInfoRow(
            'Юник номи',
            _isEditing 
                ? TextFormField(
                    controller: _uniqueNameController,
                    decoration: InputDecoration(border: OutlineInputBorder()),
                  )
                : Text(_building.uniqueName, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          
          _buildInfoRow(
            'Ҳудуд номи',
            _isEditing 
                ? TextFormField(
                    controller: _regionNameController,
                    decoration: InputDecoration(border: OutlineInputBorder()),
                  )
                : Text(_building.regionName, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          
          _buildInfoRow(
            'Қурувчи',
            _isEditing 
                ? _buildBuilderDropdown()
                : Text(_building.builder ?? 'Белгиланмаган', 
                       style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          
          _buildInfoRow(
            'Текширувчи шахс',
            _isEditing 
                ? _buildInspectorDropdown()
                : Text(_building.verificationPerson ?? 'Белгиланмаган', 
                       style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          
          _buildInfoRow(
            'Лойиҳа ҳолати',
            _isEditing 
                ? _buildStatusDropdown()
                : Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_building.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(_building.status),
                      style: TextStyle(
                        color: _getStatusColor(_building.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          
          _buildInfoRow(
            'Колодец ҳолати',
            _isEditing 
                ? _buildKolodetsDropdown()
                : Text(_building.kolodetsStatus ?? 'Белгиланмаган', 
                       style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          
          _buildInfoRow(
            'Яратилган сана',
            Text(
              DateFormat('dd.MM.yyyy HH:mm').format(_building.createdAt),
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.construction, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Қурилиш материаллари',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Agar required materials bo'lsa, available materials ham bo'ladi
          if (_building.requiredMaterials.isNotEmpty)
            _buildMaterialComparison()
          else
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Материаллар маълумоти йўқ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMaterialComparison() {
    // Create map for available materials
    final availableMaterialsMap = <String, Map<String, dynamic>>{};
    for (final material in _building.availableMaterials) {
      availableMaterialsMap[material['materialId']] = material;
    }
    
    return Column(
      children: [
        // Material status indicator
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _getMaterialStatusColor(_building.materialStatus!).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getMaterialStatusColor(_building.materialStatus!).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getMaterialStatusIcon(_building.materialStatus!),
                color: _getMaterialStatusColor(_building.materialStatus!),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Материал ҳолати: ${_getMaterialStatusText(_building.materialStatus!)}',
                style: TextStyle(
                  color: _getMaterialStatusColor(_building.materialStatus!),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        Row(
          children: [
            // Required materials
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Керакли материаллар',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    ..._building.requiredMaterials.map((material) => 
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${material['materialName']} - ${material['quantity']} ${material['unit']}${material['size'] != null && material['size'].toString().isNotEmpty ? ' (${material['size']})' : ''}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ).toList(),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12),
            
            // Available materials
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Мавжуд материаллар',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    // Show materials based on required materials
                    ..._building.requiredMaterials.asMap().entries.map((entry) {
                      final index = entry.key;
                      final requiredMaterial = entry.value;
                      final materialId = requiredMaterial['materialId'];
                      final availableMaterial = availableMaterialsMap[materialId];
                      
                      return _isEditing 
                        ? _buildEditableMaterialRow(index, requiredMaterial, availableMaterial)
                        : Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${requiredMaterial['materialName']} - ${availableMaterial?['quantity'] ?? '0'} ${requiredMaterial['unit']}${availableMaterial?['size'] != null && availableMaterial!['size'].toString().isNotEmpty ? ' (${availableMaterial['size']})' : ''}',
                              style: TextStyle(fontSize: 12),
                            ),
                          );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditableMaterialRow(int index, Map<String, dynamic> requiredMaterial, Map<String, dynamic>? availableMaterial) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              requiredMaterial['materialName'] ?? '',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: index < _availableQuantityControllers.length 
                ? _availableQuantityControllers[index] 
                : TextEditingController(text: availableMaterial?['quantity']?.toString() ?? '0'),
              decoration: InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                isDense: true,
              ),
              style: TextStyle(fontSize: 11),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          SizedBox(width: 4),
          Text(
            requiredMaterial['unit'] ?? '',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: index < _availableSizeControllers.length 
                ? _availableSizeControllers[index] 
                : TextEditingController(text: availableMaterial?['size']?.toString() ?? ''),
              decoration: InputDecoration(
                hintText: 'Ўлчам',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                isDense: true,
              ),
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.architecture, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Лойиҳа схемаси',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          SizedBox(height: 16),
          
          if (_isEditing)
            Column(
              children: [
                TextFormField(
                  controller: _schemeUrlController,
                  decoration: InputDecoration(
                    labelText: 'Схема URL',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  maxLines: 3,
                ),
                if (_schemeUrlController.text.isNotEmpty) ...[
                  SizedBox(height: 12),
                  _buildSchemePreview(_schemeUrlController.text),
                ],
              ],
            )
          else if (_building.schemeUrl != null && _building.schemeUrl!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSchemePreview(_building.schemeUrl!),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
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
                        _building.schemeUrl!,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Open URL logic
                        },
                        icon: Icon(Icons.open_in_new),
                        label: Text('Схемани очиш'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.architecture, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Схема маълумоти йўқ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSchemePreview(String imageUrl) {
    return GestureDetector(
      onTap: () {
        // Full screen image view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
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
      },
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: 150,
          maxHeight: 300,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey.shade100,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey.shade200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Расмни юклаб бўлмади',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Босиб кўриш учун',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Лойиҳа расмлари',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _building.images.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _building.images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.error, color: Colors.grey),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, Widget value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          value,
        ],
      ),
    );
  }

  // Dropdown builders and other helper methods...
  Widget _buildBuilderDropdown() {
    // Агар _selectedBuilder _builders'да йўқ бўлса, null қилиш
    if (_selectedBuilder != null && !_builders.contains(_selectedBuilder)) {
      _selectedBuilder = null;
    }
    
    return DropdownButtonFormField<String>(
      value: _selectedBuilder,
      decoration: InputDecoration(border: OutlineInputBorder()),
      items: [
        if (_isLoadingBuilders)
          DropdownMenuItem(value: null, child: Text('Юкланмоқда...'))
        else
          ..._builders.map((builder) => DropdownMenuItem(
            value: builder,
            child: Text(builder),
          )),
      ],
      onChanged: _isLoadingBuilders ? null : (val) => setState(() => _selectedBuilder = val),
    );
  }

  Widget _buildInspectorDropdown() {
    final inspectorsList = ['Алишер Каримов', 'Шахноз Иброҳимова', 'Бобур Раҳимов'];
    
    if (_selectedInspector != null && !inspectorsList.contains(_selectedInspector)) {
      _selectedInspector = null;
    }
    
    return DropdownButtonFormField<String>(
      value: _selectedInspector,
      decoration: InputDecoration(border: OutlineInputBorder()),
      items: inspectorsList
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (val) => setState(() => _selectedInspector = val),
    );
  }

  Widget _buildStatusDropdown() {
    // Agar kolodets "Йўқ" bo'lsa, faqat "Бошланмаган" ko'rsatish
    final availableStatuses = _selectedKolodetsStatus == 'Йўқ' 
        ? [BuildingStatus.notStarted]
        : BuildingStatus.values;
    
    return DropdownButtonFormField<BuildingStatus>(
      value: _selectedStatus,
      decoration: InputDecoration(border: OutlineInputBorder()),
      items: availableStatuses
          .map((status) => DropdownMenuItem(
                value: status,
                child: Text(_getStatusText(status)),
              ))
          .toList(),
      onChanged: _selectedKolodetsStatus == 'Йўқ' 
          ? null // Disable agar kolodets "Йўқ"
          : (val) => setState(() => _selectedStatus = val ?? BuildingStatus.notStarted),
    );
  }

  Widget _buildKolodetsDropdown() {
    final kolodetsStatusList = ['Бор', 'Йўқ', 'Номаълум'];
    
    if (_selectedKolodetsStatus != null && !kolodetsStatusList.contains(_selectedKolodetsStatus)) {
      _selectedKolodetsStatus = null;
    }
    
    return DropdownButtonFormField<String>(
      value: _selectedKolodetsStatus,
      decoration: InputDecoration(border: OutlineInputBorder()),
      items: kolodetsStatusList
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedKolodetsStatus = val;
          // Agar kolodets "Йўқ" bo'lsa, status "Бошланмаган" qilish
          if (val == 'Йўқ') {
            _selectedStatus = BuildingStatus.notStarted;
          }
        });
      },
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      // Update available materials based on required materials
      final updatedAvailableMaterials = <Map<String, dynamic>>[];
      
      for (int i = 0; i < _building.requiredMaterials.length; i++) {
        final requiredMaterial = _building.requiredMaterials[i];
        final updatedQuantity = i < _availableQuantityControllers.length 
          ? _availableQuantityControllers[i].text.trim() 
          : '0';
        final updatedSize = i < _availableSizeControllers.length 
          ? _availableSizeControllers[i].text.trim() 
          : '';
        
        updatedAvailableMaterials.add({
          'materialId': requiredMaterial['materialId'],
          'materialName': requiredMaterial['materialName'],
          'quantity': updatedQuantity.isNotEmpty ? updatedQuantity : '0',
          'unit': requiredMaterial['unit'],
          'size': updatedSize,
          'addedAt': DateTime.now().toIso8601String(),
        });
      }
      
      // Calculate new material status
      final newMaterialStatus = _calculateMaterialStatus(
        _building.requiredMaterials,
        updatedAvailableMaterials,
      );
      
      final updatedBuilding = Building(
        id: _building.id,
        latitude: _building.latitude,
        longitude: _building.longitude,
        uniqueName: _uniqueNameController.text,
        regionName: _regionNameController.text,
        verificationPerson: _selectedInspector,
        status: _selectedStatus,
        kolodetsStatus: _selectedKolodetsStatus,
        builder: _selectedBuilder,
        schemeUrl: _schemeUrlController.text.isEmpty ? null : _schemeUrlController.text,
        createdAt: _building.createdAt,
        images: _building.images,
        customData: _building.customData,
        materialStatus: newMaterialStatus,
        availableMaterials: updatedAvailableMaterials,
        requiredMaterials: _building.requiredMaterials,
      );

      await FirebaseService.saveBuilding(updatedBuilding);
      
      setState(() {
        _building = updatedBuilding;
        _isEditing = false;
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ўзгартиришлар сақланди')),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Хатолик: $e')),
      );
    }
  }

  // Helper methods for status colors and texts...
  Color _getStatusColor(BuildingStatus status) {
    switch (status) {
      case BuildingStatus.notStarted: return Colors.grey;
      case BuildingStatus.inProgress: return Colors.orange;
      case BuildingStatus.completed: return Colors.green;
      case BuildingStatus.paused: return Colors.red;
    }
  }

  IconData _getStatusIcon(BuildingStatus status) {
    switch (status) {
      case BuildingStatus.notStarted: return Icons.pause_circle;
      case BuildingStatus.inProgress: return Icons.construction;
      case BuildingStatus.completed: return Icons.check_circle;
      case BuildingStatus.paused: return Icons.stop_circle;
    }
  }

  String _getStatusText(BuildingStatus status) {
    switch (status) {
      case BuildingStatus.notStarted: return 'Бошланмаган';
      case BuildingStatus.inProgress: return 'Жараёнда';
      case BuildingStatus.completed: return 'Тугалланган';
      case BuildingStatus.paused: return 'Тўхтатилган';
    }
  }

  Color _getMaterialStatusColor(MaterialStatus status) {
    switch (status) {
      case MaterialStatus.complete: return Colors.green;
      case MaterialStatus.shortage: return Colors.orange;
      case MaterialStatus.critical: return Colors.red;
    }
  }

  IconData _getMaterialStatusIcon(MaterialStatus status) {
    switch (status) {
      case MaterialStatus.complete: return Icons.check_circle;
      case MaterialStatus.shortage: return Icons.warning;
      case MaterialStatus.critical: return Icons.error;
    }
  }

  String _getMaterialStatusText(MaterialStatus status) {
    switch (status) {
      case MaterialStatus.complete: return 'Етарли';
      case MaterialStatus.shortage: return 'Камчилик';
      case MaterialStatus.critical: return 'Жиддий камчилик';
    }
  }

  MaterialStatus _calculateMaterialStatus(
    List<Map<String, dynamic>> requiredMaterials,
    List<Map<String, dynamic>> availableMaterials,
  ) {
    if (requiredMaterials.isEmpty) return MaterialStatus.complete;

    final requiredMap = <String, double>{};
    final availableMap = <String, double>{};

    // Group required materials by ID + size
    for (final material in requiredMaterials) {
      final materialId = material['materialId'] as String;
      final size = material['size']?.toString() ?? '';
      final key = '$materialId|$size'; // Combine ID and size
      final quantity = double.tryParse(material['quantity'].toString()) ?? 0;
      requiredMap[key] = (requiredMap[key] ?? 0) + quantity;
    }

    // Group available materials by ID + size
    for (final material in availableMaterials) {
      final materialId = material['materialId'] as String;
      final size = material['size']?.toString() ?? '';
      final key = '$materialId|$size'; // Combine ID and size
      final quantity = double.tryParse(material['quantity'].toString()) ?? 0;
      availableMap[key] = (availableMap[key] ?? 0) + quantity;
    }

    bool hasShortage = false;
    bool hasCritical = false;

    // Check each required material against available
    for (final entry in requiredMap.entries) {
      final key = entry.key;
      final requiredQty = entry.value;
      final availableQty = availableMap[key] ?? 0;

      // Agar kerakli > mavjud bo'lsa - kamchillik
      if (requiredQty > availableQty) {
        hasShortage = true;
        // Agar mavjud keraklining 50% dan ham kam bo'lsa - kritik
        if (availableQty < requiredQty * 0.5) {
          hasCritical = true;
        }
      }
    }

    if (hasCritical) return MaterialStatus.critical;
    if (hasShortage) return MaterialStatus.shortage;
    return MaterialStatus.complete;
  }
}
