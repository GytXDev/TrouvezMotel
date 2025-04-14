import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _userPosition;
  String selectedFilterCity = "Tous";
  bool locationDenied = false;

  final List<String> _filterCities = [
    "Tous",
    "Libreville",
    "Franceville",
    "Moanda",
    "Port-Gentil"
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final permission = await Geolocator.requestPermission();
    if (!mounted) return; // ✅ vérifie que le widget est encore présent

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => locationDenied = true);
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) {
      setState(() => _userPosition = position);
    }
  }

  double _calculateDistance(double motelLat, double motelLng) {
    return Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          motelLat,
          motelLng,
        ) /
        1000;
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

  // Récupère le plus petit tarif
  String getFirstPrice(Map<String, dynamic> data) {
    final pricesRaw = data['prices'];
    if (pricesRaw is Map) {
      final values = pricesRaw.values.whereType<num>().toList();
      if (values.isNotEmpty) {
        values.sort();
        return values.first.toString();
      }
    }
    return 'N/A';
  }

  // Shimmer
  Widget buildShimmerList() {
    return ListView.builder(
      itemCount: 5,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 250,
          margin: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget buildMotelCard({
    required String imageUrl,
    required String name,
    required String city,
    required String price,
    double? distance,
    double? rating,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      'https://gytx.dev/api/image-proxy.php?url=$imageUrl',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 180,
                      color: Colors.grey.shade300,
                      child: Icon(Icons.image_not_supported, size: 60),
                    ),
            ),
            // Infos
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom
                  Text(
                    name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // Note
                  if (rating != null && rating > 0) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 4),
                  // Tarif
                  Text(
                    '$city — À partir de $price FCFA',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  // Distance
                  if (distance != null) ...[
                    SizedBox(height: 4),
                    Text(
                      'À ${distance.toStringAsFixed(1)} km',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off, size: 48, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "Localisation désactivée",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 5),
          Text(
            "Activez-la pour afficher les motels proches.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷 Header
          Container(
            padding: EdgeInsets.only(top: 40, bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Motels proches de vous',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Choix de la ville
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filterCities.length,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final city = _filterCities[index];
                      final selected = selectedFilterCity == city;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(city),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => selectedFilterCity = city),
                          selectedColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 🏷 Corps
          Expanded(
            child: locationDenied
                ? _buildLocationError()
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('motels')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // Si pas de data ou position manquante => shimmer
                      if (!snapshot.hasData || _userPosition == null) {
                        return buildShimmerList();
                      }

                      final docs = snapshot.data!.docs;

                      // On convertit chaque doc
                      final motelsWithDistance = docs
                          .map((doc) {
                            final data = doc.data() as Map<String, dynamic>?;
                            if (data == null) return null; // prudence
                            final String id = doc.id;

                            double? distance;
                            final lat = data['latitude'];
                            final lng = data['longitude'];
                            if (lat != null && lng != null) {
                              distance = _calculateDistance(
                                lat is double ? lat : (lat as num).toDouble(),
                                lng is double ? lng : (lng as num).toDouble(),
                              );
                            }

                            return {
                              'id': id,
                              'data': data,
                              'distance': distance,
                            };
                          })
                          .where((e) => e != null)
                          .toList();

                      // Filtrage par ville
                      final filteredMotels = motelsWithDistance.where((m) {
                        // m peut être non-null car on a filtré ci-dessus
                        final data = m!['data'] as Map<String, dynamic>;
                        final city = data['city']?.toString() ?? '';
                        if (selectedFilterCity == "Tous") return true;
                        return city == selectedFilterCity;
                      }).toList();

                      // Tri par distance
                      filteredMotels.sort((a, b) {
                        final distA =
                            a!['distance'] as double? ?? double.infinity;
                        final distB =
                            b!['distance'] as double? ?? double.infinity;
                        return distA.compareTo(distB);
                      });

                      // Construction de la liste
                      return ListView.builder(
                        itemCount: filteredMotels.length,
                        itemBuilder: (context, index) {
                          final motel = filteredMotels[index];
                          final data = motel!['data'] as Map<String, dynamic>;
                          final String id = motel['id'] as String;
                          final double? distance = motel['distance'] as double?;

                          final imageUrl =
                              (data['images'] as List?)?.first?.toString() ??
                                  '';
                          final name = data['name']?.toString() ?? 'Sans nom';
                          final city = data['city']?.toString() ?? '';

                          // Récupère le plus petit tarif
                          final firstPrice = getFirstPrice(data);

                          return FutureBuilder<double>(
                            future: _getAverageRating(id),
                            builder: (context, ratingSnap) {
                              final rating = ratingSnap.data ?? 0.0;

                              return buildMotelCard(
                                imageUrl: imageUrl,
                                name: name,
                                city: city,
                                price: firstPrice,
                                distance: distance,
                                rating: rating,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/motelDetail',
                                  arguments: id,
                                ),
                              );
                            },
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
