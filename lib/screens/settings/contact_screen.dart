import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  final String supportEmail = 'support@gytx.dev';
  final String partnershipEmail = 'partenariats@gytx.dev';

  void _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Message depuis TrouvezMotel',
    );

    if (!await launchUrl(emailUri)) {
      throw Exception('Impossible d’ouvrir le client email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Contact")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.support_agent, color: Colors.blue),
              title: Text(supportEmail),
              subtitle: Text("Support et assistance"),
              onTap: () => _sendEmail(supportEmail),
            ),
            ListTile(
              leading: Icon(Icons.business_center, color: Colors.teal),
              title: Text(partnershipEmail),
              subtitle: Text("Propositions de partenariat"),
              onTap: () => _sendEmail(partnershipEmail),
            ),
          ],
        ),
      ),
    );
  }
}
