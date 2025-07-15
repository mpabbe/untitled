import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import '../models/building.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // static final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _buildingsCollection = 'buildings';

  // Save building to Firestore
  static Future<void> saveBuilding(Building building) async {
    try {
      await _firestore
          .collection(_buildingsCollection)
          .doc(building.id)
          .set(building.toJson());
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

  // Delete building
  static Future<void> deleteBuilding(String buildingId) async {
    try {
      await _firestore
          .collection(_buildingsCollection)
          .doc(buildingId)
          .delete();
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