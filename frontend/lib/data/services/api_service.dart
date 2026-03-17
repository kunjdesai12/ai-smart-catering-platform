import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('');
        debugPrint('🚀 [API REQUEST] ${options.method} ${options.baseUrl}${options.path}');
        if (options.data != null) {
          debugPrint('📦 [BODY]: ${options.data}');
        }
        debugPrint('');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('');
        debugPrint('✅ [API RESPONSE] Status: ${response.statusCode} | URL: ${response.requestOptions.path}');
        debugPrint('📄 [DATA]: ${response.data}');
        debugPrint('');
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('');
        debugPrint('❌ [API ERROR] ${error.requestOptions.path}');
        debugPrint('💥 [MESSAGE]: ${error.message}');
        debugPrint('');
        handler.next(error);
      },
    ),
  );

  /// Check if backend is running
  static Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(ApiConstants.health);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get location hierarchy (Country → City) — used by Recommendation Screen
  static Future<List<Map<String, dynamic>>> getLocations() async {
    try {
      final response = await _dio.get('/api/v1/locations');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['countries']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get flat city list — used by Demand Screen
  static Future<List<Map<String, dynamic>>> getCities({String? country}) async {
    try {
      final params = <String, dynamic>{};
      if (country != null) params['country'] = country;

      final response = await _dio.get('/api/v1/cities', queryParameters: params);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['cities']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get restaurants by city/country
  static Future<List<Map<String, dynamic>>> getRestaurants({
    String? city,
    String? country,
    String? search,
    int limit = 50,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit};
      if (city != null) params['city'] = city;
      if (country != null) params['country'] = country;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await _dio.get(
        ApiConstants.restaurants,
        queryParameters: params,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['restaurants']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get single restaurant details
  static Future<Map<String, dynamic>?> getRestaurant(int restaurantId) async {
    try {
      final response = await _dio.get('${ApiConstants.restaurantDetail}/$restaurantId');
      if (response.statusCode == 200) return response.data['restaurant'];
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Predict demand bulk (24 hours)
  static Future<Map<String, dynamic>?> predictDemandBulk({
    required int restaurantId,
    required int dayOfWeek,
    required int holiday,
    required double restaurantRating,
    required int priceRange,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.predictDemandBulk, data: {
        'restaurant_id': restaurantId,
        'day_of_week': dayOfWeek,
        'hour_of_day': 0,
        'is_weekend': dayOfWeek >= 5 ? 1 : 0,
        'holiday': holiday,
        'restaurant_rating': restaurantRating,
        'price_range': priceRange,
      });
      if (response.statusCode == 200) return response.data;
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Predict ETA
  static Future<Map<String, dynamic>?> predictEta({
    required double distanceKm,
    required double preparationTimeMin,
    required String weather,
    required String trafficLevel,
    required String timeOfDay,
    required String vehicleType,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.predictEta, data: {
        'distance_km': distanceKm,
        'preparation_time_min': preparationTimeMin,
        'weather': weather,
        'traffic_level': trafficLevel,
        'time_of_day': timeOfDay,
        'vehicle_type': vehicleType,
      });
      if (response.statusCode == 200) return response.data;
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get recommendations (with location filter)
  static Future<Map<String, dynamic>?> getRecommendations({
    required String cuisine,
    required double budgetPerPerson,
    required int numPeople,
    required double minRating,
    required int topN,
    String? city,
    String? country,
  }) async {
    try {
      final data = <String, dynamic>{
        'cuisine': cuisine,
        'budget_per_person': budgetPerPerson,
        'num_people': numPeople,
        'min_rating': minRating,
        'top_n': topN,
      };
      if (city != null) data['city'] = city;
      if (country != null) data['country'] = country;

      final response = await _dio.post(ApiConstants.recommend, data: data);
      if (response.statusCode == 200) return response.data;
      return null;
    } catch (e) {
      return null;
    }
  }
}