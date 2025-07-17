class DetectedMaterial {
  String name;
  String size;
  int quantity;
  bool isMainComponent;
  String category;
  String unit;
  double confidence;
  List<String> notes;

  DetectedMaterial({
    required this.name,
    required this.size,
    required this.quantity,
    this.isMainComponent = false,
    this.category = 'other',
    this.unit = 'дона',
    this.confidence = 0.0,
    this.notes = const [],
  });

  String get description {
    final sizeText = size.isNotEmpty ? 'O\'lcham: $size' : '';
    final quantityText = 'Miqdor: $quantity $unit';
    final confidenceText = 'Ishonch: ${(confidence * 100).toStringAsFixed(1)}%';
    
    return [sizeText, quantityText, confidenceText]
        .where((text) => text.isNotEmpty)
        .join(' • ');
  }

  @override
  String toString() {
    return 'DetectedMaterial(name: $name, size: $size, quantity: $quantity, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}



