import 'package:cloud_firestore/cloud_firestore.dart';

/// Qurilish holati
enum BuildingStatus {
  notStarted,   // Бошланмаган
  inProgress,   // Жараёнда 
  completed,    // Тугалланган
  paused        // Тўхтатилган
}

/// Material status
enum MaterialStatus { 
  complete,   // Тўлиқ
  shortage,   // Камчилик
  critical    // Критик
}

/// Bino model
class Building {
  final String id;
  final double latitude;
  final double longitude;
  final String uniqueName;
  final String regionName;
  final String? verificationPerson;
  final BuildingStatus status;
  final String? kolodetsStatus;
  final String? builder;
  final String? schemeUrl;
  final DateTime createdAt;
  final List<String> images;
  final List<Map<String, String>> customData; // Keep for backward compatibility
  final List<Map<String, dynamic>> availableMaterials;
  final List<Map<String, dynamic>> requiredMaterials;
  final MaterialStatus materialStatus;

  Building({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.uniqueName,
    required this.regionName,
    this.verificationPerson,
    required this.status,
    this.kolodetsStatus,
    this.builder,
    this.schemeUrl,
    required this.createdAt,
    required this.images,
    required this.customData,
    required this.availableMaterials,
    required this.requiredMaterials,
    required this.materialStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'uniqueName': uniqueName,
      'regionName': regionName,
      'verificationPerson': verificationPerson,
      'status': status.index,
      'kolodetsStatus': kolodetsStatus,
      'builder': builder,
      'schemeUrl': schemeUrl,
      'createdAt': createdAt.toIso8601String(),
      'images': images,
      'customData': customData,
      'availableMaterials': availableMaterials,
      'requiredMaterials': requiredMaterials,
      'materialStatus': materialStatus.index,
    };
  }

  factory Building.fromMap(Map<String, dynamic> map) {
    return Building(
      id: map['id'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      uniqueName: map['uniqueName'] ?? '',
      regionName: map['regionName'] ?? '',
      verificationPerson: map['verificationPerson'],
      status: BuildingStatus.values[map['status'] ?? 0],
      kolodetsStatus: map['kolodetsStatus'],
      builder: map['builder'],
      schemeUrl: map['schemeUrl'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      images: List<String>.from(map['images'] ?? []),
      customData: List<Map<String, String>>.from(
        (map['customData'] ?? []).map((item) => Map<String, String>.from(item)),
      ),
      availableMaterials: List<Map<String, dynamic>>.from(
        (map['availableMaterials'] ?? []).map((item) => Map<String, dynamic>.from(item)),
      ),
      requiredMaterials: List<Map<String, dynamic>>.from(
        (map['requiredMaterials'] ?? []).map((item) => Map<String, dynamic>.from(item)),
      ),
      materialStatus: MaterialStatus.values[map['materialStatus'] ?? 0],
    );
  }

  factory Building.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Building.fromMap({...data, 'id': doc.id});
  }

  @override
  String toString() {
    return 'Building(id: $id, uniqueName: $uniqueName, status: $status)';
  }
}
