import 'dart:convert';
import '../config/app_config.dart';
import '../utils/http_client.dart';

class HealthCheckService {
  static Future<Map<String, dynamic>> checkApiHealth() async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/face/health');
      
      print('🔍 Testing connection to: $uri');
      
      final response = await CustomHttpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout after 10 seconds');
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': response.statusCode == 200 
          ? 'API connection successful' 
          : 'API returned status ${response.statusCode}',
        'data': response.body.isNotEmpty 
          ? json.decode(response.body) 
          : null,
        'url': uri.toString(),
      };
    } catch (e) {
      print('❌ API connection error: $e');
      
      return {
        'success': false,
        'statusCode': null,
        'message': 'Connection failed: ${e.toString()}',
        'data': null,
        'url': '${AppConfig.baseUrl}/face/health',
      };
    }
  }

  static Future<Map<String, dynamic>> testMultipleEndpoints() async {
    final endpoints = [
      '/face/health',
      '/employee',
      '/payroll', 
    ];

    final results = <String, dynamic>{};

    for (final endpoint in endpoints) {
      try {
        final uri = Uri.parse('${AppConfig.baseUrl}$endpoint');
        final response = await CustomHttpClient.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));

        results[endpoint] = {
          'success': response.statusCode < 400,
          'statusCode': response.statusCode,
          'message': 'Response received',
        };
      } catch (e) {
        results[endpoint] = {
          'success': false,
          'statusCode': null,
          'message': e.toString(),
        };
      }
    }

    return results;
  }
}