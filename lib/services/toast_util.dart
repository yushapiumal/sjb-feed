import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:statelink/theme/app_theme.dart';

class ToastUtil {
  static void showSuccess(String message) {
    _showToast(message, AppColors.primaryGreen);
  }

  static void showError(String message) {
    _showToast(message, Colors.red);
  }

  static void showInfo(String message) {
    _showToast(message, AppColors.accentOrange);
  }

  static void _showToast(String message, Color backgroundColor) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Shows a localized toast message for a specific key
  static void showLocalized(String key, {bool isError = true}) {
    _showToast(key.tr(), isError ? Colors.red : AppColors.primaryGreen);
  }
}
