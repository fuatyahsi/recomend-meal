import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import 'smart_kitchen_screen.dart';
import 'vision_lab_screen.dart';

class FlavorStudioHubScreen extends StatelessWidget {
  const FlavorStudioHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isTr = provider.languageCode == 'tr';
    final tools = [
      (
        Icons.photo_camera_back_rounded,
        isTr ? 'Görsel Analiz' : 'Visual Analysis',
        isTr
            ? 'Fotoğraf, fiş ve tabak analizini tek merkezden aç.'
            : 'Open photo, OCR, and smart scanning tools.',
        const [Color(0xFFDFF5FF), Color(0xFFF4FBFF)],
        () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VisionLabScreen()),
          );
        },
      ),
      (
        Icons.record_voice_over_rounded,
        isTr ? 'Sesli Şef Yardımcısı' : 'Voice Chef Assistant',
        isTr
            ? 'Tarifi sen seç, sonra adımları sesli destekle takip et.'
            : 'Pick the recipe first, then follow the steps with voice support.',
        const [Color(0xFFECE4FF), Color(0xFFF6F1FF)],
        () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SmartKitchenScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(isTr ? 'Lezzet Atölyesi' : 'Flavor Studio'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.18),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.18, 1.0],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF102A43),
                    Color(0xFF1F4E79),
                    Color(0xFF6DA7D9)
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1F4E79).withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_mosaic_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isTr ? 'Lezzet Atölyesi' : 'Flavor Studio',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isTr
                        ? 'Mutfağı yöneten güçlü araçları tek ekranda topla, ihtiyacın olan akışı seç.'
                        : 'Your premium hub for the strongest kitchen acceleration tools.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...tools.map(
              (tool) => InkWell(
                onTap: tool.$5,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: tool.$4),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.surface.withValues(alpha: 0.84),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(tool.$1, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tool.$2,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tool.$3,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
