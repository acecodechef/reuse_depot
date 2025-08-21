import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.userChanges();

  Future<void> _ensureUserDocument(
    User user, {
    String? name,
    String? phone,
  }) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final isAdmin = user.email == 'admin@reusedepot.com';

    // First, check if the user document already exists
    final existingDoc = await userDoc.get();

    if (existingDoc.exists) {
      // Document exists, only update necessary fields
      await userDoc.set({
        'email': user.email, // Update email if changed
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // Document doesn't exist, create it with all fields
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'name': name ?? user.displayName ?? 'New User',
        'phone': phone ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isAdmin': isAdmin,
      });
    }
  }

  Future<User?> register(
    String email,
    String password,
    String name, {
    String? phone,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('User creation failed');

      await user.getIdToken(true);
      // For registration, we want to set the name and phone
      await _ensureUserDocument(user, name: name, phone: phone);

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // For sign-in, we don't pass name/phone to avoid overwriting
        await _ensureUserDocument(userCredential.user!);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> isAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['isAdmin'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Add a method to update user profile
  Future<void> updateUserProfile({String? name, String? phone}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final userDoc = _firestore.collection('users').doc(user.uid);

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;

      if (updateData.isNotEmpty) {
        await userDoc.set(updateData, SetOptions(merge: true));
      }
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    // First, check the error message for specific patterns
    final errorMessage = e.message?.toLowerCase() ?? '';

    if (errorMessage.contains('incorrect') ||
        errorMessage.contains('wrong') ||
        errorMessage.contains('invalid') && errorMessage.contains('password')) {
      return 'Incorrect password. Please try again.';
    }

    if (errorMessage.contains('already') && errorMessage.contains('use')) {
      return 'This email is already registered. Please login instead.';
    }

    if (errorMessage.contains('user') &&
        (errorMessage.contains('not found') ||
            errorMessage.contains('no record'))) {
      return 'No user found with this email. Please check your email or create an account.';
    }

    // Then fall back to error codes
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
        return 'No user found with this email. Please check your email or create an account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
