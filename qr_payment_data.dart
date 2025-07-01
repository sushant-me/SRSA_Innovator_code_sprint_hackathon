// lib/models/qr_payment_data.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'; // FIX: Added for debugPrint

class QRPaymentData {
  final double amount;
  final String
      transactionId; // This is ALWAYS the seller's unique paymentRequestId (e.g., REQ...)
  final String shopId;
  final String?
      buyerDeviceId; // Optional: For buyer's TXR QR, indicates the buyer's device
  final String?
      buyerTxrId; // NEW: The buyer's unique transaction ID (e.g., TXZ...)

  QRPaymentData({
    required this.amount,
    required this.transactionId, // This is the seller's paymentRequestId
    required this.shopId,
    this.buyerDeviceId, // Optional parameter
    this.buyerTxrId, // New optional parameter
  });

  // Convert QRPaymentData object to a QR string
  String toQRString() {
    final Map<String, dynamic> data = {
      'amount': amount,
      'transactionId': transactionId, // This is the seller's REQ ID
      'shopId': shopId,
    };
    if (buyerDeviceId != null) {
      data['buyerDeviceId'] = buyerDeviceId;
    }
    if (buyerTxrId != null) {
      // Include buyerTxrId if present
      data['buyerTxrId'] = buyerTxrId;
    }
    return jsonEncode(data);
  }

  // Create QRPaymentData object from a QR string
  static QRPaymentData? fromQRString(String qrString) {
    try {
      final Map<String, dynamic> json = jsonDecode(qrString);
      return QRPaymentData(
        amount: (json['amount'] as num).toDouble(),
        transactionId:
            json['transactionId'], // This will be the seller's REQ ID
        shopId: json['shopId'],
        buyerDeviceId: json['buyerDeviceId'], // Nullable
        buyerTxrId: json['buyerTxrId'], // Nullable
      );
    } catch (e) {
      debugPrint('Error parsing QR Payment Data: $e'); // debugPrint used here
      return null;
    }
  }
}
