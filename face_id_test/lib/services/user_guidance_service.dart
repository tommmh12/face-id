import 'package:flutter/material.dart';

class UserGuidanceService {
  static void showTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber, size: 28),
            SizedBox(width: 12),
            Text('💡 Mẹo sử dụng', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTipItem('📷', 'Chụp ảnh rõ nét', 'Đảm bảo khuôn mặt hiển thị rõ ràng, không bị che khuất'),
              _buildTipItem('💡', 'Ánh sáng đầy đủ', 'Chụp ảnh ở nơi có ánh sáng tự nhiên tốt'),
              _buildTipItem('👤', 'Nhìn thẳng camera', 'Giữ khuôn mặt thẳng và nhìn vào camera'),
              _buildTipItem('📱', 'Giữ máy ổn định', 'Tránh run tay khi chụp ảnh'),
              _buildTipItem('⏱️', 'Chờ xử lý', 'Hệ thống cần vài giây để xác thực'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static Widget _buildTipItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void showFirstTimeHelp(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.waving_hand, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('👋 Chào mừng!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chào mừng bạn đến với ứng dụng chấm công bằng khuôn mặt!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '🎯 Hướng dẫn sử dụng:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('1. Nhấn "Chấm công vào ca" khi bắt đầu làm việc'),
            Text('2. Nhấn "Chấm công ra ca" khi kết thúc ca làm'),
            Text('3. Chụp ảnh khuôn mặt rõ nét khi được yêu cầu'),
            Text('4. Chờ hệ thống xác thực và xem kết quả'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              showTips(context);
            },
            child: const Text('Xem mẹo chụp ảnh', style: TextStyle(color: Colors.blue)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Bắt đầu sử dụng'),
          ),
        ],
      ),
    );
  }
}