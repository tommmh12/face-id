import 'package:flutter/material.dart';
import '../../models/department.dart';
import '../../services/employee_api_service.dart';
import '../../config/app_theme.dart';

class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  State<DepartmentManagementScreen> createState() =>
      _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState
    extends State<DepartmentManagementScreen> {
  final EmployeeApiService _service = EmployeeApiService();
  List<Department> _departments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _service.getDepartments();
      if (response.success && response.data != null) {
        setState(() {
          _departments = response.data!;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Không thể tải danh sách phòng ban';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showDepartmentDialog({Department? department}) async {
    final isEdit = department != null;
    final nameController = TextEditingController(text: department?.name ?? '');
    final descController = TextEditingController(
      text: department?.description ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        ),
        elevation: 10,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isEdit 
                        ? AppColors.gradientSoftOrange 
                        : AppColors.gradientSoftTeal,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppBorderRadius.xl),
                    topRight: Radius.circular(AppBorderRadius.xl),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit_rounded : Icons.add_business_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Chỉnh Sửa Phòng Ban' : 'Thêm Phòng Ban Mới',
                            style: AppTextStyles.h5.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            isEdit ? 'Cập nhật thông tin' : 'Tạo phòng ban mới',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    // Department Name Field
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: AppShadows.small,
                        borderRadius: BorderRadius.circular(AppBorderRadius.large),
                      ),
                      child: TextField(
                        controller: nameController,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Tên phòng ban *',
                          labelStyle: AppTextStyles.label,
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(AppSpacing.sm),
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.gradientSoftTeal,
                              ),
                              borderRadius: BorderRadius.circular(AppBorderRadius.small),
                            ),
                            child: const Icon(
                              Icons.business_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            borderSide: BorderSide(
                              color: AppColors.borderLight,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            borderSide: BorderSide(
                              color: AppColors.secondaryTeal,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Description Field
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: AppShadows.small,
                        borderRadius: BorderRadius.circular(AppBorderRadius.large),
                      ),
                      child: TextField(
                        controller: descController,
                        maxLines: 3,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Mô tả (tùy chọn)',
                          labelStyle: AppTextStyles.label,
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(AppSpacing.sm),
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.gradientSoftBlue,
                              ),
                              borderRadius: BorderRadius.circular(AppBorderRadius.small),
                            ),
                            child: const Icon(
                              Icons.description_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            borderSide: BorderSide(
                              color: AppColors.borderLight,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  bottom: AppSpacing.xl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.textTertiary),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.large),
                          ),
                        ),
                        child: Text(
                          'Hủy',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isEdit 
                                ? AppColors.gradientSoftOrange 
                                : AppColors.gradientSoftTeal,
                          ),
                          borderRadius: BorderRadius.circular(AppBorderRadius.large),
                          boxShadow: AppShadows.small,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Vui lòng nhập tên phòng ban'),
                                  backgroundColor: AppColors.errorColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context, true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            ),
                          ),
                          child: Text(
                            isEdit ? 'Cập Nhật' : 'Tạo Phòng Ban',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Chức năng cập nhật sẽ được triển khai sau'
                : 'Chức năng thêm mới sẽ được triển khai sau',
          ),
        ),
      );
    }

    nameController.dispose();
    descController.dispose();
  }

  Future<void> _deleteDepartment(Department department) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        ),
        elevation: 10,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.errorColor.withOpacity(0.8),
                      AppColors.errorColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppBorderRadius.xl),
                    topRight: Radius.circular(AppBorderRadius.xl),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xác nhận xóa',
                            style: AppTextStyles.h5.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Hành động này không thể hoàn tác',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                        border: Border.all(
                          color: AppColors.errorColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Bạn có chắc muốn xóa phòng ban "${department.name}"?',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.errorColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  bottom: AppSpacing.xl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.textTertiary),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.large),
                          ),
                        ),
                        child: Text(
                          'Hủy',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.errorColor.withOpacity(0.8),
                              AppColors.errorColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppBorderRadius.large),
                          boxShadow: AppShadows.small,
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            ),
                          ),
                          child: Text(
                            'Xóa',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chức năng xóa sẽ được triển khai sau')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.gradientSoftTeal,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quản Lý Phòng Ban',
                  style: AppTextStyles.h5.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_departments.length} phòng ban',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.secondaryTealLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _loadDepartments,
              icon: Icon(
                Icons.refresh_rounded,
                color: AppColors.secondaryTeal,
              ),
              tooltip: 'Làm mới',
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.gradientSoftTeal,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryTeal.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showDepartmentDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(
            Icons.add_business_rounded,
            color: Colors.white,
            size: 22,
          ),
          label: Text(
            'Thêm Phòng Ban',
            style: AppTextStyles.buttonMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
                ),
              )
            : _error != null
                ? _buildErrorState()
                : _departments.isEmpty
                    ? _buildEmptyState()
                    : _buildDepartmentList(),
      ),
    );
  }

  Widget _buildDepartmentList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Header Stats Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.gradientSoftTeal,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryTeal.withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(AppBorderRadius.large),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.domain_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng Phòng Ban',
                            style: AppTextStyles.h4.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppBorderRadius.rounded),
                            ),
                            child: Text(
                              '${_departments.length} phòng ban đang hoạt động',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Departments Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _departments.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.lg,
              mainAxisSpacing: AppSpacing.lg,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final dept = _departments[index];
              return _buildDepartmentCard(dept);
            },
          ),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(Department department) {
    // Generate different gradient for each department based on ID
    final gradients = [
      AppColors.gradientSoftBlue,
      AppColors.gradientSoftTeal,
      AppColors.gradientSoftGreen,
      AppColors.gradientSoftOrange,
      AppColors.gradientSoftPurple,
      AppColors.gradientSoftPink,
    ];
    final gradient = gradients[department.id % gradients.length];
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDepartmentDialog(department: department),
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with Icon and Menu
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(AppBorderRadius.large),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _getDepartmentIcon(department.name),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppBorderRadius.small),
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showDepartmentDialog(department: department);
                              break;
                            case 'delete':
                              _deleteDepartment(department);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_rounded, 
                                  size: 18,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                const Text('Chỉnh sửa'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_forever_rounded,
                                  color: AppColors.errorColor,
                                  size: 18,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Xóa', 
                                  style: TextStyle(color: AppColors.errorColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Department Name
                Text(
                  department.name,
                  style: AppTextStyles.h5.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                
                // Description
                if (department.description?.isNotEmpty ?? false)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppBorderRadius.small),
                    ),
                    child: Text(
                      department.description!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.small),
                    ),
                    child: Text(
                      'Chưa có mô tả',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                
                const Spacer(),
                
                // Footer Info
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.badge_rounded,
                        size: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'ID: ${department.id}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _formatDate(department.createdAt),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method to get appropriate icon for department
  IconData _getDepartmentIcon(String departmentName) {
    final name = departmentName.toLowerCase();
    if (name.contains('it') || name.contains('công nghệ')) {
      return Icons.computer_rounded;
    } else if (name.contains('hr') || name.contains('nhân sự')) {
      return Icons.people_alt_rounded;
    } else if (name.contains('marketing') || name.contains('kinh doanh')) {
      return Icons.trending_up_rounded;
    } else if (name.contains('finance') || name.contains('tài chính')) {
      return Icons.account_balance_rounded;
    } else if (name.contains('operation') || name.contains('vận hành')) {
      return Icons.settings_rounded;
    } else {
      return Icons.apartment_rounded;
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.errorColor.withOpacity(0.1),
                    AppColors.errorColor.withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.errorColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.errorColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Có lỗi xảy ra',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.errorColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                border: Border.all(
                  color: AppColors.errorColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _error ?? 'Lỗi không xác định',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.errorColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.gradientSoftBlue,
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.large),
                boxShadow: AppShadows.medium,
              ),
              child: ElevatedButton.icon(
                onPressed: _loadDepartments,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: Text(
                  'Thử lại',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.large),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.gradientSoftTeal,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryTeal.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.domain_add_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Chưa có phòng ban nào',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondaryTealLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppBorderRadius.large),
              ),
              child: Text(
                'Hãy tạo phòng ban đầu tiên để bắt đầu tổ chức công ty',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Features Preview Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.gradientSoftBlue,
                      ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.large),
                      boxShadow: AppShadows.small,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.people_alt_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Quản lý\nnhân viên',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.gradientSoftGreen,
                      ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.large),
                      boxShadow: AppShadows.small,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.analytics_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Thống kê\nhoạt động',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // CTA Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.gradientSoftTeal,
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.large),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryTeal.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showDepartmentDialog(),
                icon: const Icon(
                  Icons.add_business_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  'Tạo Phòng Ban Đầu Tiên',
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.large),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
