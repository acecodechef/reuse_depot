import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialListing {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String userId;
  final List<String> imageUrls;
  final DateTime postedDate;
  final bool isAvailable;

  MaterialListing({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.userId,
    required this.imageUrls,
    required this.postedDate,
    this.isAvailable = true,
  });

  /// Factory constructor to create a MaterialListing from a map and document ID
  factory MaterialListing.fromMap(Map<String, dynamic> data, String id) {
    return MaterialListing(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      userId: data['userId'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      postedDate:
          (data['postedDate'] is Timestamp)
              ? (data['postedDate'] as Timestamp).toDate()
              : DateTime.now(),
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  /// Converts the MaterialListing object to a Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'userId': userId,
      'imageUrls': imageUrls,
      'postedDate': postedDate,
      'isAvailable': isAvailable,
    };
  }

  /// Creates a copy with optional overrides
  MaterialListing copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    String? userId,
    List<String>? imageUrls,
    DateTime? postedDate,
    bool? isAvailable,
  }) {
    return MaterialListing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      userId: userId ?? this.userId,
      imageUrls: imageUrls ?? this.imageUrls,
      postedDate: postedDate ?? this.postedDate,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
