// lib/models/transaction.dart
//import 'package:flutter/foundation.dart'; // For debugPrint

class Transaction {
  final String id; // Unique ID for each transaction
  final double amount;
  final String type; // e.g., 'payment', 'topup'
  final DateTime timestamp;
  final String? shopId; // For payment transactions
  final String status; // e.g., 'completed', 'pending', 'failed'

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.timestamp,
    this.shopId,
    this.status = 'completed', // Default status
  });

  // Convert Transaction object to JSON (for SharedPreferences)
  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type,
    'timestamp': timestamp.toIso8601String(), // ISO 8601 for easy parsing
    'shopId': shopId,
    'status': status,
  };

  // Create Transaction object from JSON (from SharedPreferences)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'],
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
      shopId: json['shopId'],
      status: json['status'],
    );
  }
}
