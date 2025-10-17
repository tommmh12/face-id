import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/app_routes.dart';
import '../../../core/api_client.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../employee/data/employee_service.dart';
import '../../department/data/department_service.dart';
import '../../payroll/data/payroll_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiClient _apiClient = ApiClient();
  late final EmployeeService _employeeService;
  late final DepartmentService _departmentService;
  late final PayrollService _payrollService;

  bool _isLoading = true;
  String? _error;

  int _totalEmployees = 0;
  int _totalDepartments = 0;
  int _activePeriods = 0;
  bool _faceApiHealthy = false;
  bool _payrollApiHealthy = false;

  @override
  void initState() {
    super.initState();
    _employeeService = EmployeeService(_apiClient);
    _departmentService = DepartmentService(_apiClient);
    _payrollService = PayrollService(_apiClient);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Lấy thống kê song song
      final results = await Future.wait([
        _employeeService.getAllEmployees(),
        _departmentService.getAllDepartments(),
        _payrollService.getAllPeriods(),
        _checkFaceApiHealth(),
        _checkPayrollApiHealth(),
      ]);

      setState(() {
        _totalEmployees = (results[0] as List).length;
        _totalDepartments = (results[1] as List).length;
        _activePeriods = (results[2] as List)
            .where((p) => p.status == 'Active')
            .length;
        _faceApiHealthy = results[3] as bool;
        _payrollApiHealthy = results[4] as bool;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<bool> _checkFaceApiHealth() async {
    try {
      final response = await _apiClient.get('/api/Face/health');
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkPayrollApiHealth() async {
    try {
      final response = await _apiClient.get('/api/Payroll/health');
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Đang tải dữ liệu...');
    }

    if (_error != null) {
      return ErrorStateWidget(
        message: _error!,
        onRetry: _loadDashboardData,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(),
            const SizedBox(height: 24),

            // Statistics Cards
            const Text(
              'Tổng quan',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: 16),
            _buildStatisticsGrid(),
            const SizedBox(height: 24),

            // Health Status
            const Text(
              'Trạng thái hệ thống',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: 16),
            _buildHealthStatus(),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Truy cập nhanh',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: 16),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      color: AppTheme.primaryBlue,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chào mừng đến với',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hệ thống quản lý nhân viên',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cập nhật lúc ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        InfoCard(
          icon: Icons.people,
          title: 'Tổng nhân viên',
          value: _totalEmployees.toString(),
          iconColor: AppTheme.primaryBlue,
          onTap: () => Navigator.pushNamed(context, AppRoutes.employeeList),
        ),
        InfoCard(
          icon: Icons.business,
          title: 'Phòng ban',
          value: _totalDepartments.toString(),
          iconColor: AppTheme.successGreen,
          onTap: () => Navigator.pushNamed(context, AppRoutes.departments),
        ),
        InfoCard(
          icon: Icons.payment,
          title: 'Kỳ lương đang chạy',
          value: _activePeriods.toString(),
          iconColor: AppTheme.warningOrange,
          onTap: () => Navigator.pushNamed(context, AppRoutes.payroll),
        ),
        InfoCard(
          icon: Icons.calendar_today,
          title: 'Hôm nay',
          value: '${DateTime.now().day}/${DateTime.now().month}',
          iconColor: AppTheme.secondaryBlue,
        ),
      ],
    );
  }

  Widget _buildHealthStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHealthItem(
              'Face Recognition API',
              _faceApiHealthy,
            ),
            const Divider(),
            _buildHealthItem(
              'Payroll API',
              _payrollApiHealthy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthItem(String name, bool healthy) {
    return Row(
      children: [
        Icon(
          healthy ? Icons.check_circle : Icons.error,
          color: healthy ? AppTheme.successGreen : AppTheme.errorRed,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          healthy ? 'Hoạt động' : 'Lỗi',
          style: TextStyle(
            fontSize: 14,
            color: healthy ? AppTheme.successGreen : AppTheme.errorRed,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildQuickActionButton(
          icon: Icons.person_add,
          title: 'Thêm nhân viên',
          subtitle: 'Tạo hồ sơ nhân viên mới',
          color: AppTheme.primaryBlue,
          onTap: () => Navigator.pushNamed(context, AppRoutes.employeeList),
        ),
        const SizedBox(height: 12),
        _buildQuickActionButton(
          icon: Icons.payment,
          title: 'Quản lý lương',
          subtitle: 'Xem và tạo bảng lương',
          color: AppTheme.successGreen,
          onTap: () => Navigator.pushNamed(context, AppRoutes.payroll),
        ),
        const SizedBox(height: 12),
        _buildQuickActionButton(
          icon: Icons.face,
          title: 'Đăng ký khuôn mặt',
          subtitle: 'Thêm dữ liệu nhận diện',
          color: AppTheme.warningOrange,
          onTap: () => Navigator.pushNamed(context, AppRoutes.employeeList),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.business_center,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Employee Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Nhân viên'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.employeeList);
            },
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Phòng ban'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.departments);
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Bảng lương'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.payroll);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Cài đặt'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
    );
  }
}
