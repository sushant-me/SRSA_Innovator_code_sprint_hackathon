// lib/main.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Import the mobile_scanner package

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const QRScannerScreen(),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  // Controller for the MobileScanner widget
  MobileScannerController cameraController = MobileScannerController();
  // Variable to store the scanned barcode data
  String? _scannedBarcode;
  // Flag to control if the scanner is actively looking for codes
  bool _isScanning = true;

  @override
  void dispose() {
    // Dispose the camera controller when the widget is removed from the tree
    cameraController.dispose();
    super.dispose();
  }

  // Function to handle detected barcodes
  void _onBarcodeDetect(BarcodeCapture capture) {
    // Check if we are currently scanning and if any barcodes were detected
    if (_isScanning && capture.barcodes.isNotEmpty) {
      // Get the raw value of the first detected barcode
      final String? barcodeValue = capture.barcodes.first.rawValue;

      // If a barcode value is found and it's not null
      if (barcodeValue != null) {
        setState(() {
          _scannedBarcode = barcodeValue; // Store the scanned value
          _isScanning = false; // Stop scanning to prevent multiple detections
        });
        // Pause the camera to freeze the view on the detected QR
        cameraController.stop();

        // Show an alert dialog with the scanned data
        _showScannedDataDialog(barcodeValue);
      }
    }
  }

  // Function to show a dialog with the scanned QR data
  void _showScannedDataDialog(String data) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (context) => AlertDialog(
        title: const Text('QR Code Scanned!'),
        content: SelectableText(
          'Scanned Data:\n$data', // Display the scanned data
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              _resetScanner(); // Reset scanner to allow new scans
            },
            child: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  // Function to reset the scanner for a new scan
  void _resetScanner() {
    setState(() {
      _scannedBarcode = null; // Clear previous scanned data
      _isScanning = true; // Re-enable scanning
    });
    cameraController.start(); // Restart the camera
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          // MobileScanner widget takes up the full screen
          MobileScanner(
            controller: cameraController, // Assign the controller
            onDetect: _onBarcodeDetect, // Callback for barcode detection
            // You can add a scan window here if you want a specific area for scanning
            // scanWindow: Rect.fromCenter(center: MediaQuery.of(context).size.center(Offset.zero), width: 200, height: 200),
          ),
          // Overlay for visual feedback (e.g., a scanning frame)
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    'Scan QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Display scanned barcode data if available
          if (_scannedBarcode != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Last Scanned: $_scannedBarcode',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
