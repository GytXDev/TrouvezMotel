import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddReviewScreen extends StatefulWidget {
  @override
  _AddReviewScreenState createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSaving = false;

  void _submitReview(String placeId, String type) async {
    if (_rating == 0 || _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Merci de noter et commenter.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    if (userId == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userName = userDoc.data()?['name'] ?? 'Utilisateur';
    final photoURL = user?.photoURL;

    await FirebaseFirestore.instance.collection('reviews').add({
      'placeId': placeId,
      'type': type,
      'userId': userId,
      'userName': userName,
      'comment': _commentController.text.trim(),
      'rating': _rating,
      'createdAt': FieldValue.serverTimestamp(),
      'timestampBackup': DateTime.now().toIso8601String(),
      'photoURL': photoURL,
    });

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/thankYou');
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String placeId = args['placeId'];
    final String type = args['type']; // 'motel', 'restaurant', 'appartement'

    return Scaffold(
      appBar: AppBar(title: Text("Donner un avis")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📝 Votre avis compte",
                style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 10),
            Text(
              "Aidez les autres utilisateurs à faire le bon choix en partageant votre expérience.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Notez ce lieu",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setState(() => _rating = i + 1),
                      );
                    }),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Text("Comment avez-vous trouvé ce lieu ?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText:
                    "Parlez de votre séjour, du service, des équipements...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.send),
                label: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text("Partager mon avis"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed:
                    _isSaving ? null : () => _submitReview(placeId, type),
              ),
            ),
          ],
        ),
      ),
    );
  }
}