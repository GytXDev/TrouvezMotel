import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/upload_service.dart';

class EditRestaurantScreen extends StatefulWidget {
  final String placeId;
  EditRestaurantScreen({required this.placeId});

  @override
  _EditRestaurantScreenState createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quartierController = TextEditingController();
  final _contactController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _menuCategories = [];
  Map<String, bool> _features = {};
  List<String> _existingImages = [];
  List<dynamic> _newImages = [];

  String? _selectedCity;
  final List<String> _cities = [
    'Libreville',
    'Franceville',
    'Moanda',
    'Port-Gentil'
  ];

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    final doc = await FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .get();
    final data = doc.data() as Map<String, dynamic>;

    final menu = (data['menu'] as Map<String, dynamic>?) ?? {};
    final features = (data['features'] as Map<String, dynamic>?) ?? {};
    final images = (data['images'] as List?) ?? [];

    setState(() {
      _nameController.text = data['name'] ?? '';
      _quartierController.text = data['quartier'] ?? '';
      _contactController.text = data['contact'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _selectedCity = data['city'];

      _menuCategories = menu.entries.map((cat) {
        final items = (cat.value as Map<String, dynamic>);
        return {
          'name': TextEditingController(text: cat.key),
          'items': items.entries
              .map((e) => {
                    'label': TextEditingController(text: e.key),
                    'price': TextEditingController(text: e.value.toString())
                  })
              .toList()
        };
      }).toList();

      _features = {
        for (var entry in features.entries) entry.key: entry.value == true
      };

      _existingImages = List<String>.from(images);
      _loading = false;
    });
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

  Future<void> _removeExistingImage(int index) async {
    final url = _existingImages[index];
    await deleteImageFromHostinger(url);
    setState(() => _existingImages.removeAt(index));
  }

  Future<void> _pickNewImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty) {
      List<dynamic> selected = [];
      for (var img in picked) {
        selected.add(kIsWeb ? await img.readAsBytes() : io.File(img.path));
      }
      setState(() => _newImages = selected);
    }
  }

  Future<void> _updateRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    try {
      List<String> allImages = List.from(_existingImages);

      for (var img in _newImages) {
        final url = await uploadImageToHostinger(img);
        if (url != null) allImages.add(url);
      }

      if (allImages.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Merci de garder au moins 2 images.")));
        return;
      }

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

      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .update({
        'name': _nameController.text.trim(),
        'city': _selectedCity,
        'quartier': _quartierController.text.trim(),
        'contact': _contactController.text.trim(),
        'features': _features,
        'description': _descriptionController.text.trim(),
        'menu': menu,
        'images': allImages,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Modifications enregistrées")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur : ${e.toString()}")));
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  Widget _buildInputField(TextEditingController controller, String label,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        validator: (val) => label.toLowerCase().contains('facultatif') ||
                label.toLowerCase().contains('optionnel')
            ? null
            : val!.isEmpty
                ? "Ce champ est requis"
                : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
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
      appBar: AppBar(title: Text("Modifier le restaurant")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(_nameController, "Nom du restaurant"),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      items: _cities
                          .map((city) =>
                              DropdownMenuItem(value: city, child: Text(city)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedCity = val),
                      decoration: InputDecoration(
                        labelText: "Ville",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (val) =>
                          val == null ? "Choisissez une ville" : null,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    _buildInputField(_quartierController, "Quartier"),
                    _buildInputField(_contactController, "Numéro WhatsApp",
                        type: TextInputType.phone),
                    _buildInputField(
                        _descriptionController, "Description (facultatif)",
                        maxLines: 3),
                    SizedBox(height: 16),
                    Text("Menu",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 16),
                    ..._menuCategories.asMap().entries.map((catEntry) {
                      final i = catEntry.key;
                      final cat = catEntry.value;
                      final items = cat['items'];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputField(cat['name'], "Nom de la catégorie"),
                          ...items.asMap().entries.map((entry) {
                            final j = entry.key;
                            final item = entry.value;
                            return Row(
                              children: [
                                Expanded(
                                  child:
                                      _buildInputField(item['label']!, "Plat"),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: _buildInputField(
                                      item['price']!, "Prix FCFA",
                                      type: TextInputType.number),
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
                          TextButton.icon(
                            onPressed: () => _addItem(i),
                            icon: Icon(Icons.add_circle, color: Colors.green),
                            label: Text("Ajouter un plat",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Divider(),
                        ],
                      );
                    }),
                    TextButton.icon(
                      onPressed: _addCategory,
                      icon: Icon(Icons.add_box,
                          color: Theme.of(context).primaryColor),
                      label: Text("Ajouter une catégorie",
                          style:
                              TextStyle(color: Theme.of(context).primaryColor)),
                    ),
                    SizedBox(height: 20),
                    Text("Équipements",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _features.entries.map((entry) {
                        return FilterChip(
                          label: Text(entry.key),
                          selected: entry.value,
                          onSelected: (val) =>
                              setState(() => _features[entry.key] = val),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 24),
                    Text("Images actuelles",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _existingImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final url = entry.value;
                        return Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                'https://gytx.dev/api/image-proxy.php?url=$url',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removeExistingImage(index),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close,
                                    size: 12, color: Colors.white),
                              ),
                            )
                          ],
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    Text("Ajouter d'autres images",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                        onPressed: _pickNewImages,
                        icon: Icon(Icons.image),
                        label: Text("Sélectionner des images")),
                    if (_newImages.isNotEmpty)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _newImages.map((img) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.memory(img,
                                    width: 80, height: 80, fit: BoxFit.cover)
                                : Image.file(img,
                                    width: 80, height: 80, fit: BoxFit.cover),
                          );
                        }).toList(),
                      ),
                    SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _updateRestaurant,
                      icon: Icon(Icons.save),
                      label: _saving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text("Enregistrer les modifications"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
