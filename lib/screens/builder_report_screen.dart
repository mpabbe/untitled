import 'package:flutter/material.dart';
import '../models/building.dart';
import '../models/material_item.dart';
import '../services/material_service.dart';
import '../services/firebase_service.dart';

class BuilderReportScreen extends StatefulWidget {
  @override
  _BuilderReportScreenState createState() => _BuilderReportScreenState();
}

class _BuilderReportScreenState extends State<BuilderReportScreen> {
  final MaterialService _materialService = MaterialService();
  List<String> _builders = [];
  String? _selectedBuilder;
  List<Building> _buildings = [];
  Map<String, BuilderStats> _builderStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final builders = await _materialService.getBuilders();
      final buildings = await _materialService.getBuildings();
      
      setState(() {
        _builders = builders;
        _buildings = buildings;
        _calculateBuilderStats();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Маълумотларни юклашда хатолик: $e')),
      );
    }
  }

  void _calculateBuilderStats() {
    _builderStats.clear();
    
    for (final builder in _builders) {
      final builderBuildings = _buildings.where((b) => 
        b.builders != null && b.builders!.contains(builder)
      ).toList();
      
      final stats = BuilderStats(
        builderName: builder,
        totalKolodets: builderBuildings.length,
        completedKolodets: builderBuildings.where((b) => b.status == BuildingStatus.completed).length,
        inProgressKolodets: builderBuildings.where((b) => b.status == BuildingStatus.inProgress).length,
        materialStats: _calculateMaterialStats(builderBuildings),
      );
      
      _builderStats[builder] = stats;
    }
  }

  Map<String, MaterialStats> _calculateMaterialStats(List<Building> buildings) {
    final materialStats = <String, MaterialStats>{};
    
    for (final building in buildings) {
      // Required materials
      for (final material in building.requiredMaterials) {
        final materialId = material['materialId'];
        final materialName = material['materialName'] ?? 'Номсиз';
        final size = material['size']?.toString() ?? '';
        final unit = material['unit']?.toString() ?? 'дона';
        final quantity = _parseDouble(material['quantity']);
        
        // Create unique key with materialId + size
        final key = '$materialId|$size';
        
        if (!materialStats.containsKey(key)) {
          materialStats[key] = MaterialStats(
            materialName: materialName,
            size: size,
            unit: unit,
            totalRequired: 0,
            totalAvailable: 0,
            totalUsed: 0,
          );
        }
        
        materialStats[key]!.totalRequired += quantity;
      }
      
      // Available materials
      for (final material in building.availableMaterials) {
        final materialId = material['materialId'];
        final size = material['size']?.toString() ?? '';
        final quantity = _parseDouble(material['quantity']);
        
        // Create unique key with materialId + size
        final key = '$materialId|$size';
        
        if (materialStats.containsKey(key)) {
          materialStats[key]!.totalAvailable += quantity;
        }
      }
    }
    
    // Calculate used materials (available - remaining)
    for (final stats in materialStats.values) {
      stats.totalUsed = stats.totalAvailable;
    }
    
    return materialStats;
  }

  // Helper method to safely parse double values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Қурувчилар ҳисоботи'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Builder selection
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: DropdownButtonFormField<String>(
                        value: _selectedBuilder,
                        decoration: InputDecoration(
                          labelText: 'Қурувчини танланг',
                          prefixIcon: Icon(Icons.construction),
                          border: OutlineInputBorder(),
                        ),
                        items: _builders.map((builder) => DropdownMenuItem(
                          value: builder,
                          child: Text(builder),
                        )).toList(),
                        onChanged: (value) {
                          setState(() => _selectedBuilder = value);
                        },
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Builder stats
                  if (_selectedBuilder != null) ...[
                    Expanded(child: _buildBuilderReport()),
                  ] else ...[
                    Expanded(
                      child: Center(
                        child: Text(
                          'Қурувчини танланг',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildBuilderReport() {
    final stats = _builderStats[_selectedBuilder!];
    if (stats == null) return SizedBox();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Overview stats
          Row(
            children: [
              Expanded(child: _buildStatCard('Жами колодец', stats.totalKolodets, Colors.blue)),
              SizedBox(width: 8),
              Expanded(child: _buildStatCard('Тугалланган', stats.completedKolodets, Colors.green)),
              SizedBox(width: 8),
              Expanded(child: _buildStatCard('Жараёнда', stats.inProgressKolodets, Colors.orange)),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Materials table
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Материаллар ҳисоботи',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Материал')),
                        DataColumn(label: Text('Ўлчам')),
                        DataColumn(label: Text('Керак')),
                        DataColumn(label: Text('Мавжуд')),
                        DataColumn(label: Text('Ҳолат')),
                      ],
                      rows: stats.materialStats.values.map((material) {
                        final isEnough = material.totalAvailable >= material.totalRequired;
                        final shortage = material.totalRequired - material.totalAvailable;
                        
                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                constraints: BoxConstraints(maxWidth: 150),
                                child: Text(
                                  material.materialName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                material.size.isEmpty ? '-' : material.size,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DataCell(
                              Text('${material.totalRequired.toStringAsFixed(0)} ${material.unit}'),
                            ),
                            DataCell(
                              Text(
                                '${material.totalAvailable.toStringAsFixed(0)} ${material.unit}',
                                style: TextStyle(
                                  color: isEnough ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isEnough ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isEnough 
                                    ? 'Етарли' 
                                    : 'Камчилик: ${shortage.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class BuilderStats {
  final String builderName;
  final int totalKolodets;
  final int completedKolodets;
  final int inProgressKolodets;
  final Map<String, MaterialStats> materialStats;

  BuilderStats({
    required this.builderName,
    required this.totalKolodets,
    required this.completedKolodets,
    required this.inProgressKolodets,
    required this.materialStats,
  });
}

class MaterialStats {
  final String materialName;
  final String size;
  final String unit;
  double totalRequired;
  double totalAvailable;
  double totalUsed;

  MaterialStats({
    required this.materialName,
    required this.size,
    required this.unit,
    required this.totalRequired,
    required this.totalAvailable,
    required this.totalUsed,
  });
}


