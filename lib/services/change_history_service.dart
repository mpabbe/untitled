import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ChangeHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> logMaterialChange({
    required String buildingId,
    required String materialId,
    required String materialName,
    required String fieldName,
    required String oldValue,
    required String newValue,
  }) async {
    try {
      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .collection('change_history')
          .add({
        'materialId': materialId,
        'materialName': materialName,
        'fieldName': fieldName,
        'oldValue': oldValue,
        'newValue': newValue,
        'changedBy': AuthService.currentVerifierName ?? 'Admin',
        'changedAt': DateTime.now().toIso8601String(),
        'userType': AuthService.currentUserType,
      });
    } catch (e) {
      print('Error logging change: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> getChangeHistory(String buildingId) {
    return _firestore
        .collection('buildings')
        .doc(buildingId)
        .collection('change_history')
        .orderBy('changedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }
}