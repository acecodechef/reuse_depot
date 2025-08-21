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

  Future<Map<String, dynamic>> _getSellerInfo() async {
    final db = FirebaseFirestore.instance;
    final sellerDoc = await db.collection('users').doc(material.userId).get();
    return sellerDoc.data() ?? {};
  }

  Future<void> _showContactOptions(BuildContext context) async {
    final sellerInfo = await _getSellerInfo();
    final sellerName = sellerInfo['name'] ?? 'Seller';
    final sellerEmail = sellerInfo['email'] ?? '';
    final sellerPhone = sellerInfo['phone'] ?? '';

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Contact $sellerName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Email Option
                if (sellerEmail.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.blue),
                    title: Text('Email: $sellerEmail'),
                    subtitle: const Text('Send an email'),
                    onTap: () {
                      Navigator.pop(context);
                      _contactViaEmail(context, sellerEmail);
                    },
                  ),

                if (sellerEmail.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.email, color: Colors.grey),
                    title: Text('Email not provided'),
                    subtitle: Text('Seller hasn\'t shared their email'),
                  ),

                // Phone Option
                if (sellerPhone.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.green),
                    title: Text('Call: $sellerPhone'),
                    subtitle: const Text('Make a phone call'),
                    onTap: () {
                      Navigator.pop(context);
                      _contactViaPhone(context, sellerPhone);
                    },
                  ),

                if (sellerPhone.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.phone, color: Colors.grey),
                    title: Text('Phone not provided'),
                    subtitle: Text('Seller hasn\'t shared their phone number'),
                  ),

                // Message Option
                ListTile(
                  leading: const Icon(Icons.message, color: Colors.purple),
                  title: const Text('Message in App'),
                  subtitle: const Text('Chat within the app'),
                  onTap: () {
                    Navigator.pop(context);
                    _contactViaMessage(context, sellerName);
                  },
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _contactViaEmail(BuildContext context, String email) async {
    final url = 'mailto:$email?subject=Regarding ${material.title}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch email app')),
      );
    }
  }

  Future<void> _contactViaPhone(BuildContext context, String phone) async {
    final url = 'tel:$phone';
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
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Contact Seller',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
