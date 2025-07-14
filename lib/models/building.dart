import 'package:cloud_firestore/cloud_firestore.dart';

/// Qurilish holati
enum BuildingStatus {
  notStarted,   // Бошланмаган
  inProgress,   // Жараёнда
  finished,     // Тугалланган
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
  final List<String> images;
  final List<Map<String, String>> customData;
  final DateTime createdAt;

  Building({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.uniqueName,
    required this.regionName,
    this.verificationPerson,
    required this.status,
    this.kolodetsStatus,
    required this.images,
    required this.customData,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'uniqueName': uniqueName,
      'regionName': regionName,
      'verificationPerson': verificationPerson,
      'status': status.name,
      'kolodetsStatus': kolodetsStatus,
      'images': images,
      'customData': customData,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Building.fromMap(Map<String, dynamic> map) {
    return Building(
      id: map['id'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      uniqueName: map['uniqueName'] ?? '',
      regionName: map['regionName'] ?? '',
      verificationPerson: map['verificationPerson'],
      status: _parseStatus(map['status']),
      kolodetsStatus: map['kolodetsStatus'],
      images: List<String>.from(map['images'] ?? []),
      customData: List<Map<String, String>>.from(
        map['customData']?.map((e) => Map<String, String>.from(e)) ?? [],
      ),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  factory Building.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Building.fromMap(data);
  }

  static BuildingStatus _parseStatus(String? status) {
    switch (status) {
      case 'inProgress':
        return BuildingStatus.inProgress;
      case 'finished':
        return BuildingStatus.finished;
      case 'notStarted':
      default:
        return BuildingStatus.notStarted;
    }
  }
}
