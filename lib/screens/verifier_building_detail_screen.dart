import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/building.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/change_history_service.dart';

class VerifierBuildingDetailScreen extends StatefulWidget {
  final Building building;

  VerifierBuildingDetailScreen({required this.building});

  @override
  _VerifierBuildingDetailScreenState createState() => _VerifierBuildingDetailScreenState();
}

class _VerifierBuildingDetailScreenState extends State<VerifierBuildingDetailScreen> {
  late Building _building;
  List<TextEditingController> _availableQuantityControllers = [];
  List<TextEditingController> _availableSizeControllers = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _building = widget.building;
    _initializeMaterialControllers();
  }

  void _initializeMaterialControllers() {
    _availableQuantityControllers.clear();
    _availableSizeControllers.clear();
    
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

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.currentUserType == 'admin';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_building.uniqueName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isSaving ? null : _saveChanges,
          ),
          // Faqat admin uchun history button
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.history),
              onPressed: () => _showChangeHistory(),
              tooltip: 'Ўзгариш тарихи',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfo(),
            SizedBox(height: 20),
            _buildMaterialsSection(isAdmin),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Асосий маълумотлар', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            _buildInfoRow('Юник номи', _building.uniqueName),
            _buildInfoRow('Ҳудуд номи', _building.regionName),
            _buildInfoRow('Тасдиқловчи', _building.verificationPerson ?? 'Белгиланмаган'),
            _buildInfoRow('Колодец ҳолати', _building.kolodetsStatus ?? 'Белгиланмаган'),
            _buildInfoRow('Яратилган сана', DateFormat('dd.MM.yyyy HH:mm').format(_building.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsSection(bool isAdmin) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Материаллар', style: Theme.of(context).textTheme.titleLarge),
                Spacer(),
                // Faqat admin uchun history button
                if (isAdmin)
                  ElevatedButton.icon(
                    onPressed: () => _showChangeHistory(),
                    icon: Icon(Icons.history, size: 16),
                    label: Text('Тарих'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue,
                      elevation: 0,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            _buildMaterialTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialTable() {
    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('Материал номи', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Ўлчам', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Керакли', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                Expanded(flex: 2, child: Text('Мавжуд', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                Expanded(flex: 2, child: Text('Мавжудлиги', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
        
        // Material rows
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Column(
            children: List.generate(_building.requiredMaterials.length, (index) {
              return _buildMaterialRow(index);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialRow(int index) {
    final requiredMaterial = _building.requiredMaterials[index];
    final materialName = requiredMaterial['materialName'] ?? '';
    final materialUnit = requiredMaterial['unit'] ?? 'дона';
    final requiredQuantity = requiredMaterial['quantity'] ?? 0;
    final requiredSize = requiredMaterial['size'] ?? '';
    
    final availableQuantity = index < _availableQuantityControllers.length 
        ? double.tryParse(_availableQuantityControllers[index].text) ?? 0
        : 0;
    final requiredQty = double.tryParse(requiredQuantity.toString()) ?? 0;
    
    String availabilityStatus;
    Color availabilityColor;
    
    if (availableQuantity >= requiredQty) {
      availabilityStatus = 'Етарли';
      availabilityColor = Colors.green;
    } else if (availableQuantity > 0) {
      availabilityStatus = 'Камчилик';
      availabilityColor = Colors.orange;
    } else {
      availabilityStatus = 'Йўқ';
      availabilityColor = Colors.red;
    }
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
        color: index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            // Material name
            Expanded(
              flex: 4,
              child: Text(materialName),
            ),
            SizedBox(width: 6),
            
            // Size
            Expanded(
              flex: 2,
              child: Text(requiredSize.toString()),
            ),
            SizedBox(width: 6),
            
            // Required quantity
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text(requiredQuantity.toString()),
                  SizedBox(width: 4),
                  Text(
                    materialUnit,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            SizedBox(width: 6),
            
            // Available quantity - EDITABLE
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: index < _availableQuantityControllers.length 
                    ? _availableQuantityControllers[index] 
                    : TextEditingController(text: '0'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: Colors.green.shade50,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final oldValue = _getAvailableMaterialQuantity(requiredMaterial['materialId']);
                  setState(() {});
                  
                  // Log change
                  ChangeHistoryService.logMaterialChange(
                    buildingId: _building.id,
                    materialId: requiredMaterial['materialId'],
                    materialName: materialName,
                    fieldName: 'quantity',
                    oldValue: oldValue.toString(),
                    newValue: value,
                  );
                },
              ),
            ),
            SizedBox(width: 6),
            
            // Availability status
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: availabilityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: availabilityColor.withOpacity(0.3)),
                ),
                child: Text(
                  availabilityStatus,
                  style: TextStyle(
                    color: availabilityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getAvailableMaterialQuantity(String materialId) {
    final availableMaterial = _building.availableMaterials
        .firstWhere((m) => m['materialId'] == materialId, orElse: () => {});
    return double.tryParse(availableMaterial['quantity']?.toString() ?? '0') ?? 0;
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    
    try {
      final updatedAvailableMaterials = <Map<String, dynamic>>[];
      
      for (int i = 0; i < _building.requiredMaterials.length; i++) {
        final requiredMaterial = _building.requiredMaterials[i];
        final materialId = requiredMaterial['materialId'];
        
        final availableQuantity = i < _availableQuantityControllers.length
            ? double.tryParse(_availableQuantityControllers[i].text) ?? 0
            : 0;
        
        updatedAvailableMaterials.add({
          'materialId': materialId,
          'materialName': requiredMaterial['materialName'],
          'quantity': availableQuantity,
          'unit': requiredMaterial['unit'],
          'size': requiredMaterial['size'],
          'addedAt': DateTime.now().toIso8601String(),
        });
      }
      
      final updatedBuilding = Building(
        id: _building.id,
        latitude: _building.latitude,
        longitude: _building.longitude,
        uniqueName: _building.uniqueName,
        regionName: _building.regionName,
        verificationPerson: AuthService.currentVerifierName, // Auto-assign current verifier
        status: _building.status,
        kolodetsStatus: _building.kolodetsStatus,
        builders: _building.builders,
        schemeUrl: _building.schemeUrl,
        comment: _building.comment,
        createdAt: _building.createdAt,
        images: _building.images,
        customData: _building.customData,
        materialStatus: _building.materialStatus,
        availableMaterials: updatedAvailableMaterials,
        requiredMaterials: _building.requiredMaterials,
      );
      
      await FirebaseService.saveBuilding(updatedBuilding);
      
      setState(() {
        _building = updatedBuilding;
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ўзгаришлар сақланди')),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Хатолик: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showChangeHistory() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.blue.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Ўзгариш тарихи',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: ChangeHistoryService.getChangeHistory(_building.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off, 
                                 size: 64, color: Colors.grey.shade400),
                            SizedBox(height: 16),
                            Text(
                              'Ўзгариш тарихи мавжуд эмас',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.separated(
                      padding: EdgeInsets.all(16),
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                      itemBuilder: (context, index) {
                        final change = snapshot.data![index];
                        final changeDate = DateTime.parse(change['changedAt']);
                        
                        return Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Material name and field
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      change['materialName'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    change['fieldName'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              
                              // Value change
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Эски қиймат:',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.red.shade600,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            change['oldValue'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.red.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.arrow_forward, 
                                               color: Colors.grey, size: 16),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.green.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Янги қиймат:',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green.shade600,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            change['newValue'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              
                              // User and date info
                              Row(
                                children: [
                                  Icon(Icons.person, size: 14, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    change['changedBy'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Spacer(),
                                  Icon(Icons.access_time, size: 14, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd.MM.yyyy HH:mm').format(changeDate),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _availableQuantityControllers) {
      controller.dispose();
    }
    for (final controller in _availableSizeControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}




