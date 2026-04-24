import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Check if profile exists
  Future<bool> checkProfileExists() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.exists;
  }

  // 2. Save User Profile (Detailed for GST 2.0)
  Future<void> saveUserProfile({
    required String fullName,
    required String legalBusinessName,
    required String flatShopNo,
    required String area,
    required String city,
    required String pincode,
    String gstin = '',
    String businessStateCode = '',
    String pan = '',
    String bankAccountNo = '',
    String bankIfsc = '',
    String userImageUrl = '',
    String signatureImageUrl = '',
    String role = 'admin',
    String businessId = '',
    String phoneNumber = '',
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Generate businessId if not provided (for new Owners)
    String effectiveBusinessId = businessId;
    if (effectiveBusinessId.isEmpty && role == 'admin') {
      effectiveBusinessId = 'B-${DateTime.now().millisecondsSinceEpoch}';
    }

    UserModel userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      fullName: fullName,
      legalBusinessName: legalBusinessName,
      flatShopNo: flatShopNo,
      area: area,
      city: city,
      pincode: pincode,
      gstin: gstin,
      businessStateCode: businessStateCode,
      pan: pan,
      bankAccountNo: bankAccountNo,
      bankIfsc: bankIfsc,
      userImageUrl: userImageUrl,
      signatureImageUrl: signatureImageUrl,
      role: role,
      businessId: effectiveBusinessId,
      phoneNumber: phoneNumber,
      onboardingDone: true,
    );

    WriteBatch batch = _firestore.batch();

    // 1. Update User Doc
    batch.set(_firestore.collection('users').doc(user.uid), userModel.toMap());

    // 2. If Owner, set up Business Doc
    if (role == 'admin') {
      DocumentReference businessRef = _firestore
          .collection('businesses')
          .doc(effectiveBusinessId);
      batch.set(businessRef, {
        'ownerUid': user.uid,
        'businessName': legalBusinessName,
        'gstin': gstin,
        'address': {
          'flat': flatShopNo,
          'area': area,
          'city': city,
          'pincode': pincode,
          'stateCode': businessStateCode,
        },
        'bankDetails': {'accountNo': bankAccountNo, 'ifsc': bankIfsc},
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Add to Public Directory (Searchable)
      String directoryId = gstin.isNotEmpty ? gstin : (user.email ?? user.uid);
      DocumentReference publicRef = _firestore
          .collection('public_directory')
          .doc(directoryId);
      batch.set(publicRef, {
        'businessId': effectiveBusinessId,
        'businessName': legalBusinessName,
        'stateCode': businessStateCode,
        'logo': userImageUrl,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // 3. Get Current User Data
  Future<UserModel?> getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // 4. Update User Profile
  Future<void> updateUserProfile({
    String? fullName,
    String? legalBusinessName,
    String? flatShopNo,
    String? area,
    String? city,
    String? pincode,
    String? gstin,
    String? businessStateCode,
    String? pan,
    String? bankAccountNo,
    String? bankIfsc,
    String? userImageUrl,
    String? signatureImageUrl,
    String? phoneNumber,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    Map<String, dynamic> data = {};
    if (fullName != null) data['fullName'] = fullName;
    if (legalBusinessName != null) {
      data['legalBusinessName'] = legalBusinessName;
    }
    if (flatShopNo != null) data['flatShopNo'] = flatShopNo;
    if (area != null) data['area'] = area;
    if (city != null) data['city'] = city;
    if (pincode != null) data['pincode'] = pincode;
    if (gstin != null) data['gstin'] = gstin;
    if (businessStateCode != null) {
      data['businessStateCode'] = businessStateCode;
    }
    if (pan != null) data['pan'] = pan;
    if (bankAccountNo != null) data['bankAccountNo'] = bankAccountNo;
    if (bankIfsc != null) data['bankIfsc'] = bankIfsc;
    if (userImageUrl != null) data['userImageUrl'] = userImageUrl;
    if (signatureImageUrl != null) {
      data['signatureImageUrl'] = signatureImageUrl;
    }
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;

    if (data.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
    }
  }

  // 5. Convert Image to Base64 (stored in Firestore instead of Firebase Storage)
  // This avoids the need for the Blaze plan
  Future<String> uploadImage(File imageFile, String folderName) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    if (!await imageFile.exists()) {
      throw Exception("Image file not found at path: ${imageFile.path}");
    }

    try {
      final bytes = await imageFile.readAsBytes();

      // Limit file size to ~500KB to stay within Firestore doc limits
      if (bytes.length > 500 * 1024) {
        throw Exception("Image too large. Please select an image under 500KB.");
      }

      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Failed to process image: $e");
    }
  }
}
