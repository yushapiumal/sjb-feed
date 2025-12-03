import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_indicator/loading_indicator.dart';


class CustomTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final String? Function(String?)? validator;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters; // ✅ Added this

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.validator,
    this.maxLines = 1,
    this.inputFormatters, // ✅ Added this
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: widget.isPassword ? _obscureText : false,
      controller: widget.controller,
      maxLines: widget.maxLines,
      inputFormatters: widget.inputFormatters, // ✅ Added this line
      style: GoogleFonts.poppins(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: Colors.black,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.5)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        errorStyle: GoogleFonts.poppins(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: widget.controller.text.isNotEmpty
            ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
            : widget.isPassword
                ? GestureDetector(
                    onTap: () =>
                        setState(() => _obscureText = !_obscureText),
                    child: Icon(
                      _obscureText
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.black38,
                    ),
                  )
                : null,
      ),
      validator: widget.validator ??
          (value) => value == null || value.isEmpty
              ? 'Please enter your ${widget.label}'
              : null,
    );
  }
}

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double? width;
  final double? height;

  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor = const Color.fromARGB(172, 66, 136, 9),
    this.textColor = Colors.black,
    this.borderRadius = 20,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 25,
                width: 50,
                child: LoadingIndicator(
                  indicatorType: Indicator.ballPulse,
                  colors: [Colors.green, Colors.yellow],
                ),
              )
            : Text(
                text.tr(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                   fontSize: 16,
                ),
              ),
      ),
    );
  }
}
