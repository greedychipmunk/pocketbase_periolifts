import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../widgets/futuristic_widgets.dart';

/// A screen to demonstrate the futuristic theme styling
class ThemeShowcaseScreen extends StatelessWidget {
  const ThemeShowcaseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Futuristic Theme Showcase'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Color Palette Demo
            FuturisticCard(
              showGradient: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color Palette',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildColorSwatch('Electric Blue', BaseThemeConfig.primaryColor),
                      const SizedBox(width: 16),
                      _buildColorSwatch('Cyan', BaseThemeConfig.secondaryColor),
                      const SizedBox(width: 16),
                      _buildColorSwatch('Purple', BaseThemeConfig.accentColor),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Buttons Demo
            FuturisticCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buttons',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FuturisticButton(
                    text: 'Start Workout',
                    icon: Icons.play_arrow,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  FuturisticButton(
                    text: 'Loading...',
                    isLoading: true,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Standard Button'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cards Demo
            FuturisticCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cards & Surfaces',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.fitness_center, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Standard Card',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enhanced with futuristic styling',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Input Fields Demo
            FuturisticCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Input Fields',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Workout Name',
                      hintText: 'Enter workout name',
                      prefixIcon: Icon(Icons.fitness_center),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Additional notes...',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Theme Info
            FuturisticCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Information',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Mode', isDark ? 'Dark' : 'Light'),
                  _buildInfoRow('Primary Color', '#0077FF'),
                  _buildInfoRow('Secondary Color', '#00FFFF'),
                  _buildInfoRow('Accent Color', '#6B46C1'),
                  _buildInfoRow('Material Design', '3.0'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: BaseThemeConfig.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}