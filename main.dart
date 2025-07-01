// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // For enhanced typography
import 'package:offlinepay/screens/welcome_screen.dart'; // Corrected import path

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OfflinePay',
      theme: ThemeData(
        // Keeping primarySwatch for backward compatibility for some widgets,
        // but prefer using colorScheme for Material 3.
        primarySwatch: Colors.blueGrey,
        colorScheme: ColorScheme.fromSeed(
          seedColor:
              Colors.blueGrey, // Modern Material 3 approach for primary color
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Using Google Fonts for a modern and consistent look across the app.
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        useMaterial3: true, // Enable Material 3 features
        // Custom AppBar theme for a consistent look.
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[800],
          foregroundColor: Colors.white,
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        // Custom ElevatedButton theme for consistent button styling.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ),
      // The starting point of your application will be the WelcomeScreen.
      home: const WelcomeScreen(),
    );
  }
}
