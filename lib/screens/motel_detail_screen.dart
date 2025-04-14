import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MotelDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String motelId = ModalRoute.of(context)!.settings.arguments as String;

    String _formatDate(DateTime date) {
      final months = [
        "janvier",
        "février",
        "mars",
        "avril",
        "mai",
        "juin",
        "juillet",
        "août",
        "septembre",
        "octobre",
        "novembre",
        "décembre"
      ];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    }

    return Scaffold(
      appBar: AppBar(title: Text("Détails du motel")),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('motels').doc(motelId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text("Erreur de chargement"));
          if (!snapshot.hasData || !snapshot.data!.exists)
            return Center(child: CircularProgressIndicator());

          final motel = snapshot.data!.data() as Map<String, dynamic>;

          final name = motel['name'] ?? '';
          final city = motel['city'] ?? '';
          final quartier = motel['quartier'] ?? '';
          final contact = motel['contact'];
          final images = List<String>.from(motel['images'] ?? []);
          final prices = Map<String, dynamic>.from(motel['prices'] ?? {});
          final features = Map<String, dynamic>.from(motel['features'] ?? {});

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (images.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      itemCount: images.length,
                      controller: PageController(viewportFraction: 0.85),
                      itemBuilder: (context, index) => AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.only(right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Hero(
                            tag: 'motel-image-${images[index]}',
                            child: Image.network(
                              'https://gytx.dev/api/image-proxy.php?url=${images[index]}',
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                Text(
                  name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Chip(
                      avatar: Text("🏘️", style: TextStyle(fontSize: 16)),
                      label: Text(
                        quartier.isNotEmpty ? quartier : "Quartier non précisé",
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                      backgroundColor: Colors.grey[200],
                      shape: StadiumBorder(),
                    ),
                    SizedBox(width: 8),
                    Text(
                      city,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                FutureBuilder<double>(
                  future: _getAverageRating(motelId),
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data == 0.0) return SizedBox();
                    return Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        SizedBox(width: 5),
                        Text("${snap.data!.toStringAsFixed(1)} / 5",
                            style: TextStyle(fontWeight: FontWeight.w500))
                      ],
                    );
                  },
                ),
                SizedBox(height: 20),
                Text("Tarifs",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                ...prices.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.price_change,
                              size: 18, color: Colors.blueGrey),
                          SizedBox(width: 8),
                          Text("${e.key} : ${e.value} FCFA",
                              style: TextStyle(fontSize: 15)),
                        ],
                      ),
                    )),
                SizedBox(height: 20),
                Text("Équipements",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      features.entries.where((e) => e.value == true).map((e) {
                    return Chip(
                      label: Text(e.key,
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      backgroundColor: Colors.grey.shade200,
                    );
                  }).toList(),
                ),
                SizedBox(height: 24),
                if (contact != null && contact.toString().isNotEmpty)
                  ElevatedButton.icon(
                    icon: Icon(Icons.chat),
                    label: Text("Contacter sur WhatsApp"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final url =
                          Uri.parse("https://wa.me/${contact.toString()}");
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                  ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/addReview',
                        arguments: motelId);
                  },
                  icon: Icon(Icons.rate_review),
                  label: Text("Donner un avis"),
                ),
                SizedBox(height: 30),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .where('motelId', isEqualTo: motelId)
                      .orderBy('createdAt', descending: true)
                      .limit(3)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return SizedBox();
                    final reviews = snapshot.data!.docs;

                    if (reviews.isEmpty)
                      return Text("Aucun avis pour le moment.");

                    return AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Avis récents",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          ...reviews.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final rating = data['rating'] ?? 0;
                            final name = data['userName'] ?? 'Utilisateur';
                            final comment = data['comment'] ?? '';
                            final timestamp = data['createdAt'] as Timestamp?;
                            final date = timestamp != null
                                ? DateTime.fromMillisecondsSinceEpoch(
                                    timestamp.millisecondsSinceEpoch)
                                : null;
                            final photoUrl = data['photoURL'] ?? null;
                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            final isOwnReview =
                                currentUser?.uid == data['userId'];

                            return GestureDetector(
                              onLongPress: () async {
                                if (!isOwnReview) return;
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("Supprimer cet avis ?"),
                                    content:
                                        Text("Cette action est irréversible."),
                                    actions: [
                                      TextButton(
                                        child: Text("Annuler"),
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                      ),
                                      TextButton(
                                        child: Text("Supprimer",
                                            style:
                                                TextStyle(color: Colors.red)),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                      )
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await doc.reference.delete();
                                }
                              },
                              child: Card(
                                margin: EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundImage: photoUrl != null
                                                ? NetworkImage(photoUrl)
                                                : null,
                                            child: photoUrl == null
                                                ? Icon(Icons.person,
                                                    size: 16,
                                                    color: Colors.white)
                                                : null,
                                            backgroundColor: Colors.grey,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            name,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          Spacer(),
                                          if (date != null)
                                            Text(
                                              "${_formatDate(date)}",
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        children: List.generate(5, (i) {
                                          return Icon(
                                            i < rating
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: 18,
                                            color: Colors.amber,
                                          );
                                        }),
                                      ),
                                      SizedBox(height: 8),
                                      Text(comment),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Future<double> _getAverageRating(String motelId) async {
    final reviews = await FirebaseFirestore.instance
        .collection('reviews')
        .where('motelId', isEqualTo: motelId)
        .get();

    if (reviews.docs.isEmpty) return 0.0;

    final total = reviews.docs.fold<double>(
      0.0,
      (sum, doc) => sum + (doc['rating'] ?? 0.0),
    );

    return total / reviews.docs.length;
  }
}