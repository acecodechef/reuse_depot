import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reuse_depot/models/material.dart';
import 'package:reuse_depot/services/database_service.dart';

class AdminListingManagement extends StatefulWidget {
  final MaterialListing material;

  const AdminListingManagement({Key? key, required this.material})
    : super(key: key);

  @override
  _AdminListingManagementState createState() => _AdminListingManagementState();
}

class _AdminListingManagementState extends State<AdminListingManagement> {
  late MaterialListing _editedMaterial;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _editedMaterial = widget.material;
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      Provider.of<DatabaseService>(
        context,
        listen: false,
      ).updateMaterial(_editedMaterial);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing updated successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteListing() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Delete'),
                content: const Text(
                  'Are you sure you want to delete this listing?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<DatabaseService>(
          context,
          listen: false,
        ).deleteMaterial(_editedMaterial.id);
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Listing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveChanges,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editedMaterial.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'Category: ${_editedMaterial.category}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Location: ${_editedMaterial.location}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Posted: ${_editedMaterial.postedDate.toLocal().toString().split(' ')[0]}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Available'),
                  value: _editedMaterial.isAvailable,
                  onChanged: (value) {
                    setState(() {
                      _editedMaterial = _editedMaterial.copyWith(
                        isAvailable: value,
                      );
                    });
                  },
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _deleteListing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Delete Listing'),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
