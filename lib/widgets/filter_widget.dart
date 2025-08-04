import 'package:flutter/material.dart';

class FilterWidget extends StatefulWidget {
  final ValueChanged<Map<String, String>> onFiltersChanged;
  final List<String> categories;
  final List<String> locations;

  const FilterWidget({
    required this.onFiltersChanged,
    required this.categories,
    required this.locations,
    Key? key,
  }) : super(key: key);

  @override
  _FilterWidgetState createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  String? _selectedCategory;
  String? _selectedLocation;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                ),
              ),
              onChanged: (value) => _applyFilters(),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: [
                DropdownMenuItem(value: '', child: Text('All Categories')),
                ...widget.categories.map(
                  (category) =>
                      DropdownMenuItem(value: category, child: Text(category)),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedCategory = value);
                _applyFilters();
              },
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              items: [
                DropdownMenuItem(value: '', child: Text('All Locations')),
                ...widget.locations.map(
                  (location) =>
                      DropdownMenuItem(value: location, child: Text(location)),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedLocation = value);
                _applyFilters();
              },
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilters() {
    widget.onFiltersChanged({
      'search': _searchController.text,
      'category': _selectedCategory ?? '',
      'location': _selectedLocation ?? '',
    });
  }
}
