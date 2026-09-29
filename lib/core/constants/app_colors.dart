import 'package:flutter/material.dart';

/// Centralized color palette for MoneyPilot.
/// Matches the web application's modern emerald and clean fintech aesthetic.
class AppColors {
  AppColors._();

  // Brand Primary (Emerald)
  static const Color primary = Color(0xFF005C46); // Primary Emerald #005C46
  static const Color primaryLight = Color(0xFF10B981); // brand-400
  static const Color primaryDark = Color(0xFF047857); // brand-600 / darker emerald #047857
  static const Color emerald = Color(0xFF059669); // Emerald #059669
  static const Color primaryContainer = Color(0xFFD1FAE5); // emerald-100 #D1FAE5
  static const Color onPrimaryContainer = Color(0xFF065F46); // emerald-800

  // Brand Gradients & Accents
  static const Color teal = Color(0xFF0D9488);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color sky = Color(0xFF0EA5E9);
  static const Color indigo = Color(0xFF6366F1);

  // Functional / Financial Status Colors
  static const Color income = Color(0xFF10B981); // Emerald #10B981
  static const Color expense = Color(0xFFF43F5E); // Rose / Red #F43F5E
  static const Color darkExpense = Color(0xFFDC2626); // Dark expense #DC2626
  static const Color warning = Color(0xFFF59E0B); // Amber #F59E0B
  static const Color info = Color(0xFF3B82F6); // Blue
  static const Color purple = Color(0xFF8B5CF6); // Violet

  // Light Theme Surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC); // slate-50 #F8FAFC
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF); // #FFFFFF
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0); // slate-200
  static const Color dividerLight = Color(0xFFF1F5F9); // slate-100

  // Light Theme Typography
  static const Color textPrimaryLight = Color(0xFF0F172A); // slate-900
  static const Color textSecondaryLight = Color(0xFF64748B); // slate-500
  static const Color textMutedLight = Color(0xFF94A3B8); // slate-400

  // Dark Theme Surfaces
  static const Color backgroundDark = Color(0xFF0B1120); // slate-950
  static const Color surfaceDark = Color(0xFF0F172A); // slate-900
  static const Color cardDark = Color(0xFF1E293B); // slate-800
  static const Color borderDark = Color(0xFF334155); // slate-700
  static const Color dividerDark = Color(0xFF1E293B);

  // Dark Theme Typography
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // slate-50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // slate-400
  static const Color textMutedDark = Color(0xFF64748B); // slate-500

  // Chart Palette (matches web application Recharts)
  static const List<Color> chartColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF14B8A6), // Teal
    Color(0xFF3B82F6), // Blue
    Color(0xFFF97316), // Orange
    Color(0xFF84CC16), // Lime
    Color(0xFF0EA5E9), // Sky
  ];
}
