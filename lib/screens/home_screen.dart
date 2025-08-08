import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reuse_depot/models/material.dart';
import 'package:reuse_depot/services/database_service.dart';
import 'package:reuse_depot/services/auth_service.dart';
import 'package:reuse_depot/screens/add_listing_screen.dart';
import 'package:reuse_depot/screens/listing_detail_screen.dart';
import 'package:reuse_depot/screens/conversations_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationFilterController =
      TextEditingController();
  String _searchQuery = '';
  String _locationFilter = '';
  List<String> _selectedCategories = [];
  bool _showAvailableOnly = true;
  bool _showFilters = false;

  final List<String> _allCategories = [
    'Wood',
    'Tile',
    'Cabinets',
    'Fixtures',
    'Paint',
    'Tools',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _locationFilterController.dispose();
    super.dispose();
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _toggleAvailabilityFilter() {
    setState(() {
      _showAvailableOnly = !_showAvailableOnly;
    });
  }

  void _toggleFiltersVisibility() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedCategories = [];
      _showAvailableOnly = true;
      _searchQuery = '';
      _locationFilter = '';
      _searchController.clear();
      _locationFilterController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reuse Depot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _toggleFiltersVisibility,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddListingScreen()),
              );
            },
          ),

          // In HomeScreen's AppBar actions
          StreamBuilder<int>(
            stream: Provider.of<DatabaseService>(context).getTotalUnreadCount(
              Provider.of<AuthService>(context).currentUser!.uid,
            ),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(Icons.message),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConversationsListScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
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
          if (_showFilters) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _resetFilters,
                        child: Text('Reset'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Availability',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: Text('Available only'),
                    value: _showAvailableOnly,
                    onChanged: (value) => _toggleAvailabilityFilter(),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Location',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _locationFilterController,
                    decoration: InputDecoration(
                      hintText: 'Filter by location...',
                      prefixIcon: Icon(Icons.location_on),
                      suffixIcon:
                          _locationFilter.isNotEmpty
                              ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _locationFilter = '';
                                    _locationFilterController.clear();
                                  });
                                },
                              )
                              : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _locationFilter = value;
                      });
                    },
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Categories',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8.0,
                    children:
                        _allCategories.map((category) {
                          return FilterChip(
                            label: Text(category),
                            selected: _selectedCategories.contains(category),
                            onSelected: (selected) => _toggleCategory(category),
                          );
                        }).toList(),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
            Divider(),
          ],
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

                List<MaterialListing> filteredMaterials = snapshot.data!;

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  filteredMaterials =
                      filteredMaterials.where((material) {
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
                }

                // Apply location filter
                if (_locationFilter.isNotEmpty) {
                  filteredMaterials =
                      filteredMaterials.where((material) {
                        return material.location.toLowerCase().contains(
                          _locationFilter.toLowerCase(),
                        );
                      }).toList();
                }

                // Apply category filter
                if (_selectedCategories.isNotEmpty) {
                  filteredMaterials =
                      filteredMaterials.where((material) {
                        return _selectedCategories.contains(material.category);
                      }).toList();
                }

                // Apply availability filter
                if (_showAvailableOnly) {
                  filteredMaterials =
                      filteredMaterials.where((material) {
                        return material.isAvailable;
                      }).toList();
                }

                if (filteredMaterials.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No results found'),
                        SizedBox(height: 8),
                        TextButton(
                          onPressed: _resetFilters,
                          child: Text('Reset filters'),
                        ),
                      ],
                    ),
                  );
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(material.description),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.category, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    material.category,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.location_on, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    material.location,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing:
                              material.isAvailable
                                  ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                  : Icon(Icons.cancel, color: Colors.red),
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
