import 'package:flutter/material.dart';

/// Colores institucionales NovaUniversitas
/// Fuente: CLAUDE-flutter.md y SRS v2.0
class NovaColors {
  // Primarios institucionales
  static const Color greenDark = Color(0xFF1A4731);
  static const Color greenMedium = Color(0xFF2E7D52);
  static const Color greenLight = Color(0xFFD4EDDA);
  static const Color gold = Color(0xFFC8960C);
  static const Color goldLight = Color(0xFFFFF8E1);

  // Semánticos (estados de pedido)
  static const Color statusReady = Color(0xFF1B5E20); // LISTO_PARA_ENTREGAR
  static const Color statusInProgress = Color(0xFFE65100); // EN_PREPARACION
  static const Color statusRejected = Color(0xFFB71C1C); // RECHAZADO_*

  // Neutrales
  static const Color grayLight = Color(0xFFF4F6F4);
  static const Color grayMedium = Color(0xFFDEE3DE);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Feedback
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
}
