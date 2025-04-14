import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class ThankYouScreen extends StatefulWidget {
  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play(); // lance les confettis
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, size: 90, color: Colors.amber),
                    SizedBox(height: 24),
                    Text(
                      "Merci pour votre avis !",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Votre retour aide toute la communauté à faire le bon choix ✨\nC’est grâce à vous qu’on avance !",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.popUntil(
                          context, ModalRoute.withName('/main')),
                      icon: Icon(Icons.home_rounded),
                      label: Text("Retour à l’accueil"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🎉 Confettis
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            maxBlastForce: 10,
            minBlastForce: 5,
            shouldLoop: false,
            colors: [
              Colors.amber,
              Colors.green,
              Colors.pink,
              Colors.blue,
              Colors.orange,
            ],
          ),
        ],
      ),
    );
  }
}