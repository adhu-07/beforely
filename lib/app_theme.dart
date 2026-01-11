import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color paperWhite = Color(0xFFFDFBF7); // Warm paper texture
  static const Color inkBlack = Color(0xFF1A1A1A);   // Soft black like ink
  static const Color teaGreen = Color(0xFFD4E09B);   // Highlighter green
  static const Color errorRed = Color(0xFFEB5757);   // Teacher's red pen
  static const Color pencilGrey = Color(0xFF828282);

  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: paperWhite,
    primaryColor: inkBlack,
    
    // TEXT THEME: Using "Patrick Hand" for a handwritten feel
    textTheme: TextTheme(
      displayLarge: GoogleFonts.patrickHand(
        fontSize: 48, 
        fontWeight: FontWeight.bold, 
        color: inkBlack,
        height: 1.0,
      ),
      headlineMedium: GoogleFonts.patrickHand(
        fontSize: 32, 
        fontWeight: FontWeight.w600, 
        color: inkBlack
      ),
      headlineSmall: GoogleFonts.patrickHand(
        fontSize: 24, 
        fontWeight: FontWeight.w600, 
        color: inkBlack
      ),
      bodyLarge: GoogleFonts.patrickHand(
        fontSize: 20, 
        color: inkBlack
      ),
      bodyMedium: GoogleFonts.patrickHand( // Standard text
        fontSize: 18, 
        color: inkBlack
      ),
      labelLarge: GoogleFonts.patrickHand(
        fontSize: 18, 
        fontWeight: FontWeight.bold, 
        color: paperWhite // For buttons
      ),
    ),

    // BUTTON THEME
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: inkBlack,
        foregroundColor: paperWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: inkBlack, width: 1), // Hand-drawn border feel
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    
    // INPUT THEME
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: inkBlack, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: inkBlack, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: teaGreen, width: 3),
      ),
    ),
  );
}