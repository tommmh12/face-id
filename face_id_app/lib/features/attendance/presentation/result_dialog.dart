import 'package:flutter/material.dart';
import '../model/attendance_response.dart';

class ResultDialog extends StatelessWidget {
  final AttendanceResponse response;
  final String checkType;

  const ResultDialog({
    super.key,
    required this.response,
    required this.checkType,
  });

  String _formatDateTime(String isoDateTime) {
    try {
      final dateTime = DateTime.parse(isoDateTime);
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final second = dateTime.second.toString().padLeft(2, '0');
      
      return '$day/$month/$year $hour:$minute:$second';
    } catch (e) {
      return isoDateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = response.success;
    final userData = response.userData;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSuccess
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                size: 50,
                color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              isSuccess ? 'Thành công!' : 'Thất bại',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),

            // Content
            if (isSuccess && userData != null) ...[
              _buildInfoRow(
                icon: Icons.person,
                label: 'Họ và tên',
                value: userData.fullName,
              ),
              const SizedBox(height: 12),
              
              _buildInfoRow(
                icon: Icons.access_time,
                label: 'Thời gian',
                value: _formatDateTime(userData.checkTime),
              ),
              const SizedBox(height: 12),
              
              _buildInfoRow(
                icon: Icons.trending_up,
                label: 'Độ tương đồng',
                value: '${userData.similarityScore.toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 12),
              
              _buildInfoRow(
                icon: userData.checkType == 'IN' 
                    ? Icons.login 
                    : Icons.logout,
                label: 'Loại',
                value: userData.checkType == 'IN' 
                    ? 'Vào làm (Check-In)' 
                    : 'Tan ca (Check-Out)',
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        response.message,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess
                      ? Colors.green.shade400
                      : Colors.red.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Đóng',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
