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
  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> sendMessage(Message message) async {
    await _firestore.collection('messages').add(message.toMap());
  }

  Stream<List<Message>> getConversation(String userId1, String userId2) {
    return _firestore
        .collection('messages')
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
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Message.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // database_service.dart
  Stream<List<Map<String, dynamic>>> getUserConversations(String userId) {
    return _firestore
        .collection('messages')
        .where(
          Filter.or(
            Filter('senderId', isEqualTo: userId),
            Filter('receiverId', isEqualTo: userId),
          ),
        )
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          // Group by the other user ID
          final conversations = <String, Map<String, dynamic>>{};

          for (final doc in snapshot.docs) {
            final message = Message.fromMap(doc.data(), doc.id);
            final otherUserId =
                message.senderId == userId
                    ? message.receiverId
                    : message.senderId;

            if (!conversations.containsKey(otherUserId)) {
              conversations[otherUserId] = {
                'lastMessage': message,
                'unreadCount': 0,
              };
            }

            // Count unread messages where current user is receiver
            if (message.receiverId == userId && !message.isRead) {
              conversations[otherUserId]!['unreadCount'] += 1;
            }
          }

          return conversations.values.toList();
        });
  }

  Future<void> markMessagesAsRead(
    String currentUserId,
    String otherUserId,
  ) async {
    final query =
        await _firestore
            .collection('messages')
            .where('senderId', isEqualTo: otherUserId)
            .where('receiverId', isEqualTo: currentUserId)
            .where('isRead', isEqualTo: false)
            .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Stream<int> getUnreadMessageCount(String userId) {
    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
}
