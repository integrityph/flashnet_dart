import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../config/index.dart'; // Adjust path if needed
import '../types/index.dart'; // Adjust path if needed
import '../types/errors.dart'; // Adjust path if needed

class RequestOptions {
  final Map<String, String>? headers;
  final dynamic body;
  final Map<String, dynamic>? params;

  RequestOptions({
    this.headers,
    this.body,
    this.params,
  });
}

/// Fallback exception class to handle non-structured errors with extra properties
/// just like the TypeScript version extending the standard Error.
class LegacyApiClientException implements Exception {
  final String message;
  final int? status;
  final Map<String, dynamic>? response;
  final Map<String, dynamic>? request;

  LegacyApiClientException(
    this.message, {
    this.status,
    this.response,
    this.request,
  });

  @override
  String toString() => message;
}

class ApiClient {
  final ClientNetworkConfig config;
  String? _authToken;

  /// Create an ApiClient with new ClientNetworkConfig
  ApiClient(this.config);

  /// @deprecated Use standard ApiClient(ClientNetworkConfig) instead
  /// Create an ApiClient with legacy NetworkConfig for backward compatibility
  @Deprecated('Use ClientNetworkConfig instead of NetworkConfig')
  ApiClient.legacy(NetworkConfig legacyConfig) 
      // Assuming a valid cast/mapping exists between NetworkConfig and ClientNetworkConfig
      : config = legacyConfig as ClientNetworkConfig; 

  void setAuthToken(String token) {
    _authToken = token;
  }

  Future<T> _makeRequest<T>(
    String url,
    String method, [
    RequestOptions? options,
  ]) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (options?.headers != null) ...options!.headers!,
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    // Build the URI and add query parameters if provided
    var uri = Uri.parse(url);
    if (options?.params != null) {
      final queryParams = <String, String>{};
      options!.params!.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });

      // Merge with any existing query parameters in the URL
      final mergedParams = Map<String, String>.from(uri.queryParameters);
      mergedParams.addAll(queryParams);
      
      uri = uri.replace(queryParameters: mergedParams);
    }

    final methodUpper = method.toUpperCase();
    final bodyStr = (options?.body != null && methodUpper != 'GET')
        ? jsonEncode(options!.body)
        : null;

    http.Response response;

    // Dispatch the request
    try {
      switch (methodUpper) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: bodyStr);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: bodyStr);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers, body: bodyStr);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: bodyStr);
          break;
        default:
          throw Exception('Unsupported HTTP method: $methodUpper');
      }
    } catch (e) {
      throw Exception('Network request failed: $e');
    }

    // Process Response
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      return decoded as T;
    } else {
      FlashnetErrorResponseBody? errorData;
      Map<String, dynamic>? jsonMap;
      try {
        jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
        errorData = FlashnetErrorResponseBody.fromJson(jsonMap);
      } catch (_) {
        errorData = null;
      }

      // Check if it's a structured FlashnetError response
      if (jsonMap is Map<String, dynamic> &&
          jsonMap.containsKey('errorCode') &&
          jsonMap['errorCode'] is String) {
        // Assuming FlashnetError has a named constructor or static factory 
        // `fromResponse(Map<String, dynamic> responseBody, int status)`
        throw FlashnetError.fromResponse(
          errorData,
          response.statusCode,
        );
      }

      // Legacy/fallback error handling for non-structured errors
      final legacyError = jsonMap is Map<String, dynamic> ? jsonMap : null;
      final message = legacyError?['message'] as String? ??
          legacyError?['msg'] as String? ??
          'HTTP error! status: ${response.statusCode}';

      // Create error with additional properties for backwards compatibility
      throw LegacyApiClientException(
        message,
        status: response.statusCode,
        response: {
          'status': response.statusCode,
          'data': errorData,
        },
        request: {
          'url': uri.toString(),
          'method': methodUpper,
          'body': options?.body,
        },
      );
    }
  }

  // AMM Gateway endpoints

  Future<T> ammPost<T>(
    String path,
    dynamic body, [
    RequestOptions? options,
  ]) async {
    final mergedOptions = RequestOptions(
      headers: options?.headers,
      params: options?.params,
      body: body,
    );
    return _makeRequest<T>('${config.ammGatewayUrl}$path', 'POST', mergedOptions);
  }

  Future<T> ammGet<T>(String path, [RequestOptions? options]) async {
    return _makeRequest<T>('${config.ammGatewayUrl}$path', 'GET', options);
  }

  // Mempool API endpoints

  Future<T> mempoolGet<T>(String path, [RequestOptions? options]) async {
    return _makeRequest<T>('${config.mempoolApiUrl}$path', 'GET', options);
  }

  // SparkScan API endpoints (if available)

  Future<T> sparkScanGet<T>(String path, [RequestOptions? options]) async {
    if (config.sparkScanUrl == null || config.sparkScanUrl!.isEmpty) {
      throw Exception('SparkScan URL not configured for this network');
    }
    return _makeRequest<T>('${config.sparkScanUrl}$path', 'GET', options);
  }
}