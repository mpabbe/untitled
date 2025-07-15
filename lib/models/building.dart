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
  final List<String>? builders; // String? builder o'rniga List<String>? builders
  final String? schemeUrl;
  final String? comment;
  final DateTime createdAt;
  final List<String> images;
  final Map<String, dynamic>? customData;
  final MaterialStatus? materialStatus;
  final List<Map<String, dynamic>> availableMaterials;
  final List<Map<String, dynamic>> requiredMaterials;

  Building({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.uniqueName,
    required this.regionName,
    this.verificationPerson,
    required this.status,
    this.kolodetsStatus,
    this.builders, // builder o'rniga builders
    this.schemeUrl,
    this.comment,
    required this.createdAt,
    this.images = const [],
    this.customData,
    this.materialStatus,
    this.availableMaterials = const [],
    this.requiredMaterials = const [],
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      uniqueName: json['uniqueName'] ?? '',
      regionName: json['regionName'] ?? '',
      verificationPerson: json['verificationPerson'],
      status: BuildingStatus.values.firstWhere(
        (e) => e.toString() == 'BuildingStatus.${json['status']}',
        orElse: () => BuildingStatus.notStarted,
      ),
      kolodetsStatus: json['kolodetsStatus'],
      builders: json['builders'] != null ? List<String>.from(json['builders']) : null,
      schemeUrl: json['schemeUrl'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      customData: json['customData'] is Map ? Map<String, dynamic>.from(json['customData']) : null,
      materialStatus: json['materialStatus'] != null
          ? MaterialStatus.values.firstWhere(
              (e) => e.toString() == 'MaterialStatus.${json['materialStatus']}',
              orElse: () => MaterialStatus.shortage,
            )
          : null,
      availableMaterials: json['availableMaterials'] != null
          ? List<Map<String, dynamic>>.from(json['availableMaterials'])
          : [],
      requiredMaterials: json['requiredMaterials'] != null
          ? List<Map<String, dynamic>>.from(json['requiredMaterials'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'uniqueName': uniqueName,
      'regionName': regionName,
      'verificationPerson': verificationPerson,
      'status': status.toString().split('.').last,
      'kolodetsStatus': kolodetsStatus,
      'builders': builders, // builder o'rniga builders
      'schemeUrl': schemeUrl,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'images': images,
      'customData': customData,
      'materialStatus': materialStatus?.toString().split('.').last,
      'availableMaterials': availableMaterials,
      'requiredMaterials': requiredMaterials,
    };
  }

  factory Building.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Building.fromJson({...data, 'id': doc.id});
  }

  @override
  String toString() {
    return 'Building(id: $id, uniqueName: $uniqueName, status: $status)';
  }
}
