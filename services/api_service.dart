import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import '../models/auth_model.dart'; // AuthResponse, User, DecodedToken burada tanımlı
import '../models/exercise_model.dart'; // Exercise modeli burada tanımlı
import '../models/workout_model.dart'; // WorkOut modeli burada tanımlı
import '../models/workoutitem_model.dart'; // WorkOutItem ve Unit burada tanımlı
import '../pages/create_workout_page.dart'; // WorkoutItemData için

class ApiService {
  static const String baseUrl = 'https://api.teknolojiport.com/api';
  static const Duration timeoutDuration = Duration(seconds: 30);

  static void _log(String message) {
    developer.log(message, name: 'ApiService');
  }

  static Future<http.Response> _makeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(timeoutDuration);
      return response;
    } catch (e) {
      _log('Request error: $e');
      rethrow;
    }
  }

  /// Safely parse JSON response
  static dynamic _safeJsonDecode(String responseBody) {
    if (responseBody.isEmpty) {
      throw Exception('Empty response body');
    }

    try {
      return jsonDecode(responseBody);
    } catch (e) {
      _log('JSON decode error: $e');
      _log('Response body: $responseBody');
      throw Exception('Invalid JSON response: $e');
    }
  }

  /// JWT token'ı çözüp Map olarak döner
  static Map<String, dynamic> decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Geçersiz token formatı');

    final payload = parts[1];
    final normalized = base64.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final payloadMap = json.decode(decoded);

    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Geçersiz payload');
    }

    return payloadMap;
  }

  /// Login işlemi
  static Future<AuthResponse> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return AuthResponse(
        token: '',
        success: false,
        message: 'E-posta ve şifre gerekli',
        user: null,
      );
    }

    try {
      _log('Login attempt with email: $email');

      final requestBody = {'email': email.trim(), 'password': password.trim()};

      final response = await _makeRequest(
        () => http.post(
          Uri.parse('$baseUrl/Auth/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestBody),
        ),
      );

      _log('Response status code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _safeJsonDecode(response.body);
        AuthResponse authResponse = AuthResponse.fromJson(data);

        if (authResponse.token.isNotEmpty) {
          try {
            final decoded = decodeJwtPayload(authResponse.token);
            authResponse = authResponse.copyWith(
              decodedToken: DecodedToken.fromJson(decoded),
            );
            _log('JWT decoded successfully');
          } catch (e) {
            _log('JWT decode error: $e');
          }
        }

        return authResponse;
      } else {
        final errorData = _safeJsonDecode(response.body);
        String errorMessage =
            errorData['message']?.toString() ??
            errorData['error']?.toString() ??
            'Giriş başarısız: HTTP ${response.statusCode}';

        return AuthResponse(
          token: '',
          success: false,
          message: errorMessage,
          user: null,
        );
      }
    } catch (e) {
      _log('Login exception: $e');
      return AuthResponse(
        token: '',
        success: false,
        message: 'Ağ hatası: Bağlantınızı kontrol edin',
        user: null,
      );
    }
  }

  /// Fetch exercises from API
  static Future<List<Exercise>> getExercises() async {
    try {
      _log('Fetching exercises from API');

      // Get JWT token for authentication
      final token = await AuthHelper.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final response = await _makeRequest(
        () => http.get(
          Uri.parse('$baseUrl/exercise'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      _log('Exercises response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = _safeJsonDecode(response.body);

        // Handle different response structures
        List<dynamic> exercisesData;

        if (responseData is List) {
          // Direct array response
          exercisesData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          // Wrapped response - check common wrapper keys
          if (responseData.containsKey('data')) {
            exercisesData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('exercises')) {
            exercisesData = responseData['exercises'] as List<dynamic>;
          } else if (responseData.containsKey('items')) {
            exercisesData = responseData['items'] as List<dynamic>;
          } else if (responseData.containsKey('results')) {
            exercisesData = responseData['results'] as List<dynamic>;
          } else {
            // If it's a single exercise object, wrap it in a list
            exercisesData = [responseData];
          }
        } else {
          throw Exception('Unexpected response format');
        }

        final exercises = exercisesData
            .where((json) => json != null)
            .map((json) => Exercise.fromJson(json as Map<String, dynamic>))
            .toList();
        _log('Successfully fetched ${exercises.length} exercises');
        return exercises;
      } else {
        final errorData = _safeJsonDecode(response.body);
        String errorMessage =
            errorData['message']?.toString() ??
            'Failed to fetch exercises: HTTP ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      _log('Get exercises exception: $e');
      rethrow;
    }
  }

  /// Fetch workouts from API
  static Future<List<WorkOut>> getWorkouts() async {
    try {
      _log('Fetching workouts from API');

      // Get JWT token for authentication
      final token = await AuthHelper.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final response = await _makeRequest(
        () => http.get(
          Uri.parse('$baseUrl/WorkOut'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      _log('Workouts response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = _safeJsonDecode(response.body);

        List<dynamic> workoutsData;
        if (responseData is List) {
          workoutsData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            workoutsData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('workouts')) {
            workoutsData = responseData['workouts'] as List<dynamic>;
          } else {
            workoutsData = [responseData];
          }
        } else {
          throw Exception('Unexpected response format');
        }

        final workouts = workoutsData
            .where((json) => json != null)
            .map((json) => WorkOut.fromJson(json as Map<String, dynamic>))
            .toList();
        _log('Successfully fetched ${workouts.length} workouts');
        return workouts;
      } else {
        final errorData = _safeJsonDecode(response.body);
        String errorMessage =
            errorData['message']?.toString() ??
            'Failed to fetch workouts: HTTP ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      _log('Get workouts exception: $e');
      rethrow;
    }
  }

  /// Fetch workout items for a specific workout
  static Future<List<WorkOutItem>> getWorkoutItems(String workoutId) async {
    try {
      _log('Fetching workout items for workout: $workoutId');

      // Get JWT token for authentication
      final token = await AuthHelper.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      if (workoutId.trim().isEmpty) {
        throw Exception('Workout ID cannot be empty');
      }

      final response = await _makeRequest(
        () => http.get(
          Uri.parse(
            '$baseUrl/WorkOutItem?workOutId=$workoutId&include=exercise',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      _log('Workout items response status code: ${response.statusCode}');
      _log('Workout items response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = _safeJsonDecode(response.body);

        List<dynamic> workoutItemsData;
        if (responseData is List) {
          workoutItemsData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            workoutItemsData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('workOutItems')) {
            workoutItemsData = responseData['workOutItems'] as List<dynamic>;
          } else if (responseData.containsKey('items')) {
            workoutItemsData = responseData['items'] as List<dynamic>;
          } else {
            workoutItemsData = [responseData];
          }
        } else {
          throw Exception('Unexpected response format');
        }

        final workoutItems = workoutItemsData
            .where((json) => json != null)
            .map((json) => WorkOutItem.fromJson(json as Map<String, dynamic>))
            .toList();

        _log('Successfully fetched ${workoutItems.length} workout items');

        for (int i = 0; i < workoutItems.length; i++) {
          final item = workoutItems[i];
          _log(
            'WorkoutItem $i: exerciseId=${item.exerciseId}, exercise=${item.exercise.name ?? "null"}',
          );
        }

        return workoutItems;
      } else {
        final errorData = _safeJsonDecode(response.body);
        String errorMessage =
            errorData['message']?.toString() ??
            'Failed to fetch workout items: HTTP ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      _log('Get workout items exception: $e');
      rethrow;
    }
  }

  /// Fetch a specific exercise by ID
  static Future<Exercise?> getExerciseById(String exerciseId) async {
    try {
      _log('Fetching exercise by ID: $exerciseId');

      // Get JWT token for authentication
      final token = await AuthHelper.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      if (exerciseId.trim().isEmpty) {
        throw Exception('Exercise ID cannot be empty');
      }

      final response = await _makeRequest(
        () => http.get(
          Uri.parse('$baseUrl/exercise/$exerciseId'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      _log('Exercise by ID response status code: ${response.statusCode}');
      _log('Exercise by ID response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = _safeJsonDecode(response.body);

        if (responseData == null) {
          return null;
        }

        Map<String, dynamic>? exerciseData;
        if (responseData is Map<String, dynamic>) {
          exerciseData = responseData;
        } else if (responseData is List && responseData.isNotEmpty) {
          exerciseData = responseData.first as Map<String, dynamic>;
        } else {
          return null;
        }

        final exercise = Exercise.fromJson(exerciseData);
        _log('Successfully fetched exercise: ${exercise.name}');
        return exercise;
      } else if (response.statusCode == 404) {
        _log('Exercise not found: $exerciseId');
        return null;
      } else if (response.statusCode == 500) {
        _log(
          'Server error (500) when fetching exercise by ID. Trying fallback method...',
        );
        return await _getExerciseByIdFallback(exerciseId);
      } else {
        _log('Error response body: ${response.body}');
        final errorData = _safeJsonDecode(response.body);
        String errorMessage =
            errorData['message']?.toString() ??
            'Failed to fetch exercise: HTTP ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      _log('Get exercise by ID exception: $e');
      _log('Attempting fallback method for exercise: $exerciseId');
      return await _getExerciseByIdFallback(exerciseId);
    }
  }

  /// Fallback method to get exercise by ID when direct endpoint fails
  static Future<Exercise?> _getExerciseByIdFallback(String exerciseId) async {
    try {
      _log('Using fallback method to fetch exercise: $exerciseId');

      // Fetch all exercises and find the one with matching ID
      final allExercises = await getExercises();

      for (final exercise in allExercises) {
        if (exercise.id == exerciseId) {
          _log('Found exercise via fallback: ${exercise.name}');
          return exercise;
        }
      }

      _log('Exercise not found in fallback method: $exerciseId');
      return null;
    } catch (e) {
      _log('Fallback method failed: $e');
      return null;
    }
  }

  /// Create a new workout with workout items included
  static Future<WorkOut> createWorkoutWithItems({
    required String name,
    required double duration,
    String? description,
    String? image,
    required List<WorkoutItemData> workoutItems,
  }) async {
    try {
      _log('Creating workout with items: $name');

      // Get JWT token and decoded token for consumerId
      final token = await AuthHelper.getToken();
      final decodedToken = await AuthHelper.getDecodedToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      if (decodedToken == null || decodedToken.consumerId.isEmpty) {
        throw Exception('No consumer ID found');
      }

      // Validate input data
      if (name.trim().isEmpty) {
        throw Exception('Workout name cannot be empty');
      }

      if (duration <= 0) {
        throw Exception('Duration must be greater than 0');
      }

      if (workoutItems.isEmpty) {
        throw Exception('At least one workout item is required');
      }

      // Convert WorkoutItemData to the format expected by API
      final workOutItems = workoutItems
          .map(
            (item) => {
              'exerciseId': item.exerciseId,
              'unit': item.unit.index,
              'set': item.set,
              'quantity': item.quantity,
            },
          )
          .toList();

      // Always include all required fields - the API expects them
      final requestBody = <String, dynamic>{
        'name': name.trim(),
        'duration': duration,
        'description':
            description?.trim() ??
            '', // Always include, use empty string if null
        'image':
            image?.trim() ?? '', // Always include, use empty string if null
        'consumerId': decodedToken.consumerId,
        'workOutItems': workOutItems,
      };

      _log('Request body: ${jsonEncode(requestBody)}');
      _log('ConsumerId being sent: ${decodedToken.consumerId}');
      _log('WorkOutItems count: ${workOutItems.length}');

      final response = await _makeRequest(
        () => http.post(
          Uri.parse('$baseUrl/WorkOut'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(requestBody),
        ),
      );

      _log('Create workout response status code: ${response.statusCode}');
      _log('Create workout response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic responseData = _safeJsonDecode(response.body);

        // Check if response is null
        if (responseData == null) {
          throw Exception('Null response from server');
        }

        // Ensure we have a Map to work with
        Map<String, dynamic>? data;
        if (responseData is Map<String, dynamic>) {
          data = responseData;
        } else {
          throw Exception(
            'Invalid response format: expected Map but got ${responseData.runtimeType}',
          );
        }

        final workout = WorkOut.fromJson(data);
        _log('Successfully created workout: ${workout.id}');
        return workout;
      } else {
        // Handle error response safely
        String errorMessage =
            'Failed to create workout: HTTP ${response.statusCode}';

        try {
          final dynamic errorData = _safeJsonDecode(response.body);

          if (errorData != null && errorData is Map<String, dynamic>) {
            // Handle validation errors specifically
            if (response.statusCode == 400 && errorData.containsKey('errors')) {
              final errors = errorData['errors'];
              if (errors is Map<String, dynamic>) {
                final errorMessages = <String>[];

                errors.forEach((field, messages) {
                  if (messages is List) {
                    for (final message in messages) {
                      errorMessages.add('$field: $message');
                    }
                  }
                });

                if (errorMessages.isNotEmpty) {
                  errorMessage =
                      'Validation errors: ${errorMessages.join(', ')}';
                }
              }
            } else {
              // Try to get error message from various possible fields
              errorMessage =
                  errorData['message']?.toString() ??
                  errorData['error']?.toString() ??
                  errorData['title']?.toString() ??
                  errorMessage;
            }
          }
        } catch (e) {
          _log('Error parsing error response: $e');
          // Keep the default error message
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      _log('Create workout exception: $e');
      rethrow;
    }
  }

  /// Create a new workout (legacy method - kept for compatibility)
  static Future<WorkOut> createWorkout({
    required String name,
    required double duration,
    String? description,
    String? image,
  }) async {
    try {
      _log('Creating workout: $name');

      // Get JWT token and decoded token for consumerId
      final token = await AuthHelper.getToken();
      final decodedToken = await AuthHelper.getDecodedToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      if (decodedToken == null || decodedToken.consumerId.isEmpty) {
        throw Exception('No consumer ID found');
      }

      // Validate input data
      if (name.trim().isEmpty) {
        throw Exception('Workout name cannot be empty');
      }

      if (duration <= 0) {
        throw Exception('Duration must be greater than 0');
      }

      // Always include all required fields - the API expects them
      final requestBody = <String, dynamic>{
        'name': name.trim(),
        'duration': duration,
        'description':
            description?.trim() ??
            '', // Always include, use empty string if null
        'image':
            image?.trim() ?? '', // Always include, use empty string if null
        'consumerId': decodedToken.consumerId,
      };

      _log('Request body: ${jsonEncode(requestBody)}');
      _log('ConsumerId being sent: ${decodedToken.consumerId}');

      final response = await _makeRequest(
        () => http.post(
          Uri.parse('$baseUrl/WorkOut'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(requestBody),
        ),
      );

      _log('Create workout response status code: ${response.statusCode}');
      _log('Create workout response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic responseData = _safeJsonDecode(response.body);

        // Check if response is null
        if (responseData == null) {
          throw Exception('Null response from server');
        }

        // Ensure we have a Map to work with
        Map<String, dynamic>? data;
        if (responseData is Map<String, dynamic>) {
          data = responseData;
        } else {
          throw Exception(
            'Invalid response format: expected Map but got ${responseData.runtimeType}',
          );
        }

        final workout = WorkOut.fromJson(data);
        _log('Successfully created workout: ${workout.id}');
        return workout;
      } else {
        // Handle error response safely
        String errorMessage =
            'Failed to create workout: HTTP ${response.statusCode}';

        try {
          final dynamic errorData = _safeJsonDecode(response.body);

          if (errorData != null && errorData is Map<String, dynamic>) {
            // Handle validation errors specifically
            if (response.statusCode == 400 && errorData.containsKey('errors')) {
              final errors = errorData['errors'];
              if (errors is Map<String, dynamic>) {
                final errorMessages = <String>[];

                errors.forEach((field, messages) {
                  if (messages is List) {
                    for (final message in messages) {
                      errorMessages.add('$field: $message');
                    }
                  }
                });

                if (errorMessages.isNotEmpty) {
                  errorMessage =
                      'Validation errors: ${errorMessages.join(', ')}';
                }
              }
            } else {
              // Try to get error message from various possible fields
              errorMessage =
                  errorData['message']?.toString() ??
                  errorData['error']?.toString() ??
                  errorData['title']?.toString() ??
                  errorMessage;
            }
          }
        } catch (e) {
          _log('Error parsing error response: $e');
          // Keep the default error message
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      _log('Create workout exception: $e');
      rethrow;
    }
  }

  /// Create a workout item
  static Future<WorkOutItem> createWorkoutItem({
    required String workoutId,
    required String exerciseId,
    required Unit unit,
    required int set,
    required int quantity,
  }) async {
    try {
      _log('Creating workout item for workout: $workoutId');

      // Get JWT token for authentication
      final token = await AuthHelper.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Validate input data
      if (workoutId.trim().isEmpty) {
        throw Exception('Workout ID cannot be empty');
      }

      if (exerciseId.trim().isEmpty) {
        throw Exception('Exercise ID cannot be empty');
      }

      if (set <= 0) {
        throw Exception('Set count must be greater than 0');
      }

      if (quantity <= 0) {
        throw Exception('Quantity must be greater than 0');
      }

      final requestBody = {
        'workOutId': workoutId.trim(),
        'exerciseId': exerciseId.trim(),
        'unit': unit.index,
        'set': set,
        'quantity': quantity,
      };

      _log('WorkoutItem request body: ${jsonEncode(requestBody)}');

      final response = await _makeRequest(
        () => http.post(
          Uri.parse('$baseUrl/WorkOutItem'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(requestBody),
        ),
      );

      _log('Create workout item response status code: ${response.statusCode}');
      _log('Create workout item response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic responseData = _safeJsonDecode(response.body);

        // Check if response is null
        if (responseData == null) {
          throw Exception('Null response from server');
        }

        // Ensure we have a Map to work with
        Map<String, dynamic>? data;
        if (responseData is Map<String, dynamic>) {
          data = responseData;
        } else {
          throw Exception(
            'Invalid response format: expected Map but got ${responseData.runtimeType}',
          );
        }

        final workoutItem = WorkOutItem.fromJson(data);
        _log('Successfully created workout item: ${workoutItem.id}');
        return workoutItem;
      } else {
        // Handle error response safely
        String errorMessage =
            'Failed to create workout item: HTTP ${response.statusCode}';

        try {
          final dynamic errorData = _safeJsonDecode(response.body);

          if (errorData != null && errorData is Map<String, dynamic>) {
            // Handle validation errors specifically
            if (response.statusCode == 400 && errorData.containsKey('errors')) {
              final errors = errorData['errors'];
              if (errors is Map<String, dynamic>) {
                final errorMessages = <String>[];

                errors.forEach((field, messages) {
                  if (messages is List) {
                    for (final message in messages) {
                      errorMessages.add('$field: $message');
                    }
                  }
                });

                if (errorMessages.isNotEmpty) {
                  errorMessage =
                      'Validation errors: ${errorMessages.join(', ')}';
                }
              }
            } else {
              // Try to get error message from various possible fields
              errorMessage =
                  errorData['message']?.toString() ??
                  errorData['error']?.toString() ??
                  errorData['title']?.toString() ??
                  errorMessage;
            }
          }
        } catch (e) {
          _log('Error parsing error response: $e');
          // Keep the default error message
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      _log('Create workout item exception: $e');
      rethrow;
    }
  }
}
