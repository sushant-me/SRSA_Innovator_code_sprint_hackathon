// lib/utils/qr_scanner_utility.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Changed from qr_code_scanner

class QRScannerUtility {
  // This static method shows a dialog with a QR scanner.
  // It returns the scanned QR code data as a String, or null if scanning is cancelled or fails.
  static Future<String?> scanQRCode(
    BuildContext context,
    GlobalKey
        qrKey, // qrKey might not be strictly necessary for MobileScanner in this setup, but kept for consistency if needed elsewhere.
  ) async {
    // Initialize the controller here, before the dialog is shown.
    final MobileScannerController controller = MobileScannerController();
    String? scannedCode; // Variable to store the scanned code

    // Show a dialog that contains the QR scanning view
    await showDialog<String>(
      context: context,
      barrierDismissible:
          false, // Prevents dialog from closing when tapping outside
      builder: (dialogContext) => AlertDialog(
        title: const Text('Scan QR Code'), // Title of the dialog
        content: SizedBox(
          height: 300, // Fixed height for the scanner area
          width: 300, // Fixed width for the scanner area
          // MobileScanner widget to display the camera feed and detect QR codes
          child: MobileScanner(
            // Pass the initialized controller to the MobileScanner widget
            controller: controller,
            onDetect: (capture) {
              // Changed from onQRViewCreated and scannedDataStream.listen
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && scannedCode == null) {
                scannedCode =
                    barcodes.first.rawValue; // Store the first detected code
                controller
                    .stop(); // Stop scanner after first successful scan (no need for ?. because it's non-nullable)
                // Pop the dialog with the scanned code as the result
                Navigator.pop(dialogContext, scannedCode);
              }
            },
            // MobileScanner does not use 'overlay' in the same way as qr_code_scanner.
            // Custom overlays would be built using a Stack widget around MobileScanner.
          ),
        ),
        actions: [
          // Close button for the dialog
          TextButton(
            onPressed: () {
              controller
                  .stop(); // Stop the camera when closing the dialog (no need for ?.)
              Navigator.pop(dialogContext); // Close the dialog
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
    return scannedCode; // Return the scanned code
  }
}
