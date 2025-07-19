import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import '../models/building.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // static final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _buildingsCollection = 'buildings';
  static const String _imagesCollection = 'uploaded_images'; // Yangi collection

  // Rasm URL'ni Firebase'ga saqlash
  static Future<void> saveImageUrl(String imageUrl, {
    String? originalFileName,
    int? fileSize,
    String? uploadService,
  }) async {
    try {
      final imageDoc = {
        'url': imageUrl,
        'originalFileName': originalFileName,
        'fileSize': fileSize,
        'uploadService': uploadService,
        'uploadedAt': DateTime.now().toIso8601String(),
        'usageCount': 1,
      };

      // URL'ni ID sifatida ishlatish (hash)
      final imageId = imageUrl.hashCode.abs().toString();
      
      await _firestore
          .collection(_imagesCollection)
          .doc(imageId)
          .set(imageDoc, SetOptions(merge: true));
          
      print('Image URL saved to Firebase: $imageUrl');
    } catch (e) {
      print('Error saving image URL: $e');
    }
  }

  // Barcha saqlangan rasmlarni olish
  static Future<List<Map<String, dynamic>>> getSavedImages() async {
    try {
      final snapshot = await _firestore
          .collection(_imagesCollection)
          .orderBy('uploadedAt', descending: true)
          .limit(50) // Oxirgi 50 ta rasm
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting saved images: $e');
      return [];
    }
  }

  // Rasm ishlatilganini belgilash
  static Future<void> incrementImageUsage(String imageUrl) async {
    try {
      final imageId = imageUrl.hashCode.abs().toString();
      
      await _firestore
          .collection(_imagesCollection)
          .doc(imageId)
          .update({
        'usageCount': FieldValue.increment(1),
        'lastUsedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error incrementing image usage: $e');
    }
  }

  // Save building to Firestore
  static Future<void> saveBuilding(Building building) async {
    try {
      // Building saqlash
      await _firestore
          .collection(_buildingsCollection)
          .doc(building.id)
          .set(building.toJson());
          
      // Rasmlar usage count'ini oshirish
      for (final imageUrl in building.images) {
        await incrementImageUsage(imageUrl);
      }
    } catch (e) {
      throw Exception('Failed to save building: $e');
    }
  }

  // Get all buildings from Firestore
  static Stream<List<Building>> getBuildings() {
    return _firestore
        .collection(_buildingsCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Building.fromDocumentSnapshot(doc))
        .toList());
  }

  // Upload image to Firebase Storage
  // static Future<String> uploadImage(File imageFile, String buildingId) async {
  //   try {
  //     // final ref = _storage.ref().child('building_images/$buildingId.jpg');
  //     final uploadTask = ref.putFile(imageFile);
  //     final snapshot = await uploadTask.whenComplete(() {});
  //     final downloadUrl = await snapshot.ref.getDownloadURL();
  //     return downloadUrl;
  //   } catch (e) {
  //     throw Exception('Failed to upload image: $e');
  //   }
  // }

  // Building'ni o'chirish
  static Future<void> deleteBuilding(String buildingId) async {
    try {
      await _firestore.collection(_buildingsCollection).doc(buildingId).delete();
    } catch (e) {
      throw Exception('Failed to delete building: $e');
    }
  }

  // Get building by ID
  static Future<Building?> getBuildingById(String buildingId) async {
    try {
      final doc = await _firestore
          .collection(_buildingsCollection)
          .doc(buildingId)
          .get();

      if (doc.exists) {
        return Building.fromDocumentSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get building: $e');
    }
  }

  // Verifier management methods
  static Future<List<Map<String, dynamic>>> getAllVerifiers() async {
    try {
      final snapshot = await _firestore
          .collection('verifiers')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Null safety for isActive field
        if (data['isActive'] == null) {
          data['isActive'] = true;
        }
        
        // Null safety for other fields
        data['name'] = data['name'] ?? 'Номсиз';
        data['key'] = data['key'] ?? '';
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get verifiers: $e');
    }
  }

  static Future<void> addVerifier(String name, String key) async {
    try {
      // Check if key already exists
      final existingSnapshot = await _firestore
          .collection('verifiers')
          .where('key', isEqualTo: key)
          .limit(1)
          .get();

      if (existingSnapshot.docs.isNotEmpty) {
        throw Exception('Бу калит аллақачон мавжуд');
      }

      await _firestore.collection('verifiers').add({
        'name': name,
        'key': key,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add verifier: $e');
    }
  }

  static Future<void> updateVerifier(String oldKey, String newName, String newKey) async {
    try {
      // Find document by old key
      final snapshot = await _firestore
          .collection('verifiers')
          .where('key', isEqualTo: oldKey)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Тасдиқловчи топилмади');
      }

      // Check if new key already exists (if changed)
      if (oldKey != newKey) {
        final existingSnapshot = await _firestore
            .collection('verifiers')
            .where('key', isEqualTo: newKey)
            .limit(1)
            .get();

        if (existingSnapshot.docs.isNotEmpty) {
          throw Exception('Бу калит аллақачон мавжуд');
        }
      }

      final docId = snapshot.docs.first.id;
      await _firestore.collection('verifiers').doc(docId).update({
        'name': newName,
        'key': newKey,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update verifier: $e');
    }
  }

  static Future<void> updateVerifierStatus(String key, bool isActive) async {
    try {
      final snapshot = await _firestore
          .collection('verifiers')
          .where('key', isEqualTo: key)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Тасдиқловчи топилмади');
      }

      final docId = snapshot.docs.first.id;
      await _firestore.collection('verifiers').doc(docId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update verifier status: $e');
    }
  }

  static Future<void> deleteVerifier(String key) async {
    try {
      final snapshot = await _firestore
          .collection('verifiers')
          .where('key', isEqualTo: key)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Тасдиқловчи топилмади');
      }

      final docId = snapshot.docs.first.id;
      await _firestore.collection('verifiers').doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete verifier: $e');
    }
  }

  // Update building method (if not exists)
  static Future<void> updateBuilding(Building building) async {
    try {
      await _firestore
          .collection(_buildingsCollection)
          .doc(building.id)
          .update(building.toJson());
    } catch (e) {
      throw Exception('Failed to update building: $e');
    }
  }
}
