import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/building.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'user_building_detail_screen.dart';
import 'dart:async';

class UserMapScreen extends StatefulWidget {
  @override
  State<UserMapScreen> createState() => _UserMapScreenState();
}

class _UserMapScreenState extends State<UserMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Building> _buildings = [];
  List<Building> _searchResults = [];
  bool _isLoading = true;
  
  LatLng _center = LatLng(40.495, 68.787);
  LatLng? _currentLocation;
  bool _showSearchResults = false;

  StreamSubscription<QuerySnapshot>? _buildingsSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _getCurrentLocation();
    _setupRealTimeListener();

    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });

    _searchFocusNode.addListener(() {
      setState(() => _showSearchResults = _searchFocusNode.hasFocus && _searchController.text.isNotEmpty);
    });
  }

  void _setupRealTimeListener() {
    _buildingsSubscription = FirebaseFirestore.instance
        .collection('buildings')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _buildingsSubscription?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final buildings = await FirebaseService.getBuildings().first;
      
      setState(() {
        _buildings = buildings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Маълумотларни юклашда хатолик: $e')),
      );
    }
  }

  void _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
    final position = await Geolocator.getCurrentPosition();
    setState(() => _currentLocation = LatLng(position.latitude, position.longitude));
  }

  void _onSearchChanged(String value) {
    final query = value.toLowerCase();
    setState(() {
      _searchResults = _buildings.where((b) {
        final uniqueNameMatch = b.uniqueName.toLowerCase().contains(query);
        final regionNameMatch = b.regionName.toLowerCase().contains(query);
        
        if (query.contains(' ')) {
          final words = query.split(' ').where((word) => word.isNotEmpty).toList();
          final allWordsMatch = words.every((word) =>
            b.uniqueName.toLowerCase().contains(word) ||
            b.regionName.toLowerCase().contains(word)
          );
          return allWordsMatch;
        }
        
        return uniqueNameMatch || regionNameMatch;
      }).toList();
      
      _showSearchResults = query.isNotEmpty && _searchFocusNode.hasFocus;
    });
  }

  void _onBuildingTap(Building building) {
    FocusScope.of(context).unfocus();
    _mapController.move(LatLng(building.latitude, building.longitude), 17);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserBuildingDetailScreen(building: building)),
    );

    _searchController.clear();
    setState(() {
      _showSearchResults = false;
      _searchResults.clear();
    });
  }

  Widget _buildStatusIcon(BuildingStatus status) {
    IconData icon;
    switch (status) {
      case BuildingStatus.notStarted:
        icon = Icons.hourglass_empty;
        break;
      case BuildingStatus.inProgress:
        icon = Icons.autorenew;
        break;
      case BuildingStatus.completed:
        icon = Icons.check_circle_outline;
        break;
      case BuildingStatus.paused:
        icon = Icons.pause_circle_outline;
        break;
    }
    return Icon(icon, size: 20, color: _getStatusColor(status));
  }

  IconData _getStatusIcon(BuildingStatus status) {
    switch (status) {
      case BuildingStatus.notStarted:
        return Icons.hourglass_empty;
      case BuildingStatus.inProgress:
        return Icons.autorenew;
      case BuildingStatus.completed:
        return Icons.check_circle_outline;
      case BuildingStatus.paused:
        return Icons.pause_circle_outline;
    }
  }

  Color _getStatusColor(BuildingStatus status) {
    switch (status) {
      case BuildingStatus.notStarted:
        return Colors.grey;
      case BuildingStatus.inProgress:
        return Colors.orange;
      case BuildingStatus.completed:
        return Colors.green;
      case BuildingStatus.paused:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Колодец Харитаси'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
              minZoom: 6.0,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(37.0, 55.0),
                  const LatLng(45.7, 73.2),
                ),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.de/tiles/osmde/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'com.yourcompany.yourapp',
                tileBounds: LatLngBounds(
                  LatLng(37.0, 55.0),
                  LatLng(45.7, 73.2),
                ),
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 60,
                  size: Size(40, 40),
                  markers: _buildings.map((building) => Marker(
                    point: LatLng(building.latitude, building.longitude),
                    width: 80,
                    height: 60,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _onBuildingTap(building),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _getStatusColor(building.status), width: 3),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor(building.status).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: _buildStatusIcon(building.status),
                          ),
                          SizedBox(height: 2),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              building.uniqueName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                  builder: (context, markers) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${markers.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Search section
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Уник номи, жой номи билан қидиринг...",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Container(
                        margin: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.search, color: Colors.blue.shade600),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade400),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                          setState(() => _showSearchResults = false);
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                
                // Search results dropdown
                if (_showSearchResults && _searchResults.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    constraints: BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final building = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getStatusColor(building.status).withOpacity(0.1),
                            ),
                            child: Icon(
                              _getStatusIcon(building.status),
                              color: _getStatusColor(building.status),
                              size: 16,
                            ),
                          ),
                          title: Text(
                            building.uniqueName,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            building.regionName,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                          onTap: () => _onBuildingTap(building),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}