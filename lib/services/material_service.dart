import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/material_item.dart';

class MaterialService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _materialsCollection = 'materials';
  static const String _buildersCollection = 'builders';

  // Cache for materials to avoid frequent Firebase calls
  static List<MaterialItem>? _cachedMaterials;
  static List<String>? _cachedBuilders;
  static DateTime? _lastMaterialsFetch;
  static DateTime? _lastBuildersFetch;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Get all materials with caching
  Future<List<MaterialItem>> getMaterials({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    // Return cached data if available and not expired
    if (!forceRefresh && 
        _cachedMaterials != null && 
        _lastMaterialsFetch != null &&
        now.difference(_lastMaterialsFetch!) < _cacheExpiry) {
      return _cachedMaterials!;
    }

    try {
      final snapshot = await _firestore
          .collection(_materialsCollection)
          .orderBy('name')
          .get();

      final materials = snapshot.docs
          .map((doc) => MaterialItem.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Update cache
      _cachedMaterials = materials;
      _lastMaterialsFetch = now;

      return materials;
    } catch (e) {
      // Return cached data if available, otherwise empty list
      return _cachedMaterials ?? [];
    }
  }

  // Get all builders with caching
  Future<List<String>> getBuilders({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    // Return cached data if available and not expired
    if (!forceRefresh && 
        _cachedBuilders != null && 
        _lastBuildersFetch != null &&
        now.difference(_lastBuildersFetch!) < _cacheExpiry) {
      return _cachedBuilders!;
    }

    try {
      final snapshot = await _firestore
          .collection(_buildersCollection)
          .orderBy('name')
          .get();

      final builders = snapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();

      // Update cache
      _cachedBuilders = builders;
      _lastBuildersFetch = now;

      return builders;
    } catch (e) {
      // Return cached data if available, otherwise default list
      return _cachedBuilders ?? [
        'ООО "Стройтех"',
        'ИП Каримов А.А.',
        'ООО "БилдКонструкт"',
        'ИП Рахимов Б.Р.',
      ];
    }
  }

  // Add new material
  Future<void> addMaterial(MaterialItem material) async {
    try {
      await _firestore
          .collection(_materialsCollection)
          .doc(material.id)
          .set(material.toMap());
      
      // Clear cache to force refresh
      _cachedMaterials = null;
      _lastMaterialsFetch = null;
    } catch (e) {
      throw Exception('Failed to add material: $e');
    }
  }

  // Check if material exists by name
  Future<bool> materialExists(String name) async {
    try {
      final snapshot = await _firestore
          .collection(_materialsCollection)
          .where('name', isEqualTo: name.trim())
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Add new builder
  Future<void> addBuilder(String builderName) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore
          .collection(_buildersCollection)
          .doc(id)
          .set({
        'name': builderName.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // Clear cache to force refresh
      _cachedBuilders = null;
      _lastBuildersFetch = null;
    } catch (e) {
      throw Exception('Failed to add builder: $e');
    }
  }

  // Check if builder exists
  Future<bool> builderExists(String name) async {
    try {
      final snapshot = await _firestore
          .collection(_buildersCollection)
          .where('name', isEqualTo: name.trim())
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Clear all caches
  static void clearCache() {
    _cachedMaterials = null;
    _cachedBuilders = null;
    _lastMaterialsFetch = null;
    _lastBuildersFetch = null;
  }
}

