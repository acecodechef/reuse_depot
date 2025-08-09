import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.userChanges();

  Future<void> _ensureUserDocument(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final isAdmin =
          user.email == 'admin@reusedepot.com'; // Compare email here

      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? 'New User',
        'createdAt': FieldValue.serverTimestamp(),
        'isAdmin': isAdmin, // Store as boolean
      }, SetOptions(merge: true)); // Merge to avoid overwriting
    } catch (e) {
      print('Error ensuring user document: $e');
      rethrow;
    }
  }

  Future<User?> register(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) throw Exception('User creation failed');

      await Future.wait([user.updateDisplayName(name), user.reload()]);
      await user.getIdToken(true);
      await _ensureUserDocument(user);

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _ensureUserDocument(userCredential.user!);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
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

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
