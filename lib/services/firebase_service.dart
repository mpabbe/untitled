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
}
