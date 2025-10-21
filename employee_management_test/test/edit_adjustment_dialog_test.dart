import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:employee_management_test/models/dto/payroll_dtos.dart';

// Helper functions for validation (matching EditAdjustmentDialog logic)
String? _validateAmount(String value) {
  if (value.isEmpty) {
    return 'Vui lòng nhập số tiền';
  }
  
  final amount = _parseAmount(value);
  if (amount <= 0) {
    return 'Số tiền phải lớn hơn 0';
  }
  
  if (amount > 999999999) {
    return 'Số tiền không được vượt quá 999,999,999 VNĐ';
  }
  
  return null;
}

String? _validateDescription(String value) {
  if (value.isEmpty) {
    return 'Vui lòng nhập mô tả';
  }
  
  if (value.length < 10) {
    return 'Mô tả phải có ít nhất 10 ký tự';
  }
  
  if (value.length > 500) {
    return 'Mô tả không được vượt quá 500 ký tự';
  }
  
  return null;
}

String? _validateUpdateReason(String value) {
  if (value.isEmpty) {
    return 'Lý do cập nhật là bắt buộc (để audit)';
  }
  
  if (value.length < 15) {
    return 'Lý do cập nhật phải có ít nhất 15 ký tự';
  }
  
  return null;
}

String _formatCurrency(double amount) {
  final formatter = NumberFormat('#,###', 'vi_VN');
  return formatter.format(amount);
}

double _parseAmount(String value) {
  if (value.isEmpty) return 0;
  
  try {
    // Remove commas and parse
    final cleanValue = value.replaceAll(',', '');
    return double.parse(cleanValue);
  } catch (e) {
    return 0;
  }
}

void main() {
  group('Validation Logic Tests', () {
    test('should validate amount constraints', () {
      // Test empty amount
      String? result = _validateAmount('');
      expect(result, 'Vui lòng nhập số tiền');

      // Test zero amount
      result = _validateAmount('0');
      expect(result, 'Số tiền phải lớn hơn 0');

      // Test negative amount
      result = _validateAmount('-5000000');
      expect(result, 'Số tiền phải lớn hơn 0');

      // Test too large amount
      result = _validateAmount('1000000000');
      expect(result, 'Số tiền không được vượt quá 999,999,999 VNĐ');

      // Test valid amount
      result = _validateAmount('5000000');
      expect(result, isNull);

      // Test max valid amount
      result = _validateAmount('999999999');
      expect(result, isNull);
    });

    test('should validate description length', () {
      // Test empty description
      String? result = _validateDescription('');
      expect(result, 'Vui lòng nhập mô tả');

      // Test too short description
      result = _validateDescription('Short');
      expect(result, 'Mô tả phải có ít nhất 10 ký tự');

      // Test too long description
      result = _validateDescription('A' * 501);
      expect(result, 'Mô tả không được vượt quá 500 ký tự');

      // Test valid description
      result = _validateDescription('Thưởng tháng 1/2025');
      expect(result, isNull);

      // Test min valid length
      result = _validateDescription('1234567890');
      expect(result, isNull);

      // Test max valid length
      result = _validateDescription('A' * 500);
      expect(result, isNull);
    });

    test('should validate update reason length', () {
      // Test empty reason
      String? result = _validateUpdateReason('');
      expect(result, 'Lý do cập nhật là bắt buộc (để audit)');

      // Test too short reason
      result = _validateUpdateReason('Too short');
      expect(result, 'Lý do cập nhật phải có ít nhất 15 ký tự');

      // Test valid reason
      result = _validateUpdateReason('Điều chỉnh theo quyết định HĐQT');
      expect(result, isNull);

      // Test min valid length
      result = _validateUpdateReason('123456789012345');
      expect(result, isNull);
    });

    test('should format currency correctly', () {
      expect(_formatCurrency(0), '0');
      expect(_formatCurrency(1000), '1,000');
      expect(_formatCurrency(1000000), '1,000,000');
      expect(_formatCurrency(5000000), '5,000,000');
      expect(_formatCurrency(999999999), '999,999,999');
    });

    test('should parse amount from formatted string', () {
      expect(_parseAmount(''), 0);
      expect(_parseAmount('1,000'), 1000);
      expect(_parseAmount('5,000,000'), 5000000);
      expect(_parseAmount('999,999,999'), 999999999);
      expect(_parseAmount('abc'), 0); // Invalid input
    });
  });

  group('SalaryAdjustmentResponse', () {
    late SalaryAdjustmentResponse adjustment;

    setUp(() {
      adjustment = SalaryAdjustmentResponse(
        id: 1,
        employeeId: 1,
        adjustmentType: 'BONUS',
        amount: 5000000,
        effectiveDate: DateTime(2025, 1, 15),
        description: 'Test bonus',
        createdBy: 'HR001',
        isProcessed: false,
        createdAt: DateTime(2025, 1, 10),
        lastUpdatedAt: DateTime(2025, 1, 10),
        lastUpdatedBy: 'HR001',
      );
    });

    test('should return correct type color', () {
      expect(adjustment.getTypeColor(), Colors.green);
      
      final penalty = adjustment.copyWith(adjustmentType: 'PENALTY');
      expect(penalty.getTypeColor(), Colors.red);
      
      final correction = adjustment.copyWith(adjustmentType: 'CORRECTION');
      expect(correction.getTypeColor(), Colors.orange);
    });

    test('should return correct type label', () {
      expect(adjustment.getTypeLabel(), 'Thưởng');
      
      final penalty = adjustment.copyWith(adjustmentType: 'PENALTY');
      expect(penalty.getTypeLabel(), 'Phạt');
      
      final correction = adjustment.copyWith(adjustmentType: 'CORRECTION');
      expect(correction.getTypeLabel(), 'Điều chỉnh');
    });

    test('should determine edit capability correctly', () {
      expect(adjustment.canEdit, isTrue);
      
      final processed = adjustment.copyWith(isProcessed: true);
      expect(processed.canEdit, isFalse);
    });
  });

  group('UpdateSalaryAdjustmentRequest', () {
    test('should create valid request object', () {
      final request = UpdateSalaryAdjustmentRequest(
        adjustmentType: 'BONUS',
        amount: 8000000,
        effectiveDate: DateTime(2025, 1, 20),
        description: 'Updated bonus amount',
        updatedBy: 'HR001',
        updateReason: 'Increase bonus per board decision',
      );

      final json = request.toJson();
      
      expect(json['adjustmentType'], 'BONUS');
      expect(json['amount'], 8000000);
      expect(json['description'], 'Updated bonus amount');
      expect(json['updatedBy'], 'HR001');
      expect(json['updateReason'], 'Increase bonus per board decision');
      expect(json['effectiveDate'], isA<String>());
    });

    test('should handle date serialization correctly', () {
      final request = UpdateSalaryAdjustmentRequest(
        adjustmentType: 'BONUS',
        amount: 5000000,
        effectiveDate: DateTime(2025, 1, 15, 10, 30),
        description: 'Test',
        updatedBy: 'HR001',
        updateReason: 'Test reason for update',
      );

      final json = request.toJson();
      expect(json['effectiveDate'], '2025-01-15T10:30:00.000Z');
    });
  });
}

// Extension for copyWith functionality (if not already implemented)
extension SalaryAdjustmentResponseCopyWith on SalaryAdjustmentResponse {
  SalaryAdjustmentResponse copyWith({
    int? id,
    int? employeeId,
    String? adjustmentType,
    double? amount,
    DateTime? effectiveDate,
    String? description,
    bool? isProcessed,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    String? lastUpdatedBy,
  }) {
    return SalaryAdjustmentResponse(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      adjustmentType: adjustmentType ?? this.adjustmentType,
      amount: amount ?? this.amount,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      description: description ?? this.description,
      createdBy: this.createdBy,
      isProcessed: isProcessed ?? this.isProcessed,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
    );
  }
}