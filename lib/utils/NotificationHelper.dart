// lib/utils/notification_helper.dart
import 'package:flutter/material.dart';

// Der globale Key bleibt genau gleich!
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class NotificationHelper {
  
  // 🔴 FEHLER-Meldung (Rot)
  static void showError(String message) {
    _showSnackBar(message, Colors.redAccent.shade700, Icons.error_outline);
  }

  // 🟢 ERFOLGS-Meldung (Grün)
  static void showSuccess(String message) {
    _showSnackBar(message, Colors.green.shade700, Icons.check_circle_outline);
  }

  // 🔵 INFO-Meldung (Blau) - z.B. für "Lade Daten..."
  static void showInfo(String message) {
    _showSnackBar(message, Colors.blue.shade700, Icons.info_outline);
  }

  // Interne Hilfsmethode, die das Design für alle SnackBars zentral steuert
  static void _showSnackBar(String message, Color backgroundColor, IconData icon) {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3), // 3 Sekunden reicht meistens
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}