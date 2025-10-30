import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../providers/theme_provider.dart';
import '../providers/units_provider.dart';
import '../providers/rest_time_settings_provider.dart';
import '../widgets/base_layout.dart';
import '../constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  final WorkoutService workoutService;
  final AuthService authService;
  final VoidCallback onAuthError;

  const SettingsScreen({
    Key? key,
    required this.workoutService,
    required this.authService,
    required this.onAuthError,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  
  // User preferences
  bool _enableSounds = true;
  bool _enableVibration = true;
  bool _enableNotifications = true;
  
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _enableSounds = prefs.getBool('enableSounds') ?? true;
        _enableVibration = prefs.getBool('enableVibration') ?? true;
        _enableNotifications = prefs.getBool('enableNotifications') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      print('Error saving setting $key: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving setting: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.authService.signOut();
        // The app will automatically redirect to login due to auth state change
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: $e')),
          );
        }
      }
    }
  }

  void _showRestTimeDialog(RestTimeSettingsProvider restTimeProvider) {
    int tempValue = restTimeProvider.defaultRestTimeSeconds;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Rest Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set the default rest time between sets:'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  Slider(
                    value: tempValue.toDouble(),
                    min: 30,
                    max: 300,
                    divisions: 27,
                    label: '${tempValue}s (${(tempValue / 60).toStringAsFixed(1)}min)',
                    onChanged: (value) {
                      setState(() {
                        tempValue = value.round();
                      });
                    },
                  ),
                  Text(
                    '${tempValue} seconds (${(tempValue / 60).toStringAsFixed(1)} minutes)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await restTimeProvider.setDefaultRestTimeSeconds(tempValue);
                Navigator.of(context).pop();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving rest time: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.fitness_center, size: 48),
      children: [
        const Text(
          'A comprehensive workout tracking and periodization app designed to help you achieve your fitness goals.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:\n'
          '• Workout tracking with rest timers\n'
          '• Periodized training programs\n'
          '• Progress analytics\n'
          '• Calendar view of workouts\n'
          '• Customizable settings',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      workoutService: widget.workoutService,
      authService: widget.authService,
      onAuthError: widget.onAuthError,
      currentIndex: 4, // Settings tab
      title: 'Settings',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('Workout Settings'),
                Consumer<UnitsProvider>(
                  builder: (context, unitsProvider, child) {
                    return _buildSettingCard(
                      title: 'Units',
                      subtitle: unitsProvider.getSystemDescription(),
                      icon: Icons.straighten,
                      trailing: Switch(
                        value: unitsProvider.useMetricSystem,
                        onChanged: unitsProvider.isLoading ? null : (value) {
                          unitsProvider.setUseMetricSystem(value);
                        },
                      ),
                    );
                  },
                ),
                Consumer<RestTimeSettingsProvider>(
                  builder: (context, restTimeProvider, child) {
                    return Column(
                      children: [
                        _buildSettingCard(
                          title: 'Override Rest Time',
                          subtitle: restTimeProvider.useDefaultRestTime 
                              ? 'Use default rest time instead of program times'
                              : 'Use rest times from workout program',
                          icon: Icons.timer_outlined,
                          trailing: Switch(
                            value: restTimeProvider.useDefaultRestTime,
                            onChanged: restTimeProvider.isLoading ? null : (value) {
                              restTimeProvider.setUseDefaultRestTime(value);
                            },
                          ),
                        ),
                        _buildSettingCard(
                          title: 'Default Rest Time',
                          subtitle: restTimeProvider.useDefaultRestTime
                              ? '${restTimeProvider.defaultRestTimeSeconds}s (${(restTimeProvider.defaultRestTimeSeconds / 60).toStringAsFixed(1)}min)'
                              : 'Enable override to set custom rest time',
                          icon: Icons.timer,
                          onTap: restTimeProvider.useDefaultRestTime && !restTimeProvider.isLoading
                              ? () => _showRestTimeDialog(restTimeProvider) 
                              : null,
                          trailing: restTimeProvider.useDefaultRestTime 
                              ? const Icon(Icons.chevron_right)
                              : null,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Notifications & Sounds'),
                _buildSettingCard(
                  title: 'Enable Notifications',
                  subtitle: 'Receive workout reminders and updates',
                  icon: Icons.notifications,
                  trailing: Switch(
                    value: _enableNotifications,
                    onChanged: (value) async {
                      if (value) {
                        // Request permissions when enabling notifications
                        final granted = await _notificationService.requestPermissions();
                        if (!granted) {
                          if (mounted) {
                            _showPermissionDialog();
                          }
                          return;
                        }
                      }
                      setState(() {
                        _enableNotifications = value;
                      });
                      _saveSetting('enableNotifications', value);
                    },
                  ),
                ),
                _buildSettingCard(
                  title: 'Sound Effects',
                  subtitle: 'Play sounds for timer and completion',
                  icon: Icons.volume_up,
                  trailing: Switch(
                    value: _enableSounds,
                    onChanged: (value) {
                      setState(() {
                        _enableSounds = value;
                      });
                      _saveSetting('enableSounds', value);
                    },
                  ),
                ),
                _buildSettingCard(
                  title: 'Vibration',
                  subtitle: 'Vibrate for timer alerts and feedback',
                  icon: Icons.vibration,
                  trailing: Switch(
                    value: _enableVibration,
                    onChanged: (value) {
                      setState(() {
                        _enableVibration = value;
                      });
                      _saveSetting('enableVibration', value);
                    },
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('App Settings'),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return _buildSettingCard(
                      title: 'Theme',
                      subtitle: themeProvider.getThemeDescription(themeProvider.themeModeString),
                      icon: Icons.palette,
                      onTap: () => _showThemeDialog(themeProvider),
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Support & Info'),
                _buildSettingCard(
                  title: 'About ${AppConstants.appName}',
                  subtitle: 'App version and information',
                  icon: Icons.info,
                  onTap: _showAboutDialog,
                  trailing: const Icon(Icons.chevron_right),
                ),
                _buildSettingCard(
                  title: 'Contact Support',
                  subtitle: 'Get help or report issues',
                  icon: Icons.support_agent,
                  onTap: _showContactDialog,
                  trailing: const Icon(Icons.chevron_right),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Account'),
                _buildSettingCard(
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  icon: Icons.logout,
                  onTap: _handleLogout,
                  trailing: const Icon(Icons.chevron_right),
                  textColor: Colors.red,
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (textColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: textColor ?? Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: textColor?.withOpacity(0.7) ?? Colors.grey[600],
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _showThemeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Follow System'),
              value: 'system',
              groupValue: themeProvider.themeModeString,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeFromString(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Light Mode'),
              value: 'light',
              groupValue: themeProvider.themeModeString,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeFromString(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark Mode'),
              value: 'dark',
              groupValue: themeProvider.themeModeString,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeFromString(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text('Please email help@periolifts.com with any issues and/or feature requests.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Permission'),
        content: const Text(
          'Notification permission was denied. To enable notifications for rest timer completion, '
          'please go to your device settings and allow notifications for PerioLifts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}