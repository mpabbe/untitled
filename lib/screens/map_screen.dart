import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/building.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'add_building_screen.dart';
import 'building_detail_screen.dart';
import 'login_screen.dart';
import 'verifier_building_detail_screen.dart';
import 'verifier_management_screen.dart';
import 'builder_report_screen.dart';
import 'admin_change_history_screen.dart';
import 'package:geoxml/geoxml.dart';
import '../services/material_service.dart';

class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Building> _buildings = [];
  List<Building> _filteredBuildings = [];
  List<Building> _searchResults = [];
  List<String> _builders = []; // _verifiers o'rniga
  String _selectedBuilder = 'Барчаси'; // _selectedVerifier o'rniga
  bool _isLoading = true;
  
  List<LatLng> _kmlPolylinePoints = [];
  List<Polyline> _polylines = [];
  List<Marker> _markers = [];
  LatLng _center = LatLng(40.495, 68.787);
  LatLng? _currentLocation;
  bool _showSearchResults = false;

  final MaterialService _materialService = MaterialService();

  // O'zbekiston chegaralari (asosiy shaharlar atrofida)
  static LatLngBounds _uzbekistanBounds = LatLngBounds(
    LatLng(37.184, 55.997), // Termez atrofi (South-West)
    LatLng(45.590, 73.055), // Zarafshon atrofi (North-East)
  );

  @override
  void initState() {
    super.initState();
    print('MapScreen initState started'); // Debug
    _loadData();
    _getCurrentLocation();
    _loadKml();

    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });

    _searchFocusNode.addListener(() {
      setState(() => _showSearchResults = _searchFocusNode.hasFocus && _searchController.text.isNotEmpty);
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final buildings = await FirebaseService.getBuildings().first;
      final builders = await MaterialService().getBuilders(); // getVerifiers o'rniga
      
      setState(() {
        _buildings = buildings;
        _filteredBuildings = buildings;
        _builders = ['Барчаси', ...builders]; // _verifiers o'rniga
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Маълумотларни юклашда хатолик: $e')),
      );
    }
  }

  void _filterBuildingsByBuilder(String? builder) { // _filterBuildingsByVerifier o'rniga
    setState(() {
      _selectedBuilder = builder ?? 'Барчаси';
      
      if (_selectedBuilder == 'Барчаси') {
        _filteredBuildings = _buildings;
      } else {
        _filteredBuildings = _buildings.where((building) {
          return building.builders != null && 
                 building.builders!.contains(_selectedBuilder);
        }).toList();
      }
    });
  }

  void _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
    final position = await Geolocator.getCurrentPosition();
    setState(() => _currentLocation = LatLng(position.latitude, position.longitude));
  }


  Future<void> _loadKml() async {
    final kmlString = await rootBundle.loadString('assets/file.kml');
    final geoXml = await GeoXml.fromKmlString(kmlString);

    // Extract polylines (from tracks and routes)
    final lines = <Polyline>[];
    // for (final trk in geoXml.trks) {
    //   for (final seg in trk.trksegs) {
    //     final points = seg.trkpts
    //         .where((pt) => pt.lat != null && pt.lon != null)
    //         .map((pt) => LatLng(pt.lat!, pt.lon!))
    //         .toList();
    //     if (points.isNotEmpty) {
    //       lines.add(Polyline(
    //         points: points,
    //         strokeWidth: 4,
    //         color: Colors.blue,
    //       ));
    //     }
    //   }
    // }

    for (final rte in geoXml.rtes) {
      final points = rte.rtepts
          .where((pt) => pt.lat != null && pt.lon != null)
          .map((pt) => LatLng(pt.lat!, pt.lon!))
          .toList();
      if (points.isNotEmpty) {
        lines.add(Polyline(
          points: points,
          strokeWidth: 3,
          color: Colors.blue,
        ));
      }
    }

    // Extract markers (from waypoints)
    final markers = geoXml.wpts
        .where((pt) => pt.lat != null && pt.lon != null)
        .map((pt) => Marker(
      point: LatLng(pt.lat!, pt.lon!),
      width: 30,
      height: 30,
      child: Icon(Icons.location_pin, color: Colors.red),
    ))
        .toList();

    setState(() {
      _polylines = lines;
      // _markers = markers;
    });
  }



  void _onSearchChanged(String value) {
    final query = value.toLowerCase();
    setState(() {
      _searchResults = _filteredBuildings.where((b) {
        final uniqueNameMatch = b.uniqueName.toLowerCase().contains(query);
        final regionNameMatch = b.regionName.toLowerCase().contains(query);
        final verificationPersonMatch = 
            (b.verificationPerson?.toLowerCase().contains(query) ?? false);
        final buildersMatch = b.builders?.any((builder) => 
            builder.toLowerCase().contains(query)) ?? false;
        
        if (query.contains(' ')) {
          final words = query.split(' ').where((word) => word.isNotEmpty).toList();
          final allWordsMatch = words.every((word) =>
            b.uniqueName.toLowerCase().contains(word) ||
            b.regionName.toLowerCase().contains(word) ||
            (b.verificationPerson?.toLowerCase().contains(word) ?? false) ||
            (b.builders?.any((builder) => builder.toLowerCase().contains(word)) ?? false)
          );
          return allWordsMatch;
        }
        
        return uniqueNameMatch || regionNameMatch || verificationPersonMatch || buildersMatch;
      }).toList();
      
      _showSearchResults = query.isNotEmpty && _searchFocusNode.hasFocus;
    });
  }

  void _onBuildingTap(Building building) {
    // Focus ni tozalash
    FocusScope.of(context).unfocus();

    _mapController.move(LatLng(building.latitude, building.longitude), 17);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BuildingDetailScreen(building: building)),
    );

    _searchController.clear();
    setState(() {
      _showSearchResults = false;
      _searchResults.clear();
    });
  }


  void _resetMapOrientation() {
    _mapController.rotate(0);
  }

  List<Building> _filterByStatus(BuildingStatus status) {
    return _filteredBuildings.where((b) => b.status == status).toList();
  }

  List<Marker> _buildMarkers() {
    return _buildings.map((building) => Marker(
      point: LatLng(building.latitude, building.longitude),
      width: 180,
      height: 60,
      child: GestureDetector(
        onTap: () => _onBuildingTap(building),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _getStatusColor(building.status), width: 2),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _buildStatusIcon(building.status),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  building.uniqueName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    )).toList();
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

  Widget _buildStatusList(String label, BuildingStatus status, Color color) {
    final list = _filterByStatus(status);
    if (list.isEmpty) return SizedBox.shrink();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          '$label (${list.length})',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: list.map((building) => ListTile(
          title: Text(building.uniqueName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Тасдиқловчи: ${building.verificationPerson ?? "йўқ"}'),
              if (building.builders != null && building.builders!.isNotEmpty)
                Text('Қурувчилар: ${building.builders!.join(", ")}'),
              if (building.availableMaterials.isNotEmpty)
                Text(
                  'Материаллар: ${building.availableMaterials.length} та',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
            ],
          ),
          onTap: () => _onBuildingTap(building),
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = Platform.isWindows;

    return Scaffold(
      appBar: AppBar(
        title: Text('Колодец Харитаси'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Change History button (faqat admin uchun)
          if (AuthService.currentUserType == 'admin')
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminChangeHistoryScreen()),
              ),
              icon: Icon(Icons.history),
              tooltip: 'Ўзгариш тарихи',
            ),
          // Verifier management
          if (AuthService.currentUserType == 'admin')
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VerifierManagementScreen()),
              ),
              icon: Icon(Icons.people),
              tooltip: 'Тасдиқловчилар',
            ),
          // Builder report
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BuilderReportScreen()),
            ),
            icon: Icon(Icons.assessment),
            tooltip: 'Ҳисобот',
          ),
          // Logout
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
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // Map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 14,
                    minZoom: 6.0,
                    maxZoom: 18.0,
                    // O'zbekiston chegaralari
                    cameraConstraint: CameraConstraint.contain(
                      bounds: LatLngBounds(
                        const LatLng(37.0, 55.0),
                        const LatLng(45.7, 73.2),
                      ),
                    ),
                    onLongPress: (tapPosition, point) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddBuildingScreen(
                            latitude: point.latitude,
                            longitude: point.longitude,
                          ),
                        ),
                      );
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://{s}.tile.openstreetmap.de/tiles/osmde/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                      userAgentPackageName: 'com.yourcompany.yourapp',
                      // Faqat O'zbekiston hududida tile'lar yuklanadi
                      tileBounds: LatLngBounds(
                        LatLng(37.0, 55.0), // South-West
                        LatLng(45.7, 73.2), // North-East
                      ),
                    ),
                    if (_polylines.isNotEmpty)
                      PolylineLayer(polylines: _polylines),
                    if (_markers.isNotEmpty)
                      MarkerLayer(markers: _markers),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 60,
                        size: Size(40, 40),
                        markers: _filteredBuildings.map((building) => Marker(
                          point: LatLng(building.latitude, building.longitude),
                          width: 80,
                          height: 60,
                          alignment: Alignment.topCenter, // Circle yuqorida, text pastda
                          child: GestureDetector(
                            onTap: () => _onBuildingTap(building),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Circle marker
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
                                // Seria ID text
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

                // Search and filter section
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      // Search va Verifier filter - yonma-yon
                      Row(
                        children: [
                          // Search field - kattaroq
                          Expanded(
                            flex: 3,
                            child: Container(
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
                          ),
                          
                          SizedBox(width: 12),
                          
                          // Verifier filter dropdown - kichikroq
                          Expanded(
                            flex: 2,
                            child: Container(
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
                              child: _isLoading
                                  ? Container(
                                      height: 56,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                            SizedBox(height: 4),
                                            Text('Юкланмоқда...', style: TextStyle(fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                    )
                                  : _builders.isEmpty
                                      ? Container(
                                          height: 56,
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.error_outline, size: 16, color: Colors.red),
                                                Text('Маълумот йўқ', style: TextStyle(fontSize: 10, color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: double.infinity,
                                          child: DropdownButtonFormField<String>(
                                            value: _selectedBuilder,
                                            decoration: InputDecoration(
                                              labelText: 'Қурувчи',
                                              prefixIcon: Icon(Icons.construction, color: Colors.blue, size: 18),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              labelStyle: TextStyle(fontSize: 12),
                                            ),
                                            items: _builders.map((builder) {
                                              // Har bir qурувчи uchun binolar sonini hisoblash
                                              final buildingCount = builder == 'Барчаси' 
                                                  ? _buildings.length
                                                  : _buildings.where((b) => 
                                                      b.builders != null && b.builders!.contains(builder)
                                                    ).length;
                                              
                                              return DropdownMenuItem(
                                                value: builder,
                                                child: Row(
                                                  children: [
                                                    if (builder == 'Барчаси')
                                                      Icon(Icons.all_inclusive, size: 14, color: Colors.green)
                                                    else
                                                      Icon(Icons.construction, size: 14, color: Colors.blue),
                                                    SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        '$builder ($buildingCount)',
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              print('Selected builder: $value'); // Debug
                                              _filterBuildingsByBuilder(value);
                                            },
                                            style: TextStyle(fontSize: 12, color: Colors.black),
                                          ),
                                        ),
                            ),
                          )
                        ],
                      ),
                      
                      // Search results dropdown - faqat search qilganda ko'rinadi
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
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      building.regionName,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    if (building.verificationPerson != null)
                                      Text(
                                        'Тасдиқловчи: ${building.verificationPerson}',
                                        style: TextStyle(fontSize: 11, color: Colors.blue),
                                      ),
                                  ],
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

                // Action buttons
                Positioned(
                  top: 140,
                  right: 20,
                  child: Column(
                    children: [
                      _buildActionButton(
                        icon: Icons.people,
                        tooltip: 'Тасдиқловчилар бошқаруви',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => VerifierManagementScreen()),
                        ),
                        color: Colors.purple,
                      ),
                      SizedBox(height: 8),
                      _buildActionButton(
                        icon: Icons.analytics,
                        tooltip: 'Қурувчилар ҳисоботи',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BuilderReportScreen()),
                        ),
                        color: Colors.purple,
                      ),
                      SizedBox(height: 8),
                      _buildActionButton(
                        icon: Icons.explore,
                        tooltip: 'Харитани текислаш',
                        onPressed: _resetMapOrientation,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),

                // Statistics overlay
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    padding: EdgeInsets.all(16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedBuilder != null && _selectedBuilder != 'Барчаси') ...[
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.blue, size: 16),
                              SizedBox(width: 6),
                              Text(
                                _selectedBuilder!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                        ],
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatItem('Жами', _filteredBuildings.length, Colors.blue),
                            SizedBox(width: 16),
                            _buildStatItem('Тугалланган', _filterByStatus(BuildingStatus.completed).length, Colors.green),
                            SizedBox(width: 16),
                            _buildStatItem('Жараёнда', _filterByStatus(BuildingStatus.inProgress).length, Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sidebar for Windows
          if (isWindows)
            Container(
              width: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(-2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Лойиҳалар ҳолати',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStatusList("Бошланмаган", BuildingStatus.notStarted, Colors.grey),
                          _buildStatusList("Жараёнда", BuildingStatus.inProgress, Colors.orange),
                          _buildStatusList("Тугалланган", BuildingStatus.completed, Colors.green),
                          _buildStatusList("Тўхтатилган", BuildingStatus.paused, Colors.red),
                        ],
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

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            child: Icon(icon, color: color, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
