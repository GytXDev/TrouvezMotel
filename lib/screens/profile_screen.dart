import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import 'edit_motel_screen.dart';
import '../services/upload_service.dart'; // Pour deleteImageFromHostinger

class ProfileScreen extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>> _getUserProfile(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    return {
      'name': data['name'],
      'badge': data['badge'],
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (user == null)
      return Scaffold(body: Center(child: Text("Non connecté")));

    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserProfile(user!.uid),
      builder: (context, snapshot) {
        final userData = snapshot.data ?? {};
        final badge = userData['badge'];
        final firestoreName = userData['name']?.toString();

        final displayName = firestoreName?.isNotEmpty == true
            ? firestoreName
            : (user!.displayName ?? user!.email ?? 'Utilisateur');

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // ✅ AppBar Customisée
              Container(
                padding:
                    EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        displayName!.substring(0, 1).toUpperCase(),
                        style:
                            TextStyle(fontSize: 24, color: AppColors.primary),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (badge != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Chip(
                                avatar: Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                label: Text(
                                  badge,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: Colors.white,
                              ),
                            )
                        ],
                      ),
                    )
                  ],
                ),
              ),

              SizedBox(height: 12),

              // 🔸 Bouton de soutien
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(Icons.favorite, color: Colors.redAccent),
                    title: Text("Soutenir l'application",
                        style: textTheme.bodyMedium),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pushNamed(context, '/support'),
                  ),
                ),
              ),

              SizedBox(height: 12),

              // 🔸 Liste des motels créés
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('motels')
                      .where('createdBy', isEqualTo: user!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return Center(child: Text("Erreur de chargement"));
                    if (!snapshot.hasData)
                      return Center(child: CircularProgressIndicator());

                    final motels = snapshot.data!.docs;

                    if (motels.isEmpty)
                      return Center(
                          child:
                              Text("Vous n'avez encore ajouté aucun motel."));

                    return ListView.builder(
                      itemCount: motels.length,
                      padding: EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final doc = motels[index];
                        final data = doc.data() as Map<String, dynamic>?;

                        if (data == null) return SizedBox();

                        final id = doc.id;
                        final images = (data['images'] as List?) ?? [];
                        final image = images.isNotEmpty ? images.first : '';
                        final name = data['name']?.toString() ?? 'Sans nom';
                        final city = data['city']?.toString() ?? '';

                        return Card(
                          margin: EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: image != ''
                                  ? Image.network(
                                      'https://gytx.dev/api/image-proxy.php?url=$image',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(Icons.image, size: 40),
                            ),
                            title: Text(
                              name,
                              style: textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(city, style: textTheme.bodyMedium),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditMotelScreen(motelId: id),
                                    ),
                                  );
                                } else if (value == 'delete') {
                                  _deleteMotel(context, id, images);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                    value: 'edit', child: Text("Modifier")),
                                PopupMenuItem(
                                    value: 'delete', child: Text("Supprimer")),
                              ],
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
      },
    );
  }

  void _deleteMotel(
      BuildContext context, String id, List<dynamic> images) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirmer la suppression"),
        content: Text("Voulez-vous vraiment supprimer ce motel ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Annuler")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Supprimer")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        for (var img in images) {
          await deleteImageFromHostinger(img);
        }

        await FirebaseFirestore.instance.collection('motels').doc(id).delete();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Motel supprimé")),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur suppression : $e")),
        );
      }
    }
  }
}
