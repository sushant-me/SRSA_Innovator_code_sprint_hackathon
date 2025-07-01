// lib/constants/values.dart

// Application Info
const String appName = 'OfflinePay';
const String appSlogan = 'Revolutionizing Payments';

// Authentication and Roles
const String defaultPin = "1234";

// Buyer (Customer) Credentials
const String buyerUsername = "9863635324";
const String buyerPassword = "8084";
const String buyerUserId = "user1"; // Default buyer user ID

// New Customer Credentials
const String buyer2Username = "1010";
const String buyer2Password = "1010";
const String buyer2UserId = "user20";

// Seller (Shopkeeper) Credentials
const String sellerUsername = "1234";
const String sellerPassword = "0987";
const String sellerShopId = "shop1"; // Default seller shop ID

// New Shopkeeper Credentials
const String seller2Username = "9090";
const String seller2Password = "9090";
const String seller2ShopId = "shop20";

// Default/Initial Values
const String defaultShopId = 'SHOP10';
const double initialBuyerLoadAmount =
    500.0; // Initial balance loaded by buyer for demo
const double initialSellerLoadAmount =
    1000.0; // New: Initial balance for seller
const double onlineSecurityBalance =
    100.0; // Amount retained online for security, used for offline calculation
const double defaultSellerPaymentAmount =
    300.0; // Default amount for seller's QR (if not dynamically entered)

// SharedPreferences Keys (used for local persistence)
const String spDeviceId = 'deviceId';
const String spSellerShopId = 'sellerShopId';
const String spSellerBalance = 'sellerBalance';
const String spBuyerOfflineBalance = 'buyerOfflineBalance';
const String spBuyerTotalBalance = 'buyerTotalBalance';
const String spBuyerOnlineSecurityBalance =
    'buyerOnlineSecurityBalance'; // Used for the "security deposit" portion
const String spBuyerTransactionHistory =
    'buyerTransactionHistory'; // Key for storing buyer transaction history
const String spSellerTransactionHistory =
    'sellerTransactionHistory'; // New: Key for storing seller transaction history
const String spSellerPendingPayments =
    'sellerPendingPayments'; // New: Key for seller pending payment requests

// Status Messages (for user feedback)
const String statusWelcomeSeller = 'Welcome Seller!';
const String statusWelcomeBuyer = 'Welcome Buyer!';
const String statusQrScanCancelled = 'QR scan cancelled or failed.';
const String statusInvalidQrData = 'Invalid QR code data!';
const String statusInsufficientBalance = 'Insufficient offline balance!';
const String statusIncorrectPin = 'Incorrect PIN. Try again.';
const String statusNoTxrScanned = 'No TXR QR scanned!';
const String statusTxrMismatch = 'TXR Mismatch or Invalid!';
const String statusTopupOnlineOnly = 'Top-up available only when online.';
const String statusTransactionDuplicate = 'Transaction already processed.';
const String statusSellerTxrQrInvalid =
    'Invalid TXR QR: Missing required data.'; // New: for seller TXR scan
const String statusSellerTxrQrNotFound =
    'TXR QR not matched with any pending request.'; // New: for seller TXR scan
const String statusSellerTxrQrAlreadyUsed =
    'TXR QR already used for this shop.'; // New: for seller TXR scan
const String statusSellerTransactionSuccess =
    'Payment received successfully!'; // New: for seller success
const String statusSellerTopupOnlineOnly =
    'Top-up for seller available only when online.'; // New: for seller topup restriction

// Language/Localization Keys (simple placeholders for now)
const String langEnglish = 'English';
const String langNepali = 'Nepali';
const String appTitleEnglish = 'OfflinePay';
const String appTitleNepali = 'अफलाइनपे'; // Nepali for OfflinePay
const String totalBalanceTextEnglish = 'Total Balance';
const String totalBalanceTextNepali = 'कुल ब्यालेन्स';
const String offlineWalletTextEnglish = 'Offline Wallet';
const String offlineWalletTextNepali = 'अफलाइन वालेट';
const String onlineSecurityTextEnglish = 'Online Security';
const String onlineSecurityTextNepali = 'अनलाइन सुरक्षा';
const String addTopupTextEnglish = 'Add Top-up (NPR 100)';
const String addTopupTextNepali = 'टप-अप थप्नुहोस् (रु १००)';
const String scanToPayTextEnglish = 'Scan Seller\'s QR to Pay';
const String scanToPayTextNepali = 'बिक्रेताको QR स्क्यान गर्नुहोस्';
const String transactionHistoryTextEnglish = 'Transaction History';
const String transactionHistoryTextNepali = 'लेनदेनको इतिहास';
const String contactSupportTextEnglish = 'Contact Support';
const String contactSupportTextNepali = 'सहायताको लागि सम्पर्क गर्नुहोस्';
const String loginScreenTitleEnglish = 'Login';
const String loginScreenTitleNepali = 'लगइन';
const String usernameHintEnglish = 'Username';
const String usernameHintNepali = 'प्रयोगकर्ता नाम';
const String passwordHintEnglish = 'Password';
const String passwordHintNepali = 'पासवर्ड';
const String loginButtonTextEnglish = 'Login';
const String loginButtonTextNepali = 'लग - इन';
const String invalidCredentialsTextEnglish = 'Invalid username or password.';
const String invalidCredentialsTextNepali =
    'अमान्य प्रयोगकर्ता नाम वा पासवर्ड।';
const String selectLanguageTextEnglish = 'Select Language';
const String selectLanguageTextNepali = 'भाषा चयन गर्नुहोस्';
const String generateQrTextEnglish =
    'Generate Payment QR'; // New: Seller QR Gen
const String generateQrTextNepali = 'भुक्तानी QR उत्पन्न गर्नुहोस्';
const String scanTxrQrTextEnglish =
    'Scan Transaction QR'; // New: Seller TXR Scan
const String scanTxrQrTextNepali = 'लेनदेन QR स्क्यान गर्नुहोस्';
const String staticQrTextEnglish = 'Shop\'s Static QR'; // New: Seller Static QR
const String staticQrTextNepali = 'पसलको स्थिर QR';
const String sellerQrAmountHintEnglish =
    'Enter Amount (NPR)'; // New: Seller QR Amount
const String sellerQrAmountHintNepali = 'रकम प्रविष्ट गर्नुहोस् (रु)';
const String sellerTransactionHistoryTextEnglish =
    'Received Transactions'; // New: Seller Transaction History
const String sellerTransactionHistoryTextNepali = 'प्राप्त लेनदेनहरू';
const String syncingStatusEnglish =
    'Online (Syncing...)'; // New: Syncing status
const String syncingStatusNepali = 'अनलाइन (सिंक गर्दै...)';
const String onlineStatusEnglish = 'Online'; // New: Online status
const String onlineStatusNepali = 'अनलाइन';
const String offlineStatusEnglish = 'Offline'; // New: Offline status
const String offlineStatusNepali = 'अफलाइन';
