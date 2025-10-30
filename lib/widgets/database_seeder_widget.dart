import 'package:flutter/material.dart';
import '../services/seeder_helper.dart';

class DatabaseSeederWidget extends StatefulWidget {
  const DatabaseSeederWidget({Key? key}) : super(key: key);

  @override
  _DatabaseSeederWidgetState createState() => _DatabaseSeederWidgetState();
}

class _DatabaseSeederWidgetState extends State<DatabaseSeederWidget> {
  bool _isSeeding = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Seeder',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSeeding
                      ? null
                      : () => _runSeeder(SeederHelper.runSeeder),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Full Seed (Clear + Seed)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSeeding
                      ? null
                      : () => _runSeeder(SeederHelper.quickSeed),
                  icon: const Icon(Icons.add),
                  label: const Text('Quick Seed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSeeding
                      ? null
                      : () => _runSeeder(SeederHelper.seedExercisesOnly),
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Exercises Only'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSeeding
                      ? null
                      : () => _runSeeder(SeederHelper.clearAllData),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Clear All Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (_isSeeding) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Seeding in progress...'),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runSeeder(Future<void> Function() seederFunction) async {
    setState(() {
      _isSeeding = true;
      _statusMessage = 'Starting seeder...';
    });

    try {
      await seederFunction();
      setState(() {
        _statusMessage = 'Seeding completed successfully! ✅';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e ❌';
      });
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }
}
