import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await saveUserProfile(
          uid: credential.user!.uid,
          email: email,
          fullName: fullName,
        );
      }
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  /// Save basic user data to Firestore
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    required String fullName,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'businessId': null, // Initially null until business is created
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. Login
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An unknown error occurred during login.';
    } catch (e) {
      throw 'System error: $e';
    }
  }

  // 3. Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Could not send reset email.';
    }
  }

  // 4. Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 5. Current user
  User? get currentUser => _auth.currentUser;
}
