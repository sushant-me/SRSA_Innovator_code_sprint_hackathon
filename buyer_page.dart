import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BuyerPage extends StatefulWidget {
  const BuyerPage({Key? key}) : super(key: key);

  @override
  State<BuyerPage> createState() => _BuyerPageState();
}

class _BuyerPageState extends State<BuyerPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String? qrData;

  void _generateQR() {
    final name = _nameController.text.trim();
    final amount = _amountController.text.trim();

    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    // You can customize the QR data format (JSON-like for now)
    setState(() {
      qrData = 'Buyer: ${name.isEmpty ? "Anonymous" : name}, Amount: Rs.$amount';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buyer QR Generator')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Buyer Name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (Rs)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateQR,
              child: const Text('Generate QR Code'),
            ),
            const SizedBox(height: 20),
            if (qrData != null)
              QrImageView(
                data: qrData!,
                version: QrVersions.auto,
                size: 250.0,
              ),
          ],
        ),
      ),
    );
  }
}
