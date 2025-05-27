import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("À propos de nous", style: GoogleFonts.poppins()),
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(Icons.location_on, size: 72, color: AppColors.primary),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  "TrouvezMotel",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Notre mission",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "TrouvezMotel est une application conçue pour vous aider à localiser rapidement les motels disponibles autour de vous, comparer les prix et réserver facilement.",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                "Pourquoi cette application ?",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Nous avons constaté qu’il était difficile de trouver rapidement un bon motel sans perdre du temps. Avec TrouvezMotel, vous pouvez voir les photos, les prix et les notes en un seul endroit !",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                "Notre vision",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Offrir une expérience fluide et de confiance pour les utilisateurs à la recherche d’un lieu agréable, abordable et disponible dans leur ville ou quartier.",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              SizedBox(height: 30),
              Center(
                child: Text(
                  "Merci de faire partie de notre aventure ❤️",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}