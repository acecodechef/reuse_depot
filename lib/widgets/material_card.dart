import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:reuse_depot/models/material.dart';

class MaterialCard extends StatelessWidget {
  final MaterialListing material;
  final VoidCallback? onTap;

  const MaterialCard({required this.material, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (material.imageUrls.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: material.imageUrls.first,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) =>
                          Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Chip(
                        label: Text(material.category),
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.2),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.location_on, size: 16),
                      SizedBox(width: 4),
                      Text(
                        material.location,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
