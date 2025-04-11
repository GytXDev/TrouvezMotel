import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;

import '../services/upload_service.dart';

class AddMotelScreen extends StatefulWidget {
  @override
  State<AddMotelScreen> createState() => _AddMotelScreenState();
}

class _AddMotelScreenState extends State<AddMotelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quartierController = TextEditingController();
  final _contactController = TextEditingController();

  List<Map<String, TextEditingController>> _dynamicPrices = [];
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
    "❄️ Clim": false,
    "📶 Wifi": false,
    "📺 Télévision": false,
    "🧼 Propre": false,
    "🍾 Champagne": false,
    "🛁 Jacuzzi": false,
    "🛎️ Room Service": false,
    "🅿️ Parking": false,
  };

  @override
  void initState() {
    super.initState();
    _getLocation();
    _addPriceField();
  }

  void _addPriceField() {
    setState(() {
      _dynamicPrices.add(
          {'label': TextEditingController(), 'price': TextEditingController()});
    });
  }

  void _removePriceField(int index) {
    setState(() {
      _dynamicPrices.removeAt(index);
    });
  }

  Future<void> _getLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        setState(() => _locationDenied = true);
        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _locationDenied = false;
      });
    } catch (_) {
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

  Future<void> _saveMotel() async {
    if (!_formKey.currentState!.validate() ||
        _currentPosition == null ||
        _images.length < 2) return;

    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      List<String> imageUrls = [];

      for (var img in _images) {
        final imageData = kIsWeb ? img : img;
        final url = await uploadImageToHostinger(imageData);
        if (url != null) imageUrls.add(url);
      }

      if (imageUrls.length < 2) {
        throw Exception("Échec de l’upload des images");
      }

      final prices = {
        for (var item in _dynamicPrices)
          if (item['label']!.text.isNotEmpty && item['price']!.text.isNotEmpty)
            item['label']!.text: int.tryParse(item['price']!.text) ?? 0
      };

      await FirebaseFirestore.instance.collection('motels').add({
        'name': _nameController.text.trim(),
        'city': _selectedCity,
        'quartier': _quartierController.text.trim(),
        'contact': _contactController.text.trim(),
        'features': features,
        'prices': prices,
        'images': imageUrls,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'createdByEmail': FirebaseAuth.instance.currentUser?.email,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Motel ajouté avec succès !")),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } catch (e) {
      if (!mounted) return;
      print("Erreur : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${e.toString()}")),
      );
    } finally {
      if (!mounted) return;
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
        validator: (val) => val!.isEmpty ? "Ce champ est requis" : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quartierController.dispose();
    _contactController.dispose();
    _dynamicPrices.forEach((map) {
      map['label']?.dispose();
      map['price']?.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un motel'),
        automaticallyImplyLeading: false,
      ),
      body: _locationDenied
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, color: Colors.red, size: 60),
                  SizedBox(height: 16),
                  Text("La localisation est nécessaire pour ajouter un motel."),
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
                        _buildTextField(_nameController, "Nom du motel"),
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
                        SizedBox(height: 16),
                        _buildTextField(_quartierController, "Quartier"),
                        _buildTextField(_contactController, "Numéro WhatsApp",
                            keyboardType: TextInputType.phone),
                        SizedBox(height: 16),
                        Text("Tarifs",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        ..._dynamicPrices.asMap().entries.map((entry) {
                          final index = entry.key;
                          final fields = entry.value;
                          return Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                    fields['label']!, "Libellé (ex : 1h, 3h)",
                                    keyboardType: TextInputType.text),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _buildTextField(
                                    fields['price']!, "Prix (FCFA)",
                                    keyboardType: TextInputType.number),
                              ),
                              IconButton(
                                onPressed: () => _removePriceField(index),
                                icon: Icon(Icons.remove_circle_outline,
                                    color: Colors.red),
                              )
                            ],
                          );
                        }).toList(),
                        TextButton.icon(
                          onPressed: _addPriceField,
                          icon: Icon(Icons.add),
                          label: Text("Ajouter un tarif"),
                        ),
                        SizedBox(height: 16),
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
                              labelStyle: TextStyle(
                                color: entry.value
                                    ? Theme.of(context).primaryColor
                                    : Colors.black,
                              ),
                              backgroundColor: Colors.grey[200],
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: entry.value
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 20),
                        TextButton.icon(
                          icon: Icon(Icons.image),
                          label: Text("Sélectionner les images"),
                          onPressed: _pickImages,
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
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("Sélectionnez au moins 2 images."),
                          ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveMotel,
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
