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

  IconData _getStatusIcon() {
    switch (response.status) {
      case 'verified':
        return Icons.check_circle;
      case 'no_face':
        return Icons.face_retouching_off;
      case 'no_match':
      case 'not_registered':
        return Icons.person_off;
      case 'no_users':
        return Icons.group_off;
      case 'already_checked_in':
        return Icons.event_busy;
      case 'low_quality':
        return Icons.wb_sunny_outlined;
      default:
        return Icons.error;
    }
  }

  Color _getStatusColor() {
    switch (response.status) {
      case 'verified':
        return Colors.green.shade700;
      case 'no_face':
      case 'low_quality':
        return Colors.orange.shade700;
      case 'already_checked_in':
        return Colors.blue.shade700;
      default:
        return Colors.red.shade700;
    }
  }

  String _getTitle() {
    switch (response.status) {
      case 'verified':
        return 'Thành công!';
      case 'no_face':
        return 'Không thấy khuôn mặt';
      case 'no_match':
      case 'not_registered':
        return 'Chưa đăng ký';
      case 'already_checked_in':
        return 'Đã chấm công';
      case 'low_quality':
        return 'Chất lượng ảnh thấp';
      default:
        return 'Thất bại';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = response.status == 'verified';
    final matchedEmployee = response.matchedEmployee;
    final statusColor = _getStatusColor();

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
                color: statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(),
                size: 50,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _getTitle(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 16),

            // Content
            if (isSuccess && matchedEmployee != null) ...[
              _buildInfoRow(
                icon: Icons.badge,
                label: 'Mã nhân viên',
                value: matchedEmployee.employeeCode,
              ),
              const SizedBox(height: 12),
              
              _buildInfoRow(
                icon: Icons.person,
                label: 'Họ và tên',
                value: matchedEmployee.fullName,
              ),
              const SizedBox(height: 12),
              
              if (matchedEmployee.departmentName != null) ...[
                _buildInfoRow(
                  icon: Icons.business,
                  label: 'Phòng ban',
                  value: matchedEmployee.departmentName!,
                ),
                const SizedBox(height: 12),
              ],
              
              if (matchedEmployee.position != null) ...[
                _buildInfoRow(
                  icon: Icons.work,
                  label: 'Chức vụ',
                  value: matchedEmployee.position!,
                ),
                const SizedBox(height: 12),
              ],
              
              _buildInfoRow(
                icon: Icons.trending_up,
                label: 'Độ tin cậy',
                value: '${response.confidence.toStringAsFixed(2)}%',
              ),
              const SizedBox(height: 12),
              
              _buildInfoRow(
                icon: Icons.login,
                label: 'Loại',
                value: 'Vào làm (Check-In)',
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: statusColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            response.message,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (response.confidence > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Độ tin cậy: ${response.confidence.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: statusColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Suggestions based on status
              const SizedBox(height: 16),
              if (response.status == 'no_face') ...[
                _buildSuggestion('Đảm bảo khuôn mặt trong khung hình'),
                _buildSuggestion('Ánh sáng đủ để nhận diện'),
              ] else if (response.status == 'low_quality') ...[
                _buildSuggestion('Cải thiện ánh sáng'),
                _buildSuggestion('Giữ camera ổn định'),
                _buildSuggestion('Nhìn thẳng vào camera'),
              ] else if (response.status == 'not_registered' || response.status == 'no_match') ...[
                _buildSuggestion('Liên hệ quản trị viên để đăng ký khuôn mặt'),
                _buildSuggestion('Kiểm tra bạn đã được thêm vào hệ thống'),
              ] else if (response.status == 'no_users') ...[
                _buildSuggestion('Chưa có nhân viên nào đăng ký khuôn mặt'),
                _buildSuggestion('Liên hệ quản trị viên'),
              ],
            ],
            
            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Đóng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
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
