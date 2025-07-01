// lib/screens/buyer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:offlinepay/constants/values.dart';
import 'package:offlinepay/models/qr_payment_data.dart';
import 'package:offlinepay/services/storage_service.dart';
import 'package:offlinepay/utils/qr_scanner_utility.dart';
// ignore: unused_import
import 'package:offlinepay/widgets/app_button.dart';
import 'package:offlinepay/models/transaction.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:offlinepay/screens/welcome_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  BuyerHomeScreenState createState() => BuyerHomeScreenState();
}

class BuyerHomeScreenState extends State<BuyerHomeScreen> {
  double _onlineBalance = onlineSecurityBalance;
  double _offlineBalance = 0.0;
  double _currentDisplayBalance = 0.0;

  // User ID
  String _userId = buyerUserId;

  // Connectivity and Status
  String _mode = "Offline";
  // ignore: unused_field
  String _status = statusWelcomeBuyer;
  bool _isSyncing = false;

  // QR and Transaction Data
  String _scannedPaymentData = "";
  String _txrQrData = "";

  // Language State
  String _currentLanguage = langEnglish;

  // Transaction History
  List<Transaction> _transactionHistory = [];
  Set<String> _processedTransactionIds = {};

  StreamSubscription? _connectivitySubscription;
  final GlobalKey _qrKey = GlobalKey(debugLabel: "QR");

  // Scroll Controller for the SingleChildScrollView
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTopButton = false;

  @override
  void initState() {
    super.initState();
    _initializeBuyerData();
    _startConnectivityMonitoring();

    // Add listener to scroll controller
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Listener for scroll position
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

  // Method to scroll to the top
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _initializeBuyerData() async {
    _offlineBalance = await StorageService.getBuyerOfflineBalance();
    _onlineBalance = await StorageService.getBuyerOnlineSecurityBalance();
    _userId = await StorageService.getBuyerUserId();
    await _loadTransactionHistory();

    // Simulate initial balance load and split for the first time if needed
    if (_offlineBalance == 0.0 && _onlineBalance == onlineSecurityBalance) {
      await _loadInitialBalance(initialBuyerLoadAmount);
    }
    _updateDisplayBalance();
    setState(() {});
    _checkConnectivity();
  }

  // Loads an initial balance and splits it into online security and offline wallet.
  Future<void> _loadInitialBalance(double initialAmount) async {
    _onlineBalance = onlineSecurityBalance;
    _offlineBalance = initialAmount - _onlineBalance;
    await StorageService.setBuyerOfflineBalance(_offlineBalance);
    await StorageService.setBuyerOnlineSecurityBalance(_onlineBalance);
    _updateDisplayBalance();
    setState(() {
      _status =
          "Initial balance loaded: NPR ${_currentDisplayBalance.toStringAsFixed(0)}";
    });
  }

  // Persists buyer's balances and user ID to local storage.
  Future<void> _saveBuyerData() async {
    await StorageService.setBuyerOfflineBalance(_offlineBalance);
    await StorageService.setBuyerOnlineSecurityBalance(_onlineBalance);
    await StorageService.setBuyerUserId(_userId);
  }

  // Loads transaction history from SharedPreferences
  Future<void> _loadTransactionHistory() async {
    final historyJson = await StorageService.getBuyerTransactionHistory();
    if (historyJson.isNotEmpty) {
      try {
        final List<dynamic> decodedList = jsonDecode(historyJson);
        setState(() {
          _transactionHistory =
              decodedList.map((e) => Transaction.fromJson(e)).toList();
          _processedTransactionIds =
              _transactionHistory.map((t) => t.id).toSet();
        });
      } catch (e) {
        debugPrint("Error loading transaction history: $e");
        setState(() {
          _status = "Error loading transaction history.";
          _transactionHistory = [];
          _processedTransactionIds = {};
        });
      }
    }
  }

  // Saves transaction history to SharedPreferences
  Future<void> _saveTransactionHistory() async {
    final historyJson =
        jsonEncode(_transactionHistory.map((e) => e.toJson()).toList());
    await StorageService.setBuyerTransactionHistory(historyJson);
  }

  // Adds a new transaction to history and saves
  void _addTransaction(Transaction transaction) {
    setState(() {
      _transactionHistory.insert(0, transaction);
      _processedTransactionIds.add(transaction.id);
    });
    _saveTransactionHistory();
  }

  // Updates the balance displayed based on online/offline mode
  void _updateDisplayBalance() {
    setState(() {
      if (_mode == "Online") {
        _currentDisplayBalance = _offlineBalance + _onlineBalance;
      } else {
        _currentDisplayBalance = _offlineBalance;
      }
    });
  }

  // Starts listening for network connectivity changes.
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

  // Checks current connectivity status and updates the mode.
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
          _status = "Connectivity check failed: $e";
        });
      }
    }
  }

  // Updates the connectivity mode based on the result.
  void _updateConnectivityMode(ConnectivityResult result) async {
    setState(() {
      _mode = (result == ConnectivityResult.none) ? "Offline" : "Online";
      _isSyncing = (_mode == "Online");
      _status =
          (_mode == "Online") ? syncingStatusEnglish : offlineStatusEnglish;
      _updateDisplayBalance();
    });

    if (_mode == "Online") {
      await Future.delayed(const Duration(seconds: 2));
      await _saveBuyerData();
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _status = onlineStatusEnglish;
        });
      }
    }
  }

  // Initiates scanning of the seller's payment QR.
  void _scanSellerPaymentQR() async {
    if (!mounted) return;
    final scannedCode = await QRScannerUtility.scanQRCode(context, _qrKey);
    if (!mounted) return;
    if (scannedCode != null && scannedCode.isNotEmpty) {
      _scannedPaymentData = scannedCode;
      _processPaymentRequest();
    } else {
      setState(() {
        _status = statusQrScanCancelled;
      });
    }
  }

  // Processes the payment request from the scanned QR data.
  Future<void> _processPaymentRequest() async {
    if (_scannedPaymentData.isEmpty) {
      setState(() {
        _status = "No payment QR scanned!";
      });
      return;
    }

    final paymentRequestData = QRPaymentData.fromQRString(_scannedPaymentData);

    if (paymentRequestData == null ||
        paymentRequestData.amount <= 0 ||
        paymentRequestData.transactionId.isEmpty ||
        paymentRequestData.shopId.isEmpty) {
      setState(() {
        _status = statusInvalidQrData;
      });
      return;
    }

    // Check if this transaction (based on seller's REQ ID) has already been processed
    if (_processedTransactionIds.contains(paymentRequestData.transactionId)) {
      setState(() {
        _status = statusTransactionDuplicate;
      });
      return;
    }

    if (_offlineBalance < paymentRequestData.amount) {
      setState(() {
        _status = statusInsufficientBalance;
      });
      return;
    }

    // Prompt for PIN confirmation
    bool pinConfirmed = await _showPinConfirmationDialog();

    if (pinConfirmed) {
      setState(() {
        _offlineBalance -= paymentRequestData.amount;
      });
      await _saveBuyerData();
      _updateDisplayBalance();

      // Generate TXR QR data for seller verification
      final buyerUniqueTxrId = "TXZ${DateTime.now().millisecondsSinceEpoch}";
      _txrQrData = QRPaymentData(
        amount: paymentRequestData.amount,
        transactionId: paymentRequestData.transactionId,
        shopId: paymentRequestData.shopId,
        buyerDeviceId: "BUYER_DEVICE_MOCK",
        buyerTxrId: buyerUniqueTxrId,
      ).toQRString();

      // Add transaction to history (using buyer's unique TXR ID as the primary ID for buyer's history)
      _addTransaction(
        Transaction(
          id: buyerUniqueTxrId,
          amount: paymentRequestData.amount,
          type: "payment",
          timestamp: DateTime.now(),
          shopId: paymentRequestData.shopId,
          status: "completed",
        ),
      );

      setState(() {
        _status =
            "Payment successful! NPR ${paymentRequestData.amount.toStringAsFixed(0)} paid to ${paymentRequestData.shopId}. Show TXR QR to seller.";
      });
    } else {
      setState(() {
        _status = "Payment cancelled or incorrect PIN.";
      });
    }
  }

  // Shows a PIN confirmation dialog.
  Future<bool> _showPinConfirmationDialog() async {
    TextEditingController pinController = TextEditingController();
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Payment with PIN"),
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
                  if (pinController.text == defaultPin) {
                    Navigator.pop(context, true);
                  } else {
                    Navigator.pop(context, false);
                    setState(() {
                      _status = statusIncorrectPin;
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

  // Function to add balance (for demo purposes)
  void _addTopup() async {
    if (_mode == "Offline") {
      setState(() {
        _status = statusTopupOnlineOnly;
      });
      return;
    }
    const double topupAmount = 100.0;
    setState(() {
      _offlineBalance += topupAmount;
    });
    await _saveBuyerData();
    _updateDisplayBalance();

    // Add topup transaction to history
    _addTransaction(
      Transaction(
        id: "TOPUP${DateTime.now().millisecondsSinceEpoch}",
        amount: topupAmount,
        type: "topup",
        timestamp: DateTime.now(),
        status: "completed",
      ),
    );

    setState(() {
      _status =
          "NPR ${topupAmount.toStringAsFixed(0)} topped up. Current Balance: NPR ${_currentDisplayBalance.toStringAsFixed(2)}";
    });
  }

  // Shows transaction history in a dialog
  void _showTransactionHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == langEnglish
            ? transactionHistoryTextEnglish
            : transactionHistoryTextNepali),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: _transactionHistory.isEmpty
              ? Center(
                  child: Text(_currentLanguage == langEnglish
                      ? "No transactions yet."
                      : "अहिलेसम्म कुनै लेनदेन छैन।"))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _transactionHistory.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactionHistory[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${_currentLanguage == langEnglish ? "ID" : "आईडी"}: ${transaction.id}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${_currentLanguage == langEnglish ? "Amount" : "रकम"}: NPR ${transaction.amount.toStringAsFixed(0)}",
                              style: TextStyle(
                                color: transaction.type == "payment"
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "${_currentLanguage == langEnglish ? "Type" : "प्रकार"}: ${transaction.type == "payment" ? (_currentLanguage == langEnglish ? "Payment" : "भुक्तानी") : (_currentLanguage == langEnglish ? "Top-up" : "टप-अप")}",
                            ),
                            if (transaction.shopId != null)
                              Text(
                                  "${_currentLanguage == langEnglish ? "Shop ID" : "पसल आईडी"}: ${transaction.shopId}"),
                            Text(
                              "${_currentLanguage == langEnglish ? "Time" : "समय"}: ${transaction.timestamp.toLocal().toString().split(".")[0]}", // Format timestamp
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              "${_currentLanguage == langEnglish ? "Status" : "स्थिति"}: ${transaction.status}",
                              style: TextStyle(
                                  color: transaction.status == "completed"
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
                _currentLanguage == langEnglish ? "Close" : "बन्द गर्नुहोस्"),
          ),
        ],
      ),
    );
  }

  // Shows contact support info
  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == langEnglish
            ? contactSupportTextEnglish
            : contactSupportTextNepali),
        content: Text(
          _currentLanguage == langEnglish
              ? "For any emergency or support, please contact:\nPhone: 9863635324\nEmail: sushant.poudel2023@gmail.com"
              : "कुनै पनि आपतकालीन वा सहयोगको लागि, कृपया सम्पर्क गर्नुहोस्:\nफोन: ९८६३६३५३२४\nइमेल: sushant.poudel2023@gmail.com",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
                _currentLanguage == langEnglish ? "Close" : "बन्द गर्नुहोस्"),
          ),
        ],
      ),
    );
  }

  // Function to change the User ID
  void _changeUserId() {
    TextEditingController userIdController = TextEditingController(
      text: _userId,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User ID'),
        content: TextField(
          controller: userIdController,
          decoration: const InputDecoration(labelText: 'New User ID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _userId = userIdController.text.trim();
              });
              await _saveBuyerData();
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
              _showStatusDialog(
                  'User ID Updated', 'User ID updated to $_userId');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Helper function to show a simple status dialog
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

  //show Settings Dialog with Logout and Change User ID ---
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == langEnglish ? 'Settings' : 'सेटिङ्स'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: Text(_currentLanguage == langEnglish
                  ? 'Change User ID'
                  : 'प्रयोगकर्ता आईडी परिवर्तन गर्नुहोस्'),
              onTap: () {
                Navigator.of(context).pop();
                _changeUserId();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(_currentLanguage == langEnglish ? 'Logout' : 'लगआउट'),
              onTap: () {
                Navigator.of(context).pop();
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
                (Route<dynamic> route) => false,
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
              ? "OfflinePay - Buyer (${_isSyncing ? syncingStatusEnglish : (_mode == "Online" ? onlineStatusEnglish : offlineStatusEnglish)})"
              : "अफलाइनपे - ग्राहक (${_isSyncing ? syncingStatusNepali : (_mode == "Online" ? onlineStatusNepali : offlineStatusNepali)})",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        actions: [
          // Language selection dropdown
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _currentLanguage,
              icon: const Icon(Icons.language, color: Colors.white),
              dropdownColor: Colors.blueGrey.shade800,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _currentLanguage = newValue;
                    _updateDisplayBalance();
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
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _currentLanguage == langEnglish
                    ? 'Good morning, User ${_userId.replaceAll('user', '')}'
                    : 'शुभ प्रभात, प्रयोगकर्ता ${_userId.replaceAll('user', '')}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                "NPR ${_currentDisplayBalance.toStringAsFixed(2)}",
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
                  color: Colors.white
                      // ignore: deprecated_member_use
                      .withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          // ignore: deprecated_member_use
                          .withOpacity(0.15),
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

              // Action Buttons Grid
              Align(
                alignment: Alignment.center,
                child: Wrap(
                  spacing: 20.0,
                  runSpacing: 20.0,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildActionButton(
                      context,
                      Icons.add_circle,
                      _currentLanguage == langEnglish
                          ? addTopupTextEnglish
                          : addTopupTextNepali,
                      _mode == "Online" ? _addTopup : null,
                      Colors.green.shade700,
                    ),
                    _buildActionButton(
                      context,
                      Icons.account_balance,
                      _currentLanguage == langEnglish
                          ? 'Bank Transfer'
                          : 'बैंक स्थानान्तरण',
                      () {
                        _showStatusDialog('Bank Transfer',
                            'This feature is under development.');
                      },
                      Colors
                          .indigo.shade700, // Distinct color for bank transfer
                    ),
                    _buildActionButton(
                      context,
                      Icons.local_offer, // Promo Code icon
                      _currentLanguage == langEnglish
                          ? 'Promo Code'
                          : 'प्रोमो कोड',
                      () {
                        _showStatusDialog(
                            'Promo Code', 'This feature is under development.');
                      },
                      Colors.purple.shade700, // Distinct color for promo code
                    ),
                    _buildActionButton(
                      context,
                      Icons.help_outline, // Help icon
                      _currentLanguage == langEnglish
                          ? contactSupportTextEnglish
                          : contactSupportTextNepali,
                      _contactSupport,
                      Colors.teal.shade700, // Distinct color for help
                    ),
                    _buildActionButton(
                      context,
                      Icons.qr_code_scanner,
                      _currentLanguage == langEnglish
                          ? scanToPayTextEnglish
                          : scanToPayTextNepali,
                      _scanSellerPaymentQR,
                      Colors.orange.shade700, // Distinct color for scan to pay
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
                      fontSize: 24, // Larger title
                    ),
              ),
              const SizedBox(height: 15),
              // Transaction History Card
              InkWell(
                onTap: _showTransactionHistory,
                borderRadius: BorderRadius.circular(25), // More rounded
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25), // Increased padding
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700, // Consistent with app bar
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.2), // Stronger shadow
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
                            ? 'View Transaction History'
                            : 'लेनदेन इतिहास हेर्नुहोस्',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8), // Increased spacing
                      Text(
                        _currentLanguage == langEnglish
                            ? 'Review all your past payments and top-ups.'
                            : 'तपाईंको सबै विगतका भुक्तानी र टप-अपहरू समीक्षा गर्नुहोस्।',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              // Larger body text
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 20), // Increased spacing
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.history,
                            size: 50,
                            color:
                                // ignore: deprecated_member_use
                                Colors.white.withOpacity(0.8)), // Larger icon
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Settings Card
              InkWell(
                onTap: _showSettingsDialog, // Calls the new settings dialog
                borderRadius: BorderRadius.circular(25), // More rounded
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25), // Increased padding
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700, // Vibrant orange
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.2), // Stronger shadow
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
                      const SizedBox(height: 8), // Increased spacing
                      Text(
                        _currentLanguage == langEnglish
                            ? 'Manage app settings and logout.'
                            : 'एप सेटिङ्स व्यवस्थापन गर्नुहोस् र लगआउट गर्नुहोस्।',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              // Larger body text
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.settings,
                            size: 50,
                            color:
                                // ignore: deprecated_member_use
                                Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Display generated TXR QR code
              if (_txrQrData.isNotEmpty)
                Column(
                  children: [
                    Text(
                      _currentLanguage == langEnglish
                          ? "Show this TXR QR to Seller:"
                          : "यो TXR QR बिक्रेतालाई देखाउनुहोस्:",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((255 * 0.25).round()),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(15),
                      child: QrImageView(
                        data: _txrQrData,
                        version: QrVersions.auto,
                        size: 280.0,
                        gapless: false,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "TXR QR Content (for debug): $_txrQrData",
                      style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      //  Scroll to Top
      floatingActionButton: _showScrollToTopButton
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: Colors.blue.shade700,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }

  // New: Widget to build a single action button for the grid
  Widget _buildActionButton(BuildContext context, IconData icon, String label,
      VoidCallback? onPressed, Color backgroundColor) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      // ignore: deprecated_member_use
      splashColor: Colors.white.withOpacity(0.3),
      // ignore: deprecated_member_use
      highlightColor: Colors.white.withOpacity(0.1),
      child: Container(
        width: 120,
        height: 120,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: backgroundColor.withOpacity(onPressed != null ? 0.95 : 0.6),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(onPressed != null ? 1.0 : 0.8),
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to allow firstWhereOrNull
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
