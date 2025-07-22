// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the currently signed-in user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print("Sign-in failed: $e");
      return null;
    }
  }

  // Get role of user from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && (doc.data() as Map<String, dynamic>).containsKey('role')) {
        return doc.get('role');
      }
      return null; // Role not found
    } catch (e) {
      print("Get user role failed: $e");
      return null;
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Sign up as Driver
  Future<User?> signUpDriver({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? assignedTruckId,
  }) async {
    return _signUpUser(
      email: email,
      password: password,
      name: name,
      phone: phone,
      role: 'driver',
      additionalData: {'assignedTruckId': assignedTruckId ?? ''},
    );
  }

  // Sign up as Admin
  Future<User?> signUpAdmin({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    return _signUpUser(
      email: email,
      password: password,
      name: name,
      phone: phone,
      role: 'admin',
    );
  }

  // Private helper to avoid code duplication for user signup
  Future<User?> _signUpUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        Map<String, dynamic> userData = {
          'name': name,
          'email': email,
          'phone': phone,
          'role': role,
          'createdAt': Timestamp.now(),
        };

        if (additionalData != null) {
          userData.addAll(additionalData);
        }

        await _firestore.collection('users').doc(user.uid).set(userData);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("Failed to sign up user: ${e.message}");
      return null;
    }
  }
}
