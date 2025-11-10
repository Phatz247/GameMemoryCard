import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameThemeData {
  // Colors
  static const Color primaryColor = Color(0xFF6366f1); // Indigo
  static const Color secondaryColor = Color(0xFFf59e0b); // Amber
  static const Color accentColor = Color(0xFF10b981); // Emerald
  static const Color errorColor = Color(0xFFef4444); // Red
  static const Color surfaceColor = Color(0xFF1a1a2e);
  static const Color darkBackgroundColor = Color(0xFF1a1a2e); // Added for profile screen

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1a1a2e),
      Color(0xFF16213e),
      Color(0xFF0f0f23),
      Color(0xFF000000),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2d3748),
      Color(0xFF1a202c),
    ],
  );

  static BoxDecoration gameCardDecoration = BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration statusBarDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.black.withOpacity(0.4),
        Colors.black.withOpacity(0.2),
      ],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withOpacity(0.1),
      width: 1,
    ),
  );


  static TextStyle titleTextStyle = GoogleFonts.orbitron(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(
        color: primaryColor.withOpacity(0.5),
        blurRadius: 10,
        offset: const Offset(0, 0),
      ),
    ],
  );

  static TextStyle statusTextStyle = GoogleFonts.rajdhani(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle scoreTextStyle = GoogleFonts.rajdhani(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: secondaryColor,
  );

  static final TextStyle bodyTextStyle = GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.white,
  );


  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 8,
    shadowColor: primaryColor.withOpacity(0.4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white.withOpacity(0.1),
    foregroundColor: Colors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.white.withOpacity(0.2)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );


  static BoxDecoration floatingIconDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        primaryColor.withOpacity(0.8),
        primaryColor.withOpacity(0.6),
      ],
    ),
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
