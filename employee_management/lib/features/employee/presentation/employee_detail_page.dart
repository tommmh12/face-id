import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../utils/formatters.dart';
import '../data/employee_service.dart';
import '../data/models/employee_model.dart';
import '../../payroll/data/payroll_service.dart';
import '../../payroll/data/models/payroll_model.dart';

class EmployeeDetailPage extends StatefulWidget {
  final int? employeeId;

  const EmployeeDetailPage({super.key, this.employeeId});

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late final EmployeeService _employeeService;
  late final PayrollService _payrollService;
  late final TabController _tabController;

  Employee? _employee;
  PayrollRule? _payrollRule;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _employeeService = EmployeeService(_apiClient);
    _payrollService = PayrollService(_apiClient);
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.employeeId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final employee = await _employeeService.getEmployeeById(widget.employeeId!);
      PayrollRule? payrollRule;
      
      try {
        payrollRule = await _payrollService.getEmployeeRule(widget.employeeId!);
      } catch (e) {
        // Ignore if no payroll rule exists
      }

      setState(() {
        _employee = employee;
        _payrollRule = payrollRule;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết nhân viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Thông tin', icon: Icon(Icons.person)),
            Tab(text: 'Lương & Phụ cấp', icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Đang tải thông tin...');
    }

    if (_error != null) {
      return ErrorStateWidget(
        message: _error!,
        onRetry: _loadData,
      );
    }

    if (_employee == null) {
      return const EmptyWidget(
        icon: Icons.person_outline,
        message: 'Không tìm thấy thông tin nhân viên',
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildProfileTab(),
        _buildPayrollTab(),
      ],
    );
  }

  Widget _buildProfileTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Face Image Card
            _buildFaceCard(),
            const SizedBox(height: 16),

            // Basic Info Card
            _buildInfoCard(),
            const SizedBox(height: 16),

            // Contact Info Card
            _buildContactCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ảnh nhận diện khuôn mặt',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.mediumGray),
                    ),
                    child: _employee!.faceImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _employee!.faceImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person,
                                size: 80,
                                color: AppTheme.darkGray,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 80,
                            color: AppTheme.darkGray,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _registerFace(),
                        icon: const Icon(Icons.camera_alt),
                        label: Text(_employee!.faceImageUrl == null
                            ? 'Đăng ký khuôn mặt'
                            : 'Cập nhật ảnh'),
                      ),
                      if (_employee!.faceImageUrl != null) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _verifyFace(),
                          icon: const Icon(Icons.face),
                          label: const Text('Xác thực'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cơ bản',
              style: AppTheme.heading3,
            ),
            const Divider(),
            _buildInfoRow('Mã nhân viên', _employee!.employeeCode),
            _buildInfoRow('Họ và tên', _employee!.fullName),
            _buildInfoRow('Phòng ban', _employee!.departmentName ?? 'N/A'),
            _buildInfoRow('Chức vụ', _employee!.position ?? 'N/A'),
            _buildInfoRow(
              'Ngày sinh',
              _employee!.dateOfBirth != null
                  ? Formatters.formatDate(_employee!.dateOfBirth)
                  : 'N/A',
            ),
            _buildInfoRow(
              'Ngày vào làm',
              _employee!.joinDate != null
                  ? Formatters.formatDate(_employee!.joinDate)
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Trạng thái: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.darkGray,
                  ),
                ),
                StatusBadge(isActive: _employee!.isActive),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin liên hệ',
              style: AppTheme.heading3,
            ),
            const Divider(),
            _buildInfoRow('Email', _employee!.email ?? 'N/A'),
            _buildInfoRow(
              'Số điện thoại',
              _employee!.phoneNumber != null
                  ? Formatters.formatPhoneNumber(_employee!.phoneNumber)
                  : 'N/A',
            ),
            _buildInfoRow(
              'Ngày tạo',
              Formatters.formatDateTime(_employee!.createdAt),
            ),
            if (_employee!.updatedAt != null)
              _buildInfoRow(
                'Cập nhật lần cuối',
                Formatters.formatDateTime(_employee!.updatedAt),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_payrollRule != null) ...[
            _buildPayrollRuleCard(),
          ] else ...[
            const EmptyWidget(
              icon: Icons.payment,
              message: 'Chưa có quy tắc lương cho nhân viên này',
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showCreatePayrollRuleDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tạo quy tắc lương'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPayrollRuleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quy tắc lương',
                  style: AppTheme.heading3,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showCreatePayrollRuleDialog(),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(
              'Lương cơ bản',
              Formatters.formatCurrency(_payrollRule!.baseSalary),
            ),
            _buildInfoRow(
              'Tỷ lệ OT',
              Formatters.formatPercentage(_payrollRule!.overtimeRate),
            ),
            _buildInfoRow(
              'Tỷ lệ bảo hiểm',
              Formatters.formatPercentage(_payrollRule!.insuranceRate),
            ),
            _buildInfoRow(
              'Tỷ lệ thuế',
              Formatters.formatPercentage(_payrollRule!.taxRate),
            ),
            _buildInfoRow(
              'Có hiệu lực từ',
              Formatters.formatDate(_payrollRule!.effectiveFrom),
            ),
            if (_payrollRule!.effectiveTo != null)
              _buildInfoRow(
                'Hết hiệu lực',
                Formatters.formatDate(_payrollRule!.effectiveTo),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerFace() async {
    final ImagePicker picker = ImagePicker();
    
    // Show option to choose camera or gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn nguồn ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Convert to base64
      final Uint8List imageBytes = await image.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // Call API
      final request = RegisterFaceRequest(
        employeeId: widget.employeeId!,
        faceImageBase64: base64Image,
      );

      final response = await _employeeService.registerFace(request);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký khuôn mặt thành công!')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Đăng ký thất bại')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _verifyFace() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final Uint8List imageBytes = await image.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final request = VerifyFaceRequest(
        imageBase64: base64Image,
      );

      final response = await _employeeService.verifyFace(request);

      if (!mounted) return;
      Navigator.pop(context);

      final isMatch = response['data']?['isMatch'] ?? false;
      final confidence = response['data']?['confidence'] ?? 0.0;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isMatch ? 'Xác thực thành công!' : 'Xác thực thất bại'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMatch ? Icons.check_circle : Icons.cancel,
                size: 64,
                color: isMatch ? AppTheme.successGreen : AppTheme.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Độ chính xác: ${(confidence * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16),
              ),
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
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _showCreatePayrollRuleDialog() {
    showDialog(
      context: context,
      builder: (context) => CreatePayrollRuleDialog(
        employeeId: widget.employeeId!,
        existingRule: _payrollRule,
        onSuccess: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }
}

// Dialog to create/update payroll rule
class CreatePayrollRuleDialog extends StatefulWidget {
  final int employeeId;
  final PayrollRule? existingRule;
  final VoidCallback onSuccess;

  const CreatePayrollRuleDialog({
    super.key,
    required this.employeeId,
    this.existingRule,
    required this.onSuccess,
  });

  @override
  State<CreatePayrollRuleDialog> createState() =>
      _CreatePayrollRuleDialogState();
}

class _CreatePayrollRuleDialogState extends State<CreatePayrollRuleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _baseSalaryController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _baseSalaryController = TextEditingController(
      text: widget.existingRule?.baseSalary.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _baseSalaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClient();
      final payrollService = PayrollService(apiClient);

      final request = CreatePayrollRuleRequest(
        employeeId: widget.employeeId,
        baseSalary: double.parse(_baseSalaryController.text),
        standardWorkingDays: 22,
        socialInsuranceRate: 8.0,
        healthInsuranceRate: 1.5,
        unemploymentInsuranceRate: 1.0,
        personalDeduction: 11000000,
        numberOfDependents: 0,
        dependentDeduction: 4400000,
      );

      await payrollService.createOrUpdateRule(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu quy tắc lương thành công!')),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingRule == null
          ? 'Tạo quy tắc lương'
          : 'Cập nhật quy tắc lương'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _baseSalaryController,
                decoration: const InputDecoration(
                  labelText: 'Lương cơ bản (VNĐ) *',
                  border: OutlineInputBorder(),
                  helperText: 'Ví dụ: 20000000',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập lương cơ bản';
                  if (double.tryParse(value!) == null) return 'Số không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Ghi chú: Các thông số bảo hiểm và thuế sử dụng giá trị mặc định theo quy định.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
