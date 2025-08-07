// screens/conversations_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:reuse_depot/models/message.dart';
import 'package:reuse_depot/models/material.dart';
import 'package:reuse_depot/services/auth_service.dart';
import 'package:reuse_depot/services/database_service.dart';
import 'package:reuse_depot/screens/conversation_screen.dart';
import 'package:intl/intl.dart';

class ConversationsListScreen extends StatelessWidget {
  const ConversationsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DatabaseService>(context);
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: Text('Messages')),
      body: StreamBuilder<List<Message>>(
        stream: db.getUserConversations(auth.currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading conversations'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data ?? [];

          if (messages.isEmpty) {
            return Center(child: Text('No conversations yet'));
          }

          // Filter out messages with empty listingId
          final validMessages =
              messages.where((m) => m.listingId.isNotEmpty).toList();

          return ListView.builder(
            itemCount: validMessages.length,
            itemBuilder: (context, index) {
              final message = validMessages[index];
              final otherUserId =
                  message.receiverId == auth.currentUser?.uid
                      ? message.senderId
                      : message.receiverId;

              if (otherUserId.isEmpty) {
                return ListTile(title: Text('Invalid conversation'));
              }

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future:
                    firestore
                        .collection('materials')
                        .doc(message.listingId)
                        .get(),
                builder: (context, listingSnapshot) {
                  if (!listingSnapshot.hasData) {
                    return ListTile(title: Text('Loading listing...'));
                  }

                  final listingData = listingSnapshot.data?.data();
                  if (listingData == null) {
                    return ListTile(title: Text('Deleted listing'));
                  }

                  final listing = MaterialListing.fromMap(
                    listingData,
                    message.listingId,
                  );

                  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future:
                        firestore.collection('users').doc(otherUserId).get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return ListTile(title: Text('Loading user...'));
                      }

                      final userData = userSnapshot.data?.data();
                      final userName = userData?['name'] ?? 'Unknown User';
                      final userEmail = userData?['email'] ?? '';

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(userName.isNotEmpty ? userName[0] : '?'),
                        ),
                        title: Text(userName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${listing.title}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              message.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: Text(
                          DateFormat('MMM d').format(message.timestamp),
                          style: TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ConversationScreen(
                                    receiverId: otherUserId,
                                    listing: listing,
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
