/// ------------------

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/building.dart';
import '../services/firebase_service.dart';
import 'add_building_screen.dart';
import 'building_detail_screen.dart';
import 'package:geoxml/geoxml.dart';

class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Building> _buildings = [];
  List<Building> _searchResults = [];
  List<LatLng> _kmlPolylinePoints = [];
  List<Polyline> _polylines = [];
  List<Marker> _markers = [];
  LatLng _center = LatLng(40.495, 68.787); // Guliston
  LatLng? _currentLocation;
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
    _getCurrentLocation();

    // Search controller listener
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });

    _searchFocusNode.addListener(() {
      setState(() => _showSearchResults = _searchFocusNode.hasFocus && _searchController.text.isNotEmpty);
    });
    _loadKml();
  }

  void _loadBuildings() {
    FirebaseService.getBuildings().listen((buildings) {
      setState(() => _buildings = buildings);
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
      _searchResults = _buildings.where((b) {
        // Unique name bo'yicha qidirish
        final uniqueNameMatch = b.uniqueName.toLowerCase().contains(query);
        
        // Region name (joy nomi) bo'yicha qidirish
        final regionNameMatch = b.regionName.toLowerCase().contains(query);
        
        // Verification person bo'yicha qidirish
        final verificationPersonMatch = 
            (b.verificationPerson?.toLowerCase().contains(query) ?? false);
        
        // Agar query'da bo'sh joy bo'lsa - bir nechta so'z bo'yicha qidirish
        if (query.contains(' ')) {
          final words = query.split(' ').where((word) => word.isNotEmpty).toList();
          final allWordsMatch = words.every((word) =>
            b.uniqueName.toLowerCase().contains(word) ||
            b.regionName.toLowerCase().contains(word) ||
            (b.verificationPerson?.toLowerCase().contains(word) ?? false)
          );
          return allWordsMatch;
        }
        
        return uniqueNameMatch || regionNameMatch || verificationPersonMatch;
      }).toList();
      
      _showSearchResults = query.isNotEmpty && _searchFocusNode.hasFocus;
    });
  }

  void _onBuildingTap(Building building) {
    _mapController.move(LatLng(building.latitude, building.longitude), 17);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BuildingDetailScreen(building: building)),
    );
    // Yangi joyga fokusni olib tashlash
    _searchFocusNode.unfocus();
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
    return _buildings.where((b) => b.status == status).toList();
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _buildStatusIcon(building.status),
            ),
            SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  building.uniqueName, // uniqueName o'rniga id ko'rsatish
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 14,
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
                    ),
                    if (_polylines.isNotEmpty)
                      PolylineLayer(polylines: _polylines),
                    if (_markers.isNotEmpty)
                      MarkerLayer(markers: _markers),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 60,
                        size: Size(40, 40),
                        markers: _buildMarkers(),
                        builder: (context, markers) => CircleAvatar(
                          backgroundColor: Colors.blue.shade700,
                          child: Text(
                            '${markers.length}',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Search input va natijalar
                Positioned(
                  top: 20,
                  left: 20,
                  right: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: "Уник номи, жой номи ёки тасдиқловчи билан қидиринг...",
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _searchFocusNode.unfocus();
                                setState(() => _showSearchResults = false);
                              },
                            )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      if (_showSearchResults && _searchResults.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(top: 6),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          constraints: BoxConstraints(
                            maxHeight: 300,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final building = _searchResults[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _onBuildingTap(building),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      dense: true,
                                      title: Text(building.uniqueName),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            building.verificationPerson ?? "Тасдиқловчи йўқ",
                                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                          ),
                                          if (building.availableMaterials.isNotEmpty)
                                            Text(
                                              'Материаллар: ${building.availableMaterials.length} та',
                                              style: TextStyle(color: Colors.green, fontSize: 10),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                Positioned(
                  top: 24,
                  right: 20,
                  child: FloatingActionButton(
                    mini: true,
                    tooltip: 'Харитани текислаш',
                    onPressed: _resetMapOrientation,
                    child: Icon(Icons.explore),
                  ),
                ),
              ],
            ),
          ),
          if (isWindows)
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}
