// ============================================================
// lib/core/constants/app_colors.dart
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Palette (Starbucks-Inspired) ──────────────────
  static const Color primary    = Color(0xFF006241); // Deep Green
  static const Color accent     = Color(0xFF1E3932); // Forest Green
  static const Color background = Color(0xFFF2F0EB); // Warm Cream
  static const Color surface    = Color(0xFFFFFFFF); // White

  // ── Text ─────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Status ───────────────────────────────────────────────
  static const Color pending    = Color(0xFFF59E0B); // Amber
  static const Color processing = Color(0xFF3B82F6); // Blue
  static const Color ready      = Color(0xFF8B5CF6); // Purple
  static const Color completed  = Color(0xFF10B981); // Emerald
  static const Color cancelled  = Color(0xFFEF4444); // Red

  /// Returns the status chip color given an order status string
  static Color statusColor(String status) {
    switch (status) {
      case 'pending':    return pending;
      case 'processing': return processing;
      case 'ready':      return ready;
      case 'completed':  return completed;
      case 'cancelled':  return cancelled;
      default:           return textSecondary;
    }
  }
}
