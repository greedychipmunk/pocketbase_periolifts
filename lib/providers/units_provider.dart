import 'package:flutter/material.dart';
import '../services/units_service.dart';

/// Provider for managing unit system state across the app
class UnitsProvider extends ChangeNotifier {
  final UnitsService _unitsService = UnitsService();
  bool _useMetricSystem = false;
  bool _isLoading = true;

  bool get useMetricSystem => _useMetricSystem;
  bool get isLoading => _isLoading;
  
  UnitsProvider() {
    _loadUnitSystem();
  }
  
  /// Load current unit system from SharedPreferences
  Future<void> _loadUnitSystem() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _useMetricSystem = await _unitsService.getUseMetricSystem();
    } catch (e) {
      // If loading fails, keep default (false) and log error
      print('Error loading unit system preference: $e');
      _useMetricSystem = false;
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// Toggle between metric and imperial systems
  Future<void> toggleUnitSystem() async {
    await setUseMetricSystem(!_useMetricSystem);
  }
  
  /// Set unit system preference
  Future<void> setUseMetricSystem(bool useMetric) async {
    if (_useMetricSystem == useMetric) return;
    
    _useMetricSystem = useMetric;
    notifyListeners();
    
    try {
      await _unitsService.setUseMetricSystem(useMetric);
      // Ensure service cache is consistent
      _unitsService.clearCache();
    } catch (e) {
      // If save fails, revert the state to maintain consistency
      _useMetricSystem = !useMetric;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Get weight unit label
  String getWeightUnit() {
    return _useMetricSystem ? 'kg' : 'lbs';
  }
  
  /// Get length unit label
  String getLengthUnit() {
    return _useMetricSystem ? 'cm' : 'in';
  }
  
  /// Convert weight value based on current unit system
  /// Assumes input is always in kg (metric) and converts to display units
  double convertWeightFromKg(double weightInKg) {
    if (_useMetricSystem) {
      return weightInKg;
    } else {
      return weightInKg * 2.20462; // kg to lbs
    }
  }
  
  /// Convert weight value to kg (for storage)
  /// Assumes input is in current display units
  double convertWeightToKg(double weight) {
    if (_useMetricSystem) {
      return weight;
    } else {
      return weight / 2.20462; // lbs to kg
    }
  }
  
  /// Convert length value based on current unit system
  /// Assumes input is always in cm (metric) and converts to display units
  double convertLengthFromCm(double lengthInCm) {
    if (_useMetricSystem) {
      return lengthInCm;
    } else {
      return lengthInCm * 0.393701; // cm to in
    }
  }
  
  /// Convert length value to cm (for storage)
  /// Assumes input is in current display units
  double convertLengthToCm(double length) {
    if (_useMetricSystem) {
      return length;
    } else {
      return length / 0.393701; // in to cm
    }
  }
  
  /// Format weight with appropriate unit
  String formatWeight(double weightInKg, {int decimals = 1}) {
    final convertedWeight = convertWeightFromKg(weightInKg);
    return '${convertedWeight.toStringAsFixed(decimals)} ${getWeightUnit()}';
  }
  
  /// Format length with appropriate unit
  String formatLength(double lengthInCm, {int decimals = 1}) {
    final convertedLength = convertLengthFromCm(lengthInCm);
    return '${convertedLength.toStringAsFixed(decimals)} ${getLengthUnit()}';
  }
  
  /// Get unit system description for settings
  String getSystemDescription() {
    return _useMetricSystem ? 'Metric (kg, cm)' : 'Imperial (lbs, in)';
  }
}