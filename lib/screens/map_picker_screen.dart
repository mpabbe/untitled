import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const MapPickerScreen({
    Key? key,
    required this.initialLatitude,
    required this.initialLongitude,
  }) : super(key: key);

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late MapController _mapController;
  late LatLng _pickedPoint;

  @override
  void initState() {
    super.initState();
    _pickedPoint = LatLng(widget.initialLatitude, widget.initialLongitude);
    _mapController = MapController();
  }

  void _onMapMove(MapEvent event) {
    setState(() {
      _pickedPoint = _mapController.camera.center;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'lat': _pickedPoint.latitude,
                'lng': _pickedPoint.longitude,
              });
            },
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(initialCenter: LatLng(41.3, 69.2), initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      const LatLng(41.3111, 69.2797),
                      const LatLng(41.3120, 69.2805),
                      const LatLng(41.3130, 69.2815),
                    ],
                    color: Colors.red,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
            ],
          ),
          const Center(
            child: Icon(Icons.place, size: 40, color: Colors.red),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Latitude: ${_pickedPoint.latitude.toStringAsFixed(6)}'),
                  Text('Longitude: ${_pickedPoint.longitude.toStringAsFixed(6)}'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
