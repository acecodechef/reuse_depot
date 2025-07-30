import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reuse_depot/models/material.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new material listing
  Future<String> addMaterial(MaterialListing material) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('materials')
          .add(material.toMap());
      return docRef.id;
    } catch (e) {
      print("mydebug: ${e.toString()}");
      return "0";
    }
  }

  // Get all materials
  Stream<List<MaterialListing>> getMaterials() {
    return _firestore
        .collection('materials')
        .orderBy('postedDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => MaterialListing.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Get materials by user
  Stream<List<MaterialListing>> getUserMaterials(String userId) {
    return _firestore
        .collection('materials')
        .where('userId', isEqualTo: userId)
        .orderBy('postedDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => MaterialListing.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }
}
