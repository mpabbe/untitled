import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/material_item.dart';

class MaterialService {
  static final MaterialService _instance = MaterialService._internal();
  factory MaterialService() => _instance;
  MaterialService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection names
  static const String _materialsCollection = 'materials';
  static const String _buildersCollection = 'builders';
  static const String _verifiersCollection = 'verifiers'; // Bu collection Firestore'da mavjudmi?
  
  // Cache variables
  List<MaterialItem>? _cachedMaterials;
  List<String>? _cachedBuilders;
  List<String>? _cachedVerifiers;
  DateTime? _lastMaterialsFetch;
  DateTime? _lastBuildersFetch;
  DateTime? _lastVerifiersFetch;
  
  // Cache expiry duration
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

  // Get all verifiers with caching
  Future<List<String>> getVerifiers({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    // Return cached data if available and not expired
    if (!forceRefresh && 
        _cachedVerifiers != null && 
        _lastVerifiersFetch != null &&
        now.difference(_lastVerifiersFetch!) < _cacheExpiry) {
      print('Returning cached verifiers: $_cachedVerifiers'); // Debug
      return _cachedVerifiers!;
    }

    try {
      print('Fetching verifiers from Firestore...'); // Debug
      final snapshot = await _firestore
          .collection(_verifiersCollection)
          .orderBy('name')
          .get();

      print('Firestore snapshot docs count: ${snapshot.docs.length}'); // Debug

      final verifiers = snapshot.docs
          .map((doc) {
            final data = doc.data();
            print('Verifier doc data: $data'); // Debug
            return data['name'] as String;
          })
          .toList();

      print('Processed verifiers: $verifiers'); // Debug

      // Update cache
      _cachedVerifiers = verifiers;
      _lastVerifiersFetch = now;

      return verifiers;
    } catch (e) {
      print('Error in getVerifiers: $e'); // Debug
      // Return cached data if available, otherwise default list
      final fallbackVerifiers = _cachedVerifiers ?? [
        'Мансур ака',
        'Нурназар Равшанов', 
        'Кобил ака',
      ];
      print('Returning fallback verifiers: $fallbackVerifiers'); // Debug
      return fallbackVerifiers;
    }
  }

  // Add new verifier
  Future<void> addVerifier(String verifierName) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      print('Adding verifier with ID: $id, Name: $verifierName'); // Debug
      
      final docData = {
        'name': verifierName.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      print('Document data: $docData'); // Debug
      
      await _firestore
          .collection(_verifiersCollection)
          .doc(id)
          .set(docData);
      
      print('Verifier added to Firestore successfully'); // Debug
      
      // Clear cache to force refresh
      _cachedVerifiers = null;
      _lastVerifiersFetch = null;
      print('Cache cleared'); // Debug
    } catch (e) {
      print('Error in addVerifier: $e'); // Debug
      throw Exception('Failed to add verifier: $e');
    }
  }

  // Check if verifier exists
  Future<bool> verifierExists(String name) async {
    try {
      print('Checking if verifier exists: $name'); // Debug
      final snapshot = await _firestore
          .collection(_verifiersCollection)
          .where('name', isEqualTo: name.trim())
          .limit(1)
          .get();

      final exists = snapshot.docs.isNotEmpty;
      print('Verifier exists result: $exists, docs count: ${snapshot.docs.length}'); // Debug
      return exists;
    } catch (e) {
      print('Error in verifierExists: $e'); // Debug
      return false;
    }
  }

  // Clear all caches
  static void clearCache() {
    // _cachedMaterials = null;
    // _cachedBuilders = null;
    // _lastMaterialsFetch = null;
    // _lastBuildersFetch = null;
  }
}







