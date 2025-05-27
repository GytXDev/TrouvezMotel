import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AppartementDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String appartementId =
        ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: Text("Détails de l'appartement")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('places')
            .doc(appartementId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Erreur"));
          if (!snapshot.hasData || !snapshot.data!.exists)
            return Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? '';
          final city = data['city'] ?? '';
          final quartier = data['quartier'] ?? '';
          final contact = data['contact'];
          final images = List<String>.from(data['images'] ?? []);
          final description = data['description'] ?? '';
          final features = Map<String, dynamic>.from(data['features'] ?? {});
          final prices = Map<String, dynamic>.from(data['prices'] ?? {});
          final lat = data['latitude'];
          final lng = data['longitude'];

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
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              'https://gytx.dev/api/image-proxy.php?url=${images[index]}',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                SizedBox(height: 16),
                Text(name,
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      avatar: Text("🏢", style: TextStyle(fontSize: 16)),
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
                if (description.isNotEmpty)
                  Text(description,
                      style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                SizedBox(height: 16),
                Text("Tarifs",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                ...prices.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key,
                              style: TextStyle(color: Colors.grey[800])),
                          Text("${e.value} FCFA",
                              style: TextStyle(fontWeight: FontWeight.w500)),
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
                  children: features.entries
                      .where((e) => e.value == true)
                      .map((e) => Chip(
                            label: Text(e.key,
                                style: TextStyle(fontWeight: FontWeight.w500)),
                            backgroundColor: Colors.grey.shade200,
                          ))
                      .toList(),
                ),
                SizedBox(height: 24),
                if (lat != null && lng != null)
                  ElevatedButton.icon(
                    icon: Icon(Icons.map),
                    label: Text("Voir sur la carte"),
                    onPressed: () {
                      final url = Uri.parse(
                          "https://www.google.com/maps/search/?api=1&query=$lat,$lng");
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                  ),
                SizedBox(height: 16),
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
                  icon: Icon(Icons.rate_review),
                  label: Text("Donner un avis"),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/addReview',
                      arguments: {
                        'placeId':
                            appartementId, // ou restaurantId, ou appartementId
                        'type':
                            'appartement', // ou 'restaurant', ou 'appartement'
                      },
                    );
                  },
                ),
                SizedBox(height: 30),
                Text("Avis récents",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .where('placeId', isEqualTo: appartementId)
                      .orderBy('createdAt', descending: true)
                      .limit(3)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return SizedBox();
                    final reviews = snapshot.data!.docs;

                    if (reviews.isEmpty)
                      return Text("Aucun avis pour le moment.",
                          style: TextStyle(color: Colors.grey[600]));

                    return Column(
                      children: reviews.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['userName'] ?? 'Utilisateur';
                        final comment = data['comment'] ?? '';
                        final rating = data['rating'] ?? 0;
                        final timestamp = data['createdAt'] as Timestamp?;
                        final date = timestamp != null
                            ? DateTime.fromMillisecondsSinceEpoch(
                                timestamp.millisecondsSinceEpoch)
                            : null;

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(comment),
                                if (date != null)
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      "${date.day}/${date.month}/${date.year}",
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
