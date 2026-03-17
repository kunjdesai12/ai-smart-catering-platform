class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://192.168.29.215:8000';

  // Endpoints
  static const String health = '/health';
  static const String modelInfo = '/model-info';
  static const String cities = '/api/v1/cities';
  static const String restaurants = '/api/v1/restaurants';
  static const String restaurantDetail = '/api/v1/restaurant';
  static const String predictDemand = '/api/v1/predict-demand';
  static const String predictDemandBulk = '/api/v1/predict-demand-bulk';
  static const String predictEta = '/api/v1/predict-eta';
  static const String recommend = '/api/v1/recommend';
}