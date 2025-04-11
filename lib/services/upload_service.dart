import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart'; // pour kIsWeb
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; 

Future<String?> uploadImageToHostinger(dynamic image) async {
  final uri = Uri.parse('https://gytx.dev/api/upload_image.php');

  try {
    final request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      // 🕸 Web: image = Uint8List
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        image,
        filename: 'web_image.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    } else {
      // 📱 Mobile: image = File
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        (image as io.File).path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final decoded = jsonDecode(responseBody);
      if (decoded['success'] == true && decoded['url'] != null) {
        return decoded['url'];
      } else {
        print('Erreur serveur: ${decoded['message']}');
        return null;
      }
    } else {
      print('Erreur HTTP: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Erreur lors de l’upload: $e');
    return null;
  }
}

Future<void> deleteImageFromHostinger(String imageUrl) async {
  try {
    final filename = imageUrl.split('/').last;

    final response = await http.post(
      Uri.parse('https://gytx.dev/api/delete_image.php'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"filename": filename}),
    );

    final result = jsonDecode(response.body);
    if (result['success'] != true) {
      print("Erreur suppression image : ${result['message']}");
    }
  } catch (e) {
    print("Erreur réseau lors de la suppression : $e");
  }
}
