import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Servicio de abstracción multiplataforma para FrigoLab.
/// Aísla llamadas específicas de plataforma (orientación de pantalla, modo inmersivo, etc.)
/// garantizando compatibilidad total y transparente entre Android y Web.
class PlatformService {
  /// Indica si la aplicación se ejecuta en navegador Web
  static bool get isWeb => kIsWeb;

  /// Indica si la aplicación se ejecuta en un dispositivo móvil táctil nativo
  static bool get isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Indica si la aplicación se ejecuta en un entorno de escritorio nativo o navegador desktop
  static bool get isDesktop => kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS;

  /// Solicita orientación apaisada y pantalla completa inmersiva (solo en plataformas móviles nativas)
  static Future<void> enterFullscreenLandscape() async {
    if (kIsWeb) return;
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (_) {
      // No-op en entornos donde no esté soportado
    }
  }

  /// Restaura las orientaciones normales y barras de sistema del dispositivo
  static Future<void> exitFullscreenLandscape() async {
    if (kIsWeb) return;
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {
      // No-op en entornos donde no esté soportado
    }
  }
}
