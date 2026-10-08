import 'package:flutter/material.dart';
import '../../../state/session_coordinator.dart';
import '../../theme/scada_colors.dart';

/// Barra de control interactiva para operaciones de Deshacer, Rehacer y Reinicio jerárquico.
/// Diseñada con estética industrial SCADA y adaptativa para Android y Windows.
class SessionControlBar extends StatelessWidget {
  final SessionCoordinator coordinator;
  final bool compact;

  const SessionControlBar({
    super.key,
    required this.coordinator,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) {
        final canUndo = coordinator.canUndo;
        final canRedo = coordinator.canRedo;
        final nextUndo = coordinator.nextUndoDescription;
        final nextRedo = coordinator.nextRedoDescription;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón DESHACER
            Tooltip(
              message: canUndo
                  ? 'Deshacer: $nextUndo'
                  : 'Deshacer (Sin acciones en el historial)',
              child: compact
                  ? IconButton(
                      icon: const Icon(Icons.undo, size: 18),
                      color: canUndo ? ScadaColors.infoBlue : ScadaColors.textMuted,
                      onPressed: canUndo ? () => coordinator.undo() : null,
                      visualDensity: VisualDensity.compact,
                    )
                  : OutlinedButton.icon(
                      onPressed: canUndo ? () => coordinator.undo() : null,
                      icon: const Icon(Icons.undo, size: 14),
                      label: Text(
                        'DESHACER${canUndo ? ' (${coordinator.undoCount})' : ''}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: canUndo ? ScadaColors.infoBlue : ScadaColors.textMuted,
                        side: BorderSide(
                          color: canUndo
                              ? ScadaColors.infoBlue.withValues(alpha: 0.6)
                              : ScadaColors.border,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
            ),
            const SizedBox(width: 6),

            // Botón REHACER
            Tooltip(
              message: canRedo
                  ? 'Rehacer: $nextRedo'
                  : 'Rehacer (Sin acciones deshechas)',
              child: compact
                  ? IconButton(
                      icon: const Icon(Icons.redo, size: 18),
                      color: canRedo ? ScadaColors.cyanAccent : ScadaColors.textMuted,
                      onPressed: canRedo ? () => coordinator.redo() : null,
                      visualDensity: VisualDensity.compact,
                    )
                  : OutlinedButton.icon(
                      onPressed: canRedo ? () => coordinator.redo() : null,
                      icon: const Icon(Icons.redo, size: 14),
                      label: Text(
                        'REHACER${canRedo ? ' (${coordinator.redoCount})' : ''}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: canRedo ? ScadaColors.cyanAccent : ScadaColors.textMuted,
                        side: BorderSide(
                          color: canRedo
                              ? ScadaColors.cyanAccent.withValues(alpha: 0.6)
                              : ScadaColors.border,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
            ),
            const SizedBox(width: 6),

            // Botón REINICIAR (Abre menú jerárquico con diálogo de confirmación)
            Tooltip(
              message: 'Opciones de reinicio (Práctica, Instalación, Total)',
              child: compact
                  ? IconButton(
                      icon: const Icon(Icons.restart_alt, size: 18),
                      color: ScadaColors.warningAmber,
                      onPressed: () => _showResetModal(context),
                      visualDensity: VisualDensity.compact,
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _showResetModal(context),
                      icon: const Icon(Icons.restart_alt, size: 14),
                      label: const Text(
                        'REINICIAR',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScadaColors.warningAmber.withValues(alpha: 0.2),
                        foregroundColor: ScadaColors.warningAmber,
                        side: BorderSide(color: ScadaColors.warningAmber.withValues(alpha: 0.7)),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showResetModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ScadaColors.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: ScadaColors.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.restart_alt, color: ScadaColors.warningAmber, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'OPCIONES DE REINICIO DE FRIGOLAB',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: ScadaColors.textPrimary,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: ScadaColors.textMuted, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Opción 1: REINICIAR PRÁCTICA
            ListTile(
              tileColor: ScadaColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: ScadaColors.border),
              ),
              leading: const Icon(Icons.school, color: ScadaColors.infoBlue),
              title: const Text(
                'REINICIAR PRÁCTICA ACTUAL',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
              ),
              subtitle: const Text(
                'Devuelve la práctica o montaje en taller a su estado inicial. No afecta al resto de la instalación.',
                style: TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                coordinator.resetPractice();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Práctica restablecida al estado inicial.'),
                    backgroundColor: ScadaColors.infoBlue,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // Opción 2: REINICIAR INSTALACIÓN (Con confirmación previa)
            ListTile(
              tileColor: ScadaColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: ScadaColors.border),
              ),
              leading: const Icon(Icons.build_circle, color: ScadaColors.warningAmber),
              title: const Text(
                'REINICIAR INSTALACIÓN',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
              ),
              subtitle: const Text(
                'Devuelve la máquina al ciclo básico inicial (detiene simulación, restaura actuadores y elimina fallos).',
                style: TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmResetInstallation(context);
              },
            ),
            const SizedBox(height: 10),

            // Opción 3: REINICIAR TODO (Con confirmación previa)
            ListTile(
              tileColor: ScadaColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: ScadaColors.dangerRed),
              ),
              leading: const Icon(Icons.refresh, color: ScadaColors.dangerRed),
              title: const Text(
                'REINICIAR TODO',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ScadaColors.dangerRed),
              ),
              subtitle: const Text(
                'Restaura el estado global completo y limpia el historial. El progreso educativo NO se eliminará.',
                style: TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmResetAll(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetInstallation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: ScadaColors.surfaceCard,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: ScadaColors.warningAmber),
            SizedBox(width: 8),
            Text('¿Reiniciar la instalación?', style: TextStyle(fontSize: 14, color: ScadaColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Se perderán los cambios realizados en el circuito, tuberías y actuadores desde el último estado guardado.',
          style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('CANCELAR', style: TextStyle(color: ScadaColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dlgCtx);
              coordinator.resetInstallation();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Instalación reiniciada al estado nominal de fábrica.'),
                  backgroundColor: ScadaColors.warningAmber,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.warningAmber, foregroundColor: Colors.black),
            child: const Text('REINICIAR INSTALACIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmResetAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: ScadaColors.surfaceCard,
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: ScadaColors.dangerRed),
            SizedBox(width: 8),
            Text('¿Reiniciar FrigoLab?', style: TextStyle(fontSize: 14, color: ScadaColors.textPrimary)),
          ],
        ),
        content: const Text(
          'La instalación, prácticas, montajes y configuración volverán a su estado inicial y el historial de acciones se vaciará.\n\nEl progreso educativo permanente no se eliminará.',
          style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('CANCELAR', style: TextStyle(color: ScadaColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dlgCtx);
              coordinator.resetAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('FrigoLab restablecido a valores iniciales globales.'),
                  backgroundColor: ScadaColors.dangerRed,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.dangerRed, foregroundColor: Colors.white),
            child: const Text('REINICIAR TODO', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
