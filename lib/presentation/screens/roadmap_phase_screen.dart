import 'package:flutter/material.dart';
import '../theme/scada_colors.dart';

/// Pantalla informativa rigurosa para módulos correspondientes a fases futuras del roadmap.
class RoadmapPhaseScreen extends StatelessWidget {
  final String title;
  final String phaseBadge;
  final String description;
  final List<String> plannedFeatures;
  final IconData icon;

  const RoadmapPhaseScreen({
    super.key,
    required this.title,
    required this.phaseBadge,
    required this.description,
    required this.plannedFeatures,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScadaColors.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ScadaColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ScadaColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ScadaColors.infoBlue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: ScadaColors.infoBlue),
                    ),
                    child: Icon(icon, color: ScadaColors.infoBlue, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Chip(
                          label: Text(phaseBadge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          backgroundColor: ScadaColors.surface,
                          side: const BorderSide(color: ScadaColors.borderLight),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ScadaColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: const TextStyle(fontSize: 13, color: ScadaColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'FUNCIONALIDADES PROGRAMADAS PARA ESTA FASE:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: ScadaColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              ...plannedFeatures.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, size: 6, color: ScadaColors.infoBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(f, style: const TextStyle(fontSize: 12, color: ScadaColors.textPrimary)),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ScadaColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: ScadaColors.textMuted),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Actualmente estás ejecutando la FASE 1 (Fundamentos y Ciclo Básico). Este módulo se activará según el orden riguroso del roadmap.',
                        style: TextStyle(fontSize: 11, color: ScadaColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
