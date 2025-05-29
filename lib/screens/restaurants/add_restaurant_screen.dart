import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;

import '../../services/upload_service.dart';

class AddRestaurantScreen extends StatefulWidget {
  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quartierController = TextEditingController();
  final _contactController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<Map<String, dynamic>> _menuCategories = [
    {
      'name': TextEditingController(text: "Plats principaux"),
      'items': <Map<String, TextEditingController>>[
        {'label': TextEditingController(), 'price': TextEditingController()}
      ]
    }
  ];

  List<dynamic> _images = [];
  Position? _currentPosition;
  bool _isSaving = false;
  bool _locationDenied = false;

  String? _selectedCity;
  final List<String> _cities = [
    'Libreville',
    'Franceville',
    'Moanda',
    'Port-Gentil',
  ];

  Map<String, bool> features = {
    "🍽️ Menu varié": false,
    "📶 Wifi": false,
    "🌿 Terrasse": false,
    "🎶 Ambiance": false,
    "🅿️ Parking": false,
  };

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  void _addCategory() {
    setState(() {
      _menuCategories.add({
        'name': TextEditingController(),
        'items': <Map<String, TextEditingController>>[]
      });
    });
  }

  void _addItem(int catIndex) {
    setState(() {
      _menuCategories[catIndex]['items'].add({
        'label': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  Future<void> _getLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() => _locationDenied = true);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _locationDenied = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationDenied = true);
    }
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();

    if (picked.length >= 2) {
      List<dynamic> selected = [];
      for (var img in picked) {
        if (kIsWeb) {
          final bytes = await img.readAsBytes();
          selected.add(bytes);
        } else {
          selected.add(io.File(img.path));
        }
      }

      setState(() {
        _images = selected;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Merci de sélectionner au moins 2 images.')),
      );
    }
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate() ||
        _currentPosition == null ||
        _images.length < 2) return;

    setState(() => _isSaving = true);

    try {
      List<String> imageUrls = [];
      for (var img in _images) {
        final url = await uploadImageToHostinger(img);
        if (url != null) imageUrls.add(url);
      }

      if (imageUrls.length < 2) throw Exception("Upload d'images incomplet");

      // Construction du menu
      final Map<String, Map<String, int>> menu = {};
      for (var category in _menuCategories) {
        final name = category['name'].text.trim();
        if (name.isEmpty) continue;

        final items =
            category['items'] as List<Map<String, TextEditingController>>;
        final Map<String, int> catItems = {};
        for (var item in items) {
          final label = item['label']!.text.trim();
          final price = int.tryParse(item['price']!.text.trim()) ?? 0;
          if (label.isNotEmpty && price > 0) {
            catItems[label] = price;
          }
        }
        if (catItems.isNotEmpty) {
          menu[name] = catItems;
        }
      }

      await FirebaseFirestore.instance.collection('places').add({
        'name': _nameController.text.trim(),
        'city': _selectedCity,
        'quartier': _quartierController.text.trim(),
        'contact': _contactController.text.trim(),
        'features': features,
        'description': _descriptionController.text.trim(),
        'menu': menu,
        'images': imageUrls,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'createdByEmail': FirebaseAuth.instance.currentUser?.email,
        'type': 'restaurant',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Restaurant ajouté avec succès !")),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${e.toString()}")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (val) => label.toLowerCase().contains('facultatif') ||
                label.toLowerCase().contains('optionnel')
            ? null
            : val!.isEmpty
                ? "Ce champ est requis"
                : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quartierController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    _menuCategories.forEach((cat) {
      cat['name'].dispose();
      for (var item in cat['items']) {
        item['label']?.dispose();
        item['price']?.dispose();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ajouter un restaurant')),
      body: _locationDenied
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, color: Colors.red, size: 60),
                  SizedBox(height: 16),
                  Text("Activez la localisation pour ajouter."),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _getLocation,
                    icon: Icon(Icons.refresh),
                    label: Text("Réessayer"),
                  ),
                ],
              ),
            )
          : _currentPosition == null
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(_nameController, "Nom du restaurant"),
                        DropdownButtonFormField<String>(
                          value: _selectedCity,
                          items: _cities.map((city) {
                            return DropdownMenuItem(
                                value: city, child: Text(city));
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCity = val),
                          decoration: InputDecoration(labelText: "Ville"),
                          validator: (val) =>
                              val == null ? "Choisissez une ville" : null,
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        _buildTextField(_quartierController, "Quartier"),
                        _buildTextField(_contactController, "Numéro WhatsApp",
                            keyboardType: TextInputType.phone),
                        _buildTextField(
                            _descriptionController, "Description (facultatif)",
                            maxLines: 3),
                        SizedBox(height: 16),
                        Text(
                          "Menu du restaurant",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Indiquez les catégories (ex : Pizza, Boissons) et ajoutez les plats avec leurs prix.",
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey[600],
                              height: 1.4),
                        ),
                        SizedBox(height: 16),
                        ..._menuCategories.asMap().entries.map((catEntry) {
                          final i = catEntry.key;
                          final cat = catEntry.value;
                          final items = cat['items'];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                  cat['name'], "Nom de la catégorie"),
                              ...items.asMap().entries.map((entry) {
                                final j = entry.key;
                                final item = entry.value;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        item['label']!,
                                        "Plat",
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: _buildTextField(
                                        item['price']!,
                                        "Prix FCFA",
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    if (items.length > 1)
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            item['label']?.dispose();
                                            item['price']?.dispose();
                                            items.removeAt(j);
                                          });
                                        },
                                        icon: Icon(Icons.remove_circle_outline,
                                            color: Colors.red),
                                      ),
                                  ],
                                );
                              }),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _addItem(i),
                                    icon: Icon(Icons.add_circle,
                                        color: Colors.green),
                                    label: Text("Ajouter un plat",
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  if (_menuCategories.length > 1)
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline,
                                          color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          cat['name']?.dispose();
                                          for (var item in cat['items']) {
                                            item['label']?.dispose();
                                            item['price']?.dispose();
                                          }
                                          _menuCategories.removeAt(i);
                                        });
                                      },
                                    ),
                                ],
                              ),
                              Divider(),
                              Divider(),
                            ],
                          );
                        }),
                        TextButton.icon(
                          onPressed: _addCategory,
                          icon: Icon(Icons.add_box,
                              color: Theme.of(context).primaryColor),
                          label: Text("Ajouter une catégorie",
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor)),
                        ),
                        SizedBox(height: 20),
                        Text("Équipements",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: features.entries.map((entry) {
                            return FilterChip(
                              label: Text(entry.key),
                              selected: entry.value,
                              onSelected: (val) =>
                                  setState(() => features[entry.key] = val),
                              selectedColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.15),
                              backgroundColor: Colors.grey[200],
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 20),
                        TextButton.icon(
                          onPressed: _pickImages,
                          icon: Icon(Icons.image),
                          label: Text("Sélectionner les images"),
                        ),
                        if (_images.isNotEmpty)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _images.map((img) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? Image.memory(img,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover)
                                    : Image.file(img,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover),
                              );
                            }).toList(),
                          ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveRestaurant,
                          icon: Icon(Icons.save),
                          label: _isSaving
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text("Enregistrer"),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
