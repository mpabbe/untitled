import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/building.dart';
import 'verifier_building_detail_screen.dart';
import 'login_screen.dart';

class VerifierScreen extends StatefulWidget {
  @override
  _VerifierScreenState createState() => _VerifierScreenState();
}

class _VerifierScreenState extends State<VerifierScreen> {
  List<Building> _buildings = [];
  List<Building> _filteredBuildings = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('VerifierScreen initState - Current verifier: ${AuthService.currentVerifierName}'); // Debug
    _loadBuildings();
    _searchController.addListener(_onSearchChanged);
  }

  void _loadBuildings() {
    print('Loading ALL buildings for verifier: ${AuthService.currentVerifierName}'); // Debug
    
    FirebaseService.getBuildings().listen((buildings) {
      print('Total buildings received: ${buildings.length}'); // Debug
      
      final currentVerifier = AuthService.currentVerifierName;
      if (currentVerifier == null) {
        print('Current verifier is null!'); // Debug
        setState(() {
          _buildings = [];
          _filteredBuildings = [];
        });
        return;
      }
      
      // BARCHA binolarni ko'rsatish (hech qanday status filtri yo'q)
      print('Showing ALL buildings regardless of status: ${buildings.length}'); // Debug
      
      setState(() {
        _buildings = buildings; // Barcha binolar
        _filteredBuildings = buildings; // Barcha binolar
      });
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    print('Search query: "$query"'); // Debug
    
    setState(() {
      if (query.isEmpty) {
        _filteredBuildings = _buildings;
      } else {
        _filteredBuildings = _buildings.where((b) {
          final uniqueNameMatch = b.uniqueName.toLowerCase().contains(query);
          final regionNameMatch = b.regionName.toLowerCase().contains(query);
          
          print('Building ${b.uniqueName}: uniqueName match=$uniqueNameMatch, region match=$regionNameMatch'); // Debug
          
          return uniqueNameMatch || regionNameMatch;
        }).toList();
      }
      print('Filtered results: ${_filteredBuildings.length}'); // Debug
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Тасдиқловчи: ${AuthService.currentVerifierName}'),
        actions: [
          IconButton(
            onPressed: () {
              AuthService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Колодец қидириш...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          
          // Buildings list
          Expanded(
            child: _filteredBuildings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty 
                              ? 'Колодецлар мавжуд эмас'
                              : 'Қидирув натижаси топилмади',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredBuildings.length,
                    itemBuilder: (context, index) {
                      final building = _filteredBuildings[index];
                      
                      // Status color
                      Color statusColor;
                      String statusText;
                      switch (building.status) {
                        case BuildingStatus.inProgress:
                          statusColor = Colors.blue;
                          statusText = 'Жараёнда';
                          break;
                        case BuildingStatus.completed:
                          statusColor = Colors.green;
                          statusText = 'Тугалланган';
                          break;
                        default:
                          statusColor = Colors.grey;
                          statusText = 'Номаълум';
                      }
                      
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(building.uniqueName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(building.regionName),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (building.verificationPerson != null) ...[
                                    SizedBox(width: 8),
                                    Text(
                                      'Тасдиқловчи: ${building.verificationPerson}',
                                      style: TextStyle(fontSize: 10, color: Colors.blue),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VerifierBuildingDetailScreen(building: building),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}








