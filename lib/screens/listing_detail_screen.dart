import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reuse_depot/models/material.dart';

import 'package:reuse_depot/screens/conversation_screen.dart';

class ListingDetailScreen extends StatelessWidget {
  final MaterialListing material;

  const ListingDetailScreen({Key? key, required this.material})
    : super(key: key);

  Future<void> _showContactOptions(BuildContext context) async {
    final db = FirebaseFirestore.instance;

    // Get seller's name
    final sellerDoc = await db.collection('users').doc(material.userId).get();
    final sellerName = sellerDoc.data()?['name'] ?? 'Seller';

    await showModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Contact $sellerName',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Send Email'),
                  onTap: () {
                    Navigator.pop(context);
                    _contactViaEmail(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.phone),
                  title: Text('Call Seller'),
                  onTap: () {
                    Navigator.pop(context);
                    _contactViaPhone(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.message),
                  title: Text('Message in App'),
                  onTap: () {
                    Navigator.pop(context);
                    _contactViaMessage(context, sellerName);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _contactViaEmail(BuildContext context) async {
    final url = 'mailto:seller@example.com?subject=Regarding ${material.title}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch email app')),
      );
    }
  }

  Future<void> _contactViaPhone(BuildContext context) async {
    final url = 'tel:+1234567890';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone app')),
      );
    }
  }

  void _contactViaMessage(BuildContext context, String sellerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ConversationScreen(
              otherUserId: material.userId,
              otherUserName: sellerName,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (material.imageUrls.isNotEmpty)
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: material.imageUrls.length,
                  itemBuilder: (context, index) {
                    try {
                      Uint8List imageBytes = base64Decode(
                        material.imageUrls[index],
                      );
                      return Image.memory(
                        imageBytes,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.broken_image));
                        },
                      );
                    } catch (e) {
                      return const Center(child: Icon(Icons.broken_image));
                    }
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(material.category),
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  if (material.description.isNotEmpty)
                    Text(
                      material.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        material.location,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Posted on ${material.postedDate.toLocal().toString().split(' ')[0]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            onPressed: () => _showContactOptions(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Contact Seller'),
          ),
        ),
      ),
    );
  }
}
