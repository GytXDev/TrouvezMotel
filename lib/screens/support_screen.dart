import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import 'payment_status_screen.dart';

enum DonationMethod { mobileMoney, virement }

class SupportScreen extends StatefulWidget {
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _nameController = TextEditingController();
  final _customAmountController = TextEditingController();

  DonationMethod _selectedMethod = DonationMethod.mobileMoney;
  int? _selectedAmount;
  bool _customAmountSelected = false;
  bool _loading = false;
  bool _submitted = false;

  final NumberFormat _amountFormatter = NumberFormat.decimalPattern('fr');

  String _formatAmount(int amount) {
    return "${_amountFormatter.format(amount)} CFA";
  }

  Future<void> _submitManualDonation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final name = _nameController.text.trim();
    final amount = _customAmountSelected
        ? int.tryParse(_customAmountController.text.trim())
        : _selectedAmount;

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez entrer un montant valide")),
      );
      setState(() => _loading = false);
      return;
    }

    await FirebaseFirestore.instance.collection('donations').add({
      'name': name,
      'amount': amount,
      'method': _selectedMethod == DonationMethod.mobileMoney
          ? 'MobileMoney'
          : 'Virement',
      'validated': _selectedMethod == DonationMethod.mobileMoney,
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (_selectedMethod == DonationMethod.mobileMoney && uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'badge': 'Donateur ❤️',
      }, SetOptions(merge: true));
    }

    setState(() {
      _loading = false;
      _submitted = true;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text("Merci", style: GoogleFonts.poppins()),
          ],
        ),
        content: Text(
          "Un grand merci pour votre soutien !\n\nVous êtes désormais Donateur.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _handleMobileMoneyPayment() {
    if (!_formKey.currentState!.validate()) return;

    final numero = _numeroController.text.trim();
    final name = _nameController.text.trim();
    final amount = _customAmountSelected
        ? int.tryParse(_customAmountController.text.trim())
        : _selectedAmount;

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez entrer un montant valide")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentStatusScreen(
          numero: numero,
          amount: amount,
          name: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
          title: Text("Soutenir l'application", style: GoogleFonts.poppins())),
      body: Container(
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _submitted
              ? _buildThankYouScreen()
              : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Text(
                        "🙏 L'application TrouvezMotel est gratuite, sans publicité. Votre générosité nous aide à améliorer l’application TrouvezMotel :",
                        style: GoogleFonts.poppins(
                            fontSize: 15, color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "- Publication sur l'App Store\n"
                        "- Ajout de nouvelles fonctionnalités\n"
                        "- Maintien d'une expérience sans publicité",
                        style: GoogleFonts.poppins(color: Colors.grey[700]),
                      ),
                      SizedBox(height: 20),
                      _buildField(_nameController, "Votre nom"),
                      _buildDonationMethodSelector(),
                      SizedBox(height: 10),
                      _buildAmountSelector(),
                      SizedBox(height: 20),
                      if (_selectedMethod == DonationMethod.mobileMoney)
                        _buildField(
                          _numeroController,
                          "Numéro Mobile Money",
                          isPhone: true,
                        ),
                      SizedBox(height: 10),
                      _buildDonationButton(theme),
                      SizedBox(height: 30),
                      Text(
                        "Donateurs récents",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildDonorsList(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildThankYouScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
          SizedBox(height: 16),
          Text("Merci pour votre soutien !",
              style: GoogleFonts.poppins(fontSize: 18)),
          Text("Votre geste compte énormément.", style: GoogleFonts.poppins()),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label,
      {bool isPhone = false, bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhone
            ? TextInputType.phone
            : isNumeric
                ? TextInputType.number
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        style: GoogleFonts.poppins(),
        validator: (val) {
          if (val == null || val.trim().isEmpty) return "Champ requis";
          if (isNumeric && int.tryParse(val.trim()) == null)
            return "Nombre invalide";
          return null;
        },
      ),
    );
  }

  Widget _buildDonationMethodSelector() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile(
            title: Text("Mobile Money", style: GoogleFonts.poppins()),
            value: DonationMethod.mobileMoney,
            groupValue: _selectedMethod,
            onChanged: (val) => setState(() => _selectedMethod = val!),
          ),
        ),
        Expanded(
          child: RadioListTile(
            title: Text("Virement", style: GoogleFonts.poppins()),
            value: DonationMethod.virement,
            groupValue: _selectedMethod,
            onChanged: (val) => setState(() => _selectedMethod = val!),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSelector() {
    final chips = [500, 2000, 3000, 5000, 10000];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Montant du don",
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10, // Ajout espace vertical
          children: chips
              .map((amount) => ChoiceChip(
                    label: Text(_formatAmount(amount),
                        style: GoogleFonts.poppins()),
                    selected:
                        _selectedAmount == amount && !_customAmountSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedAmount = amount;
                        _customAmountSelected = false;
                        _customAmountController.clear();
                      });
                    },
                  ))
              .toList()
            ..add(
              ChoiceChip(
                label: Text("Autres", style: GoogleFonts.poppins()),
                selected: _customAmountSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedAmount = null;
                    _customAmountSelected = true;
                  });
                },
              ),
            ),
        ),
        if (_customAmountSelected)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _buildField(
              _customAmountController,
              "Montant personnalisé",
              isNumeric: true,
            ),
          ),
      ],
    );
  }

  Widget _buildDonationButton(ThemeData theme) {
    return ElevatedButton.icon(
      onPressed: _loading
          ? null
          : _selectedMethod == DonationMethod.mobileMoney
              ? _handleMobileMoneyPayment
              : _submitManualDonation,
      icon: Icon(
        _selectedMethod == DonationMethod.mobileMoney
            ? Icons.mobile_friendly
            : Icons.attach_money,
      ),
      label: Text(
        _selectedMethod == DonationMethod.mobileMoney
            ? "Faire un don via Mobile Money"
            : "Être contacté pour un virement",
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedMethod == DonationMethod.mobileMoney
            ? theme.primaryColor
            : Colors.grey[800],
        padding: EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildDonorsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where('validated', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.white,
            child: Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text("Aucun don pour l’instant...",
              style: GoogleFonts.poppins());
        }

        final donations = snapshot.data!.docs;

        return Column(
          children: donations.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Anonyme';
            final amount = data['amount'] ?? 0;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text(name, style: GoogleFonts.poppins()),
                subtitle: Text("A donné ${_formatAmount(amount)}",
                    style: GoogleFonts.poppins()),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}