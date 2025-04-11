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

  void _submitReview(String motelId) async {
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

    await FirebaseFirestore.instance.collection('reviews').add({
      'motelId': motelId,
      'userId': userId,
      'userName': userName,
      'comment': _commentController.text.trim(),
      'rating': _rating,
      'createdAt': FieldValue.serverTimestamp(),
      'timestampBackup': DateTime.now().toIso8601String(),
    });

    Navigator.pushReplacementNamed(context, '/thankYou');
  }

  @override
  Widget build(BuildContext context) {
    final String motelId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: Text("Donner un avis")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Votre expérience",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Notez ce motel",
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
            SizedBox(height: 24),
            Text("Commentaire",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Partagez ce que vous avez apprécié ou non...",
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
                    : Text("Envoyer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : () => _submitReview(motelId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
