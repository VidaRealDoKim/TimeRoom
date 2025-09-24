import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Make sure this is added to your pubspec.yaml

class QRCodeScreen extends StatelessWidget {
  final String qrData; // Data to be encoded in the QR code

  const QRCodeScreen({super.key, required this.qrData});

  @override
  Widget build(BuildContext context) {
    // Define your primary and accent colors based on your app's theme
    // You might want to get these from Theme.of(context) if you have a defined theme
    final Color primaryColor = Colors.teal[400]!; // Based on your "TIME ROOM" logo and bottom nav
    final Color accentColor = Colors.white; // Used for text/icons on primary backgrounds
    final Color backgroundColor = Colors.grey[100]!; // Light grey background like your images

    return Scaffold(
      backgroundColor: backgroundColor, // Overall screen background
      appBar: AppBar(
        backgroundColor: accentColor, // White app bar background
        foregroundColor: primaryColor, // Icon and text color for app bar
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the logo and text
          mainAxisSize: MainAxisSize.min, // Shrink row to fit children
          children: [
            // Example for your logo - replace with your actual logo asset if possible
            // Image.asset('assets/LogoHorizontal.png', height: 28), // Adjust path/height
            Icon(Icons.watch_later_outlined, color: primaryColor, size: 28), // Example icon
            const SizedBox(width: 8),
            Text(
              'TIME ROOM',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true, // Center the row within the app bar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // Your existing actions, e.g., notification icon
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
        elevation: 0, // No shadow under the app bar, as seen in your images
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Padding around the card
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0), // Rounded corners for the card
            ),
            elevation: 2, // Subtle shadow for the card
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Make the column take minimum vertical space
                children: [
                  const Text(
                    'Liberação por QR Code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aponte a imagem abaixo para a câmera disponível em sua Academia e aguarde a liberação.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // QR Code display
                  Container(
                    padding: const EdgeInsets.all(8.0), // Padding around QR code
                    decoration: BoxDecoration(
                      color: Colors.white, // Ensure white background for QR
                      borderRadius: BorderRadius.circular(8.0), // Slight round for QR container
                      border: Border.all(color: Colors.grey[300]!), // Subtle border
                    ),
                    child: QrImageView(
                      data: qrData, // The data you want to encode
                      version: QrVersions.auto,
                      size: 200.0,
                      gapless: true,
                      foregroundColor: Colors.black, // Default QR color
                      errorStateBuilder: (cxt, err) {
                        return const Center(
                          child: Text(
                            'Oops! Algo deu errado ao gerar o QR Code.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // "Tudo certo, Liberado!" Button
                  SizedBox(
                    width: double.infinity, // Full width button
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement actual release logic
                        print('QR Code Liberado!');
                        // Maybe show a success message or navigate back
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor, // Use your app's primary color
                        foregroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 1, // Subtle elevation
                      ),
                      child: const Text(
                        'Tudo certo, Liberado!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // "Cancelar" Button
                  SizedBox(
                    width: double.infinity, // Full width button
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Go back
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600], // Grey text like your other text buttons
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures all labels are shown
        backgroundColor: primaryColor, // Greenish teal from your bottom nav
        selectedItemColor: accentColor, // White for selected item
        unselectedItemColor: accentColor.withOpacity(0.7), // Slightly faded white for unselected
        currentIndex: 2, // Assuming "Criar Sala" (QR code action) is index 2
        onTap: (index) {
          // Handle navigation based on the tapped index
          // You'll need to implement your actual navigation logic here
          switch (index) {
            case 0:
            // Navigator.pushNamed(context, '/home');
              break;
            case 1:
            // Navigator.pushNamed(context, '/salas');
              break;
            case 2:
            // This is the "Criar Sala" or QR code related item, already on this screen
            // If it's a dedicated QR screen, tapping it again might do nothing or refresh.
              break;
            case 3:
            // Navigator.pushNamed(context, '/usuarios');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room), // Or a similar icon for "Salas"
            label: 'Salas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code), // Icon for "Criar Sala" / QR Code action
            label: 'Criar Sala',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people), // Icon for "Usuários"
            label: 'Usuários',
          ),
        ],
      ),
    );
  }
}