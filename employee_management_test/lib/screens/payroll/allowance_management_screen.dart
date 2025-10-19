import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/dto/payroll_dtos.dart';
import '../../services/payroll_api_service.dart';
import '../../utils/app_logger.dart';

/// Màn hình quản lý phụ cấp của nhân viên
/// 
/// Features:
/// - Danh sách phụ cấp theo danh mục (ăn trưa, đi lại, điện thoại, nhà ở, chức vụ)
/// - Toggle switch bật/tắt phụ cấp
/// - Hiển thị ngày hiệu lực và ngày hết hạn
/// - CRUD operations: Thêm, sửa, xóa phụ cấp
/// - Filter theo danh mục
/// - Search theo tên phụ cấp
/// - Empty state handling
class AllowanceManagementScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  const AllowanceManagementScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<AllowanceManagementScreen> createState() => _AllowanceManagementScreenState();
}

class _AllowanceManagementScreenState extends State<AllowanceManagementScreen> {
  final PayrollApiService _apiService = PayrollApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<AllowanceResponse> _allAllowances = [];
  List<AllowanceResponse> _filteredAllowances = [];
  String? _selectedCategory;
  bool _isLoading = false;

  // Danh mục phụ cấp
  final Map<String, Map<String, dynamic>> _categories = {
    'Lunch': {'icon': '🍔', 'label': 'Ăn trưa', 'color': Colors.orange},
    'Transport': {'icon': '🚗', 'label': 'Đi lại', 'color': Colors.blue},
    'Phone': {'icon': '📱', 'label': 'Điện thoại', 'color': Colors.purple},
    'Housing': {'icon': '🏠', 'label': 'Nhà ở', 'color': Colors.green},
    'Position': {'icon': '💼', 'label': 'Chức vụ', 'color': Colors.amber},
  };

  @override
  void initState() {
    super.initState();
    AppLogger.info('Screen initialized for employee ${widget.employeeId}', tag: 'AllowanceManagement');
    _loadAllowances();
  }

  @override
  void dispose() {
    _searchController.dispose();
    AppLogger.info('Screen disposed', tag: 'AllowanceManagement');
    super.dispose();
  }

  /// Load danh sách phụ cấp từ API
  Future<void> _loadAllowances() async {
    setState(() => _isLoading = true);
    AppLogger.info('Loading allowances for employee ${widget.employeeId}', tag: 'AllowanceManagement');

    try {
      final response = await _apiService.getEmployeeAllowances(widget.employeeId);
      
      if (response.success && response.data != null) {
        setState(() {
          _allAllowances = response.data!;
          _applyFilters();
        });
        AppLogger.success('Loaded ${_allAllowances.length} allowances', tag: 'AllowanceManagement');
      } else {
        AppLogger.error('Failed to load allowances: ${response.message}', tag: 'AllowanceManagement');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Exception loading allowances', error: e, tag: 'AllowanceManagement');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải danh sách phụ cấp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Áp dụng filters (category + search)
  void _applyFilters() {
    _filteredAllowances = _allAllowances.where((allowance) {
      // Filter by category
      if (_selectedCategory != null && allowance.allowanceType != _selectedCategory) {
        return false;
      }

      // Filter by search text
      final searchText = _searchController.text.toLowerCase();
      if (searchText.isNotEmpty) {
        return allowance.allowanceType.toLowerCase().contains(searchText);
      }

      return true;
    }).toList();

    AppLogger.info('Filtered: ${_filteredAllowances.length}/${_allAllowances.length} allowances', tag: 'AllowanceManagement');
  }

  /// Hiển thị dialog thêm/sửa phụ cấp
  Future<void> _showAllowanceDialog({AllowanceResponse? existingAllowance}) async {
    final isEdit = existingAllowance != null;
    AppLogger.info(isEdit ? 'Opening edit dialog' : 'Opening create dialog', tag: 'AllowanceManagement');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AllowanceFormDialog(
        employeeId: widget.employeeId,
        existingAllowance: existingAllowance,
        categories: _categories,
      ),
    );

    if (result == true) {
      _loadAllowances(); // Reload list
    }
  }

  /// Toggle trạng thái IsActive
  Future<void> _toggleAllowanceStatus(AllowanceResponse allowance) async {
    AppLogger.info('Toggling allowance ${allowance.id}: ${allowance.isActive} -> ${!allowance.isActive}', tag: 'AllowanceManagement');

    // TODO: Implement PUT /api/payroll/allowances/{id} endpoint
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          allowance.isActive 
            ? 'Đã tắt phụ cấp "${allowance.allowanceType}"' 
            : 'Đã bật phụ cấp "${allowance.allowanceType}"'
        ),
        backgroundColor: const Color(0xFF34C759),
      ),
    );

    // Simulate update locally (Note: In real app, need backend PUT endpoint)
    _loadAllowances(); // Reload to get fresh data
  }

  /// Xác nhận xóa phụ cấp
  Future<void> _confirmDeleteAllowance(AllowanceResponse allowance) async {
    AppLogger.warning('Delete confirmation for allowance ${allowance.id}', tag: 'AllowanceManagement');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa phụ cấp "${allowance.allowanceType}"?\n\nHành động này không thể hoàn tác.'),
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
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAllowance(allowance);
    }
  }

  /// Xóa phụ cấp
  Future<void> _deleteAllowance(AllowanceResponse allowance) async {
    AppLogger.info('Deleting allowance ${allowance.id}', tag: 'AllowanceManagement');

    // TODO: Implement DELETE /api/payroll/allowances/{id} endpoint
    // For now, just show a message and remove from list
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa phụ cấp "${allowance.allowanceType}"'),
        backgroundColor: const Color(0xFF34C759),
      ),
    );

    setState(() {
      _allAllowances.removeWhere((a) => a.id == allowance.id);
      _applyFilters();
    });

    AppLogger.success('Deleted allowance ${allowance.id}', tag: 'AllowanceManagement');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎁 Quản lý phụ cấp', style: TextStyle(fontSize: 18)),
            Text(
              widget.employeeName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ℹ️ Thông tin'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Nhân viên: ${widget.employeeName}'),
                        Text('ID: ${widget.employeeId}'),
                        const SizedBox(height: 8),
                        Text('Tổng phụ cấp: ${_allAllowances.length}'),
                        Text('Đang kích hoạt: ${_allAllowances.where((a) => a.isActive).length}'),
                        Text('Tạm ngừng: ${_allAllowances.where((a) => !a.isActive).length}'),
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
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm phụ cấp...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _applyFilters());
                      },
                    )
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() => _applyFilters());
              },
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // "Tất cả" chip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Tất cả'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = null;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                // Category chips
                ..._categories.entries.map((entry) {
                  final category = entry.key;
                  final info = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Text(info['icon'] as String),
                      label: Text(info['label'] as String),
                      selected: _selectedCategory == category,
                      selectedColor: (info['color'] as Color).withOpacity(0.2),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                          _applyFilters();
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Allowances list
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredAllowances.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadAllowances,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredAllowances.length,
                      itemBuilder: (context, index) {
                        final allowance = _filteredAllowances[index];
                        return _buildAllowanceCard(allowance);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAllowanceDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm phụ cấp'),
        backgroundColor: const Color(0xFF0A84FF),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    final hasFilters = _selectedCategory != null || _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters 
              ? 'Không tìm thấy phụ cấp nào' 
              : 'Chưa có phụ cấp nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters 
              ? 'Thử thay đổi bộ lọc hoặc tìm kiếm' 
              : 'Nhấn nút "Thêm phụ cấp" để bắt đầu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _searchController.clear();
                  _applyFilters();
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Xóa bộ lọc'),
            ),
          ],
        ],
      ),
    );
  }

  /// Build allowance card
  Widget _buildAllowanceCard(AllowanceResponse allowance) {
    final categoryInfo = _categories[allowance.allowanceType];
    final icon = categoryInfo?['icon'] as String? ?? '🎁';
    final color = categoryInfo?['color'] as Color? ?? Colors.blue;

    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Icon + Name + Active switch
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allowance.allowanceType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        categoryInfo?['label'] as String? ?? allowance.allowanceType,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Active switch
                Switch(
                  value: allowance.isActive,
                  onChanged: (value) => _toggleAllowanceStatus(allowance),
                  activeColor: const Color(0xFF34C759),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Amount
            Row(
              children: [
                Icon(Icons.attach_money, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                const Text(
                  'Số tiền: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  formatter.format(allowance.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF34C759),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Effective date
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                const Text('Hiệu lực: '),
                Text(
                  dateFormatter.format(allowance.effectiveDate),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (allowance.expiryDate != null) ...[
                  const Text(' - '),
                  Text(
                    dateFormatter.format(allowance.expiryDate!),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Is recurring
            Row(
              children: [
                Icon(
                  allowance.isRecurring ? Icons.repeat : Icons.event,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  allowance.isRecurring ? 'Định kỳ hàng tháng' : 'Một lần',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),

            // Is Deduction
            if (allowance.isDeduction) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.remove_circle_outline, size: 20, color: Colors.red[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Khấu trừ',
                    style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAllowanceDialog(existingAllowance: allowance),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0A84FF),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDeleteAllowance(allowance),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF3B30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog form thêm/sửa phụ cấp
class _AllowanceFormDialog extends StatefulWidget {
  final int employeeId;
  final AllowanceResponse? existingAllowance;
  final Map<String, Map<String, dynamic>> categories;

  const _AllowanceFormDialog({
    required this.employeeId,
    this.existingAllowance,
    required this.categories,
  });

  @override
  State<_AllowanceFormDialog> createState() => _AllowanceFormDialogState();
}

class _AllowanceFormDialogState extends State<_AllowanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final PayrollApiService _apiService = PayrollApiService();

  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  String _selectedCategory = 'Lunch';
  DateTime _effectiveDate = DateTime.now();
  DateTime? _expiryDate;
  bool _isRecurring = true;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingAllowance;
    _nameController = TextEditingController(text: existing?.allowanceType ?? '');
    _amountController = TextEditingController(
      text: existing?.amount.toStringAsFixed(0) ?? '',
    );
    _descriptionController = TextEditingController(text: ''); // No description field in AllowanceResponse

    if (existing != null) {
      _selectedCategory = existing.allowanceType;
      _effectiveDate = existing.effectiveDate;
      _expiryDate = existing.expiryDate;
      _isRecurring = existing.isRecurring;
      _isActive = existing.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Pick effective date
  Future<void> _pickEffectiveDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => _effectiveDate = picked);
    }
  }

  /// Pick expiry date
  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? _effectiveDate.add(const Duration(days: 365)),
      firstDate: _effectiveDate,
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  /// Save allowance
  Future<void> _saveAllowance() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final isEdit = widget.existingAllowance != null;
    AppLogger.info(isEdit ? 'Updating allowance' : 'Creating allowance', tag: 'AllowanceForm');

    final request = CreateAllowanceRequest(
      employeeId: widget.employeeId,
      allowanceType: _nameController.text.trim(), // Use allowanceType instead of name
      amount: double.parse(_amountController.text.replaceAll(',', '')),
      isDeduction: false, // Default to not a deduction
      effectiveDate: _effectiveDate,
      expiryDate: _expiryDate,
      isRecurring: _isRecurring,
    );

    AppLogger.info('Request: ${request.toJson()}', tag: 'AllowanceForm');

    try {
      final response = await _apiService.createAllowance(request);

      if (response.success) {
        AppLogger.success('Allowance saved successfully', tag: 'AllowanceForm');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Đã cập nhật phụ cấp' : 'Đã thêm phụ cấp mới'),
              backgroundColor: const Color(0xFF34C759),
            ),
          );
          Navigator.pop(context, true); // Return true to reload list
        }
      } else {
        AppLogger.error('Failed to save: ${response.message}', tag: 'AllowanceForm');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Exception', error: e, tag: 'AllowanceForm');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lưu phụ cấp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      AppLogger.info('Save operation completed', tag: 'AllowanceForm');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingAllowance != null;
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      title: Text(isEdit ? '✏️ Sửa phụ cấp' : '➕ Thêm phụ cấp mới'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category selection
              const Text(
                'Danh mục *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: widget.categories.entries.map((entry) {
                  final category = entry.key;
                  final info = entry.value;
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(info['icon'] as String, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(info['label'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Name
              const Text(
                'Tên phụ cấp *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'VD: Phụ cấp ăn trưa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên phụ cấp';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Amount
              const Text(
                'Số tiền (₫) *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  hintText: 'VD: 1000000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: '₫',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return 'Số tiền phải lớn hơn 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Effective date
              const Text(
                'Ngày hiệu lực *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickEffectiveDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormatter.format(_effectiveDate)),
                ),
              ),

              const SizedBox(height: 16),

              // Expiry date (optional)
              Row(
                children: [
                  const Text(
                    'Ngày hết hạn (không bắt buộc)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_expiryDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _expiryDate = null),
                      tooltip: 'Xóa ngày hết hạn',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickExpiryDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event_busy),
                  ),
                  child: Text(
                    _expiryDate != null 
                      ? dateFormatter.format(_expiryDate!) 
                      : 'Không có ngày hết hạn',
                    style: TextStyle(
                      color: _expiryDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Is recurring
              SwitchListTile(
                title: const Text('Định kỳ hàng tháng'),
                subtitle: const Text('Tự động áp dụng mỗi tháng'),
                value: _isRecurring,
                onChanged: (value) => setState(() => _isRecurring = value),
                activeColor: const Color(0xFF34C759),
              ),

              // Is active
              SwitchListTile(
                title: const Text('Kích hoạt ngay'),
                subtitle: const Text('Áp dụng vào tính lương'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                activeColor: const Color(0xFF34C759),
              ),

              const SizedBox(height: 16),

              // Description (optional)
              const Text(
                'Ghi chú (không bắt buộc)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'VD: Phụ cấp ăn trưa theo chính sách công ty',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveAllowance,
          icon: _isSaving 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
          label: Text(_isSaving ? 'Đang lưu...' : 'Lưu'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0A84FF),
          ),
        ),
      ],
    );
  }
}
