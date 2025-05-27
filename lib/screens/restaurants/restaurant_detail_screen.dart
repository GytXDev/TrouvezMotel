import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class RestaurantDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String restaurantId =
        ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: Text("Détails du restaurant")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('places')
            .doc(restaurantId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Erreur"));
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? '';
          final city = data['city'] ?? '';
          final quartier = data['quartier'] ?? '';
          final contact = data['contact'];
          final images = List<String>.from(data['images'] ?? []);
          final features = Map<String, dynamic>.from(data['features'] ?? {});
          final description = data['description'] ?? '';
          final menu = Map<String, dynamic>.from(data['menu'] ?? {});
          final lat = data['latitude'];
          final lng = data['longitude'];
          final _pageController = PageController(viewportFraction: 0.92);

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
                      avatar: Text("🍽️", style: TextStyle(fontSize: 16)),
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
                Text("Menu 🍽️",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: menu.length,
                    itemBuilder: (context, index) {
                      final catEntry = menu.entries.elementAt(index);
                      final catName = catEntry.key;
                      final plats = Map<String, dynamic>.from(catEntry.value);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("🍕", style: TextStyle(fontSize: 20)),
                              SizedBox(width: 6),
                              Text(
                                catName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          ...plats.entries.map((plat) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    plat.key,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    "${plat.value} FCFA",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: menu.length,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Theme.of(context).colorScheme.primary,
                      dotColor: Colors.grey.shade300,
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
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
                SizedBox(
                  height: 24,
                ),
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
                SizedBox(height: 20),
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
                ElevatedButton.icon(
                  icon: Icon(Icons.rate_review),
                  label: Text("Donner un avis"),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/addReview',
                      arguments: {
                        'placeId':
                            restaurantId, // ou restaurantId, ou appartementId
                        'type':
                            'restaurant', // ou 'restaurant', ou 'appartement'
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
                      .where('placeId', isEqualTo: restaurantId)
                      .orderBy('createdAt', descending: true)
                      .limit(3)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return SizedBox();
                    final reviews = snapshot.data!.docs;

                    if (reviews.isEmpty) {
                      return Text("Aucun avis pour le moment.",
                          style: TextStyle(color: Colors.grey[600]));
                    }

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
