import 'package:flutter/material.dart';

/// Visual tokens lifted from the reference screenshots. Kept centralized so
/// the Worksheet Generator UI doesn't scatter magic colors/radii — and so
/// no other feature accidentally redefines this look differently.
class MoolBhashaTheme {
  MoolBhashaTheme._();

  static const Color cream = Color(0xFFFBF6EC);
  static const Color darkGreen = Color(0xFF1F4A3C);
  static const Color mediumGreen = Color(0xFF2C6B54);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color fieldBackground = Color(0xFFF3EEE1);
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color divider = Color(0xFFE7E0CF);

  static const double cardRadius = 20;
  static const double fieldRadius = 14;
  static const double buttonRadius = 16;

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      );

  static InputDecoration dropdownDecoration({String? hint}) => InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide.none,
        ),
      );
}
