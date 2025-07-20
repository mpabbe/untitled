import 'package:flutter/material.dart';
import 'dart:io';
import '../models/building.dart';

class UserBuildingDetailScreen extends StatelessWidget {
  final Building building;

  const UserBuildingDetailScreen({Key? key, required this.building}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(building.uniqueName ?? 'Бино тафсилотлари'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            SizedBox(height: 16),
            if (building.schemeUrl != null && building.schemeUrl!.isNotEmpty)
              _buildSchemeSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Асосий маълумотлар', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _buildInfoRow('Номи', building.uniqueName ?? 'Номсиз'),
            _buildInfoRow('Ҳудуд', building.regionName),
            _buildInfoRow('Статус', _getStatusText(building.status)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSchemeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Схема', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _buildImageWidget(building.schemeUrl!,context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl,BuildContext context) {
    if (imageUrl.startsWith('C:') || imageUrl.startsWith('/') || imageUrl.contains('\\')) {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return GestureDetector(
          onTap: () => _showFullScreenImage(context,imageUrl, isFile: true),
          child: Image.file(file, fit: BoxFit.contain),
        );
      }
    }
    
    return GestureDetector(
      onTap: () => _showFullScreenImage(context,imageUrl, isFile: false),
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey.shade200,
            child: Center(child: Text('Расм юкланмади')),
          );
        },
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl, {required bool isFile}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              'Схема',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: isFile
                  ? Image.file(
                      File(imageUrl),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.error, color: Colors.white, size: 64);
                      },
                    )
                  : Image.network(
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
  }

  String _getStatusText(BuildingStatus status) {
    switch (status) {
      case BuildingStatus.notStarted: return 'Бошланмаган';
      case BuildingStatus.inProgress: return 'Жараёнда';
      case BuildingStatus.completed: return 'Тугалланган';
      default: return 'Номаълум';
    }
  }
}
