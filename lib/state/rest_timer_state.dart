import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/vibration_service.dart';

/// State class for rest timer
class RestTimerState {
  final bool isResting;
  final int remainingRestTime;
  final Duration? originalRestTime;

  const RestTimerState({
    this.isResting = false,
    this.remainingRestTime = 0,
    this.originalRestTime,
  });

  RestTimerState copyWith({
    bool? isResting,
    int? remainingRestTime,
    Duration? originalRestTime,
  }) {
    return RestTimerState(
      isResting: isResting ?? this.isResting,
      remainingRestTime: remainingRestTime ?? this.remainingRestTime,
      originalRestTime: originalRestTime ?? this.originalRestTime,
    );
  }

  /// Get formatted time string (MM:SS)
  String get formattedTime {
    final minutes = remainingRestTime ~/ 60;
    final seconds = remainingRestTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get progress as percentage (0.0 to 1.0)
  double get progress {
    if (originalRestTime == null || originalRestTime!.inSeconds == 0) {
      return 0.0;
    }
    final total = originalRestTime!.inSeconds;
    final elapsed = total - remainingRestTime;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'RestTimerState('
        'isResting: $isResting, '
        'remainingTime: $remainingRestTime, '
        'formatted: $formattedTime'
        ')';
  }
}

/// Notifier for managing rest timer state
class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  final VibrationService _vibrationService = VibrationService();

  RestTimerNotifier() : super(const RestTimerState()) {
    _initializeNotifications();
  }

  /// Initialize notification service
  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
      }
    }
  }

  /// Trigger notification and vibration when rest timer completes
  Future<void> _onTimerComplete() async {
    try {
      // Trigger notification
      await _notificationService.showRestTimerCompletionNotification();
      
      // Trigger vibration (works regardless of notification settings)
      await _vibrationService.vibrateForRestTimer();
    } catch (e) {
      if (kDebugMode) {
        print('Error showing rest timer completion notification or vibration: $e');
      }
    }
  }

  /// Start the rest timer
  void startTimer(Duration restDuration) {
    // Cancel any existing timer
    _timer?.cancel();

    final seconds = restDuration.inSeconds;
    
    state = RestTimerState(
      isResting: true,
      remainingRestTime: seconds,
      originalRestTime: restDuration,
    );

    // Start countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingRestTime > 0) {
        state = state.copyWith(
          remainingRestTime: state.remainingRestTime - 1,
        );
      } else {
        // Timer finished
        timer.cancel();
        state = state.copyWith(isResting: false);
        _timer = null;
        
        // Trigger notification
        _onTimerComplete();
      }
    });
  }

  /// Skip/cancel the rest timer
  void skipRest() {
    _timer?.cancel();
    _timer = null;
    
    state = const RestTimerState(
      isResting: false,
      remainingRestTime: 0,
    );
  }

  /// Pause the timer
  void pauseTimer() {
    _timer?.cancel();
    _timer = null;
    // Keep the current state but stop the countdown
  }

  /// Resume the timer from current remaining time
  void resumeTimer() {
    if (!state.isResting || state.remainingRestTime <= 0) {
      return;
    }

    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingRestTime > 0) {
        state = state.copyWith(
          remainingRestTime: state.remainingRestTime - 1,
        );
      } else {
        timer.cancel();
        state = state.copyWith(isResting: false);
        _timer = null;
        
        // Trigger notification
        _onTimerComplete();
      }
    });
  }

  /// Add time to the current timer
  void addTime(int seconds) {
    if (state.isResting) {
      state = state.copyWith(
        remainingRestTime: state.remainingRestTime + seconds,
      );
    }
  }

  /// Subtract time from the current timer
  void subtractTime(int seconds) {
    if (state.isResting) {
      final newTime = (state.remainingRestTime - seconds).clamp(0, 999999);
      state = state.copyWith(remainingRestTime: newTime);
      
      if (newTime == 0) {
        skipRest();
      }
    }
  }

  /// Check if timer is actively counting down
  bool get isActivelyTiming => state.isResting && _timer != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}