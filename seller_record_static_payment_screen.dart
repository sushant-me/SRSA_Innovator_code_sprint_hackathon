// lib/screens/seller_record_static_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:offlinepay/constants/values.dart';
import 'package:offlinepay/models/seller_transaction.dart';
import 'package:offlinepay/services/storage_service.dart';
import 'package:offlinepay/widgets/app_button.dart';
// ignore: unnecessary_import
import 'package:flutter/foundation.dart'; // For debugPrint
import 'dart:convert'; // FIX: Added for jsonDecode and jsonEncode

class SellerRecordStaticPaymentScreen extends StatefulWidget {
  const SellerRecordStaticPaymentScreen({super.key});

  @override
  State<SellerRecordStaticPaymentScreen> createState() =>
      _SellerRecordStaticPaymentScreenState();
}

class _SellerRecordStaticPaymentScreenState
    extends State<SellerRecordStaticPaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _statusMessage = '';
  final String _currentLanguage =
      langEnglish; // FIX: Declared _currentLanguage for localization

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Function to record the static payment
  Future<void> _recordStaticPayment() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter the amount received.';
      });
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _statusMessage = 'Invalid amount entered.';
      });
      return;
    }

    // Prompt for PIN confirmation (seller's confirmation for recording)
    bool pinConfirmed = await _showPinConfirmationDialog();

    if (pinConfirmed) {
      try {
        // Add money to seller's balance
        double currentBalance = await StorageService.getSellerBalance();
        currentBalance += amount;
        await StorageService.setSellerBalance(currentBalance);

        // Record the transaction in seller's history
        // For static QR, we generate a unique TXR ID for recording purposes
        final String recordedTxrId =
            'STATIC_TXR_${DateTime.now().millisecondsSinceEpoch}';
        final String paymentRequestId =
            'STATIC_REQ_${DateTime.now().millisecondsSinceEpoch}'; // Mock request ID for static

        final newTransaction = SellerTransaction(
          txrId: recordedTxrId,
          amount: amount,
          type: 'received_static_payment',
          timestamp: DateTime.now(),
          buyerDeviceId: 'N/A (Static QR)', // Not applicable for static QR
          paymentRequestId: paymentRequestId,
          status: 'completed',
        );

        // Load existing history, add new, and save
        String historyJson = await StorageService.getSellerTransactionHistory();
        List<dynamic> decodedList = [];
        if (historyJson.isNotEmpty) {
          try {
            decodedList = jsonDecode(historyJson);
          } catch (e) {
            debugPrint('Error decoding seller transaction history: $e');
            // If corrupted, start with an empty list
            decodedList = [];
          }
        }
        decodedList.insert(0, newTransaction.toJson()); // Add to beginning
        await StorageService.setSellerTransactionHistory(
            jsonEncode(decodedList));

        setState(() {
          _statusMessage =
              'Payment of NPR ${amount.toStringAsFixed(0)} recorded successfully!';
          _amountController.clear();
        });

        // Optionally, pop back to SellerHomeScreen after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true); // Pass true to indicate success
          }
        });
      } catch (e) {
        debugPrint('Error recording static payment: $e');
        setState(() {
          _statusMessage = 'Failed to record payment: $e';
        });
      }
    } else {
      setState(() {
        _statusMessage = 'Payment recording cancelled or incorrect PIN.';
      });
    }
  }

  // Shows a PIN confirmation dialog for the seller
  Future<bool> _showPinConfirmationDialog() async {
    TextEditingController pinController = TextEditingController();
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Recording with PIN"),
            content: TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Enter your PIN"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (pinController.text == sellerPassword) {
                    // FIX: Used sellerPassword from values.dart
                    // Seller confirms with their password
                    Navigator.pop(context, true);
                  } else {
                    Navigator.pop(context, false);
                    setState(() {
                      _statusMessage =
                          statusIncorrectPin; // Reusing status, but it's seller's PIN
                    });
                  }
                },
                child: const Text("Confirm"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentLanguage == langEnglish
              ? 'Record Static Payment'
              : 'स्थिर भुक्तानी रेकर्ड गर्नुहोस्',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient (consistent with other screens)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blueGrey.shade900,
                  Colors.blueGrey.shade700,
                  Colors.blueGrey.shade500,
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code, size: 100, color: Colors.white),
                  const SizedBox(height: 30),
                  Text(
                    _currentLanguage == langEnglish
                        ? 'Enter Amount Received via Static QR'
                        : 'स्थिर QR मार्फत प्राप्त रकम प्रविष्ट गर्नुहोस्',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 24,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _currentLanguage == langEnglish
                            ? sellerQrAmountHintEnglish
                            : sellerQrAmountHintNepali,
                        labelStyle: TextStyle(color: Colors.blueGrey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        prefixIcon:
                            Icon(Icons.money, color: Colors.blueGrey[700]),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('successfully')
                          ? Colors.lightGreenAccent
                          : Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  AppButton(
                    text: _currentLanguage == langEnglish
                        ? 'Record Payment'
                        : 'भुक्तानी रेकर्ड गर्नुहोस्',
                    icon: Icons.check_circle,
                    backgroundColor: Colors.green.shade600,
                    onPressed: _recordStaticPayment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
