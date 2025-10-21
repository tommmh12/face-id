import 'package:flutter/material.dart';
import 'package:employee_management_test/models/dto/payroll_dtos.dart';
import 'package:employee_management_test/screens/payroll/widgets/edit_adjustment_dialog.dart';

/// Demo script to test Salary Adjustment Edit workflow manually
/// Run this with: flutter run lib/demo_salary_adjustment_edit.dart
class SalaryAdjustmentEditDemo extends StatefulWidget {
  const SalaryAdjustmentEditDemo({Key? key}) : super(key: key);

  @override
  _SalaryAdjustmentEditDemoState createState() => _SalaryAdjustmentEditDemoState();
}

class _SalaryAdjustmentEditDemoState extends State<SalaryAdjustmentEditDemo> {
  
  // Mock data for testing
  final List<SalaryAdjustmentResponse> _mockAdjustments = [
    SalaryAdjustmentResponse(
      id: 1,
      employeeId: 1,
      adjustmentType: 'BONUS',
      amount: 5000000,
      effectiveDate: DateTime(2025, 1, 15),
      description: 'Thưởng tháng 1/2025 - Hoàn thành tốt KPI',
      isProcessed: false,
      createdAt: DateTime(2025, 1, 10),
      createdBy: 'HR001',
      lastUpdatedAt: DateTime(2025, 1, 10),
      lastUpdatedBy: 'HR001',
    ),
    SalaryAdjustmentResponse(
      id: 2,
      employeeId: 1,
      adjustmentType: 'PENALTY',
      amount: 2000000,
      effectiveDate: DateTime(2025, 1, 20),
      description: 'Phạt đi muộn 3 lần trong tháng',
      isProcessed: false,
      createdAt: DateTime(2025, 1, 18),
      createdBy: 'HR002',
      lastUpdatedAt: DateTime(2025, 1, 18),
      lastUpdatedBy: 'HR002',
    ),
    SalaryAdjustmentResponse(
      id: 3,
      employeeId: 1,
      adjustmentType: 'CORRECTION',
      amount: 1500000,
      effectiveDate: DateTime(2024, 12, 31),
      description: 'Điều chỉnh lương cơ bản theo nghị định mới',
      isProcessed: true, // Already processed - cannot edit
      createdAt: DateTime(2024, 12, 25),
      createdBy: 'ADMIN',
      lastUpdatedAt: DateTime(2024, 12, 30),
      lastUpdatedBy: 'ADMIN',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Salary Adjustment Edit Demo'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'DEMO TESTING GUIDE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Click Edit trên adjustment #1 (BONUS) hoặc #2 (PENALTY)\n'
                      '2. Thay đổi amount, description, update reason\n'
                      '3. Click "Lưu & Tính lại lương"\n'
                      '4. Adjustment #3 (CORRECTION) đã processed → không edit được\n'
                      '5. Test validation bằng cách để trống các field bắt buộc',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Test results card
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'EXPECTED RESULTS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '✅ Dialog mở với data pre-filled\n'
                      '✅ Validation errors khi submit invalid data\n'
                      '✅ Success message sau khi update\n'
                      '✅ Processed adjustments không edit được\n'
                      '✅ Transaction flow: Update → Recalculate',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Adjustments list
            Text(
              '💰 Salary Adjustments (Demo Data)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView.builder(
                itemCount: _mockAdjustments.length,
                itemBuilder: (context, index) {
                  final adjustment = _mockAdjustments[index];
                  return _buildAdjustmentCard(adjustment);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentCard(SalaryAdjustmentResponse adjustment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Type chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: adjustment.getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: adjustment.getTypeColor().withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTypeIcon(adjustment.adjustmentType),
                        size: 16,
                        color: adjustment.getTypeColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        adjustment.getTypeLabel(),
                        style: TextStyle(
                          color: adjustment.getTypeColor(),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                
                // Amount
                Text(
                  '${_formatCurrency(adjustment.amount)} ₫',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: adjustment.getTypeColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              adjustment.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // Details row
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatDate(adjustment.effectiveDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  adjustment.lastUpdatedBy ?? 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                
                // Status and Edit button
                if (adjustment.isProcessed) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Đã xử lý',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () => _editAdjustment(adjustment),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'BONUS':
        return Icons.trending_up;
      case 'PENALTY':
        return Icons.trending_down;
      case 'CORRECTION':
        return Icons.edit;
      default:
        return Icons.attach_money;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _editAdjustment(SalaryAdjustmentResponse adjustment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditAdjustmentDialog(
        adjustment: adjustment,
        periodId: 1, // Mock current period ID
        onUpdated: () {
          // Simulate refresh
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã cập nhật thành công adjustment #${adjustment.id} và tính lại lương!',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Xem',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to payroll report or employee detail
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Salary Adjustment Edit Demo',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    ),
    home: const SalaryAdjustmentEditDemo(),
    debugShowCheckedModeBanner: false,
  ));
}