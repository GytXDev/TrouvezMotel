import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final Uri _privacyUri =
      Uri.parse('https://gytx.dev/trouvezmotel/privacy_policy.html');

  // 🔹 Pour email/password
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false; // bascule inscription/connexion

  Future<void> _launchPrivacyPolicy() async {
    if (!await launchUrl(_privacyUri, mode: LaunchMode.externalApplication)) {
      throw Exception('Impossible d’ouvrir $_privacyUri');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez entrer un email et un mot de passe.")),
      );
      return;
    }

    try {
      UserCredential credential;
      if (_isSignUp) {
        // Mode inscription
        credential = await _authService.signUpWithEmail(email, password);
      } else {
        // Mode connexion
        credential = await _authService.signInWithEmail(email, password);
      }

      final user = credential.user;
      if (user != null) {
        // On vérifie si le profil est complet ou non
        final isCompleted = await _authService.isProfileCompleted(user.uid);
        Navigator.pushReplacementNamed(
          context,
          isCompleted ? '/main' : '/completeProfile',
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.message}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
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

                // Bouton Google
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
                        Navigator.pushReplacementNamed(
                            context, isCompleted ? '/main' : '/completeProfile');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Connexion annulée ou échouée.")),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Erreur de connexion : $e")),
                      );
                    }
                  },
                ),
                SizedBox(height: 16),

                // OU
                Text("OU", style: TextStyle(color: Colors.grey[700])),

                SizedBox(height: 16),
                // Champs email/password
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Mot de passe",
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _handleEmailAuth,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isSignUp ? "S'inscrire" : "Se connecter",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                ),
                SizedBox(height: 8),
                // Lien pour basculer inscription / connexion
                TextButton(
                  onPressed: () {
                    setState(() => _isSignUp = !_isSignUp);
                  },
                  child: Text(
                    _isSignUp
                        ? "Déjà un compte ? Se connecter"
                        : "Pas de compte ? S'inscrire",
                    style: TextStyle(color: AppColors.primary),
                  ),
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
      ),
    );
  }
}
