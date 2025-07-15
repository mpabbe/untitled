class MaterialItem {
  final String id;
  final String name;
  final String unit;
  final DateTime? createdAt;

  MaterialItem({
    required this.id,
    required this.name,
    required this.unit,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory MaterialItem.fromMap(Map<String, dynamic> map) {
    return MaterialItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      unit: map['unit'] ?? 'дона',
      createdAt: map['createdAt'] != null 
          ? DateTime.tryParse(map['createdAt']) 
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MaterialItem(id: $id, name: $name, unit: $unit)';
  }
}

class BuildingMaterial {
  final String materialId;
  final String materialName;
  final double quantity;
  final String size;
  final String unit;

  BuildingMaterial({
    required this.materialId,
    required this.materialName,
    required this.quantity,
    required this.size,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'materialName': materialName,
      'quantity': quantity,
      'size': size,
      'unit': unit,
    };
  }

  factory BuildingMaterial.fromMap(Map<String, dynamic> map) {
    return BuildingMaterial(
      materialId: map['materialId'] ?? '',
      materialName: map['materialName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      size: map['size'] ?? '',
      unit: map['unit'] ?? '',
    );
  }
}
