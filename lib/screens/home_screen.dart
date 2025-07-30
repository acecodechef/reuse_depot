import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reuse_depot/models/material.dart';
import 'package:reuse_depot/services/database_service.dart';
import 'package:reuse_depot/services/auth_service.dart';
import 'package:reuse_depot/screens/add_listing_screen.dart';
import 'package:reuse_depot/screens/listing_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reuse Depot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddListingScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'signout') {
                await Provider.of<AuthService>(
                  context,
                  listen: false,
                ).signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'signout',
                  child: Text('Sign Out'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search materials...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MaterialListing>>(
              stream: Provider.of<DatabaseService>(context).getMaterials(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return const Center(child: Text('No materials available'));
                }

                final filteredMaterials =
                    _searchQuery.isEmpty
                        ? snapshot.data!
                        : snapshot.data!.where((material) {
                          return material.title.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              material.description.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              material.category.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              );
                        }).toList();

                if (filteredMaterials.isEmpty) {
                  return const Center(child: Text('No results found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredMaterials.length,
                  itemBuilder: (context, index) {
                    final material = filteredMaterials[index];

                    Widget imageWidget;
                    if (material.imageUrls.isNotEmpty) {
                      try {
                        Uint8List imageBytes = base64Decode(
                          material.imageUrls.first,
                        );
                        imageWidget = Image.memory(
                          imageBytes,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        );
                      } catch (e) {
                        imageWidget = _buildPlaceholder();
                      }
                    } else {
                      imageWidget = _buildPlaceholder();
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ListingDetailScreen(material: material),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Container(
                            width: 60,
                            height: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: imageWidget,
                            ),
                          ),
                          title: Text(material.title),
                          subtitle: Text(material.description),
                          trailing: Text(material.category),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade300,
      child: const Icon(
        Icons.image_not_supported,
        size: 30,
        color: Colors.grey,
      ),
    );
  }
}
