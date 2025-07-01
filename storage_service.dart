// lib/services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:offlinepay/constants/values.dart'; // Ensure this import path is correct and exists

class StorageService {
  static Future<double> getSellerBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(spSellerBalance) ?? 0.0;
  }

  static Future<void> setSellerBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(spSellerBalance, balance);
  }

  static Future<String> getSellerShopId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(spSellerShopId) ?? defaultShopId;
  }

  static Future<void> setSellerShopId(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(spSellerShopId, shopId);
  }

  static Future<double> getBuyerOfflineBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(spBuyerOfflineBalance) ?? 0.0;
  }

  static Future<void> setBuyerOfflineBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(spBuyerOfflineBalance, balance);
  }

  static Future<double> getBuyerTotalBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(spBuyerTotalBalance) ?? 0.0;
  }

  static Future<void> setBuyerTotalBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(spBuyerTotalBalance, balance);
  }

  static Future<double> getBuyerOnlineSecurityBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(spBuyerOnlineSecurityBalance) ??
        onlineSecurityBalance;
  }

  static Future<void> setBuyerOnlineSecurityBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(spBuyerOnlineSecurityBalance, balance);
  }

  // Methods for Buyer's Transaction History
  static Future<String> getBuyerTransactionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(spBuyerTransactionHistory) ??
        '[]'; // Default to empty JSON array string
  }

  static Future<void> setBuyerTransactionHistory(String historyJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(spBuyerTransactionHistory, historyJson);
  }

  // Methods for Seller's Transaction History
  static Future<String> getSellerTransactionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(spSellerTransactionHistory) ??
        '[]'; // Default to empty JSON array string
  }

  static Future<void> setSellerTransactionHistory(String historyJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(spSellerTransactionHistory, historyJson);
  }

  // Methods for Seller's Pending Payment Requests
  static Future<String> getSellerPendingPayments() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(spSellerPendingPayments) ??
        '[]'; // Default to empty JSON array string
  }

  static Future<void> setSellerPendingPayments(String pendingJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(spSellerPendingPayments, pendingJson);
  }

  // Method to clear all stored data for testing/reset
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
