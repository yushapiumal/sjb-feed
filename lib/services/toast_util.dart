import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:statelink/theme/app_theme.dart';

class ToastUtil {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(String message) {
    _showToast(message, AppColors.primaryGreen, Icons.check_circle_rounded);
  }

  static void showError(String message) {
    _showToast(message, const Color(0xFFE53935), Icons.error_rounded);
  }

  static void showInfo(String message) {
    _showToast(message, AppColors.accentOrange, Icons.info_rounded);
  }

  static void _showToast(String message, Color color, IconData icon) {
    final state = messengerKey.currentState;
    if (state == null) return;

    // Clear previous toasts immediately
    state.clearSnackBars();

    state.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Shows a localized toast message for a specific key
  static void showLocalized(String key, {bool isError = true}) {
    _showToast(
      key.tr(),
      isError ? const Color(0xFFE53935) : AppColors.primaryGreen,
      isError ? Icons.error_rounded : Icons.check_circle_rounded,
    );
  }
}
