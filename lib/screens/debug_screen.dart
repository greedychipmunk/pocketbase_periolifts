import 'package:flutter/material.dart';
import '../widgets/database_seeder_widget.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
        backgroundColor: Colors.orange,
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            DatabaseSeederWidget(),
            // Add more debug tools here as needed
          ],
        ),
      ),
    );
  }
}
