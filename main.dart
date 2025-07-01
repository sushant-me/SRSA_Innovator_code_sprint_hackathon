import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// Main app widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 215, 51, 1),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Home 🎪'),
    );
  }
}

// Home Page
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loginRequired = true; // Disable UI until login is done

  @override
  void initState() {
    super.initState();

    // Show login popup after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      _showLoginPopup();
    });
  }

  void _showLoginPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LoginPopup(onLoginSuccess: () {
        setState(() {
          _loginRequired = false; // Unlock the UI
        });
        Navigator.of(context).pop(); // Close the dialog
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: AbsorbPointer(
        absorbing: _loginRequired,
        child: Opacity(
          opacity: _loginRequired ? 0.4 : 1,
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & avatar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Good Morning,',
                            style:
                                TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Sushil Dai',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage('assets/profile.jpg'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search bar
                  TextField(
                    enabled: !_loginRequired,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Categories
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _categoryItem(Icons.directions_car, "Load Balance",
                            Colors.blue),
                        _categoryItem(Icons.wifi_off, "Offline Mode",
                            Colors.orange),
                        _categoryItem(Icons.wifi, "Online Mode", Colors.green),
                        _categoryItem(Icons.account_balance, "Bank Transfer",
                            Colors.purple),
                        _categoryItem(Icons.discount, "Promo Code", Colors.red),
                        _categoryItem(Icons.help_outline, "Help", Colors.teal),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Promo Cards
                  Expanded(
                    child: ListView(
                      children: [
                        _promoCard(
                          'Discover New Movies',
                          'Get the latest movies and shows.',
                          Colors.blueAccent,
                        ),
                        const SizedBox(height: 20),
                        _promoCard(
                          'Get Airline Tickets',
                          'Enjoy Travelling at Discounted Price',
                          Colors.greenAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Category
  Widget _categoryItem(IconData icon, String label, Color color) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
              fontSize: 13,
              color: _darken(color, 0.25),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Promo Card
  Widget _promoCard(String title, String subtitle, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // Darken helper
  Color _darken(Color color, [double amount = .1]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

// 🔐 LOGIN POPUP
class LoginPopup extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  const LoginPopup({super.key, required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    final TextEditingController userController = TextEditingController();
    final TextEditingController passController = TextEditingController();

    return AlertDialog(
      title: const Text('Login Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: userController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: passController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (userController.text.isNotEmpty &&
                passController.text.isNotEmpty) {
              onLoginSuccess();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please fill in all fields")),
              );
            }
          },
          child: const Text('Login'),
        ),
      ],
    );
  }
}
