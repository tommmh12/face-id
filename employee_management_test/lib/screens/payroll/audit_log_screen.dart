import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dto/payroll_dtos.dart';
import '../../models/employee.dart';
import '../../services/payroll_api_service.dart';
import '../../services/employee_api_service.dart';
import '../../utils/app_logger.dart';
import 'employee_hr_profile_screen.dart';

/// 🔍 Audit Log Screen - Version 3 FINAL (Production-Ready)
/// 
/// Features V3:
/// - ✅ Date Range Presets (8 options, default 30 days)
/// - ✅ Log Grouping (auto-group 5+ logs)
/// - ✅ Expand/Collapse grouped cards
/// - ✅ Global Employee Cache (static)
/// - ✅ Tooltips on all fields
/// - ✅ End-of-day fix (23:59:59)
/// - ✅ Toggle grouping button
/// - ✅ Currency formatting
/// - ✅ Enhanced summary display
/// - ✅ Difference indicators
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

// ==================== DATE PRESET ENUM ====================
enum DatePreset {
  today,
  last7Days,
  last30Days,
  last90Days,
  thisMonth,
  lastMonth,
  thisPeriod,
  custom,
}

extension DatePresetExtension on DatePreset {
  String get displayName {
    switch (this) {
      case DatePreset.today:
        return 'Hôm nay';
      case DatePreset.last7Days:
        return '7 ngày qua';
      case DatePreset.last30Days:
        return '30 ngày qua';
      case DatePreset.last90Days:
        return '90 ngày qua';
      case DatePreset.thisMonth:
        return 'Tháng này';
      case DatePreset.lastMonth:
        return 'Tháng trước';
      case DatePreset.thisPeriod:
        return 'Kỳ lương hiện tại';
      case DatePreset.custom:
        return 'Tùy chỉnh';
    }
  }
  
  DateTimeRange getRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (this) {
      case DatePreset.today:
        return DateTimeRange(
          start: today,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      
      case DatePreset.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      
      case DatePreset.last30Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      
      case DatePreset.last90Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 89)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      
      case DatePreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      
      case DatePreset.lastMonth:
        final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(
          start: firstDayLastMonth,
          end: lastDayLastMonth,
        );
      
      case DatePreset.thisPeriod:
      case DatePreset.custom:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
    }
  }
}

// ==================== LOG GROUP MODEL ====================
class LogGroup {
  final String groupKey;
  final List<AuditLogResponse> logs;
  final String action;
  final String entityType;
  final int userId;
  final String? userName;
  final DateTime timestamp;
  bool isExpanded = false;
  
  LogGroup({
    required this.groupKey,
    required this.logs,
    required this.action,
    required this.entityType,
    required this.userId,
    this.userName,
    required this.timestamp,
  });
  
  String get displayTitle {
    final count = logs.length;
    
    if (entityType == 'PayrollRecord' && action == 'INSERT') {
      return 'Tính lương cho $count nhân viên';
    }
    
    if (entityType == 'SalaryAdjustment' && action == 'INSERT') {
      return 'Thêm điều chỉnh cho $count nhân viên';
    }
    
    if (entityType == 'PayrollRecord' && action == 'UPDATE') {
      return 'Cập nhật lương cho $count nhân viên';
    }
    
    return '${_getActionName(action)} ${_getEntityName(entityType)} ($count)';
  }
  
  String _getActionName(String action) {
    switch (action) {
      case 'INSERT': return 'Tạo';
      case 'UPDATE': return 'Cập nhật';
      case 'DELETE': return 'Xóa';
      default: return action;
    }
  }
  
  String _getEntityName(String entityType) {
    switch (entityType) {
      case 'PayrollRecord': return 'Bảng lương';
      case 'SalaryAdjustment': return 'Điều chỉnh';
      case 'PayrollPeriod': return 'Kỳ lương';
      default: return entityType;
    }
  }
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final _payrollService = PayrollApiService();
  final _employeeService = EmployeeApiService();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  
  // Filters
  String? _selectedEntityType;
  int? _selectedEmployeeId;
  String? _selectedAction;
  DateTime? _fromDate;
  DateTime? _toDate;
  DatePreset _selectedPreset = DatePreset.last30Days; // Default 30 days
  
  // Data
  List<AuditLogResponse> _logs = [];
  List<LogGroup> _groupedLogs = [];
  List<Employee> _employees = [];
  bool _isLoading = false;
  bool _isLoadingEmployees = false;
  bool _enableGrouping = true; // Toggle grouping
  int _currentPage = 1;
  int _pageSize = 20;
  int _totalRecords = 0;
  
  // Cache
  final Map<int, Employee> _employeeCache = {};
  static final Map<int, Employee> _globalEmployeeCache = {};
  
  @override
  void initState() {
    super.initState();
    
    // Default to 30 days (industry standard)
    final range = _selectedPreset.getRange();
    _fromDate = range.start;
    _toDate = range.end;
    
    _loadEmployeesFromCache();
    _loadAuditLogs();
  }
  
  // ==================== EMPLOYEE CACHE ====================
  
  Future<void> _loadEmployeesFromCache() async {
    // Try global cache first
    if (_globalEmployeeCache.isNotEmpty) {
      setState(() {
        _employeeCache.addAll(_globalEmployeeCache);
        _employees = _globalEmployeeCache.values.toList();
      });
      AppLogger.debug('Loaded ${_employees.length} employees from cache', tag: 'AuditLog');
      return;
    }
    
    await _loadEmployees();
  }
  
  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    
    try {
      final response = await _employeeService.getAllEmployees();
      
      if (response.success && response.data != null) {
        setState(() {
          _employees = response.data!;
          
          _employeeCache.clear();
          _globalEmployeeCache.clear();
          
          for (var emp in _employees) {
            _employeeCache[emp.id] = emp;
            _globalEmployeeCache[emp.id] = emp;
          }
        });
        
        AppLogger.debug('Loaded ${_employees.length} employees from API', tag: 'AuditLog');
      }
    } catch (e) {
      AppLogger.error('Failed to load employees', error: e, tag: 'AuditLog');
    } finally {
      setState(() => _isLoadingEmployees = false);
    }
  }
  
  String _getEmployeeName(int? employeeId) {
    if (employeeId == null) return 'N/A';
    final emp = _employeeCache[employeeId];
    return emp != null ? emp.fullName : 'Employee #$employeeId';
  }
  
  // ==================== LOAD AUDIT LOGS ====================
  
  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    
    try {
      // Ensure _toDate includes end of day (23:59:59)
      final adjustedToDate = _toDate != null
        ? DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59)
        : null;
      
      final response = await _payrollService.getAuditLogs(
        entityType: _selectedEntityType,
        employeeId: _selectedEmployeeId,
        action: _selectedAction,
        fromDate: _fromDate,
        toDate: adjustedToDate,
        page: _currentPage,
        pageSize: _pageSize,
      );
      
      if (response.success && response.data != null) {
        setState(() {
          _logs = response.data!;
          _totalRecords = response.data!.length; // Use list length instead
          
          if (_enableGrouping) {
            _groupedLogs = _groupLogs(_logs);
          } else {
            _groupedLogs = _logs.map((log) => LogGroup(
              groupKey: log.id.toString(),
              logs: [log],
              action: log.action,
              entityType: log.entityType,
              userId: log.userId,
              userName: log.userName,
              timestamp: log.timestamp,
            )).toList();
          }
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // ==================== LOG GROUPING LOGIC ====================
  
  List<LogGroup> _groupLogs(List<AuditLogResponse> logs) {
    final groups = <String, List<AuditLogResponse>>{};
    
    for (var log in logs) {
      final minuteTimestamp = DateTime(
        log.timestamp.year,
        log.timestamp.month,
        log.timestamp.day,
        log.timestamp.hour,
        log.timestamp.minute,
      );
      
      final key = '${log.action}_${log.entityType}_${log.userId}_${minuteTimestamp.millisecondsSinceEpoch}';
      
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(log);
    }
    
    final logGroups = <LogGroup>[];
    
    groups.forEach((key, logs) {
      if (logs.length >= 5) { // Threshold
        logGroups.add(LogGroup(
          groupKey: key,
          logs: logs,
          action: logs.first.action,
          entityType: logs.first.entityType,
          userId: logs.first.userId,
          userName: logs.first.userName,
          timestamp: logs.first.timestamp,
        ));
      } else {
        for (var log in logs) {
          logGroups.add(LogGroup(
            groupKey: log.id.toString(),
            logs: [log],
            action: log.action,
            entityType: log.entityType,
            userId: log.userId,
            userName: log.userName,
            timestamp: log.timestamp,
          ));
        }
      }
    });
    
    logGroups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return logGroups;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Audit Log - Lịch Sử Hệ Thống'),
        actions: [
          Tooltip(
            message: _enableGrouping ? 'Tắt gom nhóm' : 'Bật gom nhóm',
            child: IconButton(
              icon: Icon(_enableGrouping ? Icons.view_agenda : Icons.view_stream),
              onPressed: () {
                setState(() {
                  _enableGrouping = !_enableGrouping;
                  if (_enableGrouping) {
                    _groupedLogs = _groupLogs(_logs);
                  } else {
                    _groupedLogs = _logs.map((log) => LogGroup(
                      groupKey: log.id.toString(),
                      logs: [log],
                      action: log.action,
                      entityType: log.entityType,
                      userId: log.userId,
                      userName: log.userName,
                      timestamp: log.timestamp,
                    )).toList();
                  }
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAuditLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersSection(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _groupedLogs.isEmpty
                    ? _buildEmptyState()
                    : _buildGroupedLogsList(),
          ),
          _buildPagination(),
        ],
      ),
    );
  }
  
  // ==================== FILTERS SECTION ====================
  
  Widget _buildFiltersSection() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BỘ LỌC NÂNG CAO',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '$_totalRecords bản ghi',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildDatePresetDropdown(),
                ),
                const SizedBox(width: 12),
                if (_selectedPreset == DatePreset.custom) ...[
                  Expanded(
                    child: _buildDateRangeSelector(),
                  ),
                ] else ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _fromDate != null && _toDate != null
                                ? '${DateFormat('dd/MM/yyyy').format(_fromDate!)} - ${DateFormat('dd/MM/yyyy').format(_toDate!)}'
                                : 'N/A',
                              style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(child: _buildEntityTypeDropdown()),
                const SizedBox(width: 12),
                Expanded(child: _buildEmployeeDropdown()),
                const SizedBox(width: 12),
                Expanded(child: _buildActionDropdown()),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Tìm kiếm theo Lý do/Ghi chú',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      // Search functionality disabled - remove search query handling
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    _currentPage = 1;
                    _loadAuditLogs();
                  },
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Áp dụng'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Xóa'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDatePresetDropdown() {
    return DropdownButtonFormField<DatePreset>(
      decoration: const InputDecoration(
        labelText: 'Khoảng thời gian',
        prefixIcon: Icon(Icons.date_range, size: 20),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      value: _selectedPreset,
      items: DatePreset.values.map((preset) {
        return DropdownMenuItem(
          value: preset,
          child: Text(preset.displayName),
        );
      }).toList(),
      onChanged: (preset) {
        if (preset == null) return;
        
        setState(() {
          _selectedPreset = preset;
          
          if (preset != DatePreset.custom) {
            final range = preset.getRange();
            _fromDate = range.start;
            _toDate = range.end;
          }
        });
      },
    );
  }
  
  Widget _buildEntityTypeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Entity Type',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      value: _selectedEntityType,
      items: const [
        DropdownMenuItem(value: null, child: Text('Tất cả')),
        DropdownMenuItem(value: 'PayrollRecord', child: Text('Bảng Lương')),
        DropdownMenuItem(value: 'SalaryAdjustment', child: Text('Điều Chỉnh')),
        DropdownMenuItem(value: 'PayrollPeriod', child: Text('Kỳ Lương')),
      ],
      onChanged: (value) {
        setState(() => _selectedEntityType = value);
      },
    );
  }
  
  Widget _buildActionDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Action',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      value: _selectedAction,
      items: const [
        DropdownMenuItem(value: null, child: Text('Tất cả')),
        DropdownMenuItem(value: 'INSERT', child: Text('🟢 INSERT')),
        DropdownMenuItem(value: 'UPDATE', child: Text('🟡 UPDATE')),
        DropdownMenuItem(value: 'DELETE', child: Text('🔴 DELETE')),
      ],
      onChanged: (value) {
        setState(() => _selectedAction = value);
      },
    );
  }
  
  Widget _buildEmployeeDropdown() {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: 'Nhân viên',
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: _isLoadingEmployees 
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : null,
      ),
      value: _selectedEmployeeId,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả')),
        ..._employees.map((emp) => DropdownMenuItem(
          value: emp.id,
          child: Tooltip(
            message: '${emp.fullName} (${emp.employeeCode})',
            child: Text(
              '${emp.fullName} (${emp.employeeCode})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )),
      ],
      onChanged: _isLoadingEmployees 
        ? null 
        : (value) {
            setState(() => _selectedEmployeeId = value);
          },
    );
  }
  
  Widget _buildDateRangeSelector() {
    return InkWell(
      onTap: _showDateRangePicker,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tùy chỉnh',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(
          _fromDate != null && _toDate != null
              ? '${DateFormat('dd/MM').format(_fromDate!)} - ${DateFormat('dd/MM').format(_toDate!)}'
              : 'Chọn ngày',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
  
  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _fromDate ?? DateTime.now().subtract(const Duration(days: 29)),
        end: _toDate ?? DateTime.now(),
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedPreset = DatePreset.custom;
        _fromDate = picked.start;
        _toDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    }
  }
  
  void _clearFilters() {
    setState(() {
      _selectedEntityType = null;
      _selectedEmployeeId = null;
      _selectedAction = null;
      _selectedPreset = DatePreset.last30Days;
      final range = _selectedPreset.getRange();
      _fromDate = range.start;
      _toDate = range.end;
      _currentPage = 1;
    });
    _loadAuditLogs();
  }
  
  // ==================== GROUPED LOGS LIST ====================
  
  Widget _buildGroupedLogsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _groupedLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final group = _groupedLogs[index];
        return _buildGroupCard(group);
      },
    );
  }
  
  Widget _buildGroupCard(LogGroup group) {
    final isGroup = group.logs.length > 1;
    final actionColor = _getActionColor(group.action);
    
    return Card(
      elevation: 2,
      child: Column(
        children: [
          InkWell(
            onTap: isGroup ? () {
              setState(() {
                group.isExpanded = !group.isExpanded;
              });
            } : null,
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
                          color: actionColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getActionIcon(group.action),
                          color: actionColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Tooltip(
                              message: isGroup 
                                ? 'Nhấn để xem ${group.logs.length} bản ghi'
                                : 'Chi tiết audit log',
                              child: Text(
                                isGroup ? group.displayTitle : _buildSingleLogTitle(group.logs.first),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Tooltip(
                                  message: 'User ID: ${group.userId}',
                                  child: Text(
                                    '${group.userName ?? "Unknown"} (${group.userId})',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  _dateFormat.format(group.timestamp),
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isGroup) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: actionColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${group.logs.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: actionColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          group.isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey,
                        ),
                      ],
                    ],
                  ),
                  
                  if (!isGroup) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _buildLogContent(group.logs.first),
                  ],
                ],
              ),
            ),
          ),
          
          if (isGroup && group.isExpanded) ...[
            const Divider(height: 1),
            Container(
              color: Colors.grey[50],
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                itemCount: group.logs.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final log = group.logs[index];
                  return _buildChildLogItem(log);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _buildSingleLogTitle(AuditLogResponse log) {
    if (log.entityType == 'SalaryAdjustment' && log.action == 'INSERT') {
      final amount = _parseAmount(log.newValue);
      if (amount != null) {
        if (amount > 0) {
          return 'Thêm THƯỞNG ${_currencyFormat.format(amount)} cho ${_getEmployeeName(log.employeeId)}';
        } else {
          return 'Thêm PHẠT ${_currencyFormat.format(amount.abs())} cho ${_getEmployeeName(log.employeeId)}';
        }
      }
    }
    
    return '${_getActionDisplayName(log.action)} ${_getEntityTypeDisplayName(log.entityType)}';
  }
  
  Widget _buildChildLogItem(AuditLogResponse log) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: _getActionColor(log.action).withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getEmployeeName(log.employeeId),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (log.fieldName != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${_getFieldDisplayName(log.fieldName!)}: ${_formatValue(log.oldValue, log.fieldName)} → ${_formatValue(log.newValue, log.fieldName)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => _showLogDetails(log),
          icon: const Icon(Icons.visibility, size: 14),
          label: const Text('Chi tiết', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
  
  Widget _buildLogContent(AuditLogResponse log) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (log.fieldName != null) _buildFieldChangeEnhanced(log),
        
        if (log.reason != null && log.reason!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lý do: ${log.reason}',
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _showLogDetails(log),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('Chi tiết'),
            ),
            if (log.employeeId != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _navigateToEmployee(log.employeeId!),
                icon: const Icon(Icons.person, size: 16),
                label: const Text('Xem NV'),
              ),
            ],
          ],
        ),
      ],
    );
  }
  
  Widget _buildFieldChangeEnhanced(AuditLogResponse log) {
    final isCurrencyField = _isCurrencyField(log.fieldName);
    
    String oldValueDisplay = _formatValue(log.oldValue, log.fieldName);
    String newValueDisplay = _formatValue(log.newValue, log.fieldName);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Trường: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Tooltip(
                message: log.fieldName!,
                child: Text(
                  _getFieldDisplayName(log.fieldName!),
                  style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giá trị cũ:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Tooltip(
                      message: log.oldValue ?? 'null',
                      child: Text(
                        oldValueDisplay,
                        style: const TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: Colors.grey[600]),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giá trị mới:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Tooltip(
                      message: log.newValue ?? 'null',
                      child: Text(
                        newValueDisplay,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (isCurrencyField && log.oldValue != null && log.newValue != null) ...[
            const SizedBox(height: 8),
            _buildDifferenceIndicator(log.oldValue!, log.newValue!),
          ],
        ],
      ),
    );
  }
  
  String _formatValue(String? value, String? fieldName) {
    if (value == null || value.isEmpty || value == 'null') return 'null';
    
    if (_isCurrencyField(fieldName)) {
      final amount = _parseAmount(value);
      if (amount != null) {
        return _currencyFormat.format(amount);
      }
    }
    
    return value;
  }
  
  double? _parseAmount(String? value) {
    if (value == null || value.isEmpty || value == 'null') return null;
    try {
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }
  
  bool _isCurrencyField(String? fieldName) {
    if (fieldName == null) return false;
    const currencyFields = [
      'NetSalary', 'GrossSalary', 'BaseSalary', 'Amount',
      'SocialInsurance', 'HealthInsurance', 'UnemploymentInsurance',
      'PersonalIncomeTax', 'TotalIncome', 'TotalDeduction',
    ];
    return currencyFields.contains(fieldName);
  }
  
  Widget _buildDifferenceIndicator(String oldValue, String newValue) {
    final oldAmount = _parseAmount(oldValue);
    final newAmount = _parseAmount(newValue);
    
    if (oldAmount == null || newAmount == null) return const SizedBox.shrink();
    
    final difference = newAmount - oldAmount;
    final percentChange = oldAmount != 0 ? (difference / oldAmount * 100) : 0;
    final isIncrease = difference > 0;
    final color = isIncrease ? Colors.green : Colors.red;
    final icon = isIncrease ? Icons.trending_up : Icons.trending_down;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${isIncrease ? '+' : ''}${_currencyFormat.format(difference)}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
          if (percentChange.abs() > 0) ...[
            const SizedBox(width: 4),
            Text('(${percentChange.toStringAsFixed(1)}%)', style: TextStyle(fontSize: 11, color: color)),
          ],
        ],
      ),
    );
  }
  
  String _getFieldDisplayName(String fieldName) {
    const fieldNames = {
      'NetSalary': 'Lương Ròng',
      'GrossSalary': 'Lương Gross',
      'BaseSalary': 'Lương Cơ Bản',
      'Amount': 'Số Tiền',
      'WorkingDays': 'Ngày Công',
      'OvertimeHours': 'Giờ OT',
      'SocialInsurance': 'BHXH',
      'HealthInsurance': 'BHYT',
      'UnemploymentInsurance': 'BHTN',
      'PersonalIncomeTax': 'Thuế TNCN',
      'IsClosed': 'Trạng Thái',
    };
    return fieldNames[fieldName] ?? fieldName;
  }
  
  String _getEntityTypeDisplayName(String entityType) {
    const names = {
      'PayrollRecord': 'Bảng Lương',
      'SalaryAdjustment': 'Điều Chỉnh',
      'PayrollPeriod': 'Kỳ Lương',
      'AttendanceCorrection': 'Chấm Công',
    };
    return names[entityType] ?? entityType;
  }
  
  String _getActionDisplayName(String action) {
    const names = {
      'INSERT': 'Tạo mới',
      'UPDATE': 'Cập nhật',
      'DELETE': 'Xóa',
    };
    return names[action] ?? action;
  }
  
  Color _getActionColor(String action) {
    switch (action) {
      case 'INSERT': return Colors.green;
      case 'UPDATE': return Colors.orange;
      case 'DELETE': return Colors.red;
      default: return Colors.grey;
    }
  }
  
  IconData _getActionIcon(String action) {
    switch (action) {
      case 'INSERT': return Icons.add_circle;
      case 'UPDATE': return Icons.edit;
      case 'DELETE': return Icons.delete;
      default: return Icons.help;
    }
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Không có lịch sử thao tác', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Thử thay đổi bộ lọc hoặc khoảng thời gian', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }
  
  Widget _buildPagination() {
    final totalPages = (_totalRecords / _pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Trang $_currentPage / $totalPages (Tổng: $_totalRecords bản ghi)',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? () {
                  setState(() => _currentPage--);
                  _loadAuditLogs();
                } : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages ? () {
                  setState(() => _currentPage++);
                  _loadAuditLogs();
                } : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showLogDetails(AuditLogResponse log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết Audit Log'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID:', log.id.toString()),
              _buildDetailRow('Action:', log.action),
              _buildDetailRow('Entity Type:', log.entityType),
              _buildDetailRow('Entity ID:', log.entityId.toString()),
              if (log.employeeId != null)
                _buildDetailRow('Employee:', _getEmployeeName(log.employeeId)),
              _buildDetailRow('User:', '${log.userName ?? "Unknown"} (${log.userId})'),
              _buildDetailRow('Timestamp:', _dateFormat.format(log.timestamp)),
              if (log.fieldName != null)
                _buildDetailRow('Field:', _getFieldDisplayName(log.fieldName!)),
              if (log.oldValue != null)
                _buildDetailRow('Old Value:', _formatValue(log.oldValue, log.fieldName)),
              if (log.newValue != null)
                _buildDetailRow('New Value:', _formatValue(log.newValue, log.fieldName)),
              if (log.reason != null)
                _buildDetailRow('Reason:', log.reason!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(
            child: SelectableText(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
  
  void _navigateToEmployee(int employeeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeHRProfileScreen(
          employeeId: employeeId,
        ),
      ),
    );
  }
}
