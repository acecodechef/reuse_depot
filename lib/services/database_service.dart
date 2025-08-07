import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reuse_depot/models/material.dart';
import 'package:reuse_depot/models/message.dart';

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

  // Message related methods
  Future<void> sendMessage(Message message) async {
    await _firestore.collection('messages').add(message.toMap());
  }

  Stream<List<Message>> getConversation(
    String userId1,
    String userId2,
    String listingId,
  ) {
    try {
      return _firestore
          .collection('messages')
          .where('listingId', isEqualTo: listingId)
          .where(
            Filter.or(
              Filter.and(
                Filter('senderId', isEqualTo: userId1),
                Filter('receiverId', isEqualTo: userId2),
              ),
              Filter.and(
                Filter('senderId', isEqualTo: userId2),
                Filter('receiverId', isEqualTo: userId1),
              ),
            ),
          )
          .orderBy('timestamp', descending: false)
          .snapshots()
          .handleError((error) {
            print("Error fetching messages: $error");
            return Stream.value([]);
          })
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => Message.fromMap(doc.data(), doc.id))
                    .toList(),
          );
    } catch (e) {
      print("Error in getConversation: $e");
      return Stream.value([]);
    }
  }

  Stream<List<Message>> getUserConversations(String userId) {
    return _firestore
        .collection('messages')
        .where('senderId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Message.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    final query =
        await _firestore
            .collection('messages')
            .where('senderId', isEqualTo: conversationId)
            .where('receiverId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
