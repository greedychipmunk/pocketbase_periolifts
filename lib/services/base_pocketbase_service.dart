import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';

/// Base service class for all PocketBase-related services
/// 
/// Provides common functionality including error handling, pagination,
/// and PocketBase client access.
abstract class BasePocketBaseService {
  /// Access to the PocketBase instance
  final PocketBase pb = PocketBaseConfig.instance;
  
  /// Handle PocketBase errors and convert to user-friendly messages
  /// 
  /// [error] The error object from PocketBase operations
  /// Returns a human-readable error message
  String handleError(dynamic error) {
    if (error is ClientException) {
      final response = error.response;
      
      // Handle validation errors
      if (response['data'] != null && response['data'] is Map) {
        final data = response['data'] as Map<String, dynamic>;
        final fieldErrors = <String>[];
        
        data.forEach((field, errors) {
          if (errors is Map && errors['message'] != null) {
            fieldErrors.add('${field}: ${errors['message']}');
          }
        });
        
        if (fieldErrors.isNotEmpty) {
          return fieldErrors.join(', ');
        }
      }
      
      // Return generic message from response
      return response['message'] ?? 'Unknown error occurred';
    }
    
    // Return the string representation for other errors
    return error.toString();
  }
  
  /// Get common pagination parameters for PocketBase queries
  /// 
  /// [page] Page number (1-based)
  /// [perPage] Number of items per page
  /// [filter] PocketBase filter expression
  /// [sort] Sort expression (e.g., '-created' for descending)
  /// [expand] Relations to expand
  /// 
  /// Returns a map of query parameters
  Map<String, dynamic> getPaginationParams({
    int page = 1,
    int perPage = 20,
    String? filter,
    String? sort,
    String? expand,
  }) {
    final params = <String, dynamic>{
      'page': page,
      'perPage': perPage,
    };
    
    if (filter != null && filter.isNotEmpty) {
      params['filter'] = filter;
    }
    
    if (sort != null && sort.isNotEmpty) {
      params['sort'] = sort;
    }
    
    if (expand != null && expand.isNotEmpty) {
      params['expand'] = expand;
    }
    
    return params;
  }
  
  /// Check if the current user is authenticated
  bool get isAuthenticated => pb.authStore.isValid;
  
  /// Get the current user ID
  String? get currentUserId => pb.authStore.model?.id;
  
  /// Create a filter for user-specific records
  /// 
  /// [userField] The field name that contains the user ID (default: 'user_id')
  /// Returns a filter string for the current user
  String createUserFilter({String userField = 'user_id'}) {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return '$userField = "$userId"';
  }
  
  /// Combine multiple filter expressions with AND
  /// 
  /// [filters] List of filter expressions
  /// Returns a combined filter string
  String combineFilters(List<String> filters) {
    final nonEmptyFilters = filters.where((f) => f.isNotEmpty).toList();
    if (nonEmptyFilters.isEmpty) return '';
    if (nonEmptyFilters.length == 1) return nonEmptyFilters.first;
    return nonEmptyFilters.map((f) => '($f)').join(' && ');
  }
}