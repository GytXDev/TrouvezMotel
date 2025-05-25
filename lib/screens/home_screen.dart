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
  String selectedType = "Motels";
  bool locationDenied = false;

  final List<String> _filterCities = [
    "Tous",
    "Libreville",
    "Franceville",
    "Moanda",
    "Port-Gentil"
  ];

  final List<Map<String, String>> _filterTypes = [
    {"label": "🏨 Motels", "value": "Motels"},
    {"label": "🍽️ Restaurants", "value": "Restaurants"},
    {"label": "🏡 Appartements", "value": "Appartements"},
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final permission = await Geolocator.requestPermission();
    if (!mounted) return;

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

  double _calculateDistance(double lat, double lng) {
    return Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          lat,
          lng,
        ) /
        1000;
  }

  Future<double> _getAverageRating(String placeId) async {
    final reviews = await FirebaseFirestore.instance
        .collection('reviews')
        .where('placeId', isEqualTo: placeId)
        .get();

    if (reviews.docs.isEmpty) return 0.0;

    final total = reviews.docs.fold<double>(
      0.0,
      (sum, doc) => sum + (doc['rating'] ?? 0.0),
    );

    return total / reviews.docs.length;
  }

  String getEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return '🍽️';
      case 'appartements':
      case 'appartement':
        return '🏡';
      case 'motels':
      case 'motel':
      default:
        return '🏨';
    }
  }

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
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (rating != null && rating > 0) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
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
          Text("Localisation désactivée",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          SizedBox(height: 5),
          Text("Activez-la pour afficher les résultats proches.",
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
                    offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Établissements proches de vous',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
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
                SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filterTypes.length,
                      itemBuilder: (context, index) {
                        final typeMap = _filterTypes[index];
                        final label = typeMap['label']!;
                        final value = typeMap['value']!;
                        final selected = selectedType == value;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => selectedType = value),
                            selectedColor: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black,
                            ),
                          ),
                        );
                      }),
                ),
              ],
            ),
          ),
          Expanded(
            child: locationDenied
                ? _buildLocationError()
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('places')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || _userPosition == null) {
                        return buildShimmerList();
                      }

                      final docs = snapshot.data!.docs;
                      final placesWithDistance = docs
                          .map((doc) {
                            final data = doc.data() as Map<String, dynamic>?;
                            if (data == null) return null;
                            final id = doc.id;

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

                      final filteredPlaces = placesWithDistance.where((m) {
                        final data = m!['data'] as Map<String, dynamic>;
                        final city = data['city']?.toString() ?? '';
                        final type =
                            data['type']?.toString().toLowerCase() ?? 'motel';
                        final matchesCity = selectedFilterCity == "Tous" ||
                            city == selectedFilterCity;
                        final matchesType = type == selectedType.toLowerCase();
                        return matchesCity && matchesType;
                      }).toList();

                      filteredPlaces.sort((a, b) {
                        final distA =
                            a!['distance'] as double? ?? double.infinity;
                        final distB =
                            b!['distance'] as double? ?? double.infinity;
                        return distA.compareTo(distB);
                      });

                      return ListView.builder(
                        itemCount: filteredPlaces.length,
                        itemBuilder: (context, index) {
                          final place = filteredPlaces[index];
                          final data = place!['data'] as Map<String, dynamic>;
                          final id = place['id'] as String;
                          final distance = place['distance'] as double?;

                          final imageUrl =
                              (data['images'] as List?)?.first?.toString() ??
                                  '';
                          final name = data['name']?.toString() ?? 'Sans nom';
                          final city = data['city']?.toString() ?? '';
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
                                onTap: () {
                                  final type =
                                      data['type']?.toString().toLowerCase();
                                  String route;
                                  switch (type) {
                                    case 'restaurant':
                                      route = '/restaurantDetail';
                                      break;
                                    case 'appartement':
                                    case 'appartements':
                                      route = '/appartementDetail';
                                      break;
                                    default:
                                      route = '/motelDetail';
                                  }

                                  Navigator.pushNamed(context, route,
                                      arguments: id);
                                },
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
