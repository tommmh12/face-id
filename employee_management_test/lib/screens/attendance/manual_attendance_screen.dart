import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/manual_attendance_provider.dart';
import '../../models/dto/manual_attendance_dtos.dart';

import '../../utils/vietnam_time_zone.dart';

/// Manual Attendance Screen for HR/Manager to batch process attendance
/// Màn hình Chấm công thủ công cho HR/Quản lý xử lý hàng loạt
class ManualAttendanceScreen extends StatefulWidget {
  const ManualAttendanceScreen({super.key});

  @override
  State<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
  final TextEditingController _reasonController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManualAttendanceProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Fixed Filter Section
          _buildFilterSection(),
          
          // Employee List (Scrollable)
          Expanded(
            child: _buildEmployeeList(),
          ),
        ],
      ),
      
      // Fixed Save Button
      floatingActionButton: _buildSaveButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.1),
      scrolledUnderElevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1E293B)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit_calendar_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chấm Công Thủ Công',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Quản lý chấm công hàng loạt',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Help button
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B)),
            onPressed: () => _showHelpDialog(),
          ),
        ),
      ],
    );
  }

  /// Build fixed filter section
  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Department row
          Row(
            children: [
              // Date Picker
              Expanded(
                flex: 2,
                child: _buildDatePicker(),
              ),
              const SizedBox(width: 12),
              
              // Department Dropdown
              Expanded(
                flex: 3,
                child: _buildDepartmentDropdown(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Reason input
          _buildReasonInput(),
          
          const SizedBox(height: 16),
          
          // Summary info
          _buildSummaryInfo(),
        ],
      ),
    );
  }

  /// Build date picker
  Widget _buildDatePicker() {
    return Consumer<ManualAttendanceProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _selectDate(context, provider),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, 
                       color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ngày',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          VietnamTimeZone.formatDate(provider.selectedDate),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build department dropdown
  Widget _buildDepartmentDropdown() {
    return Consumer<ManualAttendanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingDepartments) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Đang tải phòng ban...'),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: provider.selectedDepartmentId,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.business_rounded, 
                         color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Text('Chọn phòng ban'),
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              items: provider.departments.map((dept) {
                return DropdownMenuItem<int>(
                  value: dept.id,
                  child: Row(
                    children: [
                      Icon(Icons.business_rounded, 
                           color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dept.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                provider.updateSelectedDepartment(value);
              },
            ),
          ),
        );
      },
    );
  }

  /// Build reason input
  Widget _buildReasonInput() {
    return Consumer<ManualAttendanceProvider>(
      builder: (context, provider, child) {
        return TextFormField(
          controller: _reasonController,
          decoration: InputDecoration(
            labelText: 'Lý do chấm công thủ công *',
            hintText: 'VD: Nhân viên quên chấm công, hệ thống bảo trì...',
            prefixIcon: const Icon(Icons.note_add_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          maxLines: 2,
          maxLength: 200,
          onChanged: (value) {
            provider.updateReason(value);
          },
        );
      },
    );
  }

  /// Build summary info
  Widget _buildSummaryInfo() {
    return Consumer<ManualAttendanceProvider>(
      builder: (context, provider, child) {
        if (!provider.hasEmployees) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, 
                   color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.summaryText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build employee list
  Widget _buildEmployeeList() {
    return Consumer<ManualAttendanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingEmployees) {
          return _buildLoadingState();
        }

        if (provider.errorMessage != null) {
          return _buildErrorState(provider.errorMessage!);
        }

        if (!provider.hasSelectedDepartment) {
          return _buildEmptyState(
            icon: Icons.business_outlined,
            title: 'Chọn phòng ban',
            subtitle: 'Vui lòng chọn phòng ban để xem danh sách nhân viên',
          );
        }

        if (!provider.hasEmployees) {
          return _buildEmptyState(
            icon: Icons.people_outline_rounded,
            title: 'Không có nhân viên',
            subtitle: 'Phòng ban này hiện không có nhân viên nào',
          );
        }

        return _buildEmployeeListView(provider);
      },
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Đang tải danh sách nhân viên...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final provider = context.read<ManualAttendanceProvider>();
              if (provider.selectedDepartmentId != null) {
                provider.loadEmployeesForDepartment(provider.selectedDepartmentId!);
              }
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build employee list view
  Widget _buildEmployeeListView(ManualAttendanceProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: provider.employeeAttendanceList.length,
      itemBuilder: (context, index) {
        final employee = provider.employeeAttendanceList[index];
        return _buildEmployeeCard(employee, index);
      },
    );
  }

  /// Build individual employee card
  Widget _buildEmployeeCard(EmployeeAttendanceModel employee, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: employee.isDirty 
            ? Border.all(color: Colors.orange.shade300, width: 2)
            : null,
      ),
      child: Column(
        children: [
          // Employee header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getEmployeeColor(index),
                  child: Text(
                    _getEmployeeInitials(employee.employeeName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Employee info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.employeeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${employee.employeeCode} • ${employee.departmentName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status indicator
                if (employee.isDirty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, 
                             size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Đã sửa',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Attendance controls
          if (employee.isEditable) 
            _buildEditableControls(employee)
          else 
            _buildReadOnlyInfo(employee),
        ],
      ),
    );
  }

  /// Build editable controls for employee
  Widget _buildEditableControls(EmployeeAttendanceModel employee) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          
          // Status selection
          Text(
            'Trạng thái chấm công:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          
          // Status radio buttons
          _buildStatusSelection(employee),
          
          // Additional controls for LATE status
          if (employee.selectedStatus == 'LATE') ...[
            const SizedBox(height: 12),
            _buildTimeInput(employee),
          ],
          
          // Notes input
          const SizedBox(height: 12),
          _buildNotesInput(employee),
        ],
      ),
    );
  }

  /// Build status selection radio buttons
  Widget _buildStatusSelection(EmployeeAttendanceModel employee) {
    const statuses = [
      {'value': 'PRESENT', 'label': 'Có mặt', 'icon': Icons.check_circle_outline, 'color': Colors.green},
      {'value': 'LATE', 'label': 'Trễ', 'icon': Icons.schedule_outlined, 'color': Colors.orange},
      {'value': 'ABSENT', 'label': 'Vắng', 'icon': Icons.cancel_outlined, 'color': Colors.red},
      {'value': 'ON_LEAVE', 'label': 'Phép', 'icon': Icons.event_available_outlined, 'color': Colors.blue},
    ];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((status) {
        final isSelected = employee.selectedStatus == status['value'];
        final color = status['color'] as Color;
        
        return InkWell(
          onTap: () => _updateEmployeeStatus(employee, status['value'] as String),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status['icon'] as IconData,
                  size: 16,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  status['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? color : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build time input for LATE status
  Widget _buildTimeInput(EmployeeAttendanceModel employee) {
    return InkWell(
      onTap: () => _selectTime(employee),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, 
                 color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              employee.customCheckInTime != null
                  ? 'Giờ vào: ${employee.customCheckInTime!.format(context)}'
                  : 'Chọn giờ vào làm',
              style: TextStyle(
                fontSize: 14,
                color: employee.customCheckInTime != null
                    ? Colors.black87
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build notes input
  Widget _buildNotesInput(EmployeeAttendanceModel employee) {
    return TextFormField(
      initialValue: employee.notes,
      decoration: InputDecoration(
        labelText: 'Ghi chú (tùy chọn)',
        hintText: 'Thông tin bổ sung...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      maxLines: 2,
      maxLength: 100,
      onChanged: (value) => _updateEmployeeNotes(employee, value),
    );
  }

  /// Build read-only info for already checked-in employees
  Widget _buildReadOnlyInfo(EmployeeAttendanceModel employee) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, 
                     color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    employee.automaticAttendanceInfo ?? 'Đã chấm công tự động',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build save button
  Widget _buildSaveButton() {
    return Consumer<ManualAttendanceProvider>(
      builder: (context, provider, child) {
        if (!provider.canProcess) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: provider.isProcessingBatch ? null : () => _processBatch(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            icon: provider.isProcessingBatch 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              provider.isProcessingBatch 
                  ? 'Đang xử lý...' 
                  : 'Lưu Chấm Công (${provider.modifiedEmployees.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== EVENT HANDLERS ====================

  /// Select date
  Future<void> _selectDate(BuildContext context, ManualAttendanceProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF667eea),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      provider.updateSelectedDate(picked);
    }
  }

  /// Update employee status 
  void _updateEmployeeStatus(EmployeeAttendanceModel employee, String status) {
    final provider = context.read<ManualAttendanceProvider>();
    provider.updateEmployeeStatus(employee.employeeId, status);
  }

  /// Update employee notes
  void _updateEmployeeNotes(EmployeeAttendanceModel employee, String notes) {
    final provider = context.read<ManualAttendanceProvider>();
    provider.updateEmployeeNotes(employee.employeeId, notes);
  }

  /// Select time for LATE status
  Future<void> _selectTime(EmployeeAttendanceModel employee) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: employee.customCheckInTime ?? const TimeOfDay(hour: 8, minute: 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF667eea),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      final provider = context.read<ManualAttendanceProvider>();
      provider.updateEmployeeCheckInTime(employee.employeeId, picked);
    }
  }

  /// Process batch attendance
  Future<void> _processBatch() async {
    try {
      final provider = context.read<ManualAttendanceProvider>();
      await provider.processBatch();
      
      if (provider.lastProcessResult?.success == true) {
        _showSuccessDialog(provider.lastProcessResult!);
      } else {
        _showErrorDialog(provider.lastProcessResult?.message ?? 'Có lỗi xảy ra');
      }
    } catch (e) {
      _showErrorDialog('Lỗi: $e');
    }
  }

  /// Show success dialog
  void _showSuccessDialog(ManualBatchAttendanceResponse result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Thành công'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip('Thành công', result.successfullyProcessed, Colors.green),
                const SizedBox(width: 8),
                _buildStatChip('Cập nhật', result.updatedRecords, Colors.blue),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatChip('Bỏ qua', result.skippedRecords, Colors.grey),
                const SizedBox(width: 8),
                _buildStatChip('Lỗi', result.failedRecords, Colors.red),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Lỗi'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Show help dialog
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hướng dẫn sử dụng'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Chọn ngày cần chấm công thủ công'),
              SizedBox(height: 8),
              Text('2. Chọn phòng ban để xem danh sách nhân viên'),
              SizedBox(height: 8),
              Text('3. Nhập lý do chấm công thủ công'),
              SizedBox(height: 8),
              Text('4. Chỉnh sửa trạng thái cho từng nhân viên:'),
              Text('   • Có mặt: Tạo chấm công đầy đủ'),
              Text('   • Trễ: Cần chọn giờ vào làm'),
              Text('   • Vắng: Không tạo attendance'),
              Text('   • Phép: Nghỉ có phép'),
              SizedBox(height: 8),
              Text('5. Bấm "Lưu Chấm Công" để xử lý'),
              SizedBox(height: 16),
              Text(
                'Lưu ý: Nhân viên đã chấm công tự động sẽ không thể chỉnh sửa.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  /// Build stat chip for success dialog
  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// Get employee color for avatar
  Color _getEmployeeColor(int index) {
    final colors = [
      const Color(0xFF667eea),
      const Color(0xFF764ba2),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFFFF5722),
    ];
    return colors[index % colors.length];
  }

  /// Get employee initials for avatar
  String _getEmployeeInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return 'NV';
  }
}

/// Extension for TimeOfDay to format to 24-hour string
extension TimeOfDayExtension on TimeOfDay {
  String format24Hour() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}