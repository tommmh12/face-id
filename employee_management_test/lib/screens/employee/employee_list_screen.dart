import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../models/department.dart';
import '../../services/employee_api_service.dart';
import '../../config/app_theme.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final EmployeeApiService _employeeService = EmployeeApiService();
  List<Employee> _employees = [];
  List<Department> _departments = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load departments
      final departmentsResponse = await _employeeService.getDepartments();
      if (departmentsResponse.success && departmentsResponse.data != null) {
        _departments = departmentsResponse.data!;
      }

      // Load employees
      await _loadEmployees();
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải dữ liệu: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final response = _selectedDepartmentId != null
          ? await _employeeService.getEmployeesByDepartment(
              _selectedDepartmentId!,
            )
          : await _employeeService.getAllEmployees();

      if (response.success && response.data != null) {
        setState(() {
          _employees = response.data!;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Lỗi tải danh sách nhân viên';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối: ${e.toString()}';
      });
    }
  }

  String _getDepartmentName(int departmentId) {
    final department = _departments.firstWhere(
      (dept) => dept.id == departmentId,
      orElse: () => Department(
        id: -1,
        code: null,
        name: 'Unknown',
        createdAt: DateTime.now(),
        isActive: false,
      ),
    );
    return department.name;
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
                  colors: AppColors.gradientSoftBlue,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.people_alt_rounded,
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
                  'Danh Sách Nhân Viên',
                  style: AppTextStyles.h5.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_employees.length} nhân viên',
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
              color: AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _loadData,
              icon: Icon(
                Icons.refresh_rounded,
                color: AppColors.primaryBlue,
              ),
              tooltip: 'Làm mới',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            margin: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppBorderRadius.large),
                    boxShadow: AppShadows.small,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, 
                           color: AppColors.textTertiary, size: 22),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm nhân viên...',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                          ),
                          onChanged: (value) {
                            // TODO: Implement search functionality
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.gradientSoftBlue,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Department Filter
                if (_departments.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, 
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppBorderRadius.large),
                      boxShadow: AppShadows.small,
                    ),
                    child: DropdownButtonFormField<int?>(
                      value: _selectedDepartmentId,
                      decoration: InputDecoration(
                        labelText: 'Lọc theo phòng ban',
                        labelStyle: AppTextStyles.label,
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.filter_list_rounded, 
                          size: 20,
                          color: AppColors.primaryBlue,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Tất cả phòng ban'),
                        ),
                        ..._departments.map(
                          (dept) => DropdownMenuItem<int?>(
                            value: dept.id,
                            child: Text(dept.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartmentId = value;
                        });
                        _loadEmployees();
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : _employees.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.gradientSoftBlue,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.medium,
                          ),
                          child: const Icon(
                            Icons.people_outline_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Chưa có nhân viên nào',
                          style: AppTextStyles.h5.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Hãy thêm nhân viên đầu tiên',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.gradientSoftGreen,
                            ),
                            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                            boxShadow: AppShadows.small,
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/employee/create')
                                  .then((_) => _loadData());
                            },
                            icon: const Icon(Icons.person_add_rounded),
                            label: const Text('Thêm nhân viên'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.md,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 
                      AppSpacing.sm, 
                      AppSpacing.lg, 
                      120,
                    ),
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      final employee = _employees[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppBorderRadius.large),
                          boxShadow: AppShadows.small,
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/employee/detail',
                                arguments: {'employeeId': employee.id},
                              ).then((_) => _loadData());
                            },
                            borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Row(
                                children: [
                                  // Enhanced Avatar with gradient and status
                                  Stack(
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          gradient: employee.isFaceRegistered
                                              ? LinearGradient(
                                                  colors: AppColors.gradientSoftGreen,
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : LinearGradient(
                                                  colors: [
                                                    AppColors.textTertiary.withOpacity(0.3),
                                                    AppColors.textTertiary.withOpacity(0.5),
                                                  ],
                                                ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: employee.isFaceRegistered
                                                  ? AppColors.successColor.withOpacity(0.3)
                                                  : Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          employee.isFaceRegistered
                                              ? Icons.face_retouching_natural_rounded
                                              : Icons.person_outline_rounded,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      // Active Status Badge
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: employee.isActive
                                                ? AppColors.successColor
                                                : AppColors.errorColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                            boxShadow: AppShadows.small,
                                          ),
                                          child: Icon(
                                            employee.isActive
                                                ? Icons.check_rounded
                                                : Icons.close_rounded,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: AppSpacing.lg),
                                  // Enhanced Info Section
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Name with better typography
                                        Text(
                                          employee.fullName,
                                          style: AppTextStyles.h6.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        // Employee Code & Department Row
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.sm,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: AppColors.gradientSoftBlue,
                                                ),
                                                borderRadius: BorderRadius.circular(
                                                  AppBorderRadius.xs,
                                                ),
                                              ),
                                              child: Text(
                                                employee.employeeCode,
                                                style: AppTextStyles.caption.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            Flexible(
                                              child: Text(
                                                _getDepartmentName(employee.departmentId),
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (employee.position != null) ...[
                                          const SizedBox(height: AppSpacing.xs),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryLighter,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Icon(
                                                  Icons.work_outline_rounded,
                                                  size: 12,
                                                  color: AppColors.primaryBlue,
                                                ),
                                              ),
                                              const SizedBox(width: AppSpacing.xs),
                                              Flexible(
                                                child: Text(
                                                  employee.position!,
                                                  style: AppTextStyles.caption.copyWith(
                                                    color: AppColors.textTertiary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Enhanced Action Buttons
                                  Column(
                                    children: [
                                      if (!employee.isFaceRegistered)
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: AppColors.gradientSoftOrange,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppBorderRadius.small,
                                            ),
                                            boxShadow: AppShadows.small,
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/face/register',
                                                  arguments: employee,
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(
                                                AppBorderRadius.small,
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(AppSpacing.sm),
                                                child: Icon(
                                                  Icons.face_retouching_natural_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Container(
                                        padding: const EdgeInsets.all(AppSpacing.xs),
                                        decoration: BoxDecoration(
                                          color: AppColors.borderLight,
                                          borderRadius: BorderRadius.circular(
                                            AppBorderRadius.small,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.gradientSoftGreen,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.successColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/employee/create').then((_) {
              _loadData();
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 22,
          ),
          label: Text(
            'Thêm Nhân Viên',
            style: AppTextStyles.buttonMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
