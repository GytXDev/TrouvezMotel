import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class LoginScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  final Uri _privacyUri =
      Uri.parse('https://gytx.dev/trouvezmotel/privacy_policy.html');

  Future<void> _launchPrivacyPolicy() async {
    if (!await launchUrl(_privacyUri, mode: LaunchMode.externalApplication)) {
      throw Exception('Impossible d’ouvrir $_privacyUri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_rounded,
                  size: 72, color: AppColors.primary),
              Text(
                'TrouvezMotel',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Explorez. Comparez. Réservez.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.deepPurple[300],
                ),
              ),
              SizedBox(height: 48),
              ElevatedButton.icon(
                icon: Image.asset('assets/google_icon.png', height: 24),
                label: Text(
                  'Continuer avec Google',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                onPressed: () async {
                    try {
                      final credential = await _authService.signInWithGoogle();
                      final user = credential?.user;

                      if (user != null) {
                        final isCompleted =
                            await _authService.isProfileCompleted(user.uid);
                        Navigator.pushReplacementNamed(context,
                            isCompleted ? '/main' : '/completeProfile');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("Connexion annulée ou échouée.")),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Erreur de connexion : $e")),
                      );
                    }
                  }


              ),
              SizedBox(height: 16),

              /// ✅ Politique de confidentialité
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text.rich(
                  TextSpan(
                    text: "En continuant, vous acceptez notre ",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    children: [
                      TextSpan(
                        text: "politique de confidentialité",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.deepPurple,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = _launchPrivacyPolicy,
                      ),
                      TextSpan(
                        text: " et nos conditions d'utilisation.",
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 24),
              Text(
                '* Un compte est créé automatiquement si vous êtes nouveau',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
