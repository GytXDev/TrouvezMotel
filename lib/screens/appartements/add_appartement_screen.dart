import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;

import '../../services/upload_service.dart';

class AddAppartementScreen extends StatefulWidget {
  @override
  State<AddAppartementScreen> createState() => _AddAppartementScreenState();
}

class _AddAppartementScreenState extends State<AddAppartementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quartierController = TextEditingController();
  final _contactController = TextEditingController();
  final _descriptionController = TextEditingController();

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
    "📶 Wifi": false,
    "🛏️ Meublé": false,
    "🌇 Balcon": false,
    "🛁 Douche interne": false,
    "🧼 Propre": false,
    "🚿 Eau": false,
    "📦 Avec charges": false,
    "🚫 Sans charges": false,
    "🅿️ Parking": false,
    "🔒 Sécurisé": false,
  };

  @override
  void initState() {
    super.initState();
    _getLocation();
    _addPriceField();
  }

  void _addPriceField() {
    setState(() {
      _dynamicPrices.add({
        'label': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  void _removePriceField(int index) {
    setState(() => _dynamicPrices.removeAt(index));
  }

  Future<void> _getLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _locationDenied = true);
      return;
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

      setState(() => _images = selected);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Merci de sélectionner au moins 2 images.')),
      );
    }
  }

  Future<void> _saveAppartement() async {
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

      final prices = {
        for (var item in _dynamicPrices)
          if (item['label']!.text.isNotEmpty && item['price']!.text.isNotEmpty)
            item['label']!.text: int.tryParse(item['price']!.text.trim()) ?? 0,
      };

      await FirebaseFirestore.instance.collection('places').add({
        'name': _nameController.text.trim(),
        'city': _selectedCity,
        'quartier': _quartierController.text.trim(),
        'contact': _contactController.text.trim(),
        'description': _descriptionController.text.trim(),
        'features': features,
        'prices': prices,
        'images': imageUrls,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'createdByEmail': FirebaseAuth.instance.currentUser?.email,
        'type': 'appartement',
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Ajouté !"),
          content: Text("L'appartement a été enregistré avec succès."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/main', (_) => false),
              child: Text("OK"),
            )
          ],
        ),
      );
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
    _descriptionController.dispose();
    _dynamicPrices.forEach((map) {
      map['label']?.dispose();
      map['price']?.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ajouter un appartement')),
      body: _locationDenied
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text("Activez la localisation pour continuer."),
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
                        _buildTextField(
                            _nameController, "Nom de l'appartement"),
                        DropdownButtonFormField<String>(
                          value: _selectedCity,
                          items: _cities
                              .map((city) => DropdownMenuItem(
                                  value: city, child: Text(city)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCity = val),
                          decoration: InputDecoration(labelText: "Ville"),
                          validator: (val) =>
                              val == null ? "Choisissez une ville" : null,
                        ),
                        _buildTextField(_quartierController, "Quartier"),
                        _buildTextField(_contactController, "Numéro WhatsApp",
                            keyboardType: TextInputType.phone),
                        _buildTextField(
                            _descriptionController, "Description (facultatif)",
                            maxLines: 3),
                        SizedBox(height: 16),
                        Text("Tarifs",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        ..._dynamicPrices.asMap().entries.map((entry) {
                          final i = entry.key;
                          final field = entry.value;
                          return Row(
                            children: [
                              Expanded(
                                child: _buildTextField(field['label']!,
                                    "Libellé (ex : nuit, mois)"),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _buildTextField(
                                    field['price']!, "Prix FCFA",
                                    keyboardType: TextInputType.number),
                              ),
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline,
                                    color: Colors.red),
                                onPressed: () => _removePriceField(i),
                              )
                            ],
                          );
                        }),
                        TextButton.icon(
                          icon: Icon(Icons.add),
                          label: Text("Ajouter un tarif"),
                          onPressed: _addPriceField,
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
                            padding: const EdgeInsets.only(top: 8),
                            child: Text("Ajoutez au moins 2 images.",
                                style: TextStyle(color: Colors.red)),
                          ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: Icon(Icons.save),
                          label: _isSaving
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text("Enregistrer"),
                          onPressed: _isSaving ? null : _saveAppartement,
                        )
                      ],
                    ),
                  ),
                ),
    );
  }
}
