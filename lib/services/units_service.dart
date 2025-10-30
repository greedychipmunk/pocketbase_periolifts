import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling unit conversions and system preferences
class UnitsService {
  static const String _useMetricSystemKey = 'useMetricSystem';
  
  // Conversion constants
  static const double _kgToLbsMultiplier = 2.20462;
  static const double _cmToInMultiplier = 0.393701;
  
  bool? _useMetricSystem;
  
  /// Get current unit system preference from cache or SharedPreferences
  Future<bool> getUseMetricSystem() async {
    if (_useMetricSystem != null) {
      return _useMetricSystem!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    _useMetricSystem = prefs.getBool(_useMetricSystemKey) ?? false;
    return _useMetricSystem!;
  }
  
  /// Set unit system preference and save to SharedPreferences
  Future<void> setUseMetricSystem(bool useMetric) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useMetricSystemKey, useMetric);
    _useMetricSystem = useMetric;
  }
  
  /// Convert weight value based on current unit system
  /// If useMetric is true, assumes value is in kg and returns kg
  /// If useMetric is false, converts kg to lbs or returns lbs as-is
  Future<double> convertWeight(double weight, {bool? fromMetric}) async {
    final useMetric = await getUseMetricSystem();
    
    // If we want metric output
    if (useMetric) {
      // If input is from imperial system, convert to metric
      if (fromMetric == false) {
        return weight / _kgToLbsMultiplier; // lbs to kg
      }
      return weight; // Already in kg
    } else {
      // If we want imperial output  
      // If input is from metric system, convert to imperial
      if (fromMetric == true) {
        return weight * _kgToLbsMultiplier; // kg to lbs
      }
      return weight; // Already in lbs
    }
  }
  
  /// Convert length value based on current unit system
  Future<double> convertLength(double length, {bool? fromMetric}) async {
    final useMetric = await getUseMetricSystem();
    
    // If we want metric output
    if (useMetric) {
      // If input is from imperial system, convert to metric
      if (fromMetric == false) {
        return length / _cmToInMultiplier; // in to cm
      }
      return length; // Already in cm
    } else {
      // If we want imperial output
      // If input is from metric system, convert to imperial
      if (fromMetric == true) {
        return length * _cmToInMultiplier; // cm to in
      }
      return length; // Already in in
    }
  }
  
  /// Get weight unit label based on current system
  Future<String> getWeightUnit() async {
    final useMetric = await getUseMetricSystem();
    return useMetric ? 'kg' : 'lbs';
  }
  
  /// Get length unit label based on current system
  Future<String> getLengthUnit() async {
    final useMetric = await getUseMetricSystem();
    return useMetric ? 'cm' : 'in';
  }
  
  /// Format weight with appropriate unit
  Future<String> formatWeight(double weight, {int decimals = 1, bool? fromMetric}) async {
    final convertedWeight = await convertWeight(weight, fromMetric: fromMetric);
    final unit = await getWeightUnit();
    return '${convertedWeight.toStringAsFixed(decimals)} $unit';
  }
  
  /// Format length with appropriate unit
  Future<String> formatLength(double length, {int decimals = 1, bool? fromMetric}) async {
    final convertedLength = await convertLength(length, fromMetric: fromMetric);
    final unit = await getLengthUnit();
    return '${convertedLength.toStringAsFixed(decimals)} $unit';
  }
  
  /// Clear cached values (useful for testing or when preferences change externally)
  void clearCache() {
    _useMetricSystem = null;
  }
}