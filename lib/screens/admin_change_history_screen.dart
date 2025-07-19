import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/change_history_service.dart';
import '../models/building.dart';
import '../services/firebase_service.dart';

class AdminChangeHistoryScreen extends StatefulWidget {
  @override
  _AdminChangeHistoryScreenState createState() => _AdminChangeHistoryScreenState();
}

class _AdminChangeHistoryScreenState extends State<AdminChangeHistoryScreen> {
  List<Map<String, dynamic>> _allChanges = [];
  List<Map<String, dynamic>> _filteredChanges = [];
  List<Building> _buildings = [];
  String? _selectedBuildingId;
  String? _selectedUser;
  final _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterChanges);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load buildings
      final buildings = await FirebaseService.getBuildings().first;
      
      // Load all changes from all buildings
      List<Map<String, dynamic>> allChanges = [];
      
      for (final building in buildings) {
        final changes = await ChangeHistoryService.getChangeHistory(building.id).first;
        for (final change in changes) {
          change['buildingName'] = building.uniqueName;
          change['buildingId'] = building.id;
          allChanges.add(change);
        }
      }
      
      // Sort by date (newest first)
      allChanges.sort((a, b) => 
        DateTime.parse(b['changedAt']).compareTo(DateTime.parse(a['changedAt']))
      );
      
      setState(() {
        _buildings = buildings;
        _allChanges = allChanges;
        _filteredChanges = allChanges;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Хатолик: $e')),
      );
    }
  }

  void _filterChanges() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredChanges = _allChanges.where((change) {
        final matchesSearch = query.isEmpty ||
            change['materialName'].toLowerCase().contains(query) ||
            change['buildingName'].toLowerCase().contains(query) ||
            change['changedBy'].toLowerCase().contains(query);
            
        final matchesBuilding = _selectedBuildingId == null ||
            change['buildingId'] == _selectedBuildingId;
            
        final matchesUser = _selectedUser == null ||
            change['changedBy'] == _selectedUser;
            
        return matchesSearch && matchesBuilding && matchesUser;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ўзгариш тарихи'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh),
            tooltip: 'Янгилаш',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                _buildStats(),
                Expanded(child: _buildChangesList()),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    final users = _allChanges.map((c) => c['changedBy'] as String).toSet().toList();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Қидириш (материал, бино, фойдаланувчи)...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          SizedBox(height: 12),
          
          // Filters row
          Row(
            children: [
              // Building filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedBuildingId,
                  decoration: InputDecoration(
                    labelText: 'Бино',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text('Барчаси')),
                    ..._buildings.map((b) => DropdownMenuItem(
                      value: b.id,
                      child: Text(b.uniqueName, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedBuildingId = value);
                    _filterChanges();
                  },
                ),
              ),
              SizedBox(width: 12),
              
              // User filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUser,
                  decoration: InputDecoration(
                    labelText: 'Фойдаланувчи',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text('Барчаси')),
                    ...users.map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(u, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedUser = value);
                    _filterChanges();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final totalChanges = _filteredChanges.length;
    final uniqueBuildings = _filteredChanges.map((c) => c['buildingId']).toSet().length;
    final uniqueUsers = _filteredChanges.map((c) => c['changedBy']).toSet().length;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Ўзгариш', totalChanges.toString(), Icons.edit),
          _buildStatItem('Бино', uniqueBuildings.toString(), Icons.location_city),
          _buildStatItem('Фойдаланувчи', uniqueUsers.toString(), Icons.person),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildChangesList() {
    if (_filteredChanges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'Ўзгариш тарихи топилмади',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: _filteredChanges.length,
      separatorBuilder: (context, index) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final change = _filteredChanges[index];
        final changeDate = DateTime.parse(change['changedAt']);
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        change['changedBy'][0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            change['changedBy'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${change['buildingName']} • ${DateFormat('dd.MM.yyyy HH:mm').format(changeDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        change['fieldName'],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                // Material name
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    change['materialName'],
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                
                // Value change
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          change['oldValue'],
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                      ),
                      Expanded(
                        child: Text(
                          change['newValue'],
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}