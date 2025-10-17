import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/attendance_service.dart';
import 'camera_page.dart';

final attendanceServiceProvider = Provider((ref) => AttendanceService());

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _checkApiHealth(BuildContext context, AttendanceService service) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang kiểm tra kết nối...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final isHealthy = await service.checkHealth();
      
      if (!context.mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show result
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isHealthy ? Icons.check_circle : Icons.error,
                color: isHealthy ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              const Text('Trạng thái API'),
            ],
          ),
          content: Text(
            isHealthy
                ? '✅ Kết nối API thành công!\nAPI đang hoạt động bình thường.'
                : '❌ Không thể kết nối đến API.\nVui lòng kiểm tra lại.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Lỗi'),
            ],
          ),
          content: Text('Lỗi: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(attendanceServiceProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.face,
                      size: 64,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    'Face Recognition',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Attendance System',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Check-In Button
                  SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CameraPage(checkType: 'IN'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400,
                        foregroundColor: Colors.white,
                        elevation: 4,
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Check-In',
                            style: TextStyle(fontSize: 24),
                          ),
                          Text(
                            'Vào làm',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Check-Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CameraPage(checkType: 'OUT'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade400,
                        foregroundColor: Colors.white,
                        elevation: 4,
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Check-Out',
                            style: TextStyle(fontSize: 24),
                          ),
                          Text(
                            'Tan ca',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Health Check Button
                  OutlinedButton.icon(
                    onPressed: () => _checkApiHealth(context, service),
                    icon: const Icon(Icons.wifi_find),
                    label: const Text('Kiểm tra kết nối API'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
