import 'package:flutter/material.dart';
import '../../domain/components/base_component.dart';
import '../../simulation/engine/simulation_state.dart';
import '../theme/scada_colors.dart';

/// Lienzo interactivo 2D de esquema de proceso e instrumentación (P&ID).
class PidCanvas extends StatefulWidget {
  final SimulationState state;
  final BaseComponent? selectedComponent;
  final ValueChanged<BaseComponent> onComponentSelected;

  const PidCanvas({
    super.key,
    required this.state,
    required this.selectedComponent,
    required this.onComponentSelected,
  });

  @override
  State<PidCanvas> createState() => _PidCanvasState();
}

class _PidCanvasState extends State<PidCanvas> with SingleTickerProviderStateMixin {
  late AnimationController _flowController;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flowController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _PidPainter(
            state: widget.state,
            selectedComponent: widget.selectedComponent,
            flowAnimationValue: _flowController.value,
          ),
          child: _buildInteractiveOverlay(),
        );
      },
    );
  }

  Widget _buildInteractiveOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Coordenadas normalizadas de los 4 componentes en el lienzo
        final compRect = Rect.fromCenter(center: Offset(w * 0.25, h * 0.72), width: 130, height: 110);
        final condRect = Rect.fromCenter(center: Offset(w * 0.75, h * 0.25), width: 140, height: 100);
        final expRect = Rect.fromCenter(center: Offset(w * 0.75, h * 0.72), width: 120, height: 90);
        final evapRect = Rect.fromCenter(center: Offset(w * 0.25, h * 0.25), width: 140, height: 100);

        final comp = widget.state.circuit.compressor;
        final cond = widget.state.circuit.condenser;
        final exp = widget.state.circuit.expansionDevice;
        final evap = widget.state.circuit.evaporator;

        return Stack(
          children: [
            if (comp != null)
              Positioned.fromRect(
                rect: compRect,
                child: _buildTapTarget(comp),
              ),
            if (cond != null)
              Positioned.fromRect(
                rect: condRect,
                child: _buildTapTarget(cond),
              ),
            if (exp != null)
              Positioned.fromRect(
                rect: expRect,
                child: _buildTapTarget(exp),
              ),
            if (evap != null)
              Positioned.fromRect(
                rect: evapRect,
                child: _buildTapTarget(evap),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTapTarget(BaseComponent comp) {
    final isSelected = widget.selectedComponent?.id == comp.id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onComponentSelected(comp),
        splashColor: ScadaColors.infoBlue.withValues(alpha: 0.2),
        hoverColor: Colors.white.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: ScadaColors.infoBlue, width: 2.5)
                : Border.all(color: Colors.transparent, width: 1),
          ),
        ),
      ),
    );
  }
}

class _PidPainter extends CustomPainter {
  final SimulationState state;
  final BaseComponent? selectedComponent;
  final double flowAnimationValue;

  _PidPainter({
    required this.state,
    required this.selectedComponent,
    required this.flowAnimationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cuadrícula técnica sutil de fondo
    _drawGrid(canvas, size);

    // Posiciones centrales de los cuatro bloques
    final evapCenter = Offset(w * 0.25, h * 0.25);
    final condCenter = Offset(w * 0.75, h * 0.25);
    final expCenter = Offset(w * 0.75, h * 0.72);
    final compCenter = Offset(w * 0.25, h * 0.72);

    // Conexiones de tuberías
    _drawPipes(canvas, compCenter, condCenter, expCenter, evapCenter);

    // Si la simulación está corriendo, dibujamos las partículas de refrigerante
    if (state.isRunning) {
      _drawFlowParticles(canvas, compCenter, condCenter, expCenter, evapCenter);
    }

    // Dibujo de símbolos de componentes
    _drawEvaporator(canvas, evapCenter, 140, 100);
    _drawCondenser(canvas, condCenter, 140, 100);
    _drawExpansionValve(canvas, expCenter, 120, 90);
    _drawCompressor(canvas, compCenter, 130, 110);

    // Nodos termodinámicos de referencia (Puntos 1, 2, 3, 4)
    _drawStateNodes(canvas, compCenter, condCenter, expCenter, evapCenter);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ScadaColors.border.withValues(alpha: 0.25)
      ..strokeWidth = 1;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawPipes(Canvas canvas, Offset comp, Offset cond, Offset exp, Offset evap) {
    // 1. Descarga: Compresor -> Condensador (Vapor recalentado alta presión - ROJO)
    final dischargePath = Path()
      ..moveTo(comp.dx + 40, comp.dy - 35)
      ..lineTo(comp.dx + 40, cond.dy + 20)
      ..lineTo(cond.dx - 55, cond.dy + 20);

    // 2. Línea de líquido: Condensador -> Válvula (Líquido alta presión - ROJO LÍQUIDO)
    final liquidPath = Path()
      ..moveTo(cond.dx + 55, cond.dy + 20)
      ..lineTo(exp.dx + 45, cond.dy + 20)
      ..lineTo(exp.dx + 45, exp.dy - 20)
      ..lineTo(exp.dx + 30, exp.dy - 20);

    // 3. Inyección / Bifásica: Válvula -> Evaporador (Mezcla fría - CIAN)
    final expansionPath = Path()
      ..moveTo(exp.dx - 30, exp.dy)
      ..lineTo(evap.dx + 55, exp.dy)
      ..lineTo(evap.dx + 55, evap.dy + 25);

    // 4. Aspiración: Evaporador -> Compresor (Vapor baja presión - AZUL COBALTO)
    final suctionPath = Path()
      ..moveTo(evap.dx - 55, evap.dy - 10)
      ..lineTo(comp.dx - 45, evap.dy - 10)
      ..lineTo(comp.dx - 45, comp.dy)
      ..lineTo(comp.dx - 30, comp.dy);

    _strokePath(canvas, dischargePath, ScadaColors.highPressureDischarge, 6.0);
    _strokePath(canvas, liquidPath, ScadaColors.highPressureLiquid, 5.0);
    _strokePath(canvas, expansionPath, ScadaColors.lowPressureTwoPhase, 6.0);
    _strokePath(canvas, suctionPath, ScadaColors.lowPressureSuction, 7.0);
  }

  void _strokePath(Canvas canvas, Path path, Color color, double width) {
    // Tubería exterior (metálica oscura)
    final borderPaint = Paint()
      ..color = ScadaColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + 4.0;
    canvas.drawPath(path, borderPaint);

    // Líquido/gas interior coloreado
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, corePaint);
  }

  void _drawFlowParticles(Canvas canvas, Offset comp, Offset cond, Offset exp, Offset evap) {
    final particlePaint = Paint()..style = PaintingStyle.fill;

    // Partículas en descarga
    _drawParticleAlong(canvas, Offset(comp.dx + 40, comp.dy - 10), Offset(comp.dx + 40, cond.dy + 20),
        ScadaColors.highPressureDischarge, particlePaint);

    // Partículas en línea de líquido
    _drawParticleAlong(canvas, Offset(exp.dx + 45, cond.dy + 20), Offset(exp.dx + 45, exp.dy - 20),
        ScadaColors.highPressureLiquid, particlePaint);

    // Partículas en línea de expansión
    _drawParticleAlong(canvas, Offset(exp.dx - 30, exp.dy), Offset(evap.dx + 55, exp.dy),
        ScadaColors.lowPressureTwoPhase, particlePaint);

    // Partículas en aspiración
    _drawParticleAlong(canvas, Offset(comp.dx - 45, evap.dy - 10), Offset(comp.dx - 45, comp.dy),
        ScadaColors.lowPressureSuction, particlePaint);
  }

  void _drawParticleAlong(Canvas canvas, Offset start, Offset end, Color color, Paint paint) {
    paint.color = Colors.white;
    const count = 4;
    for (int i = 0; i < count; i++) {
      final t = (flowAnimationValue + (i / count)) % 1.0;
      final currentPos = Offset.lerp(start, end, t)!;
      canvas.drawCircle(currentPos, 3.5, paint);
    }
  }

  void _drawCompressor(Canvas canvas, Offset center, double w, double h) {
    final paintBody = Paint()
      ..color = ScadaColors.surfaceCard
      ..style = PaintingStyle.fill;
    final paintBorder = Paint()
      ..color = ScadaColors.borderLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Cuerpo en campana cilíndrica del compresor hermético
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w * 0.75, height: h * 0.8),
      const Radius.circular(24),
    );
    canvas.drawRRect(rrect, paintBody);
    canvas.drawRRect(rrect, paintBorder);

    // Símbolo del pistón / biela interior
    final pistonPaint = Paint()
      ..color = state.isRunning ? ScadaColors.runningGreen : ScadaColors.textSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(center, 18, pistonPaint);
    canvas.drawLine(center, Offset(center.dx + 12, center.dy - 8), pistonPaint);

    _drawText(canvas, 'COMPRESOR', Offset(center.dx, center.dy + 38), ScadaColors.textPrimary, 11, bold: true);
    final statusText = state.isRunning ? '${state.circuit.compressor?.rpm.toInt() ?? 0} RPM' : 'DETENIDO';
    _drawText(canvas, statusText, Offset(center.dx, center.dy - 38),
        state.isRunning ? ScadaColors.runningGreen : ScadaColors.textMuted, 10);
  }

  void _drawCondenser(Canvas canvas, Offset center, double w, double h) {
    final bodyPaint = Paint()..color = ScadaColors.surfaceCard;
    final borderPaint = Paint()
      ..color = ScadaColors.borderLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromCenter(center: center, width: w * 0.8, height: h * 0.7);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);

    // Aletas y serpentín
    final finPaint = Paint()
      ..color = ScadaColors.highPressureDischarge.withValues(alpha: 0.7)
      ..strokeWidth = 2;
    for (double i = -35; i <= 35; i += 14) {
      canvas.drawLine(Offset(center.dx + i, center.dy - 18), Offset(center.dx + i, center.dy + 18), finPaint);
    }

    _drawText(canvas, 'CONDENSADOR', Offset(center.dx, center.dy + 34), ScadaColors.textPrimary, 11, bold: true);
    final fanText = state.circuit.condenser?.fanOperational == true ? 'Aire forzado' : 'Ventilador OFF';
    _drawText(canvas, fanText, Offset(center.dx, center.dy - 34), ScadaColors.textSecondary, 10);
  }

  void _drawExpansionValve(Canvas canvas, Offset center, double w, double h) {
    final bodyPaint = Paint()..color = ScadaColors.surfaceCard;
    final valvePaint = Paint()
      ..color = ScadaColors.lowPressureTwoPhase
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = ScadaColors.borderLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final bgRect = Rect.fromCenter(center: center, width: w * 0.75, height: h * 0.7);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(8)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(8)), strokePaint);

    // Conos de la válvula de expansión
    final leftTriangle = Path()
      ..moveTo(center.dx - 18, center.dy - 12)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx - 18, center.dy + 12)
      ..close();
    final rightTriangle = Path()
      ..moveTo(center.dx + 18, center.dy - 12)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx + 18, center.dy + 12)
      ..close();

    canvas.drawPath(leftTriangle, valvePaint);
    canvas.drawPath(rightTriangle, valvePaint);

    // Diafragma superior
    canvas.drawLine(Offset(center.dx - 12, center.dy - 16), Offset(center.dx + 12, center.dy - 16), strokePaint);
    canvas.drawLine(Offset(center.dx, center.dy - 16), Offset(center.dx, center.dy), strokePaint);

    _drawText(canvas, 'VÁLVULA TXV', Offset(center.dx, center.dy + 32), ScadaColors.textPrimary, 11, bold: true);
    final opening = state.circuit.expansionDevice?.openingPercent.toStringAsFixed(0) ?? '45';
    _drawText(canvas, 'Apertura: $opening%', Offset(center.dx, center.dy - 32), ScadaColors.textSecondary, 10);
  }

  void _drawEvaporator(Canvas canvas, Offset center, double w, double h) {
    final bodyPaint = Paint()..color = ScadaColors.surfaceCard;
    final borderPaint = Paint()
      ..color = ScadaColors.borderLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromCenter(center: center, width: w * 0.8, height: h * 0.7);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);

    // Aletas frías
    final finPaint = Paint()
      ..color = ScadaColors.lowPressureSuction.withValues(alpha: 0.8)
      ..strokeWidth = 2;
    for (double i = -35; i <= 35; i += 14) {
      canvas.drawLine(Offset(center.dx + i, center.dy - 18), Offset(center.dx + i, center.dy + 18), finPaint);
    }

    _drawText(canvas, 'EVAPORADOR', Offset(center.dx, center.dy + 34), ScadaColors.textPrimary, 11, bold: true);
    _drawText(canvas, 'Cámara frigorífica', Offset(center.dx, center.dy - 34), ScadaColors.textSecondary, 10);
  }

  void _drawStateNodes(Canvas canvas, Offset comp, Offset cond, Offset exp, Offset evap) {
    // 1: Aspiración
    _drawNodeBadge(canvas, Offset(comp.dx - 45, comp.dy - 40), '1', ScadaColors.lowPressureSuction);
    // 2: Descarga
    _drawNodeBadge(canvas, Offset(comp.dx + 40, cond.dy + 40), '2', ScadaColors.highPressureDischarge);
    // 3: Salida Condensador / Líquido
    _drawNodeBadge(canvas, Offset(exp.dx + 45, exp.dy - 40), '3', ScadaColors.highPressureLiquid);
    // 4: Salida Válvula / Entrada Evaporador
    _drawNodeBadge(canvas, Offset(evap.dx + 55, exp.dy + 20), '4', ScadaColors.lowPressureTwoPhase);
  }

  void _drawNodeBadge(Canvas canvas, Offset pos, String label, Color color) {
    final bgPaint = Paint()..color = ScadaColors.surfaceCardHighlight;
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(pos, 11, bgPaint);
    canvas.drawCircle(pos, 11, borderPaint);
    _drawText(canvas, label, pos, color, 11, bold: true);
  }

  void _drawText(Canvas canvas, String text, Offset center, Color color, double fontSize, {bool bold = false}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontFamily: 'monospace',
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)));
  }

  @override
  bool shouldRepaint(covariant _PidPainter oldDelegate) {
    return true;
  }
}
