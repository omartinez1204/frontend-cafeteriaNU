import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Servicio de reproducción de sonidos para notificaciones.
///
/// RF-055: Las notificaciones incluirán sonido y/o vibración según la configuración del dispositivo.
/// RF-057: El panel de caja y la pantalla de cocina recibirán alerta visual y sonora.
class NotificationSoundService {
  final AudioPlayer _newOrderPlayer = AudioPlayer();
  final AudioPlayer _readyPlayer = AudioPlayer();
  final AudioPlayer _genericPlayer = AudioPlayer();

  /// Inicializar los players de audio (no-op, se usa play directo)
  Future<void> init() async {
    // Sin precaching — usar play() directo evita timeouts de setSource()
  }

  Future<void> playNewOrderSound() async {
    await _playSound(_newOrderPlayer, 'notificationneworder.wav');
  }

  Future<void> playReadySound() async {
    await _playSound(_readyPlayer, 'notificationready.wav');
  }

  Future<void> playGenericSound() async {
    await _playSound(_genericPlayer, 'notificationgeneric.wav');
  }

  Future<void> _playSound(AudioPlayer player, String soundName) async {
    try {
      await player.stop();
      await player.play(AssetSource('sounds/$soundName'));
    } catch (e) {
      debugPrint('[NotificationSoundService] Error al reproducir $soundName: $e');
    }
  }

  void dispose() {
    _newOrderPlayer.dispose();
    _readyPlayer.dispose();
    _genericPlayer.dispose();
  }
}
