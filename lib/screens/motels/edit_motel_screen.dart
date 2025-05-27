import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/upload_service.dart';

class EditMotelScreen extends StatefulWidget {
  final String placeId;
  EditMotelScreen({required this.placeId});

  @override
  _EditMotelScreenState createState() => _EditMotelScreenState();
}

class _EditMotelScreenState extends State<EditMotelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quartierController = TextEditingController();
  final List<String> _cities = [
    'Libreville',
    'Franceville',
    'Moanda',
    'Port-Gentil'
  ];
  String? _selectedCity;

  List<Map<String, TextEditingController>> _priceControllers = [];
  Map<String, bool> _features = {};
  List<String> _existingImages = [];
  List<dynamic> _newImages = [];

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMotelData();
  }

  Future<void> _loadMotelData() async {
    final doc = await FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .get();
    final data = doc.data() as Map<String, dynamic>;

    final prices = (data['prices'] as Map<String, dynamic>?) ?? {};
    final features = (data['features'] as Map<String, dynamic>?) ?? {};
    final images = (data['images'] as List?) ?? [];

    setState(() {
      _nameController.text = data['name'] ?? '';
      _quartierController.text = data['quartier'] ?? '';
      _selectedCity = data['city'];

      _priceControllers = prices.entries.map((e) {
        return {
          'label': TextEditingController(text: e.key),
          'price': TextEditingController(text: e.value.toString())
        };
      }).toList();

      _features = {
        for (var entry in features.entries) entry.key: entry.value == true
      };

      _existingImages = List<String>.from(images);
      _loading = false;
    });
  }

  void _addPriceField() {
    setState(() {
      _priceControllers.add(
          {'label': TextEditingController(), 'price': TextEditingController()});
    });
  }

  void _removePriceField(int index) {
    setState(() => _priceControllers.removeAt(index));
  }

  Future<void> _removeExistingImage(int index) async {
    if (_existingImages.length + _newImages.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Au moins 2 images sont requises.")));
      return;
    }

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

  Future<void> _updateMotel() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (name.isEmpty || _priceControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Nom et au moins un tarif sont obligatoires.")));
      return;
    }

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

      final prices = {
        for (var entry in _priceControllers)
          if (entry['label']!.text.isNotEmpty &&
              entry['price']!.text.isNotEmpty)
            entry['label']!.text: int.tryParse(entry['price']!.text.trim()) ?? 0
      };

      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .update({
        'name': name,
        'city': _selectedCity,
        'quartier': _quartierController.text.trim(),
        'prices': prices,
        'features': _features,
        'images': allImages,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Modifications enregistrées")));
      Navigator.pop(context);
    } catch (e) {
      print("Erreur : $e");
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
        validator: (val) => val!.isEmpty ? "Champ requis" : null,
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
    _priceControllers.forEach((c) {
      c['label']?.dispose();
      c['price']?.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Modifier le motel")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(_nameController, "Nom du motel"),
                    SizedBox(height: 10),
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
                    SizedBox(height: 20),
                    _buildInputField(_quartierController, "Quartier"),
                    SizedBox(height: 16),
                    Text("Tarifs",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ..._priceControllers.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                                child: _buildInputField(
                                    item['label']!, "Libellé")),
                            SizedBox(width: 10),
                            Expanded(
                                child: _buildInputField(
                                    item['price']!, "Prix (FCFA)",
                                    type: TextInputType.number)),
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
                              onPressed: () => _removePriceField(i),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                    TextButton.icon(
                        onPressed: _addPriceField,
                        icon: Icon(Icons.add),
                        label: Text("Ajouter un tarif")),
                    SizedBox(height: 20),
                    Text("Équipements",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
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
                      onPressed: _saving ? null : _updateMotel,
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
