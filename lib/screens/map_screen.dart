// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:yandex_mapkit/yandex_mapkit.dart';
// import '../models/building.dart';
// import '../services/firebase_service.dart';
// import 'add_building_screen.dart';
// import 'building_detail_screen.dart';
// import 'dart:async';
//
// class MapScreen extends StatefulWidget {
//   @override
//   _MapScreenState createState() => _MapScreenState();
// }
//
// class _MapScreenState extends State<MapScreen> {
//   late YandexMapController _mapController;
//   List<Building> _buildings = [];
//   bool _isLoading = true;
//   bool _isMapReady = false;
//   double _currentZoom = 14.0;
//
//   final TextEditingController _searchController = TextEditingController();
//
//   final Point _center = Point(latitude: 40.4887, longitude: 68.7849);
//   final double _minLat = 40.4720;
//   final double _maxLat = 40.5065;
//   final double _minLng = 68.7625;
//   final double _maxLng = 68.8232;
//   final double _minZoom = 12.0;
//   final double _maxZoom = 20.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadBuildings();
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void _loadBuildings() {
//     FirebaseService.getBuildings().listen((buildings) {
//       setState(() {
//         _buildings = buildings;
//         _isLoading = false;
//       });
//       if (_isMapReady) _updateMapView();
//     });
//   }
//
//   void _updateMapView() {
//     if (_buildings.isEmpty) return;
//     final first = _buildings.first;
//     _mapController.moveCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(
//           target: Point(latitude: first.latitude, longitude: first.longitude),
//           zoom: 14.0,
//         ),
//       ),
//     );
//   }
//
//   // Better marker sizing - always visible
//   double _getMarkerSize() {
//     if (_currentZoom <= 11) return 80.0;
//     if (_currentZoom <= 12) return 90.0;
//     if (_currentZoom <= 13) return 100.0;
//     if (_currentZoom <= 14) return 110.0;
//     if (_currentZoom <= 15) return 120.0;
//     if (_currentZoom <= 16) return 130.0;
//     if (_currentZoom <= 17) return 140.0;
//     if (_currentZoom <= 18) return 150.0;
//     return 160.0;
//   }
//
//   double _getFontSize() {
//     if (_currentZoom <= 11) return 14.0;
//     if (_currentZoom <= 12) return 16.0;
//     if (_currentZoom <= 13) return 18.0;
//     if (_currentZoom <= 14) return 20.0;
//     if (_currentZoom <= 15) return 22.0;
//     if (_currentZoom <= 16) return 24.0;
//     if (_currentZoom <= 17) return 26.0;
//     if (_currentZoom <= 18) return 28.0;
//     return 30.0;
//   }
//
//   Future<Uint8List> _createMarkerIcon(String text, {bool isCluster = false, int? count}) async {
//     final double size = _getMarkerSize();
//     final double fontSize = _getFontSize();
//
//     final recorder = ui.PictureRecorder();
//     final canvas = Canvas(recorder);
//     final paint = Paint()..isAntiAlias = true;
//
//     if (isCluster) {
//       // Cluster marker - solid circle with strong colors
//       final center = Offset(size / 2, size / 2);
//       final radius = size / 2 - 3;
//
//       // Shadow for depth
//       paint
//         ..color = Colors.black.withOpacity(0.3)
//         ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
//       canvas.drawCircle(Offset(center.dx + 2, center.dy + 2), radius, paint);
//
//       // Main circle - solid bright color
//       paint
//         ..color = Color(0xFF1976D2)
//         ..style = PaintingStyle.fill
//         ..maskFilter = null;
//       canvas.drawCircle(center, radius, paint);
//
//       // Thick white border for contrast
//       paint
//         ..color = Colors.white
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 4.0;
//       canvas.drawCircle(center, radius, paint);
//
//       // Inner circle for better visibility
//       paint
//         ..color = Color(0xFF0D47A1)
//         ..style = PaintingStyle.fill;
//       canvas.drawCircle(center, radius - 4, paint);
//
//       // Count text - bold and clear
//       final textPainter = TextPainter(
//         text: TextSpan(
//           text: count.toString(),
//           style: TextStyle(
//             fontSize: fontSize,
//             fontWeight: FontWeight.w900,
//             color: Colors.white,
//             shadows: [
//               Shadow(
//                 color: Colors.black,
//                 offset: Offset(1, 1),
//                 blurRadius: 2,
//               ),
//             ],
//           ),
//         ),
//         textDirection: TextDirection.ltr,
//       );
//       textPainter.layout();
//
//       final textOffset = Offset(
//         center.dx - textPainter.width / 2,
//         center.dy - textPainter.height / 2,
//       );
//       textPainter.paint(canvas, textOffset);
//
//     } else {
//       // Individual building marker - solid rectangle
//       final double width = size * 2.5;
//       final double height = size * 0.8;
//
//       final rect = RRect.fromRectAndRadius(
//         Rect.fromLTWH(0, 0, width, height),
//         Radius.circular(height / 2),
//       );
//
//       // Shadow for depth
//       paint
//         ..color = Colors.black.withOpacity(0.3)
//         ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
//       canvas.drawRRect(rect.shift(Offset(2, 2)), paint);
//
//       // Main background - solid bright color
//       paint
//         ..color = Color(0xFF2196F3)
//         ..style = PaintingStyle.fill
//         ..maskFilter = null;
//       canvas.drawRRect(rect, paint);
//
//       // Thick white border
//       paint
//         ..color = Colors.white
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 4.0;
//       canvas.drawRRect(rect, paint);
//
//       // Inner background for better text visibility
//       final innerRect = RRect.fromRectAndRadius(
//         Rect.fromLTWH(4, 4, width - 8, height - 8),
//         Radius.circular((height - 8) / 2),
//       );
//       paint
//         ..color = Color(0xFF1976D2)
//         ..style = PaintingStyle.fill;
//       canvas.drawRRect(innerRect, paint);
//
//       // Text with strong contrast
//       final displayText = text.length > 12 ? '${text.substring(0, 12)}...' : text;
//       final textPainter = TextPainter(
//         text: TextSpan(
//           text: displayText,
//           style: TextStyle(
//             fontSize: fontSize * 0.9,
//             fontWeight: FontWeight.w700,
//             color: Colors.white,
//             shadows: [
//               Shadow(
//                 color: Colors.black,
//                 offset: Offset(1, 1),
//                 blurRadius: 2,
//               ),
//             ],
//           ),
//         ),
//         textDirection: TextDirection.ltr,
//         maxLines: 1,
//         textAlign: TextAlign.center,
//       );
//       textPainter.layout(maxWidth: width - 16);
//
//       final textOffset = Offset(
//         (width - textPainter.width) / 2,
//         (height - textPainter.height) / 2,
//       );
//       textPainter.paint(canvas, textOffset);
//     }
//
//     final picture = recorder.endRecording();
//     final img = await picture.toImage(
//       isCluster ? size.toInt() : (size * 2.5).toInt(),
//       isCluster ? size.toInt() : (size * 0.8).toInt(),
//     );
//     final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//     return byteData!.buffer.asUint8List();
//   }
//
//   // Better clustering - always show clusters even at low zoom
//   List<ClusterItem> _clusterBuildings() {
//     if (_currentZoom >= 17) {
//       // Very high zoom - no clustering
//       return _buildings.map((b) => ClusterItem(
//         building: b,
//         point: Point(latitude: b.latitude, longitude: b.longitude),
//         isCluster: false,
//       )).toList();
//     }
//
//     List<ClusterItem> clusters = [];
//     List<Building> processed = [];
//
//     // Better cluster radius calculation
//     double clusterRadius;
//     if (_currentZoom <= 11) {
//       clusterRadius = 0.025;
//     } else if (_currentZoom <= 12) {
//       clusterRadius = 0.020;
//     } else if (_currentZoom <= 13) {
//       clusterRadius = 0.015;
//     } else if (_currentZoom <= 14) {
//       clusterRadius = 0.010;
//     } else if (_currentZoom <= 15) {
//       clusterRadius = 0.008;
//     } else if (_currentZoom <= 16) {
//       clusterRadius = 0.005;
//     } else {
//       clusterRadius = 0.003;
//     }
//
//     for (final building in _buildings) {
//       if (processed.contains(building)) continue;
//
//       List<Building> nearbyBuildings = [building];
//       processed.add(building);
//
//       for (final other in _buildings) {
//         if (processed.contains(other)) continue;
//
//         final distance = _calculateDistance(
//           building.latitude, building.longitude,
//           other.latitude, other.longitude,
//         );
//
//         if (distance < clusterRadius) {
//           nearbyBuildings.add(other);
//           processed.add(other);
//         }
//       }
//
//       if (nearbyBuildings.length > 1) {
//         // Create cluster
//         final centerLat = nearbyBuildings.map((b) => b.latitude).reduce((a, b) => a + b) / nearbyBuildings.length;
//         final centerLng = nearbyBuildings.map((b) => b.longitude).reduce((a, b) => a + b) / nearbyBuildings.length;
//
//         clusters.add(ClusterItem(
//           buildings: nearbyBuildings,
//           point: Point(latitude: centerLat, longitude: centerLng),
//           isCluster: true,
//         ));
//       } else {
//         clusters.add(ClusterItem(
//           building: building,
//           point: Point(latitude: building.latitude, longitude: building.longitude),
//           isCluster: false,
//         ));
//       }
//     }
//
//     return clusters;
//   }
//
//   double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
//     final double dLat = lat1 - lat2;
//     final double dLng = lng1 - lng2;
//     return (dLat * dLat + dLng * dLng);
//   }
//
//   Future<PlacemarkIcon> _buildIcon(ClusterItem item) async {
//     if (item.isCluster) {
//       final imageData = await _createMarkerIcon('', isCluster: true, count: item.buildings!.length);
//       return PlacemarkIcon.single(
//         PlacemarkIconStyle(
//           image: BitmapDescriptor.fromBytes(imageData),
//           scale: 1.0,
//           anchor: Offset(0.5, 0.5),
//           zIndex: 1000.0, // Higher z-index for better visibility
//         ),
//       );
//     } else {
//       final building = item.building!;
//       final imageData = await _createMarkerIcon(building.uniqueName);
//       return PlacemarkIcon.single(
//         PlacemarkIconStyle(
//           image: BitmapDescriptor.fromBytes(imageData),
//           scale: 1.0,
//           anchor: Offset(0.5, 0.5),
//           zIndex: 500.0, // Lower z-index than clusters
//         ),
//       );
//     }
//   }
//
//   void _onMarkerTap(ClusterItem item) {
//     if (item.isCluster) {
//       // Zoom in on cluster
//       _mapController.moveCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(
//             target: item.point,
//             zoom: _currentZoom + 2.0,
//           ),
//         ),
//         animation: MapAnimation(
//           type: MapAnimationType.smooth,
//           duration: 0.5,
//         ),
//       );
//     } else {
//       // Navigate to building detail
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => BuildingDetailScreen(building: item.building!),
//         ),
//       );
//     }
//   }
//
//   void _onMapLongPress(Point point) {
//     if (_isWithinBounds(point)) {
//       HapticFeedback.mediumImpact();
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => AddBuildingScreen(
//             latitude: point.latitude,
//             longitude: point.longitude,
//           ),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Бу жой хаританинг рухсат этилган чегарасидан ташқарида'),
//           backgroundColor: Colors.orange,
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   }
//
//   bool _isWithinBounds(Point point) {
//     return point.latitude >= _minLat &&
//         point.latitude <= _maxLat &&
//         point.longitude >= _minLng &&
//         point.longitude <= _maxLng;
//   }
//
//   void _onMapCreated(YandexMapController controller) {
//     _mapController = controller;
//     _isMapReady = true;
//
//     _mapController.moveCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(target: _center, zoom: 14.0),
//       ),
//       animation: MapAnimation(
//         type: MapAnimationType.smooth,
//         duration: 1.0,
//       ),
//     );
//
//     if (_buildings.isNotEmpty) {
//       _updateMapView();
//     }
//   }
//
//   void _onCameraPositionChanged(CameraPosition position, CameraUpdateReason reason, bool finished) {
//     if (finished) {
//       setState(() {
//         _currentZoom = position.zoom;
//       });
//     }
//
//     // Boundary enforcement
//     if (!_isWithinBounds(position.target) || position.zoom < _minZoom || position.zoom > _maxZoom) {
//       final targetZoom = position.zoom < _minZoom ? _minZoom :
//       position.zoom > _maxZoom ? _maxZoom : position.zoom;
//
//       _mapController.moveCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(target: _center, zoom: targetZoom),
//         ),
//         animation: MapAnimation(
//           type: MapAnimationType.smooth,
//           duration: 0.3,
//         ),
//       );
//     }
//   }
//
//   Future<List<MapObject>> _getMarkerObjects() async {
//     final clusters = _clusterBuildings();
//     List<MapObject> markers = [];
//
//     for (final item in clusters) {
//       final icon = await _buildIcon(item);
//       markers.add(
//         PlacemarkMapObject(
//           mapId: MapObjectId(item.isCluster ? 'cluster_${item.hashCode}' : item.building!.id),
//           point: item.point,
//           icon: icon,
//           onTap: (_, __) => _onMarkerTap(item),
//         ),
//       );
//     }
//     return markers;
//   }
//
//   Widget _buildSearchBar() {
//     return Container(
//       margin: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(25),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Autocomplete<Building>(
//         optionsBuilder: (value) {
//           if (value.text.isEmpty) return const Iterable<Building>.empty();
//           return _buildings.where((b) =>
//           b.uniqueName.toLowerCase().contains(value.text.toLowerCase()) ||
//               (b.verificationPerson?.toLowerCase().contains(value.text.toLowerCase()) ?? false)
//           );
//         },
//         displayStringForOption: (b) => b.uniqueName,
//         fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
//           return TextField(
//             controller: controller,
//             focusNode: focusNode,
//             decoration: InputDecoration(
//               hintText: 'Юник номи бўйича қидиринг...',
//               prefixIcon: Icon(Icons.search, color: Color(0xFF2196F3)),
//               suffixIcon: controller.text.isNotEmpty
//                   ? IconButton(
//                 icon: Icon(Icons.clear),
//                 onPressed: () {
//                   controller.clear();
//                   focusNode.unfocus();
//                 },
//               )
//                   : null,
//               border: InputBorder.none,
//               contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//             ),
//           );
//         },
//         optionsViewBuilder: (context, onSelected, options) {
//           return Material(
//             elevation: 8.0,
//             borderRadius: BorderRadius.circular(15),
//             child: Container(
//               constraints: BoxConstraints(maxHeight: 300),
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: options.length,
//                 itemBuilder: (context, index) {
//                   final building = options.elementAt(index);
//                   return ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: Color(0xFF2196F3),
//                       child: Icon(Icons.location_city, color: Colors.white),
//                     ),
//                     title: Text(
//                       building.uniqueName,
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF1976D2),
//                       ),
//                     ),
//                     subtitle: Text(
//                       building.verificationPerson ?? 'Текширувчи кўрсатилмаган',
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                     trailing: Container(
//                       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: _getStatusColor(building.status),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         _statusToText(building.status),
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                     onTap: () {
//                       onSelected(building);
//                       _mapController.moveCamera(
//                         CameraUpdate.newCameraPosition(
//                           CameraPosition(
//                             target: Point(latitude: building.latitude, longitude: building.longitude),
//                             zoom: 17,
//                           ),
//                         ),
//                         animation: MapAnimation(
//                           type: MapAnimationType.smooth,
//                           duration: 1.0,
//                         ),
//                       );
//
//                       Future.delayed(Duration(milliseconds: 500), () {
//                         _onMarkerTap(ClusterItem(
//                           building: building,
//                           point: Point(latitude: building.latitude, longitude: building.longitude),
//                           isCluster: false,
//                         ));
//                       });
//                     },
//                   );
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Color _getStatusColor(BuildingStatus status) {
//     switch (status) {
//       case BuildingStatus.notStarted:
//         return Colors.grey;
//       case BuildingStatus.inProgress:
//         return Colors.orange;
//       case BuildingStatus.finished:
//         return Colors.green;
//     }
//   }
//
//   String _statusToText(BuildingStatus status) {
//     switch (status) {
//       case BuildingStatus.notStarted:
//         return 'Бошланмаган';
//       case BuildingStatus.inProgress:
//         return 'Жараёнда';
//       case BuildingStatus.finished:
//         return 'Тугалланган';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Map
//           _isLoading
//               ? Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
//                 ),
//                 SizedBox(height: 16),
//                 Text(
//                   'Биноларни юкланяпти...',
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 16,
//                   ),
//                 ),
//               ],
//             ),
//           )
//               : FutureBuilder<List<MapObject>>(
//             future: _getMarkerObjects(),
//             builder: (context, snapshot) {
//               if (!snapshot.hasData) {
//                 return Center(
//                   child: CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
//                   ),
//                 );
//               }
//               return YandexMap(
//                 onMapCreated: _onMapCreated,
//                 onMapLongTap: _onMapLongPress,
//                 onCameraPositionChanged: _onCameraPositionChanged,
//                 mapObjects: snapshot.data!,
//                 nightModeEnabled: false,
//                 rotateGesturesEnabled: true,
//                 scrollGesturesEnabled: true,
//                 tiltGesturesEnabled: true,
//                 zoomGesturesEnabled: true,
//               );
//             },
//           ),
//
//           // Search bar overlay
//           SafeArea(
//             child: Column(
//               children: [
//                 _buildSearchBar(),
//               ],
//             ),
//           ),
//
//           // Floating action button
//           Positioned(
//             bottom: 30,
//             right: 20,
//             child: FloatingActionButton(
//               onPressed: () {
//                 _mapController.moveCamera(
//                   CameraUpdate.newCameraPosition(
//                     CameraPosition(target: _center, zoom: 14.0),
//                   ),
//                   animation: MapAnimation(
//                     type: MapAnimationType.smooth,
//                     duration: 1.0,
//                   ),
//                 );
//               },
//               backgroundColor: Color(0xFF2196F3),
//               child: Icon(Icons.my_location, color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Helper class for clustering
// class ClusterItem {
//   final Building? building;
//   final List<Building>? buildings;
//   final Point point;
//   final bool isCluster;
//
//   ClusterItem({
//     this.building,
//     this.buildings,
//     required this.point,
//     required this.isCluster,
//   });
// }
//


/// ------------------

// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:latlong2/latlong.dart';
// import '../models/building.dart';
// import '../services/firebase_service.dart';
// import 'add_building_screen.dart';
// import 'building_detail_screen.dart';
//
// class MapScreen extends StatefulWidget {
//   @override
//   State<MapScreen> createState() => _MapScreenState();
// }
//
// class _MapScreenState extends State<MapScreen> {
//   final MapController _mapController = MapController();
//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _searchFocusNode = FocusNode();
//
//   List<Building> _buildings = [];
//   List<Building> _searchResults = [];
//   LatLng _center = LatLng(40.495, 68.787); // Guliston
//   LatLng? _currentLocation;
//   bool _showSearchResults = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadBuildings();
//     _getCurrentLocation();
//     _searchFocusNode.addListener(() {
//       setState(() => _showSearchResults = _searchFocusNode.hasFocus);
//     });
//   }
//
//   void _loadBuildings() {
//     FirebaseService.getBuildings().listen((buildings) {
//       setState(() => _buildings = buildings);
//     });
//   }
//
//   void _getCurrentLocation() async {
//     if (!await Geolocator.isLocationServiceEnabled()) return;
//     final permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied) return;
//     final position = await Geolocator.getCurrentPosition();
//     setState(() => _currentLocation = LatLng(position.latitude, position.longitude));
//   }
//
//   void _onSearchChanged(String value) {
//     final query = value.toLowerCase();
//     setState(() {
//       _searchResults = _buildings.where((b) =>
//       b.uniqueName.toLowerCase().contains(query) ||
//           (b.verificationPerson?.toLowerCase().contains(query) ?? false)
//       ).toList();
//       _showSearchResults = query.isNotEmpty;
//     });
//   }
//
//   void _onBuildingTap(Building building) {
//     _mapController.move(LatLng(building.latitude, building.longitude), 17);
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => BuildingDetailScreen(building: building)),
//     );
//   }
//
//   List<Marker> _buildMarkers() {
//     return _buildings.map((building) => Marker(
//       point: LatLng(building.latitude, building.longitude),
//       width: 180,
//       height: 60,
//       child: GestureDetector(
//         onTap: () => _onBuildingTap(building),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Dumaloq rasm yoki default icon
//             Container(
//               width: 50,
//               height: 50,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: _getStatusColor(building.status),
//                   width: 3,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black26,
//                     blurRadius: 4,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(25),
//                 child: _buildDefaultIcon(building.status),
//               ),
//             ),
//             SizedBox(width: 8),
//             // Unique name
//             Flexible(
//               child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(
//                     color: _getStatusColor(building.status),
//                     width: 2,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black26,
//                       blurRadius: 4,
//                       offset: Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Text(
//                   building.uniqueName,
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: _getStatusColor(building.status),
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                   maxLines: 1,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     )).toList();
//   }
//
//   Widget _buildDefaultIcon(BuildingStatus status) {
//     IconData iconData;
//     switch (status) {
//       case BuildingStatus.notStarted:
//         iconData = Icons.construction;
//         break;
//       case BuildingStatus.inProgress:
//         iconData = Icons.build;
//         break;
//       case BuildingStatus.finished:
//         iconData = Icons.check_circle;
//         break;
//     }
//
//     return Container(
//       width: 50,
//       height: 50,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: _getStatusColor(status).withOpacity(0.1),
//       ),
//       child: Icon(
//         iconData,
//         color: _getStatusColor(status),
//         size: 24,
//       ),
//     );
//   }
//
//   Color _getStatusColor(BuildingStatus status) {
//     switch (status) {
//       case BuildingStatus.notStarted:
//         return Colors.grey;
//       case BuildingStatus.inProgress:
//         return Colors.orange;
//       case BuildingStatus.finished:
//         return Colors.green;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               initialCenter: _center,
//               initialZoom: 14,
//               onLongPress: (tapPosition, point) {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => AddBuildingScreen(
//                       latitude: point.latitude,
//                       longitude: point.longitude,
//                     ),
//                   ),
//                 );
//               },
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate: "https://{s}.tile.openstreetmap.de/tiles/osmde/{z}/{x}/{y}.png",
//                 subdomains: ['a', 'b', 'c'],
//                 userAgentPackageName: 'com.yourcompany.yourappname',
//               ),
//               if (_currentLocation != null)
//                 CircleLayer(
//                   circles: [
//                     CircleMarker(
//                       point: _currentLocation!,
//                       color: Colors.blue.withOpacity(0.5),
//                       borderStrokeWidth: 2,
//                       borderColor: Colors.blue,
//                       radius: 100,
//                     ),
//                   ],
//                 ),
//               MarkerClusterLayerWidget(
//                 options: MarkerClusterLayerOptions(
//                   maxClusterRadius: 60, // Clustering radiusini oshirdik
//                   size: Size(50, 50),
//                   markers: _buildMarkers(),
//                   builder: (context, markers) => Container(
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.blue,
//                       border: Border.all(color: Colors.white, width: 2),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black26,
//                           blurRadius: 4,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Center(
//                       child: Text(
//                         '${markers.length}',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           Positioned(
//             top: 40,
//             left: 16,
//             right: 16,
//             child: Column(
//               children: [
//                 Material(
//                   elevation: 4,
//                   borderRadius: BorderRadius.circular(12),
//                   child: TextField(
//                     controller: _searchController,
//                     focusNode: _searchFocusNode,
//                     onChanged: _onSearchChanged,
//                     decoration: InputDecoration(
//                       hintText: "Yunik nomi bilan qidiring...",
//                       prefixIcon: Icon(Icons.search),
//                       suffixIcon: _searchController.text.isNotEmpty
//                           ? IconButton(
//                         icon: Icon(Icons.clear),
//                         onPressed: () {
//                           _searchController.clear();
//                           _searchFocusNode.unfocus();
//                           setState(() => _showSearchResults = false);
//                         },
//                       )
//                           : null,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       filled: true,
//                       fillColor: Colors.white,
//                     ),
//                   ),
//                 ),
//                 if (_showSearchResults && _searchResults.isNotEmpty)
//                   Container(
//                     margin: EdgeInsets.only(top: 4),
//                     padding: EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
//                     ),
//                     child: ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: _searchResults.length,
//                       itemBuilder: (context, index) {
//                         final building = _searchResults[index];
//                         return ListTile(
//                           onTap: () => _onBuildingTap(building),
//                           title: Text(building.uniqueName),
//                           subtitle: Text(building.verificationPerson ?? 'Tekshiruvchi yo\'q'),
//                         );
//                       },
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

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
      _searchResults = _buildings.where((b) =>
      b.uniqueName.toLowerCase().contains(query) ||
          (b.verificationPerson?.toLowerCase().contains(query) ?? false)
      ).toList();
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
                  building.uniqueName,
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
      case BuildingStatus.finished:
        icon = Icons.check_circle_outline;
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
      case BuildingStatus.finished:
        return Colors.green;
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
          subtitle: Text('Tasdiqlovchi: ${building.verificationPerson ?? "yo\'q"}'),
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
                            hintText: "Yunik nomi bilan qidiring...",
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
                                      subtitle: Text(
                                        building.verificationPerson ?? "Tasdiqlovchi yo'q",
                                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
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
                    tooltip: 'Xaritani tekislash',
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
                    _buildStatusList("Boshlanmagan", BuildingStatus.notStarted, Colors.grey),
                    _buildStatusList("Jarayonda", BuildingStatus.inProgress, Colors.orange),
                    _buildStatusList("Tugallangan", BuildingStatus.finished, Colors.green),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
