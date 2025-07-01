// lib/screens/seller_home_screen.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:offlinepay/constants/values.dart';
import 'package:offlinepay/models/qr_payment_data.dart';
import 'package:offlinepay/services/storage_service.dart';
import 'package:offlinepay/utils/qr_scanner_utility.dart';
import 'package:offlinepay/widgets/app_button.dart';
import 'package:offlinepay/models/seller_transaction.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:offlinepay/screens/welcome_screen.dart'; // Import WelcomeScreen for logout

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  SellerHomeScreenState createState() => SellerHomeScreenState();
}

class SellerHomeScreenState extends State<SellerHomeScreen> {
  String _shopId = defaultShopId;
  double _sellerBalance = 0.0;
  String _mode = 'Offline';
  // ignore: unused_field
  String _status = statusWelcomeSeller;
  bool _isSyncing = false;

  final TextEditingController _amountController = TextEditingController();
  String _generatedPaymentQrData = '';

  String _currentLanguage = langEnglish;

  List<SellerTransaction> _sellerTransactionHistory = [];
  Set<String> _processedTxrIds = {};

  List<PendingPaymentRequest> _pendingPaymentRequests = [];

  StreamSubscription? _connectivitySubscription;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTopButton = false;

  @override
  void initState() {
    super.initState();
    _initializeSellerData();
    _startConnectivityMonitoring();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _connectivitySubscription?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= 200 && !_showScrollToTopButton) {
      setState(() {
        _showScrollToTopButton = true;
      });
    } else if (_scrollController.position.pixels < 200 &&
        _showScrollToTopButton) {
      setState(() {
        _showScrollToTopButton = false;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _initializeSellerData() async {
    _shopId = await StorageService.getSellerShopId();
    _sellerBalance = await StorageService.getSellerBalance();
    await _loadSellerTransactionHistory();
    await _loadPendingPaymentRequests();

    if (_sellerBalance == 0.0) {
      _sellerBalance = initialSellerLoadAmount;
      await StorageService.setSellerBalance(_sellerBalance);
    }
    setState(() {});
    _checkConnectivity();
  }

  Future<void> _saveSellerData() async {
    await StorageService.setSellerBalance(_sellerBalance);
    await StorageService.setSellerShopId(_shopId);
  }

  Future<void> _loadSellerTransactionHistory() async {
    final historyJson = await StorageService.getSellerTransactionHistory();
    if (historyJson.isNotEmpty) {
      try {
        final List<dynamic> decodedList = jsonDecode(historyJson);
        setState(() {
          _sellerTransactionHistory =
              decodedList.map((e) => SellerTransaction.fromJson(e)).toList();
          _processedTxrIds =
              _sellerTransactionHistory.map((t) => t.txrId).toSet();
        });
      } catch (e) {
        debugPrint('Error loading seller transaction history: $e');
        setState(() {
          _status = 'Error loading transaction history.';
          _sellerTransactionHistory = [];
          _processedTxrIds = {};
        });
      }
    }
  }

  Future<void> _saveSellerTransactionHistory() async {
    final historyJson =
        jsonEncode(_sellerTransactionHistory.map((e) => e.toJson()).toList());
    await StorageService.setSellerTransactionHistory(historyJson);
  }

  void _addSellerTransaction(SellerTransaction transaction) {
    setState(() {
      _sellerTransactionHistory.insert(0, transaction);
      _processedTxrIds.add(transaction.txrId);
    });
    _saveSellerTransactionHistory();
  }

  Future<void> _loadPendingPaymentRequests() async {
    final pendingJson = await StorageService.getSellerPendingPayments();
    if (pendingJson.isNotEmpty) {
      try {
        final List<dynamic> decodedList = jsonDecode(pendingJson);
        setState(() {
          _pendingPaymentRequests = decodedList
              .map((e) => PendingPaymentRequest.fromJson(e))
              .toList();
        });
      } catch (e) {
        debugPrint('Error loading pending payment requests: $e');
        setState(() {
          _pendingPaymentRequests = [];
        });
      }
    }
  }

  Future<void> _savePendingPaymentRequests() async {
    final pendingJson =
        jsonEncode(_pendingPaymentRequests.map((e) => e.toJson()).toList());
    await StorageService.setSellerPendingPayments(pendingJson);
  }

  void _addPendingPaymentRequest(PendingPaymentRequest request) {
    setState(() {
      _pendingPaymentRequests.add(request);
    });
    _savePendingPaymentRequests();
  }

  void _fulfillPendingPaymentRequest(String paymentId) {
    setState(() {
      _pendingPaymentRequests.removeWhere((req) => req.paymentId == paymentId);
    });
    _savePendingPaymentRequests();
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (mounted) {
        final ConnectivityResult activeResult = results.firstWhere(
          (result) => result != ConnectivityResult.none,
          orElse: () => ConnectivityResult.none,
        );
        _updateConnectivityMode(activeResult);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> connectivityResults =
          await Connectivity().checkConnectivity();
      if (mounted) {
        final ConnectivityResult activeResult = connectivityResults.firstWhere(
          (result) => result != ConnectivityResult.none,
          orElse: () => ConnectivityResult.none,
        );
        _updateConnectivityMode(activeResult);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Connectivity check failed: $e';
        });
      }
    }
  }

  void _updateConnectivityMode(ConnectivityResult result) async {
    setState(() {
      _mode = (result == ConnectivityResult.none) ? 'Offline' : 'Online';
      _isSyncing = (_mode == 'Online');
      _status =
          (_mode == 'Online') ? syncingStatusEnglish : offlineStatusEnglish;
    });

    if (_mode == 'Online') {
      await Future.delayed(const Duration(seconds: 2));
      await _saveSellerData();
      await _saveSellerTransactionHistory();
      await _savePendingPaymentRequests();
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _status = onlineStatusEnglish;
        });
      }
    }
  }

  void _createPaymentQR() {
    final double? amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      _showStatusDialog('Invalid Amount',
          'Please enter a valid amount (greater than 0) to generate QR.');
      setState(() {
        _generatedPaymentQrData = '';
      });
      return;
    }

    final paymentRequestId = 'REQ${DateTime.now().millisecondsSinceEpoch}';
    final paymentData = QRPaymentData(
      amount: amount,
      transactionId: paymentRequestId,
      shopId: _shopId,
    );
    _generatedPaymentQrData = paymentData.toQRString();

    _addPendingPaymentRequest(
      PendingPaymentRequest(
        paymentId: paymentRequestId,
        amount: amount,
        timestamp: DateTime.now(),
      ),
    );

    _showQrCodeDialog(amount, _generatedPaymentQrData);
  }

  void _showQrCodeDialog(double amount, String qrData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment QR for NPR ${amount.toStringAsFixed(0)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
              gapless: false,
            ),
            const SizedBox(height: 10),
            Text('Scan this QR to receive payment.',
                style: TextStyle(color: Colors.grey[700])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _status = 'Payment QR generated and displayed.';
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _scanBuyerTxrQR() async {
    if (!mounted) return;
    final scannedCode = await QRScannerUtility.scanQRCode(context, _qrKey);
    if (!mounted) return;

    if (scannedCode != null && scannedCode.isNotEmpty) {
      final txrData = QRPaymentData.fromQRString(scannedCode);

      if (txrData == null ||
          txrData.amount <= 0 ||
          txrData.transactionId.isEmpty ||
          txrData.shopId.isEmpty ||
          txrData.buyerDeviceId == null ||
          txrData.buyerTxrId == null ||
          txrData.buyerTxrId!.isEmpty) {
        setState(() {
          _status = statusSellerTxrQrInvalid;
        });
        return;
      }

      final String buyerScannedTxrId = txrData.buyerTxrId!;
      final String sellersOriginalPaymentRequestId = txrData.transactionId;

      if (_processedTxrIds.contains(buyerScannedTxrId)) {
        setState(() {
          _status = statusSellerTxrQrAlreadyUsed;
        });
        return;
      }

      final matchingPendingRequest = _pendingPaymentRequests.firstWhereOrNull(
        (req) =>
            req.paymentId == sellersOriginalPaymentRequestId &&
            req.amount == txrData.amount,
      );

      if (matchingPendingRequest == null) {
        setState(() {
          _status = statusSellerTxrQrNotFound;
        });
        return;
      }

      setState(() {
        _sellerBalance += txrData.amount;
      });
      await _saveSellerData();

      _addSellerTransaction(
        SellerTransaction(
          txrId: buyerScannedTxrId,
          amount: txrData.amount,
          type: 'received_payment',
          timestamp: DateTime.now(),
          buyerDeviceId: txrData.buyerDeviceId,
          paymentRequestId: sellersOriginalPaymentRequestId,
          status: 'completed',
        ),
      );

      _fulfillPendingPaymentRequest(sellersOriginalPaymentRequestId);

      setState(() {
        _status = statusSellerTransactionSuccess;
        _generatedPaymentQrData = '';
      });
      _amountController.clear();
      _showStatusDialog('Payment Received!',
          'Successfully received NPR ${txrData.amount.toStringAsFixed(0)} from buyer.');
    } else {
      setState(() {
        _status = statusQrScanCancelled;
      });
    }
  }

  void _changeShopId() {
    TextEditingController shopIdController = TextEditingController(
      text: _shopId,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Shop ID'),
        content: TextField(
          controller: shopIdController,
          decoration: const InputDecoration(labelText: 'New Shop ID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _shopId = shopIdController.text.trim();
              });
              await _saveSellerData();
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
              _showStatusDialog(
                  'Shop ID Updated', 'Shop ID updated to $_shopId');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _loadBalance() async {
    const double topupAmount = 100.0;
    setState(() {
      _sellerBalance += topupAmount;
    });
    await _saveSellerData();
    _addSellerTransaction(
      SellerTransaction(
        txrId: 'TOPUP_SELLER_${DateTime.now().millisecondsSinceEpoch}',
        amount: topupAmount,
        type: 'topup',
        timestamp: DateTime.now(),
        buyerDeviceId: 'N/A', // Not applicable for seller top-up
        paymentRequestId: 'N/A', // Not applicable for seller top-up
        status: 'completed',
      ),
    );
    _showStatusDialog(
      'Balance Loaded',
      'NPR ${topupAmount.toStringAsFixed(0)} added to your balance. Current balance: NPR ${_sellerBalance.toStringAsFixed(2)}',
    );
    setState(() {
      _status = 'Balance topped up by NPR ${topupAmount.toStringAsFixed(0)}. ';
    });
  }

  void _showSellerTransactionHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == langEnglish
            ? sellerTransactionHistoryTextEnglish
            : sellerTransactionHistoryTextNepali),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: _sellerTransactionHistory.isEmpty
              ? Center(
                  child: Text(_currentLanguage == langEnglish
                      ? 'No transactions received yet.'
                      : 'अहिलेसम्म कुनै लेनदेन प्राप्त भएको छैन।'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _sellerTransactionHistory.length,
                  itemBuilder: (context, index) {
                    final transaction = _sellerTransactionHistory[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_currentLanguage == langEnglish ? 'TXR ID' : 'TXR आईडी'}: ${transaction.txrId}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_currentLanguage == langEnglish ? 'Amount' : 'रकम'}: NPR ${transaction.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${_currentLanguage == langEnglish ? 'Type' : 'प्रकार'}: ${transaction.type == 'received_payment' ? (_currentLanguage == langEnglish ? 'Received Payment' : 'प्राप्त भुक्तानी') : transaction.type}',
                            ),
                            if (transaction.buyerDeviceId != null &&
                                transaction.buyerDeviceId != 'N/A (Static QR)')
                              Text(
                                  '${_currentLanguage == langEnglish ? 'Buyer Device' : 'ग्राहक उपकरण'}: ${transaction.buyerDeviceId}'),
                            if (transaction.paymentRequestId != null &&
                                transaction.paymentRequestId != 'N/A')
                              Text(
                                  '${_currentLanguage == langEnglish ? 'Req ID' : 'अनुरोध आईडी'}: ${transaction.paymentRequestId}'),
                            Text(
                              '${_currentLanguage == langEnglish ? 'Time' : 'समय'}: ${transaction.timestamp.toLocal().toString().split('.')[0]}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              '${_currentLanguage == langEnglish ? 'Status' : 'स्थिति'}: ${transaction.status}',
                              style: TextStyle(
                                  color: transaction.status == 'completed'
                                      ? Colors.green
                                      : Colors.orange),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
                _currentLanguage == langEnglish ? 'Close' : 'बन्द गर्नुहोस्'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == langEnglish
            ? contactSupportTextEnglish
            : contactSupportTextNepali),
        content: Text(
          _currentLanguage == langEnglish
              ? 'For any emergency or support, please contact:\nPhone: 9863635324\nEmail: sushant.poudel2023@gmail.com'
              : 'कुनै पनि आपतकालीन वा सहयोगको लागि, कृपया सम्पर्क गर्नुहोस्:\nफोन: ९८६३६३५३२४\nइमेल: sushant.poudel2023@gmail.com',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
                _currentLanguage == langEnglish ? 'Close' : 'बन्द गर्नुहोस्'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == langEnglish ? 'Settings' : 'सेटिङ्स'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(_currentLanguage == langEnglish ? 'Logout' : 'लगआउट'),
              onTap: () {
                Navigator.of(context).pop(); // Close settings dialog
                _confirmLogout();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
                _currentLanguage == langEnglish ? 'Close' : 'बन्द गर्नुहोस्'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == langEnglish
            ? 'Confirm Logout'
            : 'लगआउट पुष्टि गर्नुहोस्'),
        content: Text(_currentLanguage == langEnglish
            ? 'Are you sure you want to log out?'
            : 'के तपाईं लगआउट गर्न निश्चित हुनुहुन्छ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
                _currentLanguage == langEnglish ? 'Cancel' : 'रद्द गर्नुहोस्'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (Route<dynamic> route) =>
                    false, // Remove all routes until WelcomeScreen
              );
            },
            child: Text(_currentLanguage == langEnglish ? 'Logout' : 'लगआउट'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentLanguage == langEnglish
              ? 'OfflinePay - Seller (${_isSyncing ? syncingStatusEnglish : (_mode == 'Online' ? onlineStatusEnglish : offlineStatusEnglish)})'
              : 'अफलाइनपे - बिक्रेता (${_isSyncing ? syncingStatusNepali : (_mode == 'Online' ? onlineStatusNepali : offlineStatusNepali)})',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _currentLanguage,
              icon: const Icon(Icons.language, color: Colors.white),
              dropdownColor: Colors.blueGrey.shade800,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _currentLanguage = newValue;
                  });
                }
              },
              items: <String>[langEnglish, langNepali]
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade900, // Darker green for a richer feel
              Colors.green.shade700,
              Colors.green.shade500, // Lighter green
            ],
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting and Balance Section
              Text(
                _currentLanguage == langEnglish
                    ? 'Good morning, Shop ${_shopId.replaceAll('SHOP', '')}'
                    : 'शुभ प्रभात, पसल ${_shopId.replaceAll('SHOP', '')}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                '${_currentLanguage == langEnglish ? 'Balance' : 'ब्यालेन्स'}: NPR ${_sellerBalance.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.amber.shade300,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                    ),
              ),
              const SizedBox(height: 20),

              // Search Bar (kept for future use, not directly modified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: _currentLanguage == langEnglish
                        ? 'Search...'
                        : 'खोज्नुहोस्...',
                    hintStyle: TextStyle(color: Colors.blueGrey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.blueGrey[600]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: TextStyle(color: Colors.blueGrey[800], fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),

              // Action Buttons Grid (using AppButton directly)
              Align(
                alignment: Alignment.center,
                child: Wrap(
                  spacing: 20.0,
                  runSpacing: 20.0,
                  alignment: WrapAlignment.center,
                  children: [
                    AppButton(
                      text: _currentLanguage == langEnglish
                          ? 'Load Balance'
                          : 'ब्यालेन्स लोड गर्नुहोस्',
                      icon: Icons.account_balance_wallet,
                      backgroundColor: Colors.blueGrey.shade700, // Darker shade
                      onPressed: _loadBalance,
                      iconSize: 50,
                      textSize: 16,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 15),
                    ),
                    AppButton(
                      text: _currentLanguage == langEnglish
                          ? 'Bank Transfer'
                          : 'बैंक स्थानान्तरण',
                      icon: Icons.account_balance,
                      backgroundColor: Colors.indigo.shade700,
                      onPressed: () {
                        _showStatusDialog('Bank Transfer',
                            'This feature is under development.');
                      },
                      iconSize: 50,
                      textSize: 16,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 15),
                    ),
                    AppButton(
                      text: _currentLanguage == langEnglish
                          ? 'Promo Code'
                          : 'प्रोमो कोड',
                      icon: Icons.local_offer,
                      backgroundColor: Colors.purple.shade700,
                      onPressed: () {
                        _showStatusDialog(
                            'Promo Code', 'This feature is under development.');
                      },
                      iconSize: 50,
                      textSize: 16,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 15),
                    ),
                    AppButton(
                      text: _currentLanguage == langEnglish ? 'Help' : 'मद्दत',
                      icon: Icons.help_outline,
                      backgroundColor: Colors.teal.shade700,
                      onPressed: _contactSupport,
                      iconSize: 50,
                      textSize: 16,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 15),
                    ),
                    AppButton(
                      text: _currentLanguage == langEnglish
                          ? generateQrTextEnglish
                          : generateQrTextNepali,
                      icon: Icons.qr_code,
                      backgroundColor: Colors.orange.shade700,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(_currentLanguage == langEnglish
                                ? 'Generate QR'
                                : 'QR उत्पन्न गर्नुहोस्'),
                            content: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: _currentLanguage == langEnglish
                                      ? 'Enter Amount (NPR)'
                                      : 'रकम प्रविष्ट गर्नुहोस् (NPR)'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text(_currentLanguage == langEnglish
                                    ? 'Cancel'
                                    : 'रद्द गर्नुहोस्'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  _createPaymentQR();
                                },
                                child: Text(_currentLanguage == langEnglish
                                    ? 'Generate'
                                    : 'उत्पन्न गर्नुहोस्'),
                              ),
                            ],
                          ),
                        );
                      },
                      iconSize: 50,
                      textSize: 16,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 15),
                    ),
                    AppButton(
                      text: _currentLanguage == langEnglish
                          ? scanTxrQrTextEnglish
                          : scanTxrQrTextNepali,
                      icon: Icons.camera_alt,
                      backgroundColor:
                          Colors.red.shade700, // Distinct color for scanning
                      onPressed: _scanBuyerTxrQR,
                      iconSize: 50,
                      textSize: 16,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Insights & Actions section (Transaction History & Settings)
              Text(
                _currentLanguage == langEnglish
                    ? 'Insights & Actions'
                    : 'अन्तर्दृष्टि र कार्यहरू',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
              ),
              const SizedBox(height: 15),
              // Transaction History Card
              InkWell(
                onTap: _showSellerTransactionHistory,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentLanguage == langEnglish
                            ? 'View Received Transactions'
                            : 'प्राप्त लेनदेनहरू हेर्नुहोस्',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentLanguage == langEnglish
                            ? 'Review all payments received from buyers.'
                            : 'ग्राहकहरूबाट प्राप्त सबै भुक्तानीहरू समीक्षा गर्नुहोस्।',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.history,
                            // ignore: deprecated_member_use
                            size: 50,
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Settings Card
              InkWell(
                onTap: _showSettingsDialog,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade700, // Consistent with app bar
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentLanguage == langEnglish
                            ? 'Settings'
                            : 'सेटिङ्स',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentLanguage == langEnglish
                            ? 'Manage app settings and logout.'
                            : 'एप सेटिङ्स व्यवस्थापन गर्नुहोस् र लगआउट गर्नुहोस्।',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.settings,
                            // ignore: deprecated_member_use
                            size: 50,
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Change Shop ID Card (Moved to be a dedicated card)
              InkWell(
                onTap: _changeShopId,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentLanguage == langEnglish
                            ? 'Change Shop ID'
                            : 'पसल आईडी परिवर्तन गर्नुहोस्',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentLanguage == langEnglish
                            ? 'Update your shop identifier.'
                            : 'आफ्नो पसलको पहिचान अपडेट गर्नुहोस्।',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.edit,
                            // ignore: deprecated_member_use
                            size: 50,
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _showScrollToTopButton
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: Colors.green.shade700,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }
}

// Extension to allow firstWhereOrNull, available in newer Dart/Flutter versions or with collection package
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
