import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.userChanges();

  // Add this method to ensure user documents are created
  Future<void> _ensureUserDocument(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docExists = (await userDoc.get()).exists;

      if (!docExists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? 'New User',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ User document created for ${user.uid}');
      } else {
        print('ℹ️ User document already exists for ${user.uid}');
      }
    } catch (e, stack) {
      print('❌ Error creating user document: $e');
      print(stack);
      rethrow;
    }
  }

  Future<User?> register(String email, String password, String name) async {
    print("0000000000000000000000000000000000000000000000000000");

    // 1. Create user in Firebase Auth
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    print("99999999999999999999999999999999999999999");
    final user = userCredential.user;
    if (user == null) throw Exception('User creation failed');
    print("1111111111111111111111111111111111111111111111111111111111");
    // 2. Update display name and reload
    await Future.wait([user.updateDisplayName(name), user.reload()]);
    print("222222222222222222222222222222222222222222222222222222");
    // 3. Force token refresh
    await user.getIdToken(true);
    print("ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd");

    // 4. Create user document
    await _ensureUserDocument(user);

    return user;
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure user document exists
      if (userCredential.user != null) {
        await _ensureUserDocument(userCredential.user!);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> updateUserProfile({String? name, String? photoUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Update Auth profile
      if (name != null) {
        await user.updateDisplayName(name);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Update Firestore document
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (photoUrl != null) updateData['photoURL'] = photoUrl;

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updateData);
      }

      await user.reload(); // Refresh auth user data
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data(); // Returns Map or null
    } catch (e) {
      return null; // Return null on error
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
