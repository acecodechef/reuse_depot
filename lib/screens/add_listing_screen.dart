import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reuse_depot/models/material.dart';
import 'package:reuse_depot/services/database_service.dart';
import 'package:reuse_depot/services/auth_service.dart';
import 'dart:io';
import 'dart:convert';

import 'dart:async';

class AddListingScreen extends StatefulWidget {
  @override
  _AddListingScreenState createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedCategory;
  List<File> _images = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'Wood',
    'Tile',
    'Cabinets',
    'Fixtures',
    'Paint',
    'Tools',
    'Other',
  ];

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _images.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images: ${e.toString()}')),
      );
    }
  }

  Future<List<String>> _convertImagesToBase64() async {
    List<String> base64Images = [];

    for (File image in _images) {
      final bytes = await image.readAsBytes();
      final base64Str = base64Encode(bytes);
      base64Images.add(base64Str);
    }

    return base64Images;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a category')));
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<String> base64ImageStrings = [];

      if (_images.isNotEmpty) {
        try {
          base64ImageStrings = await _convertImagesToBase64();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to convert images.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final material = MaterialListing(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        location: _locationController.text.trim(),
        userId:
            Provider.of<AuthService>(context, listen: false).currentUser!.uid,
        imageUrls: base64ImageStrings,
        postedDate: DateTime.now(),
      );

      await Provider.of<DatabaseService>(
        context,
        listen: false,
      ).addMaterial(material).timeout(Duration(seconds: 20));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Listing added successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(Duration(milliseconds: 1500));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error in _submit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSaveBeforeExitDialog() async {
    final shouldExit =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Unsaved Changes'),
                content: Text(
                  'You have unsaved changes. Do you want to save before exiting?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Discard'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Save'),
                  ),
                ],
              ),
        ) ??
        false;

    if (shouldExit) {
      await _submit();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Listing'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed:
              _isLoading
                  ? null
                  : () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _showSaveBeforeExitDialog();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value?.trim().isEmpty ?? true
                                ? 'Required field'
                                : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) => null,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    validator:
                        (value) =>
                            value == null ? 'Please select a category' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value?.trim().isEmpty ?? true
                                ? 'Required field'
                                : null,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Photos (Optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _images.isEmpty
                      ? Text('No images selected')
                      : SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Image.file(
                                    _images[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: IconButton(
                                      icon: Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _images.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: Icon(Icons.camera_alt),
                    label: Text(
                      _images.isEmpty ? 'Add Photos' : 'Add More Photos',
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child:
                        _isLoading
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text('Submit Listing'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
