import 'package:firebase_auth/firebase_auth.dart';
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

          String formatDate(DateTime date) {
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
                Row(
                  children: [
                    if (contact != null && contact.toString().isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          final url =
                              Uri.parse("https://wa.me/${contact.toString()}");
                          launchUrl(url, mode: LaunchMode.externalApplication);
                        },
                        child: Image.asset(
                          'assets/icons/whatsapp.png',
                          height: 32,
                          width: 32,
                        ),
                      ),
                    SizedBox(width: 16),
                    if (lat != null && lng != null)
                      GestureDetector(
                        onTap: () {
                          final url = Uri.parse(
                              "https://www.google.com/maps/search/?api=1&query=$lat,$lng");
                          launchUrl(url, mode: LaunchMode.externalApplication);
                        },
                        child: Image.asset(
                          'assets/icons/map.png',
                          height: 32,
                          width: 32,
                        ),
                      ),
                    SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/addReview',
                          arguments: {
                            'placeId': restaurantId,
                            'type': 'restaurant',
                          },
                        );
                      },
                      child: Image.asset(
                        'assets/icons/rating.png',
                        height: 32,
                        width: 32,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SizedBox(height: 12),
                FutureBuilder<double>(
                  future: _getAverageRating(restaurantId),
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
                SizedBox(height: 10),
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
                SizedBox(height: 30),
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
                      return Text("Aucun avis pour le moment.");
                    }

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
                                            backgroundColor: Colors.grey,
                                            child: photoUrl == null
                                                ? Icon(Icons.person,
                                                    size: 16,
                                                    color: Colors.white)
                                                : null,
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
                                              formatDate(date),
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
        .where('placeId', isEqualTo: motelId)
        .get();

    if (reviews.docs.isEmpty) return 0.0;

    final total = reviews.docs.fold<double>(
      0.0,
      (sum, doc) => sum + (doc['rating'] ?? 0.0),
    );

    return total / reviews.docs.length;
  }
}
