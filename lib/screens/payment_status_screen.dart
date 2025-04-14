import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';

import '../services/notification_service.dart';
import '../services/payment_service.dart';
import '../theme.dart';

class PaymentStatusScreen extends StatefulWidget {
  final String numero;
  final int amount;
  final String name;

  const PaymentStatusScreen({
    required this.numero,
    required this.amount,
    required this.name,
  });

  @override
  _PaymentStatusScreenState createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  late Future<Map<String, dynamic>> _paymentFuture;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 2));
    _paymentFuture = _processPayment();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _processPayment() async {
    final message = await PaymentService.makeMobileMoneyPayment(
        widget.numero, widget.amount);
    final type = PaymentService.interpretMessage(message ?? "");

    if (type == MessageType.SuccessfulTransaction) {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance.collection('donations').add({
        'name': widget.name,
        'amount': widget.amount,
        'method': 'Mobile Money',
        'validated': true,
        'userId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.showThankYouNotification(
          widget.name, widget.amount);

      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'badge': 'Donateur ❤️',
        }, SetOptions(merge: true));
      }

      _confettiController.play();
    }

    return {
      'message': message ?? "Réponse vide",
      'type': type,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text("Paiement en cours")),
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _paymentFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 20),
                      Text("Vérification du paiement...",
                          style: textTheme.bodyMedium),
                    ],
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return _buildResultCard(
                  icon: Icons.error,
                  color: AppColors.error,
                  title: "Erreur",
                  message:
                      snapshot.error?.toString() ?? "Erreur inconnue",
                  context: context,
                );
              }

              final message = snapshot.data!['message'];
              final type = snapshot.data!['type'] as MessageType;

              IconData icon;
              Color color;
              String title;

              switch (type) {
                case MessageType.SuccessfulTransaction:
                  icon = Icons.check_circle;
                  color = AppColors.success;
                  title = "Merci pour votre soutien ❤️";
                  break;
                case MessageType.InsufficientBalance:
                  icon = Icons.warning_amber_rounded;
                  color = Colors.orange;
                  title = "Solde insuffisant 😢";
                  break;
                case MessageType.IncorrectPin:
                  icon = Icons.lock_outline;
                  color = Colors.deepOrange;
                  title = "PIN incorrect";
                  break;
                case MessageType.InvalidPinLength:
                  icon = Icons.error_outline;
                  color = Colors.orangeAccent;
                  title = "PIN invalide";
                  break;
                case MessageType.CancelledTransaction:
                  icon = Icons.cancel;
                  color = Colors.grey;
                  title = "Transaction annulée";
                  break;
                case MessageType.Unknown:
                default:
                  icon = Icons.info_outline;
                  color = Colors.blueGrey;
                  title = "Résultat inconnu";
                  break;
              }

              return _buildResultCard(
                icon: icon,
                color: color,
                title: title,
                message: message,
                context: context,
              );
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.08,
              numberOfParticles: 30,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required BuildContext context,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 60),
              SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall),
              SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.arrow_back),
                label: Text("Retour à Mon Compte"),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/main',
                    (route) => false,
                    arguments: 2, // 👈 Aller directement à "Compte"
                  );

                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}