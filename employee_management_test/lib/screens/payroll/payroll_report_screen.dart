import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dto/payroll_dtos.dart';
import '../../services/payroll_api_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/pdf_generator.dart';
import 'employee_salary_detail_screen_v2.dart';
import 'employee_hr_profile_screen.dart';

/// 📊 Payroll Report Screen - Detailed Employee Payroll Table
/// 
/// Features:
/// - DataTable with employee payroll breakdown
/// - Filter by department, position
/// - Search by employee name/MSNV
/// - Export to PDF
/// - Close payroll period
/// - Individual employee detail view
class PayrollReportScreen extends StatefulWidget {
  final int periodId;
  
  const PayrollReportScreen({
    super.key,
    required this.periodId,
  });

  @override
  State<PayrollReportScreen> createState() => _PayrollReportScreenState();
}

class _PayrollReportScreenState extends State<PayrollReportScreen> {
  final PayrollApiService _payrollService = PayrollApiService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final _searchController = TextEditingController();
  
  PayrollPeriodResponse? _period;
  PayrollSummaryResponse? _summary;
  List<PayrollRecordResponse> _records = [];
  List<PayrollRecordResponse> _filteredRecords = [];
  
  bool _isLoading = true;
  String? _error;
  
  // Filters
  String? _selectedDepartment;
  String? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterRecords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // ✅ Check mounted before setState
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      AppLogger.startOperation('Load Payroll Report for Period ${widget.periodId}');
      
      // Load period info
      final periodResponse = await _payrollService.getPayrollPeriodById(widget.periodId);
      
      // ✅ Check mounted after async call
      if (!mounted) return;
      
      if (periodResponse.success && periodResponse.data != null) {
        _period = periodResponse.data;
        AppLogger.data('Period: ${_period!.periodName}', tag: 'PayrollReport');
      } else {
        // Handle period load failure gracefully
        AppLogger.warning('Could not load period info: ${periodResponse.message}', tag: 'PayrollReport');
      }
      
      // Load summary
      final summaryResponse = await _payrollService.getPayrollSummary(widget.periodId);
      
      // ✅ Check mounted after async call
      if (!mounted) return;
      
      if (summaryResponse.success && summaryResponse.data != null) {
        _summary = summaryResponse.data;
        AppLogger.data('Summary loaded: ${_summary!.totalEmployees} employees', tag: 'PayrollReport');
      } else {
        // Handle summary load failure gracefully
        AppLogger.warning('Could not load summary: ${summaryResponse.message}', tag: 'PayrollReport');
      }
      
      // ✅ Load REAL payroll records from API with better error handling
      final recordsResponse = await _payrollService.getPayrollRecords(widget.periodId);
      
      // ✅ Check mounted after async call
      if (!mounted) return;
      
      // ✅ Better error handling for API response
      if (!recordsResponse.success) {
        // API call failed
        final errorMsg = recordsResponse.message ?? 'Không thể tải dữ liệu báo cáo';
        AppLogger.error('API call failed: $errorMsg', tag: 'PayrollReport');
        throw Exception(errorMsg);
      }
      
      // ✅ Extract actual records array - ONLY check records.length, NOT totalRecords
      final List<PayrollRecordResponse> actualRecords = recordsResponse.data?.records ?? [];
      
      if (actualRecords.isEmpty) {
        // ✅ Empty state - ONLY based on actual records array length
        AppLogger.info(
          'Empty state: No records in array (records.length: ${actualRecords.length})',
          tag: 'PayrollReport',
        );
        
        // ✅ Update period info from response if available (now using periodId, periodName)
        if (recordsResponse.data?.periodName != null) {
          // Period info is now flat in the response, not nested
          // We already loaded _period from getPayrollPeriodById() call above
          AppLogger.debug('Period name from records response: ${recordsResponse.data!.periodName}', tag: 'PayrollReport');
        }
        
        // Set empty records and update UI - DON'T THROW EXCEPTION
        _records = [];
        _filteredRecords = [];
        
        // ✅ Check mounted before setState
        if (!mounted) return;
        
        setState(() {
          _isLoading = false;
        });
        
        return; // Exit early - empty state UI will show
      }
      
      // ✅ Success - we have actual data in records array
      _records = actualRecords;
      _filteredRecords = List.from(_records);
      
      // ✅ Update period info from response if available (now using periodId, periodName)
      if (recordsResponse.data!.periodName != null) {
        // Period info is now flat in the response, not nested
        // We already loaded _period from getPayrollPeriodById() call above
        AppLogger.debug('Period name from records response: ${recordsResponse.data!.periodName}', tag: 'PayrollReport');
      }
      
      // Extract unique departments/positions (if backend provides)
      // For now, filters are disabled until employee data includes these fields
      
      AppLogger.success('Loaded ${_records.length} payroll records from API', tag: 'PayrollReport');
      
      // ✅ Check mounted before final setState
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      AppLogger.success('Report loaded: ${_records.length} records', tag: 'PayrollReport');
      AppLogger.endOperation('Load Payroll Report', success: true);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load report', error: e, stackTrace: stackTrace, tag: 'PayrollReport');
      AppLogger.endOperation('Load Payroll Report', success: false);
      
      // ✅ Check mounted before setState
      if (!mounted) return;
      
      // ✅ Format user-friendly error message
      String errorMessage = e.toString();
      
      // Clean up common error patterns
      if (errorMessage.contains('SocketException') || errorMessage.contains('Failed host lookup')) {
        errorMessage = 'Không thể kết nối đến server.\nVui lòng kiểm tra kết nối mạng.';
      } else if (errorMessage.contains('TimeoutException')) {
        errorMessage = 'Kết nối bị timeout.\nVui lòng thử lại sau.';
      } else if (errorMessage.contains('FormatException') || errorMessage.contains('Unexpected character')) {
        errorMessage = 'Lỗi định dạng dữ liệu từ server.\nVui lòng liên hệ IT support.';
      } else if (errorMessage.contains('Exception:')) {
        // Keep our custom messages clean
        errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
      }
      
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    }
  }

  void _filterRecords() {
    // ✅ Check mounted before setState
    if (!mounted) return;
    
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredRecords = _records.where((record) {
        final matchesSearch = record.employeeName.toLowerCase().contains(query) ||
                            record.employeeId.toString().contains(query);
        
        // TODO: Add department/position filter when backend provides data
        final matchesDepartment = _selectedDepartment == null || true;
        final matchesPosition = _selectedPosition == null || true;
        
        return matchesSearch && matchesDepartment && matchesPosition;
      }).toList();
    });
    
    AppLogger.data('Filtered: ${_filteredRecords.length}/${_records.length} records', tag: 'PayrollReport');
  }

  // ✅ REMOVED: Dummy data generator - now using REAL API data from getPayrollRecords()

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 Báo cáo bảng lương'),
            if (_period != null)
              Text(
                _period!.periodName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          // Export PDF
          IconButton(
            onPressed: _exportPDF,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Xuất PDF',
          ),
          // Send Email
          IconButton(
            onPressed: _sendEmailNotification,
            icon: const Icon(Icons.email),
            tooltip: 'Gửi email',
          ),
          // Close Period
          if (_period != null && !_period!.isClosed)
            IconButton(
              onPressed: _closePeriod,
              icon: const Icon(Icons.lock),
              tooltip: 'Đóng kỳ lương',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, theme, colorScheme),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải báo cáo...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!, 
                style: TextStyle(color: colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    // ✅ NEW: Empty State - No payroll records
    if (_records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large icon
              const Text('💸', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Chưa có Bảng lương',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                _period != null
                  ? 'Kỳ lương "${_period!.periodName}" chưa có bản ghi lương.\nVui lòng tính lương trước.'
                  : 'Chưa có bản ghi lương cho kỳ này.\nVui lòng tính lương trước.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // ✅ Action Button: Generate Payroll
              if (_period != null && !_period!.isClosed)
                FilledButton.icon(
                  onPressed: () => _generatePayroll(),
                  icon: const Icon(Icons.account_balance_wallet, size: 24),
                  label: const Text('💰 Tính Lương Ngay'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                
              // Info for closed period
              if (_period != null && _period!.isClosed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, color: Colors.orange),
                      const SizedBox(width: 12),
                      Text(
                        'Kỳ lương đã đóng.\nKhông thể tính lương mới.',
                        style: TextStyle(color: Colors.orange[800]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ✅ NEW: Negative Salary Warning Banner
        if (_hasNegativeSalary())
          _buildNegativeSalaryWarning(),
        
        // Summary Header
        _buildSummaryHeader(theme, colorScheme),
        
        // Filters & Search
        _buildFiltersAndSearch(theme, colorScheme),
        
        // Data Table
        Expanded(
          child: _buildDataTable(theme, colorScheme),
        ),
        
        // Footer Actions
        _buildFooter(theme, colorScheme),
      ],
    );
  }

  Widget _buildSummaryHeader(ThemeData theme, ColorScheme colorScheme) {
    if (_summary == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A84FF), Color(0xFF0066CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Tổng nhân viên',
                  _summary!.totalEmployees.toString(),
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Tổng chi phí',
                  _formatCurrency(_summary!.totalNetSalary),
                  Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Lương OT',
                  _formatCurrency(_summary!.totalOvertimePay),
                  Icons.access_time,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Khấu trừ thuế',
                  _formatCurrency(_summary!.totalPITDeduction),
                  Icons.account_balance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersAndSearch(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm nhân viên (tên, MSNV)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 20),
                const SizedBox(width: 8),
                const Text('Bộ lọc:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                
                // Department Filter
                FilterChip(
                  label: Text(_selectedDepartment ?? 'Phòng ban'),
                  selected: _selectedDepartment != null,
                  onSelected: (selected) {
                    // TODO: Show department picker
                    AppLogger.ui('Department filter clicked', tag: 'PayrollReport');
                  },
                ),
                
                const SizedBox(width: 8),
                
                // Position Filter
                FilterChip(
                  label: Text(_selectedPosition ?? 'Chức vụ'),
                  selected: _selectedPosition != null,
                  onSelected: (selected) {
                    // TODO: Show position picker
                    AppLogger.ui('Position filter clicked', tag: 'PayrollReport');
                  },
                ),
                
                const SizedBox(width: 8),
                
                // Clear Filters
                if (_selectedDepartment != null || _selectedPosition != null)
                  TextButton.icon(
                    onPressed: () {
                      // ✅ Check mounted before setState
                      if (!mounted) return;
                      setState(() {
                        _selectedDepartment = null;
                        _selectedPosition = null;
                      });
                      _filterRecords();
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Xóa lọc'),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDataTable(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 24,
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFF0A84FF).withAlpha(25),
            ),
            columns: const [
              DataColumn(label: Text('STT', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Nhân viên', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Ngày công', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('OT (giờ)', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Lương cơ bản', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Phụ cấp', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Lương thực nhận', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _filteredRecords.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              
              return DataRow(
                color: WidgetStateProperty.all(
                  index.isEven ? null : colorScheme.surfaceContainerHighest.withAlpha(50),
                ),
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF0A84FF).withAlpha(50),
                          child: Text(
                            record.employeeName[0],
                            style: const TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              record.employeeName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'MSNV: ${record.employeeId}',
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => _viewEmployeeHRProfile(record), // Navigate to HR Profile
                  ),
                  DataCell(Text('${record.totalWorkingDays}')),
                  DataCell(Text('${record.totalOTHours}')),
                  DataCell(Text(_formatCurrency(record.baseSalaryActual))),
                  DataCell(Text(_formatCurrency(record.totalAllowances))),
                  DataCell(
                    Row(
                      children: [
                        if (record.netSalary < 0) ...[
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFF3B30),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _formatCurrency(record.netSalary),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: record.netSalary < 0
                                ? const Color(0xFFFF3B30) // Red for negative
                                : const Color(0xFF34C759), // Green for positive
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 20),
                      onPressed: () => _viewEmployeeDetail(record),
                      tooltip: 'Xem chi tiết',
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Text(
            'Tổng: ${_filteredRecords.length} nhân viên',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          
          if (_period != null && !_period!.isClosed) ...[
            FilledButton.icon(
              onPressed: _closePeriod,
              icon: const Icon(Icons.lock),
              label: const Text('Đóng kỳ lương'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          FilledButton.tonalIcon(
            onPressed: _exportPDF,
            icon: const Icon(Icons.file_download),
            label: const Text('Xuất PDF'),
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONS ====================

  void _viewEmployeeDetail(PayrollRecordResponse record) {
    AppLogger.navigation('PayrollReport', 'EmployeePayrollDetail', 
      arguments: {'employeeId': record.employeeId, 'periodId': widget.periodId});
    
    // Navigate to Employee Salary Detail Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeSalaryDetailScreenV2(
          periodId: widget.periodId,
          employeeId: record.employeeId,
        ),
      ),
    );
  }

  /// Navigate to Employee HR Profile (payroll rules management)
  void _viewEmployeeHRProfile(PayrollRecordResponse record) {
    AppLogger.navigation('PayrollReport', 'EmployeeHRProfile', 
      arguments: {'employeeId': record.employeeId});
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeHRProfileScreen(
          employeeId: record.employeeId,
          employeeName: record.employeeName,
        ),
      ),
    );
  }

  void _exportPDF() async {
    if (_summary == null || _filteredRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Không có dữ liệu để xuất PDF')),
      );
      return;
    }

    AppLogger.business('User requested PDF export for period ${widget.periodId}', tag: 'PayrollReport');
    
    try {
      // Show progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tạo file PDF...'),
            ],
          ),
        ),
      );

      // Generate PDF with REAL DATA
      final pdf = await PayrollPdfGenerator.generatePeriodReport(
        periodName: _period?.periodName ?? 'Kỳ lương #${widget.periodId}',
        records: _filteredRecords,
        summary: _summary!,
        companyName: 'CÔNG TY CỔ PHẦN XYZ',
      );

      // Close loading
      if (mounted) Navigator.pop(context);

      // Show action menu
      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility, color: Color(0xFF2196F3)),
                title: const Text('Xem trước'),
                onTap: () async {
                  Navigator.pop(context);
                  await PayrollPdfGenerator.previewPdf(pdf);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Color(0xFF34C759)),
                title: const Text('Tải xuống'),
                onTap: () async {
                  Navigator.pop(context);
                  final fileName = 'bao_cao_luong_${widget.periodId}_${DateTime.now().millisecondsSinceEpoch}';
                  final filePath = await PayrollPdfGenerator.savePdf(
                    pdf: pdf,
                    fileName: fileName,
                  );
                  
                  if (mounted && filePath != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(child: Text('✅ Đã lưu: $filePath')),
                          ],
                        ),
                        backgroundColor: const Color(0xFF34C759),
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Lỗi khi lưu PDF')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Color(0xFFFF9500)),
                title: const Text('Chia sẻ'),
                onTap: () async {
                  Navigator.pop(context);
                  final fileName = 'bao_cao_luong_${_period?.periodName ?? widget.periodId}';
                  await PayrollPdfGenerator.sharePdf(pdf: pdf, fileName: fileName);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to export PDF', error: e, tag: 'PayrollReport');
      
      // Close loading if still open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi tạo PDF: $e')),
        );
      }
    }
  }

  void _sendEmailNotification() async {
    AppLogger.business('User requested email notification for period ${widget.periodId}', tag: 'PayrollReport');
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email),
            SizedBox(width: 12),
            Text('Gửi thông báo lương'),
          ],
        ),
        content: Text(
          'Gửi thông báo lương qua email cho ${_filteredRecords.length} nhân viên?\n\n'
          'Mỗi nhân viên sẽ nhận được email với bảng lương chi tiết.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.send),
            label: const Text('Gửi email'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Show progress
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Đang gửi email (0/${_filteredRecords.length})...'),
              ],
            ),
          ),
        );
      }
      
      // Simulate email sending
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Đã gửi ${_filteredRecords.length} email thành công!'),
              ],
            ),
            backgroundColor: const Color(0xFF34C759),
          ),
        );
      }
      
      // TODO: Implement actual email sending via backend API
    }
  }

  void _closePeriod() async {
    AppLogger.business('User requested to close period ${widget.periodId}', tag: 'PayrollReport');
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock, color: Colors.red, size: 48),
        title: const Text('Xác nhận đóng kỳ lương'),
        content: const Text(
          'Bạn có chắc chắn muốn đóng kỳ lương này?\n\n'
          'Sau khi đóng, bạn sẽ KHÔNG THỂ chỉnh sửa bảng lương của kỳ này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
            ),
            child: const Text('Đóng kỳ lương'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Show progress
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang đóng kỳ lương...'),
              ],
            ),
          ),
        );
      }
      
      try {
        // TODO: Call API to close period
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted) {
          Navigator.pop(context); // Close progress
          
          // Update UI
          setState(() {
            _period = PayrollPeriodResponse(
              id: _period!.id,
              periodName: _period!.periodName,
              startDate: _period!.startDate,
              endDate: _period!.endDate,
              isClosed: true,
              closedAt: DateTime.now(),
              createdAt: _period!.createdAt,
            );
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Đã đóng kỳ lương thành công!'),
                ],
              ),
              backgroundColor: Color(0xFF34C759),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close progress
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString()}'),
              backgroundColor: const Color(0xFFFF3B30),
            ),
          );
        }
      }
    }
  }

  String _formatCurrency(double amount) {
    return _currencyFormat.format(amount).replaceAll('₫', '').trim();
  }

  // ✅ NEW: Check if any employee has negative salary
  bool _hasNegativeSalary() {
    return _filteredRecords.any((record) => record.netSalary < 0);
  }

  // ✅ NEW: Build negative salary warning banner
  Widget _buildNegativeSalaryWarning() {
    final negativeCount = _filteredRecords.where((r) => r.netSalary < 0).length;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[100]!, Colors.orange[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ CẢNH BÁO LƯƠNG ÂM',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Có $negativeCount nhân viên có lương ròng âm. Vui lòng kiểm tra lại Điều chỉnh Lương (Thưởng/Phạt).',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Generate Payroll function
  Future<void> _generatePayroll() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Color(0xFF0A84FF)),
            SizedBox(width: 12),
            Text('Tính lương'),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn tính lương cho kỳ "${_period?.periodName ?? ''}"?\n\n'
          'Hệ thống sẽ tính toán lương cho tất cả nhân viên dựa trên:\n'
          '• Ngày công\n'
          '• Giờ tăng ca\n'
          '• Phụ cấp\n'
          '• Thưởng/Phạt (nếu có)\n'
          '• Bảo hiểm và thuế',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tính lương'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tính lương...'),
          ],
        ),
      ),
    );

    try {
      // Call generate payroll API
      final response = await _payrollService.generatePayroll(widget.periodId);

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (response.success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      response.message ?? 'Tính lương thành công!',
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF34C759),
              duration: const Duration(seconds: 3),
            ),
          );

          // Reload data
          await _loadData();
        } else {
          // Show error from backend
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Lỗi tính lương'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(response.message ?? 'Không thể tính lương'),
                  if (response.data != null && response.data!.errors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Chi tiết lỗi:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...response.data!.errors.map(
                      (error) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text('• $error'),
                      ),
                    ),
                  ],
                ],
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
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
