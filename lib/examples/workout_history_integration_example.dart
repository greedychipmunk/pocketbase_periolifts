import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';

// Import all the new workout history components
import '../models/workout_history.dart';
import '../services/workout_history_service.dart';
import '../providers/workout_history_providers.dart';
import '../screens/dashboard_screen.dart';
import '../screens/enhanced_workout_history_screen.dart';
import '../screens/workout_history_detail_screen.dart';
import '../screens/workout_stats_screen.dart';
import '../widgets/base_layout.dart';
import '../utils/workout_converter.dart';

// Existing imports (assumed to be available)
import '../services/workout_service.dart';
import '../services/workout_session_service.dart';
import '../services/auth_service.dart';

/// Complete integration example showing how to set up and use the workout history feature
/// This example demonstrates the full workflow from setup to usage
class WorkoutHistoryIntegrationExample extends ConsumerWidget {
  const WorkoutHistoryIntegrationExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Workout History Integration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const IntegrationSetupScreen(),
    );
  }
}

/// Screen showing how to set up the workout history services and providers
class IntegrationSetupScreen extends StatefulWidget {
  const IntegrationSetupScreen({Key? key}) : super(key: key);

  @override
  State<IntegrationSetupScreen> createState() => _IntegrationSetupScreenState();
}

class _IntegrationSetupScreenState extends State<IntegrationSetupScreen> {
  late Client client;
  late WorkoutService workoutService;
  late WorkoutSessionService workoutSessionService;
  late WorkoutHistoryService workoutHistoryService;
  late AuthService authService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    // 1. Initialize Appwrite client
    client = Client()
      ..setEndpoint('YOUR_APPWRITE_ENDPOINT')
      ..setProject('YOUR_PROJECT_ID')
      ..setSelfSigned(status: true); // Only for development

    // 2. Initialize existing services
    final databases = Databases(client);
    final account = Account(client);
    
    workoutService = WorkoutService(databases: databases, client: client);
    workoutSessionService = WorkoutSessionService(databases: databases, client: client);
    authService = AuthService(account: account);

    // 3. Initialize the new workout history service
    workoutHistoryService = WorkoutHistoryService(
      databases: databases, 
      client: client,
      // These collection IDs should match your Appwrite database structure
      databaseId: '685884d800152b208c1a',
      workoutHistoryCollectionId: 'workout-history',
      workoutStatsCollectionId: 'workout-stats',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      // 4. Override the service providers
      overrides: [
        workoutHistoryServiceProvider.overrideWithValue(workoutHistoryService),
        // You would also override other service providers as needed
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Workout History Integration'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Setup Instructions Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Integration Setup',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '1. Initialize Appwrite Client and Services\n'
                        '2. Create WorkoutHistoryService instance\n'
                        '3. Override Riverpod providers\n'
                        '4. Use enhanced screens and widgets\n'
                        '5. Integrate with existing workflow',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Available Components
              Text(
                'Available Components',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Component buttons
              _buildComponentButton(
                'Dashboard',
                'Dashboard with basic workout functionality',
                Icons.dashboard,
                () => _navigateToDashboard(context),
              ),
              _buildComponentButton(
                'Workout History',
                'Complete workout history with filtering',
                Icons.history,
                () => _navigateToWorkoutHistory(context),
              ),
              _buildComponentButton(
                'Workout Statistics',
                'Advanced analytics and progress tracking',
                Icons.analytics,
                () => _navigateToWorkoutStats(context),
              ),
              _buildComponentButton(
                'Integration Example',
                'See how all components work together',
                Icons.integration_instructions,
                () => _showIntegrationDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComponentButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DashboardScreen(
          workoutService: workoutService,
          workoutSessionService: workoutSessionService,
          authService: authService,
          onAuthError: () {
            // Handle auth error
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Authentication error')),
            );
          },
        ),
      ),
    );
  }

  void _navigateToWorkoutHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EnhancedWorkoutHistoryScreen(),
      ),
    );
  }

  void _navigateToWorkoutStats(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WorkoutStatsScreen(),
      ),
    );
  }

  void _showIntegrationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Integration Workflow'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Complete Integration Steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. User completes workout in WorkoutTrackingScreenRiverpod'),
              SizedBox(height: 8),
              Text('2. Enhanced tracking provider auto-saves progress'),
              SizedBox(height: 8),
              Text('3. Completed workout saved to WorkoutHistoryService'),
              SizedBox(height: 8),
              Text('4. Enhanced Dashboard shows recent workouts'),
              SizedBox(height: 8),
              Text('5. User can view detailed history and analytics'),
              SizedBox(height: 8),
              Text('6. Statistics are calculated from workout history'),
              SizedBox(height: 16),
              Text(
                'Key Integration Points:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• WorkoutConverter for data transformation'),
              SizedBox(height: 4),
              Text('• Riverpod providers for state management'),
              SizedBox(height: 4),
              Text('• Enhanced UI components with history'),
              SizedBox(height: 4),
              Text('• BaseLayout navigation integration'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Example of how to integrate workout history into an existing app structure
class IntegratedAppExample extends ConsumerWidget {
  const IntegratedAppExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This would be your main app structure
    return MaterialApp(
      title: 'Periolifts with Workout History',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Your existing app routing and structure would go here
      home: const IntegratedHomeScreen(),
    );
  }
}

/// Example home screen showing integration with BaseLayout
class IntegratedHomeScreen extends StatelessWidget {
  const IntegratedHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock services - in real app these would be properly initialized
    final mockWorkoutService = _MockWorkoutService();
    final mockWorkoutSessionService = _MockWorkoutSessionService();
    final mockWorkoutHistoryService = _MockWorkoutHistoryService();
    final mockAuthService = _MockAuthService();

    // Example of using the enhanced BaseLayout with workout history
    return BaseLayout(
      workoutService: mockWorkoutService,
      workoutSessionService: mockWorkoutSessionService,
      workoutHistoryService: mockWorkoutHistoryService, // New parameter
      authService: mockAuthService,
      onAuthError: () {
        // Handle authentication errors
      },
      currentIndex: 0,
      title: 'Periolifts',
      // This child would be your enhanced dashboard
      child: Container(
        padding: const EdgeInsets.all(16),
        child: const Column(
          children: [
            Text(
              'Integration Complete!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'The app now includes:\n'
              '• Workout history tracking\n'
              '• Advanced analytics\n'
              '• Progress visualization\n'
              '• Enhanced user experience',
            ),
          ],
        ),
      ),
    );
  }
}

// Mock services for example purposes
class _MockWorkoutService extends WorkoutService {
  _MockWorkoutService() : super(databases: Databases(Client()), client: Client());
}

class _MockWorkoutSessionService extends WorkoutSessionService {
  _MockWorkoutSessionService() : super(databases: Databases(Client()), client: Client());
}

class _MockWorkoutHistoryService extends WorkoutHistoryService {
  _MockWorkoutHistoryService() : super(databases: Databases(Client()), client: Client());
}

class _MockAuthService extends AuthService {
  _MockAuthService() : super(account: Account(Client()));
}

/// Usage example showing how to use the workout history components
/// 
/// ```dart
/// // 1. Set up providers in your main app
/// runApp(
///   ProviderScope(
///     overrides: [
///       workoutHistoryServiceProvider.overrideWithValue(workoutHistoryService),
///     ],
///     child: MyApp(),
///   ),
/// );
/// 
/// // 2. Use dashboard screen instead of enhanced dashboard
/// Widget _buildDashboard() {
///   return DashboardScreen(
///     workoutService: workoutService,
///     workoutSessionService: workoutSessionService,
///     authService: authService,
///     onAuthError: _handleAuthError,
///   );
/// }
/// 
/// // 3. Navigate to workout history
/// void _viewWorkoutHistory() {
///   Navigator.push(
///     context,
///     MaterialPageRoute(
///       builder: (context) => const EnhancedWorkoutHistoryScreen(),
///     ),
///   );
/// }
/// 
/// // 4. View detailed workout stats
/// void _viewWorkoutStats() {
///   Navigator.push(
///     context,
///     MaterialPageRoute(
///       builder: (context) => const WorkoutStatsScreen(),
///     ),
///   );
/// }
/// 
/// // 5. Enhanced tracking with history saving
/// void _startWorkout(Workout workout) {
///   Navigator.push(
///     context,
///     MaterialPageRoute(
///       builder: (context) => EnhancedWorkoutTrackingScreen(
///         workout: workout,
///         workoutService: workoutService,
///         workoutHistoryService: workoutHistoryService,
///         authService: authService,
///         onAuthError: _handleAuthError,
///       ),
///     ),
///   );
/// }
/// ```