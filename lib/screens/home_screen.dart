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
    {"label": "🏨 Motels", "value": "Motel"},
    {"label": "🍽️ Restaurants", "value": "Restaurant"},
    {"label": "🏡 Appartements", "value": "Appartement"},
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
      setState(() => locationDenied = true);
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    if (mounted) setState(() => _userPosition = position);
  }

  double _calculateDistance(double lat, double lng) {
    return Geolocator.distanceBetween(
            _userPosition!.latitude, _userPosition!.longitude, lat, lng) /
        1000;
  }

  Future<double> _getAverageRating(String placeId) async {
    final reviews = await FirebaseFirestore.instance
        .collection('reviews')
        .where('placeId', isEqualTo: placeId)
        .get();

    if (reviews.docs.isEmpty) return 0.0;

    final total = reviews.docs
        .fold<double>(0.0, (sum, doc) => sum + (doc['rating'] ?? 0.0));
    return total / reviews.docs.length;
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

  Widget _buildShimmerList() {
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

  Widget _buildEmptyMessage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text("Aucun établissement trouvé",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text("Essayez d'autres filtres ou vérifiez votre position.",
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
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
          Text("Activez-la pour afficher les établissements proches.",
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filterCities.length,
            itemBuilder: (context, index) {
              final city = _filterCities[index];
              final selected = selectedFilterCity == city;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(city),
                  selected: selected,
                  onSelected: (_) => setState(() => selectedFilterCity = city),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle:
                      TextStyle(color: selected ? Colors.white : Colors.black),
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
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filterTypes.length,
            itemBuilder: (context, index) {
              final label = _filterTypes[index]['label']!;
              final value = _filterTypes[index]['value']!;
              final selected = selectedType == value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setState(() => selectedType = value),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle:
                      TextStyle(color: selected ? Colors.white : Colors.black),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceCard(
      Map<String, dynamic> data, String id, double? distance) {
    final imageUrl = (data['images'] as List?)?.first?.toString() ?? '';
    final name = data['name'] ?? 'Sans nom';
    final city = data['city'] ?? '';
    final firstPrice = getFirstPrice(data);

    return FutureBuilder<double>(
      future: _getAverageRating(id),
      builder: (context, snapshot) {
        final rating = snapshot.data ?? 0.0;
        return GestureDetector(
          onTap: () {
            final type = (data['type']?.toString().toLowerCase() ?? 'motel');
            String route = '/motelDetail';
            if (type == 'restaurant') route = '/restaurantDetail';
            if (type == 'appartement' || type == 'appartements') {
              route = '/appartementDetail';
            }

            Navigator.pushNamed(context, route, arguments: id);
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
                          fit: BoxFit.cover)
                      : Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: Icon(Icons.image, size: 60)),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      if (rating > 0)
                        Row(children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(rating.toStringAsFixed(1))
                        ]),
                      Text('$city — À partir de $firstPrice FCFA'),
                      if (distance != null)
                        Text('À ${distance.toStringAsFixed(1)} km',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Établissements proches"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          _buildFilters(),
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
                        return _buildShimmerList();
                      }

                      final placesWithDistance = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        double? distance;
                        if (data['latitude'] != null &&
                            data['longitude'] != null) {
                          distance = _calculateDistance(
                              (data['latitude'] as num).toDouble(),
                              (data['longitude'] as num).toDouble());
                        }

                        return {
                          'id': doc.id,
                          'data': data,
                          'distance': distance,
                        };
                      }).where((e) {
                        final data = e['data'] as Map<String, dynamic>;
                        final city = data['city']?.toString() ?? '';
                        final type =
                            data['type']?.toString().toLowerCase() ?? 'motel';
                        final matchCity = selectedFilterCity == 'Tous' ||
                            selectedFilterCity == city;
                        final matchType = selectedType.toLowerCase() == type;
                        return matchCity && matchType;
                      }).toList();

                      if (placesWithDistance.isEmpty)
                        return _buildEmptyMessage();

                      placesWithDistance.sort((a, b) => ((a['distance'] ??
                              double.infinity) as double)
                          .compareTo(
                              (b['distance'] ?? double.infinity) as double));

                      return ListView.builder(
                        itemCount: placesWithDistance.length,
                        itemBuilder: (context, index) {
                          final place = placesWithDistance[index];
                          return _buildPlaceCard(
                            place['data'] as Map<String, dynamic>,
                            place['id'] as String,
                            place['distance'] as double?,
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
