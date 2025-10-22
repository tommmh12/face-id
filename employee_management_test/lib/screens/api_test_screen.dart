import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/health_check_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({Key? key}) : super(key: key);

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  Map<String, dynamic>? testResult;
  bool isLoading = false;

  Future<void> _testApiConnection() async {
    setState(() {
      isLoading = true;
      testResult = null;
    });

    try {
      final result = await HealthCheckService.checkApiHealth();
      setState(() {
        testResult = {
          ...result,
          'timestamp': DateTime.now().toIso8601String(),
          'endpoint': 'Health Check',
        };
      });
    } catch (e) {
      setState(() {
        testResult = {
          'success': false,
          'message': 'Test failed: ${e.toString()}',
          'timestamp': DateTime.now().toIso8601String(),
          'endpoint': 'Health Check',
        };
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _testMultipleEndpoints() async {
    setState(() {
      isLoading = true;
      testResult = null;
    });

    try {
      final results = await HealthCheckService.testMultipleEndpoints();
      setState(() {
        testResult = {
          'success': true,
          'message': 'Multiple endpoints tested successfully',
          'data': results,
          'timestamp': DateTime.now().toIso8601String(),
          'endpoint': 'Multiple Endpoints',
        };
      });
    } catch (e) {
      setState(() {
        testResult = {
          'success': false,
          'message': 'Test failed: ${e.toString()}',
          'timestamp': DateTime.now().toIso8601String(),
          'endpoint': 'Multiple Endpoints',
        };
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Connection Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API Endpoint',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'https://api.studyplannerapp.io.vn/api',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _testApiConnection,
                      icon: const Icon(Icons.health_and_safety),
                      label: const Text('Test Health Check'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _testMultipleEndpoints,
                      icon: const Icon(Icons.api),
                      label: const Text('Test Multiple'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Card(
                  elevation: 1,
                  margin: EdgeInsets.only(top: 8),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Testing API connection...'),
                      ],
                    ),
                  ),
                ),
              if (testResult != null) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  color: testResult!['success'] == true
                      ? Colors.green[50]
                      : Colors.red[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              testResult!['success'] == true
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: testResult!['success'] == true
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              testResult!['success'] == true
                                  ? 'Connection Successful'
                                  : 'Connection Failed',
                              style:
                                  Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: testResult!['success'] == true
                                            ? Colors.green[800]
                                            : Colors.red[800],
                                      ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Endpoint: ${testResult!['endpoint']}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Text(
                          'Time: ${testResult!['timestamp']}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            const JsonEncoder.withIndent('  ')
                                .convert(testResult),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
