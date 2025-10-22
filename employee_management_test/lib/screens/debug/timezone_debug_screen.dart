import 'package:flutter/material.dart';
import '../../utils/vietnam_time_zone.dart';

/// 🕐 Debug Screen để kiểm tra Vietnam TimeZone
/// 
/// Screen này hiển thị các thông tin debug về múi giờ:
/// - Current time ở các timezone khác nhau
/// - Format examples
/// - Comparison với system time
class TimeZoneDebugScreen extends StatefulWidget {
  const TimeZoneDebugScreen({super.key});

  @override
  State<TimeZoneDebugScreen> createState() => _TimeZoneDebugScreenState();
}

class _TimeZoneDebugScreenState extends State<TimeZoneDebugScreen> {
  late Stream<DateTime> _timeStream;

  @override
  void initState() {
    super.initState();
    _timeStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🕐 Vietnam Timezone Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DateTime>(
        stream: _timeStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final now = snapshot.data!;
          final debugInfo = VietnamTimeZone.getDebugInfo();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildSectionHeader('🌏 Múi Giờ Việt Nam (UTC+7)'),
                _buildInfoCard([
                  'Backend: SE Asia Standard Time',
                  'Flutter: Vietnam TimeZone Utility',
                  'Đồng bộ: ✅ Enabled',
                ]),
                
                const SizedBox(height: 20),
                
                // Current Time Comparison
                _buildSectionHeader('⏰ So Sánh Thời Gian'),
                _buildTimeComparisonCard(now),
                
                const SizedBox(height: 20),
                
                // Format Examples
                _buildSectionHeader('📅 Ví Dụ Format'),
                _buildFormatExamplesCard(),
                
                const SizedBox(height: 20),
                
                // Debug Info
                _buildSectionHeader('🔧 Debug Information'),
                _buildDebugInfoCard(debugInfo),
                
                const SizedBox(height: 20),
                
                // Utility Functions Test
                _buildSectionHeader('🧪 Test Utility Functions'),
                _buildUtilityTestCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(item)),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildTimeComparisonCard(DateTime now) {
    final vietnamNow = VietnamTimeZone.now();
    final utcNow = now.toUtc();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTimeRow('🖥️ System Local', now.toString(), Colors.grey),
            const Divider(),
            _buildTimeRow('🌍 UTC', utcNow.toString(), Colors.orange),
            const Divider(),
            _buildTimeRow('🇻🇳 Vietnam (UTC+7)', vietnamNow.toString(), Colors.green),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✅ Backend sử dụng: ${VietnamTimeZone.formatDateTime(vietnamNow, useLocal: false)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, String time, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ),
        Expanded(
          child: Text(
            time,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatExamplesCard() {
    final vietnamNow = VietnamTimeZone.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormatRow('📅 Date', VietnamTimeZone.formatDate(vietnamNow, useLocal: false)),
            _buildFormatRow('🕐 Time', VietnamTimeZone.formatTime(vietnamNow, useLocal: false)),
            _buildFormatRow('📅🕐 DateTime', VietnamTimeZone.formatDateTime(vietnamNow, useLocal: false)),
            _buildFormatRow('📅🕐 Short', VietnamTimeZone.formatDateTimeShort(vietnamNow, useLocal: false)),
            _buildFormatRow('📆 Day+Date', VietnamTimeZone.formatDayDate(vietnamNow, useLocal: false)),
            _buildFormatRow('📅 Month/Year', VietnamTimeZone.formatMonthYear(vietnamNow, useLocal: false)),
            _buildFormatRow('📆 Full Date', VietnamTimeZone.formatFullDate(vietnamNow, useLocal: false)),
            _buildFormatRow('⏰ Relative', VietnamTimeZone.getRelativeTime(vietnamNow.subtract(const Duration(minutes: 30)))),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugInfoCard(Map<String, String> debugInfo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: debugInfo.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildUtilityTestCard() {
    final now = VietnamTimeZone.now();
    final startOfDay = VietnamTimeZone.startOfDay(now);
    final endOfDay = VietnamTimeZone.endOfDay(now);
    final startOfMonth = VietnamTimeZone.startOfMonth(now);
    final endOfMonth = VietnamTimeZone.endOfMonth(now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUtilityRow('📅 Is Today?', VietnamTimeZone.isToday(now) ? 'Yes ✅' : 'No ❌'),
            _buildUtilityRow('🌅 Start of Day', VietnamTimeZone.formatDateTime(startOfDay, useLocal: false)),
            _buildUtilityRow('🌆 End of Day', VietnamTimeZone.formatDateTime(endOfDay, useLocal: false)),
            _buildUtilityRow('📅 Start of Month', VietnamTimeZone.formatDateTime(startOfMonth, useLocal: false)),
            _buildUtilityRow('📅 End of Month', VietnamTimeZone.formatDateTime(endOfMonth, useLocal: false)),
            const Divider(),
            const Text('Extension Methods:', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildUtilityRow('DateTime.toVietnamTime()', now.toVietnamDateTimeString()),
            _buildUtilityRow('DateTime.isVietnamToday()', now.isVietnamToday() ? 'Yes ✅' : 'No ❌'),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}