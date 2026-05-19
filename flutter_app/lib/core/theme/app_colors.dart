import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds - Premium Dark Tech Matte Black
  static const Color background = Color(0xFF0F0F12);
  static const Color surface = Color(0xFF15151B);
  static const Color cardBg = Color(0xFF19191F);
  
  // Accents - Neon orange and electric cian
  static const Color accent = Color(0xFFFF6B00); 
  static const Color accentSecondary = Color(0xFF00E5FF); 
  static const Color warning = Color(0xFFFF8C00); 
  static const Color error = Color(0xFFFF3366); 
  
  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF9E9EB0);
  static const Color textMuted = Color(0xFF64647D);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF19191F), Color(0xFF0F0F12)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
