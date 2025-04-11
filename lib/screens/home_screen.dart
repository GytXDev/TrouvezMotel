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
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => locationDenied = true);
      return;
    }
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() => _userPosition = position);
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
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl != ''
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
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  Text('$city — À partir de $price FCFA',
                      style: TextStyle(color: Colors.grey[700])),
                  if (distance != null) ...[
                    SizedBox(height: 4),
                    Text('À ${distance.toStringAsFixed(1)} km',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ]
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
          Text("Localisation désactivée",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          SizedBox(height: 5),
          Text("Activez-la pour afficher les motels proches.",
              style: TextStyle(fontSize: 14, color: Colors.grey)),
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
          Expanded(
            child: locationDenied
                ? _buildLocationError()
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('motels')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || _userPosition == null) {
                        return buildShimmerList();
                      }

                      final docs = snapshot.data!.docs;

                      List<Map<String, dynamic>> motelsWithDistance =
                          docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final id = doc.id;

                        double? distance;
                        if (data['latitude'] != null &&
                            data['longitude'] != null) {
                          distance = _calculateDistance(
                            data['latitude'],
                            data['longitude'],
                          );
                        }

                        return {'id': id, 'data': data, 'distance': distance};
                      }).toList();

                      List<Map<String, dynamic>> filteredMotels =
                          motelsWithDistance.where((m) {
                        if (selectedFilterCity == "Tous") return true;
                        return m['data']['city'] == selectedFilterCity;
                      }).toList();

                      filteredMotels.sort((a, b) {
                        final distA = a['distance'] ?? double.infinity;
                        final distB = b['distance'] ?? double.infinity;
                        return distA.compareTo(distB);
                      });

                      return ListView.builder(
                        itemCount: filteredMotels.length,
                        itemBuilder: (context, index) {
                          final motel = filteredMotels[index];
                          final data = motel['data'] as Map<String, dynamic>;
                          final id = motel['id'];
                          final distance = motel['distance'] as double?;

                          final imageUrl =
                              (data['images'] as List?)?.first ?? '';
                          final name = data['name'] ?? 'Sans nom';
                          final city = data['city'] ?? '';
                          final prices = (data['prices'] ?? {}) as Map;
                          final firstPrice = prices.isNotEmpty
                              ? prices.values.first.toString()
                              : 'N/A';

                          return FutureBuilder<double>(
                            future: _getAverageRating(id),
                            builder: (context, snapshot) {
                              final rating = snapshot.data;

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
