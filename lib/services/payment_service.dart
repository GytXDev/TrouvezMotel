import 'dart:convert';
import 'package:http/http.dart' as http;

/// Les types de messages possibles retournés par l'API Mobile Money
enum MessageType {
  InvalidPinLength,
  InsufficientBalance,
  IncorrectPin,
  SuccessfulTransaction,
  CancelledTransaction,
  Unknown,
}

class PaymentService {
  /// Fonction d'appel à l'API de paiement
  static Future<String?> makeMobileMoneyPayment(String numero, int amount) async {
    final url = Uri.parse('https://gytx.dev/api/airtelmoney-web.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'numero': numero,
          'amount': amount.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status_message'] ?? "Message vide";
      } else {
        return "Erreur serveur : ${response.statusCode}";
      }
    } catch (e) {
      return "Erreur réseau : $e";
    }
  }

  /// Interpréter le message retourné par l'API en type
  static MessageType interpretMessage(String message) {
    message = message.toLowerCase(); // Normalize
    if (message.contains('invalid pin length')) {
      return MessageType.InvalidPinLength;
    } else if (message.contains('solde insuffisant')) {
      return MessageType.InsufficientBalance;
    } else if (message.contains('incorrect four digit pin')) {
      return MessageType.IncorrectPin;
    } else if (message.contains('transaction a ete effectue avec succes') ||
        message.contains('your transaction has been successfully processed')) {
      return MessageType.SuccessfulTransaction;
    } else if (message.contains('transaction a ete annulee avec succes')) {
      return MessageType.CancelledTransaction;
    } else {
      return MessageType.Unknown;
    }
  }
}
