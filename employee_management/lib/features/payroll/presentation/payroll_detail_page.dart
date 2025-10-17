import 'package:flutter/material.dart';

class PayrollDetailPage extends StatelessWidget {
  final int? periodId;
  final int? employeeId;

  const PayrollDetailPage({
    super.key,
    this.periodId,
    this.employeeId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bảng lương'),
      ),
      body: const Center(
        child: Text('Payroll Detail - Coming soon'),
      ),
    );
  }
}
