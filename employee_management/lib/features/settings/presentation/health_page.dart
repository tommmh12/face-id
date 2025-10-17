import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final ApiClient _apiClient = ApiClient();

  bool _isChecking = false;
  bool? _faceApiHealthy;
  bool? _payrollApiHealthy;
  DateTime? _lastCheckTime;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    setState(() {
      _isChecking = true;
      _faceApiHealthy = null;
      _payrollApiHealthy = null;
    });

    try {
      final results = await Future.wait([
        _checkFaceApiHealth(),
        _checkPayrollApiHealth(),
      ]);

      setState(() {
        _faceApiHealthy = results[0];
        _payrollApiHealthy = results[1];
        _lastCheckTime = DateTime.now();
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<bool> _checkFaceApiHealth() async {
    try {
      final response = await _apiClient.get('/api/Face/health');
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkPayrollApiHealth() async {
    try {
      final response = await _apiClient.get('/api/Payroll/health');
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra sức khỏe hệ thống'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isChecking ? null : _checkHealth,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isChecking) {
      return const LoadingWidget(message: 'Đang kiểm tra...');
    }

    return RefreshIndicator(
      onRefresh: _checkHealth,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last check time
            if (_lastCheckTime != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time, color: AppTheme.primaryBlue),
                  title: const Text('Lần kiểm tra cuối'),
                  subtitle: Text(
                    '${_lastCheckTime!.hour}:${_lastCheckTime!.minute.toString().padLeft(2, '0')} - ${_lastCheckTime!.day}/${_lastCheckTime!.month}/${_lastCheckTime!.year}',
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Health status cards
            const Text(
              'Trạng thái API',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: 16),

            _buildHealthCard(
              title: 'Face Recognition API',
              endpoint: '/api/Face/health',
              isHealthy: _faceApiHealthy,
              description: 'API nhận diện khuôn mặt và quản lý ảnh nhân viên',
            ),
            const SizedBox(height: 12),

            _buildHealthCard(
              title: 'Payroll API',
              endpoint: '/api/Payroll/health',
              isHealthy: _payrollApiHealthy,
              description: 'API quản lý lương, phụ cấp và tính toán bảng lương',
            ),
            const SizedBox(height: 24),

            // System info
            const Text(
              'Thông tin hệ thống',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Base URL', ApiClient.baseUrl),
                    const Divider(),
                    _buildInfoRow('Phiên bản', '1.0.0'),
                    const Divider(),
                    _buildInfoRow('Môi trường', 'Production'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard({
    required String title,
    required String endpoint,
    required bool? isHealthy,
    required String description,
  }) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isHealthy == null) {
      statusColor = AppTheme.darkGray;
      statusIcon = Icons.help_outline;
      statusText = 'Chưa kiểm tra';
    } else if (isHealthy) {
      statusColor = AppTheme.successGreen;
      statusIcon = Icons.check_circle;
      statusText = 'Hoạt động bình thường';
    } else {
      statusColor = AppTheme.errorRed;
      statusIcon = Icons.error;
      statusText = 'Lỗi kết nối';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Endpoint: $endpoint',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.darkGray,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
