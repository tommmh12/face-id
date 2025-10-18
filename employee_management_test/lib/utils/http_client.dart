import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as io;
import '../config/app_config.dart';

class CustomHttpClient {
  static http.Client? _client;

  static http.Client get client {
    // Always create a new client to avoid "Client is already closed" error
    if (AppConfig.isDevelopment) {
      // For development: Create client that ignores SSL certificate errors
      final httpClient = HttpClient();
      httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Allow all certificates in development mode
        return true;
      };
      return io.IOClient(httpClient);
    } else {
      // For production: Use default secure client
      return http.Client();
    }
  }

  static void dispose() {
    _client?.close();
    _client = null;
  }

  // Helper methods for common HTTP operations
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final client = CustomHttpClient.client;
    try {
      return await client.get(url, headers: headers);
    } finally {
      client.close();
    }
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final client = CustomHttpClient.client;
    try {
      return await client.post(url, headers: headers, body: body);
    } finally {
      client.close();
    }
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final client = CustomHttpClient.client;
    try {
      return await client.put(url, headers: headers, body: body);
    } finally {
      client.close();
    }
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final client = CustomHttpClient.client;
    try {
      return await client.delete(url, headers: headers);
    } finally {
      client.close();
    }
  }
}