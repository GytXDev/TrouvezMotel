import 'package:flutter/material.dart';

class ThankYouScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 80, color: Colors.amber),
              SizedBox(height: 20),
              Text(
                "Merci pour votre avis !",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                "Votre retour aide les autres à faire un bon choix ✨",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/main')),
                icon: Icon(Icons.home),
                label: Text("Retour à l'accueil"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
