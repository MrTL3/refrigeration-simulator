import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/pipe_segment_state.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';

/// Representa una partícula individual de refrigerante circulando por una tubería
class FlowParticle {
  /// Progreso paramétrico a lo largo de la tubería (0.0 = inicio, 1.0 = fin)
  double progress;

  /// Variación lateral o radio de dispersión dentro de la luz del tubo
  final double lateralOffset;

  /// Tamaño de partícula
  final double baseRadius;

  FlowParticle({
    required this.progress,
    required this.lateralOffset,
    required this.baseRadius,
  });
}

/// Sistema físico de partículas y trazadores de refrigerante.
/// La velocidad de avance es calculada de forma determinista a partir de:
/// v = m_dot / (rho * A) para cada tramo de tubería real.
class RefrigerantParticleSystem {
  final Map<String, List<FlowParticle>> _pipeParticles = {};

  RefrigerantParticleSystem() {
    _initializeParticles();
  }

  void _initializeParticles() {
    const pipeIds = ['pipe_discharge', 'pipe_liquid', 'pipe_expansion', 'pipe_suction'];
    for (final id in pipeIds) {
      final list = <FlowParticle>[];
      // 18 partículas por tramo para fluidez óptima en móvil
      for (int i = 0; i < 18; i++) {
        list.add(
          FlowParticle(
            progress: i / 18.0,
            lateralOffset: ((i % 3) - 1.0) * 2.5,
            baseRadius: (id == 'pipe_liquid') ? 3.5 : (id == 'pipe_expansion' ? 3.0 : 2.5),
          ),
        );
      }
      _pipeParticles[id] = list;
    }
  }

  /// Actualiza la posición de las partículas según el tiempo transcurrido dtRender y la velocidad física real
  void update(SimulationState state, double dtRenderSeconds) {
    for (final entry in _pipeParticles.entries) {
      final pipeId = entry.key;
      final particles = entry.value;
      final pipeState = state.pipeStates[pipeId];

      if (pipeState == null) continue;

      // Velocidad física real en m/s (de Darcy-Weisbach y conservación de masa)
      final vPhysical = pipeState.velocityMetersPerSec;
      final lengthM = pipeState.lengthMeters > 0 ? pipeState.lengthMeters : 2.0;

      // Fracción de longitud recorrida en este frame
      // Factor de escala visual: vPhysical / lengthM proporciona el tiempo real de tránsito
      final dProgress = (vPhysical / lengthM) * dtRenderSeconds * 0.5;

      for (final p in particles) {
        p.progress = (p.progress + dProgress) % 1.0;
        if (p.progress < 0) p.progress += 1.0;
      }
    }
  }

  /// Dibuja las partículas de refrigerante sobre el trazado de una tubería
  void paintPipeParticles({
    required Canvas canvas,
    required String pipeId,
    required List<Offset> pathPoints,
    required PipeSegmentState? pipeState,
  }) {
    if (pathPoints.length < 2 || pipeState == null) return;

    final particles = _pipeParticles[pipeId];
    if (particles == null) return;

    // Si no hay caudal (velocidad cero), las partículas se dibujan estáticas y tenuemente
    final isMoving = pipeState.velocityMetersPerSec > 0.05;

    // Color y características según fase del refrigerante
    Color particleColor;
    if (pipeState.isLiquid) {
      particleColor = ScadaColors.highPressureLiquid;
    } else if (pipeState.isTwoPhase) {
      particleColor = ScadaColors.lowPressureTwoPhase;
    } else if (pipeId == 'pipe_discharge') {
      particleColor = ScadaColors.highPressureDischarge;
    } else {
      particleColor = ScadaColors.lowPressureSuction;
    }

    final paint = Paint()
      ..color = particleColor.withValues(alpha: isMoving ? 0.95 : 0.4)
      ..style = PaintingStyle.fill;

    // Calculamos longitudes acumuladas para interpolación precisa a lo largo de codos
    final segLengths = <double>[];
    double totalPathLength = 0.0;
    for (int i = 0; i < pathPoints.length - 1; i++) {
      final len = (pathPoints[i + 1] - pathPoints[i]).distance;
      segLengths.add(len);
      totalPathLength += len;
    }

    if (totalPathLength <= 0) return;

    for (final p in particles) {
      final targetDistance = p.progress * totalPathLength;

      // Buscar el segmento correspondiente
      double accumulated = 0.0;
      Offset pos = pathPoints.first;
      Offset dir = Offset.zero;

      for (int i = 0; i < segLengths.length; i++) {
        final segLen = segLengths[i];
        if (accumulated + segLen >= targetDistance || i == segLengths.length - 1) {
          final segProgress = segLen > 0 ? ((targetDistance - accumulated) / segLen).clamp(0.0, 1.0) : 0.0;
          pos = Offset.lerp(pathPoints[i], pathPoints[i + 1], segProgress)!;
          dir = (pathPoints[i + 1] - pathPoints[i]) / math.max(0.001, segLen);
          break;
        }
        accumulated += segLen;
      }

      // Desplazamiento lateral perpendicular
      final normal = Offset(-dir.dy, dir.dx);
      final drawPos = pos + normal * p.lateralOffset;

      // Variación de radio si es mezcla bifásica (efecto flash gas con burbujas de vapor)
      double r = p.baseRadius;
      if (pipeState.isTwoPhase) {
        final xQuality = pipeState.state.vaporQuality;
        // A mayor calidad x, mayores burbujas de vapor
        r = p.baseRadius * (0.8 + 0.8 * xQuality);
      }

      canvas.drawCircle(drawPos, r, paint);

      // Si es vapor sobrecalentado o gas rápido, dibujar una leve estela direccional
      if (isMoving && (pipeState.isVapor || pipeState.isTwoPhase)) {
        final tailPaint = Paint()
          ..color = particleColor.withValues(alpha: 0.35)
          ..strokeWidth = r * 0.8
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(drawPos, drawPos - dir * (r * 2.2), tailPaint);
      }
    }
  }
}
