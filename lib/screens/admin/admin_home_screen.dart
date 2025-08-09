import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reuse_depot/models/material.dart';
import 'package:reuse_depot/services/database_service.dart';
import 'package:reuse_depot/services/auth_service.dart';

import 'package:reuse_depot/screens/admin/admin_listing_management.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed:
                () =>
                    Provider.of<AuthService>(context, listen: false).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Manage Listings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  return const Center(child: Text('No listings available'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final material = snapshot.data![index];
                    return ListTile(
                      title: Text(material.title),
                      subtitle: Text(material.category),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AdminListingManagement(
                                    material: material,
                                  ),
                            ),
                          );
                        },
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
}
