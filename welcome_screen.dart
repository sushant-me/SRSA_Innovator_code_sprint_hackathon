// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:offlinepay/constants/values.dart'; // Contains appName, appSlogan, defaultPin, and user credentials
import 'package:offlinepay/screens/buyer_home_screen.dart'; // Navigate to this on successful buyer login
import 'package:offlinepay/screens/seller_home_screen.dart'; // Navigate to this on successful seller login

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _statusMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handles the login attempt based on entered username and password
  void _performLogin() {
    _statusMessage = ''; // Clear previous status messages
    final enteredUsername = _usernameController.text.trim();
    final enteredPassword = _passwordController.text.trim();

    if (enteredUsername.isEmpty || enteredPassword.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter both username and password.';
      });
      return;
    }

    // Check for Buyer (Customer) credentials - User 1
    if (enteredUsername == buyerUsername && enteredPassword == buyerPassword) {
      setState(() {
        _statusMessage = 'Login successful as Customer!';
      });
      _usernameController.clear();
      _passwordController.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BuyerHomeScreen()),
      );
    }
    // Check for Buyer (Customer) credentials - User 20
    else if (enteredUsername == buyer2Username &&
        enteredPassword == buyer2Password) {
      setState(() {
        _statusMessage = 'Login successful as Customer (user20)!';
      });
      _usernameController.clear();
      _passwordController.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BuyerHomeScreen()),
      );
    }
    // Check for Seller (Shopkeeper) credentials - Shop 1
    else if (enteredUsername == sellerUsername &&
        enteredPassword == sellerPassword) {
      setState(() {
        _statusMessage = 'Login successful as Shopkeeper!';
      });
      _usernameController.clear();
      _passwordController.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SellerHomeScreen()),
      );
    }
    // Check for Seller (Shopkeeper) credentials - Shop 20
    else if (enteredUsername == seller2Username &&
        enteredPassword == seller2Password) {
      setState(() {
        _statusMessage = 'Login successful as Shopkeeper (shop20)!';
      });
      _usernameController.clear();
      _passwordController.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SellerHomeScreen()),
      );
    }
    // Invalid credentials
    else {
      setState(() {
        _statusMessage = 'Invalid username or password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$appName - $appSlogan'), // Dynamic app name and slogan
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        centerTitle: Theme.of(context).appBarTheme.centerTitle,
        shape: Theme.of(context).appBarTheme.shape,
      ),
      body: Stack(
        children: [
          // Elegant Background Gradient
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
              padding:
                  const EdgeInsets.all(25.0), // Generous padding for content
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Prominent App Icon / Logo Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(
                          0.9), // Slightly transparent white background
                      borderRadius:
                          BorderRadius.circular(30), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              // ignore: deprecated_member_use
                              .withOpacity(0.2), // Subtle shadow for depth
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.payment,
                        size: 140,
                        color: Colors.blueGrey), // Large, themed icon
                  ),
                  const SizedBox(height: 40), // Vertical spacing
                  // Bold Title for Login
                  Text(
                    'Welcome to OfflinePay!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors
                              .white, // High contrast text on dark background
                          fontSize: 32, // Large and inviting font size
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15), // Adjusted spacing
                  Text(
                    'Please log in to continue.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                      height: 40), // Vertical spacing before input fields

                  // Username Input Field
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
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: Colors.blueGrey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        prefixIcon:
                            Icon(Icons.person, color: Colors.blueGrey[700]),
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

                  // Password Input Field
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
                      controller: _passwordController,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.blueGrey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        prefixIcon:
                            Icon(Icons.lock, color: Colors.blueGrey[700]),
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

                  // Status Message
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('successful')
                          ? Colors.lightGreenAccent
                          : Colors.redAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Login Button
                  ElevatedButton.icon(
                    onPressed: _performLogin,
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: const Text('Login',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 7,
                    ),
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
