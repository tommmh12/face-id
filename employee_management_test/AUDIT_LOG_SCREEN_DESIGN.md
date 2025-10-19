# 🔍 AUDIT LOG SCREEN - THIẾT KẾ CHI TIẾT

## 🎯 Mục Tiêu
Cung cấp **truy vết đầy đủ** mọi thao tác quan trọng trong hệ thống lương để đảm bảo tính minh bạch, tuân thủ và dễ dàng debug.

---

## 📋 YÊU CẦU NGHIỆP VỤ

### 1. Các Hành Động Cần Audit (Action Types)
| Action | Entity Type | Ví dụ Sử Dụng |
|--------|-------------|---------------|
| **INSERT** | PayrollRecord | Tạo bảng lương mới cho NV |
| **UPDATE** | PayrollRecord | Tính lại lương sau chỉnh sửa |
| **UPDATE** | PayrollPeriod | Đóng kỳ lương |
| **INSERT** | SalaryAdjustment | Thêm thưởng/phạt |
| **UPDATE** | AttendanceCorrection | Sửa chấm công (ngày công, OT) |
| **DELETE** | SalaryAdjustment | Xóa điều chỉnh sai |

### 2. Thông Tin Cần Lưu
- **Ai** (userId, userName)
- **Làm gì** (action: INSERT/UPDATE/DELETE)
- **Ở đâu** (entityType, entityId)
- **Khi nào** (timestamp)
- **Trước/Sau** (oldValue, newValue)
- **Tại sao** (reason - bắt buộc cho UPDATE/DELETE)

---

## 🏗️ THIẾT KẾ GIAO DIỆN

### Layout Tổng Quan
```
┌─────────────────────────────────────────────────────────────┐
│ 🔍 Audit Log - Lịch Sử Hệ Thống                  [Export]   │
├─────────────────────────────────────────────────────────────┤
│ BỘ LỌC NÂNG CAO                                             │
│ ┌──────────────┬──────────────┬──────────────┬───────────┐ │
│ │ Entity Type  │ Employee     │ Action       │ Date Range│ │
│ │ [All▼]       │ [All▼]       │ [All▼]       │ [7 days▼] │ │
│ └──────────────┴──────────────┴──────────────┴───────────┘ │
│ [🔍 Tìm kiếm theo Lý do/Ghi chú]          [Áp dụng Bộ Lọc] │
├─────────────────────────────────────────────────────────────┤
│ DANH SÁCH THAY ĐỔI (Newest First)                          │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 🟢 INSERT | SalaryAdjustment                            │ │
│ │    Admin User • 19/10/2025 14:32                        │ │
│ │    Thêm THƯỞNG +2,000,000₫ cho Nguyễn Văn A            │ │
│ │    Lý do: "Hoàn thành dự án vượt deadline"             │ │
│ │    [Chi tiết] [Xem Employee] [Hoàn tác]                │ │
│ ├─────────────────────────────────────────────────────────┤ │
│ │ 🟡 UPDATE | PayrollRecord                               │ │
│ │    Kế toán B • 19/10/2025 13:15                         │ │
│ │    Sửa NetSalary: 15,000,000₫ → 15,500,000₫            │ │
│ │    Lý do: "Điều chỉnh BHXH sau khi KT phát hiện sai"   │ │
│ │    [Chi tiết] [Xem Payroll]                             │ │
│ ├─────────────────────────────────────────────────────────┤ │
│ │ 🔴 DELETE | SalaryAdjustment                            │ │
│ │    Admin User • 18/10/2025 09:45                        │ │
│ │    Xóa PENALTY -500,000₫ của Trần Thị C                │ │
│ │    Lý do: "Phạt nhầm người, đã hoàn lại"               │ │
│ │    [Chi tiết] [Khôi phục]                               │ │
│ └─────────────────────────────────────────────────────────┘ │
│ [Load more...] Page 1 of 10                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎨 IMPLEMENTATION

### 1. Main Screen Structure

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dto/audit_log_dtos.dart';
import '../services/payroll_api_service.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({Key? key}) : super(key: key);

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final _payrollService = PayrollApiService();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  
  // Filters
  String? _selectedEntityType;
  int? _selectedEmployeeId;
  String? _selectedAction;
  DateTime? _fromDate;
  DateTime? _toDate;
  String _searchQuery = '';
  
  // Data
  List<AuditLogResponse> _logs = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _pageSize = 20;
  int _totalRecords = 0;
  
  @override
  void initState() {
    super.initState();
    _fromDate = DateTime.now().subtract(Duration(days: 7)); // Default: Last 7 days
    _toDate = DateTime.now();
    _loadAuditLogs();
  }
  
  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _payrollService.getAuditLogs(
        entityType: _selectedEntityType,
        employeeId: _selectedEmployeeId,
        action: _selectedAction,
        fromDate: _fromDate,
        toDate: _toDate,
        page: _currentPage,
        pageSize: _pageSize,
      );
      
      if (response.success && response.data != null) {
        setState(() {
          _logs = response.data!;
          _totalRecords = response.totalRecords ?? 0;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🔍 Audit Log - Lịch Sử Hệ Thống'),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _exportToExcel,
            tooltip: 'Export to Excel',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAuditLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersSection(),
          Divider(height: 1),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? _buildEmptyState()
                    : _buildLogsList(),
          ),
          _buildPagination(),
        ],
      ),
    );
  }
  
  // ==================== FILTERS SECTION ====================
  
  Widget _buildFiltersSection() {
    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BỘ LỌC NÂNG CAO',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEntityTypeDropdown(),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildEmployeeDropdown(),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionDropdown(),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildDateRangeSelector(),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Tìm kiếm theo Lý do/Ghi chú',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    _currentPage = 1; // Reset to first page
                    _loadAuditLogs();
                  },
                  icon: Icon(Icons.filter_alt),
                  label: Text('Áp dụng Bộ Lọc'),
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: Icon(Icons.clear),
                  label: Text('Xóa Bộ Lọc'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEntityTypeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Entity Type',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      value: _selectedEntityType,
      items: [
        DropdownMenuItem(value: null, child: Text('Tất cả')),
        DropdownMenuItem(value: 'PayrollRecord', child: Text('Bảng Lương')),
        DropdownMenuItem(value: 'SalaryAdjustment', child: Text('Điều Chỉnh')),
        DropdownMenuItem(value: 'PayrollPeriod', child: Text('Kỳ Lương')),
        DropdownMenuItem(value: 'AttendanceCorrection', child: Text('Chấm Công')),
      ],
      onChanged: (value) {
        setState(() => _selectedEntityType = value);
      },
    );
  }
  
  Widget _buildActionDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Action',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      value: _selectedAction,
      items: [
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
  
  Widget _buildDateRangeSelector() {
    return InkWell(
      onTap: _showDateRangePicker,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Khoảng thời gian',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(
          _fromDate != null && _toDate != null
              ? '${DateFormat('dd/MM').format(_fromDate!)} - ${DateFormat('dd/MM').format(_toDate!)}'
              : 'Chọn ngày',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }
  
  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _fromDate ?? DateTime.now().subtract(Duration(days: 7)),
        end: _toDate ?? DateTime.now(),
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }
  
  void _clearFilters() {
    setState(() {
      _selectedEntityType = null;
      _selectedEmployeeId = null;
      _selectedAction = null;
      _fromDate = DateTime.now().subtract(Duration(days: 7));
      _toDate = DateTime.now();
      _searchQuery = '';
      _currentPage = 1;
    });
    _loadAuditLogs();
  }
  
  // ==================== LOGS LIST ====================
  
  Widget _buildLogsList() {
    return ListView.separated(
      padding: EdgeInsets.all(12),
      itemCount: _logs.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = _logs[index];
        return _buildLogCard(log);
      },
    );
  }
  
  Widget _buildLogCard(AuditLogResponse log) {
    final actionColor = _getActionColor(log.action);
    final actionIcon = _getActionIcon(log.action);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Action + Entity Type
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(actionIcon, color: actionColor, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            log.action,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: actionColor,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.entityType,
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            log.userName ?? 'Unknown User',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            _dateFormat.format(log.timestamp),
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            Divider(height: 1),
            SizedBox(height: 12),
            
            // Body: Changes Details
            if (log.fieldName != null) _buildFieldChange(log),
            
            if (log.reason != null && log.reason!.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lý do: ${log.reason}',
                        style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Footer: Actions
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showLogDetails(log),
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('Chi tiết'),
                ),
                if (log.employeeId != null) ...[
                  SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _navigateToEmployee(log.employeeId!),
                    icon: Icon(Icons.person, size: 16),
                    label: Text('Xem NV'),
                  ),
                ],
                if (log.action == 'DELETE' && _canRevert(log)) ...[
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _revertChange(log),
                    icon: Icon(Icons.undo, size: 16),
                    label: Text('Khôi phục'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
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
  
  Widget _buildFieldChange(AuditLogResponse log) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trường: ${log.fieldName}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giá trị cũ:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      log.oldValue ?? 'null',
                      style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.grey),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giá trị mới:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      log.newValue ?? 'null',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // ==================== HELPERS ====================
  
  Color _getActionColor(String action) {
    switch (action) {
      case 'INSERT':
        return Colors.green;
      case 'UPDATE':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getActionIcon(String action) {
    switch (action) {
      case 'INSERT':
        return Icons.add_circle;
      case 'UPDATE':
        return Icons.edit;
      case 'DELETE':
        return Icons.delete;
      default:
        return Icons.help;
    }
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Không có lịch sử thao tác',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Thử thay đổi bộ lọc hoặc khoảng thời gian',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPagination() {
    final totalPages = (_totalRecords / _pageSize).ceil();
    
    if (totalPages <= 1) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
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
                icon: Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() => _currentPage--);
                        _loadAuditLogs();
                      }
                    : null,
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages
                    ? () {
                        setState(() => _currentPage++);
                        _loadAuditLogs();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // ==================== ACTIONS ====================
  
  void _showLogDetails(AuditLogResponse log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết Audit Log'),
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
                _buildDetailRow('Employee ID:', log.employeeId.toString()),
              _buildDetailRow('User:', log.userName ?? 'Unknown'),
              _buildDetailRow('Timestamp:', _dateFormat.format(log.timestamp)),
              if (log.fieldName != null)
                _buildDetailRow('Field Name:', log.fieldName!),
              if (log.oldValue != null)
                _buildDetailRow('Old Value:', log.oldValue!),
              if (log.newValue != null)
                _buildDetailRow('New Value:', log.newValue!),
              if (log.reason != null)
                _buildDetailRow('Reason:', log.reason!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
  
  void _navigateToEmployee(int employeeId) {
    // Navigate to employee detail screen
    Navigator.pushNamed(context, '/employees/detail', arguments: employeeId);
  }
  
  bool _canRevert(AuditLogResponse log) {
    // Check if change can be reverted (business logic)
    // Example: Can't revert if period is closed
    return log.entityType == 'SalaryAdjustment';
  }
  
  Future<void> _revertChange(AuditLogResponse log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ Xác nhận Khôi phục'),
        content: Text('Bạn có chắc muốn khôi phục thay đổi này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Khôi phục'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Call API to revert change
      // Example: Re-create deleted adjustment
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Đã khôi phục thay đổi')),
      );
      _loadAuditLogs();
    }
  }
  
  Future<void> _exportToExcel() async {
    // Export audit logs to Excel file
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📥 Đang export... (Chức năng đang phát triển)')),
    );
  }
  
  // TODO: Implement employee dropdown (fetch from API)
  Widget _buildEmployeeDropdown() {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: 'Nhân viên',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      value: _selectedEmployeeId,
      items: [
        DropdownMenuItem(value: null, child: Text('Tất cả')),
        // TODO: Load from API
      ],
      onChanged: (value) {
        setState(() => _selectedEmployeeId = value);
      },
    );
  }
}
```

---

## 📋 DTO MODELS (Cần Tạo)

```dart
// lib/models/dto/audit_log_dtos.dart

class AuditLogResponse {
  final int id;
  final String action; // INSERT, UPDATE, DELETE
  final String entityType; // PayrollRecord, SalaryAdjustment, etc.
  final int entityId;
  final int? employeeId;
  final int userId;
  final String? userName;
  final DateTime timestamp;
  final String? fieldName;
  final String? oldValue;
  final String? newValue;
  final String? reason;

  AuditLogResponse({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.employeeId,
    required this.userId,
    this.userName,
    required this.timestamp,
    this.fieldName,
    this.oldValue,
    this.newValue,
    this.reason,
  });

  factory AuditLogResponse.fromJson(Map<String, dynamic> json) {
    return AuditLogResponse(
      id: json['id'] as int,
      action: json['action'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as int,
      employeeId: json['employeeId'] as int?,
      userId: json['userId'] as int,
      userName: json['userName'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      fieldName: json['fieldName'] as String?,
      oldValue: json['oldValue']?.toString(),
      newValue: json['newValue']?.toString(),
      reason: json['reason'] as String?,
    );
  }
}
```

---

## 🔌 API SERVICE METHOD (Cần Thêm)

```dart
// Add to lib/services/payroll_api_service.dart

/// GET /api/payroll/audit
/// Lấy danh sách audit logs với filters
Future<ApiResponse<List<AuditLogResponse>>> getAuditLogs({
  String? entityType,
  int? employeeId,
  String? action,
  DateTime? fromDate,
  DateTime? toDate,
  int page = 1,
  int pageSize = 20,
}) async {
  final queryParams = <String, String>{
    'page': page.toString(),
    'pageSize': pageSize.toString(),
  };
  
  if (entityType != null) queryParams['entityType'] = entityType;
  if (employeeId != null) queryParams['employeeId'] = employeeId.toString();
  if (action != null) queryParams['action'] = action;
  if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
  if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();
  
  final uri = Uri.parse('${ApiConfig.baseUrl}$_endpoint/audit')
      .replace(queryParameters: queryParams);
  
  AppLogger.apiRequest('$_endpoint/audit', method: 'GET', data: queryParams);
  
  final response = await handleListRequest(
    () => CustomHttpClient.get(uri, headers: ApiConfig.headers),
    (json) => AuditLogResponse.fromJson(json),
  );
  
  AppLogger.apiResponse(
    '$_endpoint/audit',
    success: response.success,
    message: response.message,
    data: response.data != null ? 'Count: ${response.data!.length}' : null,
  );
  
  return response;
}
```

---

## ✅ CHECKLIST IMPLEMENTATION

### Phase 1: Core Features (HIGH Priority)
- [ ] Tạo `audit_log_dtos.dart` với AuditLogResponse model
- [ ] Thêm `getAuditLogs()` method vào PayrollApiService
- [ ] Tạo `audit_log_screen.dart` với basic UI
- [ ] Implement filters (entity type, action, date range)
- [ ] Implement pagination
- [ ] Test với mock data

### Phase 2: Advanced Features (MEDIUM Priority)
- [ ] Implement search by reason/note
- [ ] Add employee dropdown filter (fetch from API)
- [ ] Implement "Chi tiết" dialog
- [ ] Add "Xem NV" navigation
- [ ] Add color-coded action indicators

### Phase 3: Nice-to-Have (LOW Priority)
- [ ] Implement "Khôi phục" (revert) functionality
- [ ] Export to Excel
- [ ] Real-time updates (WebSocket)
- [ ] Timeline view (alternative to list)

---

## 🎨 COLOR SCHEME

| Action | Color | Icon |
|--------|-------|------|
| INSERT | `Colors.green` | `Icons.add_circle` |
| UPDATE | `Colors.orange` | `Icons.edit` |
| DELETE | `Colors.red` | `Icons.delete` |

---

## 🔒 SECURITY CONSIDERATIONS

1. **Role-Based Access**: Chỉ Admin/Kế toán mới xem được Audit Log
2. **Sensitive Data**: Mask lương/BHXH trong logs (chỉ hiển thị cho Admin)
3. **Retention Policy**: Logs cần giữ ít nhất 3 năm (compliance)
4. **Export Audit**: Export action cũng cần được audit!

---

## 📊 PERFORMANCE NOTES

- **Pagination**: Mặc định 20 bản ghi/trang (có thể tăng lên 50/100)
- **Indexing**: Backend cần index trên `timestamp`, `entityType`, `employeeId`
- **Date Range**: Giới hạn tối đa 90 ngày để tránh query quá lớn
- **Lazy Loading**: Consider infinite scroll thay vì pagination buttons

---

**Status:** 📝 Design Spec Ready  
**Priority:** **CRITICAL** (Required for compliance & debugging)  
**Estimated Time:** 6-8 hours  
**Dependencies:** Backend cần implement `/audit` endpoint
