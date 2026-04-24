import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Get Business Details
  Future<Map<String, dynamic>?> getBusinessDetails(String businessId) async {
    DocumentSnapshot doc = await _firestore
        .collection('businesses')
        .doc(businessId)
        .get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  // 2. Search Public Directory (by GSTIN or Mobile)
  Future<Map<String, dynamic>?> searchPublicDirectory(String query) async {
    // query could be GSTIN or Mobile/Email link
    DocumentSnapshot doc = await _firestore
        .collection('public_directory')
        .doc(query)
        .get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  // 3. Update Business Settings
  Future<void> updateBusinessSettings(
    String businessId,
    Map<String, dynamic> settings,
  ) async {
    await _firestore.collection('businesses').doc(businessId).update({
      'settings': settings,
    });
  }

  // Note: Staff management removed per user request to drop RBAC.
  // One business = One user flow.
}
