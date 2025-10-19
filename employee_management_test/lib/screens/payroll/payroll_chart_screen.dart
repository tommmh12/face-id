import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_logger.dart';

/// Màn hình phân tích và biểu đồ lương
/// 
/// Features:
/// - BarChart: Chi phí lương theo tháng (12 tháng gần nhất)
/// - LineChart: Xu hướng tăng/giảm lương theo thời gian
/// - PieChart: Phân bổ lương theo phòng ban
/// - Filter: Time range, department, position
/// - Summary statistics cards
/// - Export chart as image
/// - Material 3 design
class PayrollChartScreen extends StatefulWidget {
  const PayrollChartScreen({super.key});

  @override
  State<PayrollChartScreen> createState() => _PayrollChartScreenState();
}

class _PayrollChartScreenState extends State<PayrollChartScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Filter states
  String _selectedTimeRange = '12months'; // 6months, 12months, alltime
  String? _selectedDepartment;
  String? _selectedPosition;
  
  // Dummy data
  final List<String> _departments = ['IT', 'HR', 'Sales', 'Marketing', 'Finance'];
  final List<String> _positions = ['Manager', 'Developer', 'Designer', 'Analyst', 'Intern'];
  
  // Chart data (dummy)
  final List<MonthlyPayrollData> _monthlyData = [];
  final Map<String, double> _departmentData = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    AppLogger.info('Screen initialized', tag: 'PayrollChart');
    _generateDummyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    AppLogger.info('Screen disposed', tag: 'PayrollChart');
    super.dispose();
  }

  /// Generate dummy data for charts
  void _generateDummyData() {
    // Monthly data (12 months)
    final now = DateTime.now();
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      _monthlyData.add(MonthlyPayrollData(
        month: month,
        totalCost: 200000000 + (i * 5000000) + (i % 3 * 10000000),
        employeeCount: 45 + (i % 5),
      ));
    }

    // Department data
    _departmentData['IT'] = 80000000;
    _departmentData['HR'] = 40000000;
    _departmentData['Sales'] = 60000000;
    _departmentData['Marketing'] = 35000000;
    _departmentData['Finance'] = 50000000;

    AppLogger.info('Generated dummy data: ${_monthlyData.length} months, ${_departmentData.length} departments', tag: 'PayrollChart');
  }

  /// Apply filters
  void _applyFilters() {
    AppLogger.info('Applying filters: timeRange=$_selectedTimeRange, dept=$_selectedDepartment, pos=$_selectedPosition', tag: 'PayrollChart');
    setState(() {
      // TODO: Call API with filters and reload data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Phân tích lương'),
        actions: [
          // Export button
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              AppLogger.info('Export chart clicked', tag: 'PayrollChart');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔜 Tính năng xuất biểu đồ đang phát triển'),
                  backgroundColor: Color(0xFFFF9500),
                ),
              );
            },
            tooltip: 'Xuất biểu đồ',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Cột'),
            Tab(icon: Icon(Icons.show_chart), text: 'Đường'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Tròn'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filters
          _buildFiltersSection(),
          
          // Charts
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBarChartTab(),
                _buildLineChartTab(),
                _buildPieChartTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build filters section
  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔍 Bộ lọc',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Time range filter
              ChoiceChip(
                label: const Text('6 tháng'),
                selected: _selectedTimeRange == '6months',
                onSelected: (selected) {
                  setState(() => _selectedTimeRange = '6months');
                  _applyFilters();
                },
              ),
              ChoiceChip(
                label: const Text('12 tháng'),
                selected: _selectedTimeRange == '12months',
                onSelected: (selected) {
                  setState(() => _selectedTimeRange = '12months');
                  _applyFilters();
                },
              ),
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: _selectedTimeRange == 'alltime',
                onSelected: (selected) {
                  setState(() => _selectedTimeRange = 'alltime');
                  _applyFilters();
                },
              ),
              
              const SizedBox(width: 8),
              
              // Department filter
              FilterChip(
                label: Text(_selectedDepartment ?? 'Phòng ban'),
                selected: _selectedDepartment != null,
                onSelected: (selected) {
                  _showDepartmentFilter();
                },
                avatar: _selectedDepartment != null 
                  ? const Icon(Icons.business, size: 16)
                  : null,
              ),
              
              // Position filter
              FilterChip(
                label: Text(_selectedPosition ?? 'Chức vụ'),
                selected: _selectedPosition != null,
                onSelected: (selected) {
                  _showPositionFilter();
                },
                avatar: _selectedPosition != null 
                  ? const Icon(Icons.work, size: 16)
                  : null,
              ),
              
              // Clear filters
              if (_selectedDepartment != null || _selectedPosition != null)
                ActionChip(
                  label: const Text('Xóa bộ lọc'),
                  onPressed: () {
                    setState(() {
                      _selectedDepartment = null;
                      _selectedPosition = null;
                    });
                    _applyFilters();
                  },
                  avatar: const Icon(Icons.clear, size: 16),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show department filter dialog
  void _showDepartmentFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn phòng ban'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tất cả'),
              onTap: () {
                setState(() => _selectedDepartment = null);
                Navigator.pop(context);
                _applyFilters();
              },
            ),
            ..._departments.map((dept) => ListTile(
              title: Text(dept),
              onTap: () {
                setState(() => _selectedDepartment = dept);
                Navigator.pop(context);
                _applyFilters();
              },
            )),
          ],
        ),
      ),
    );
  }

  /// Show position filter dialog
  void _showPositionFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn chức vụ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tất cả'),
              onTap: () {
                setState(() => _selectedPosition = null);
                Navigator.pop(context);
                _applyFilters();
              },
            ),
            ..._positions.map((pos) => ListTile(
              title: Text(pos),
              onTap: () {
                setState(() => _selectedPosition = pos);
                Navigator.pop(context);
                _applyFilters();
              },
            )),
          ],
        ),
      ),
    );
  }

  /// Build Bar Chart tab
  Widget _buildBarChartTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Tổng chi phí',
                  NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(_monthlyData.fold<double>(0, (sum, item) => sum + item.totalCost)),
                  Icons.attach_money,
                  const Color(0xFF0A84FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Trung bình/tháng',
                  NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(_monthlyData.fold<double>(0, (sum, item) => sum + item.totalCost) / _monthlyData.length),
                  Icons.trending_up,
                  const Color(0xFF34C759),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Chart title
          const Text(
            '💰 Chi phí lương theo tháng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Hiển thị ${_monthlyData.length} tháng gần nhất',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          
          const SizedBox(height: 24),
          
          // Bar chart
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _monthlyData.map((e) => e.totalCost).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = _monthlyData[group.x.toInt()];
                      return BarTooltipItem(
                        '${DateFormat('MM/yyyy').format(data.month)}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(data.totalCost),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _monthlyData.length) {
                          final data = _monthlyData[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MM/yy').format(data.month),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000000).toStringAsFixed(0)}M',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50000000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_monthlyData.length, (index) {
                  final data = _monthlyData[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.totalCost,
                        color: const Color(0xFF0A84FF),
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Line Chart tab
  Widget _buildLineChartTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart title
          const Text(
            '📈 Xu hướng chi phí lương',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Theo dõi xu hướng tăng/giảm theo thời gian',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          
          const SizedBox(height: 24),
          
          // Line chart
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50000000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _monthlyData.length) {
                          final data = _monthlyData[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MM/yy').format(data.month),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000000).toStringAsFixed(0)}M',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_monthlyData.length - 1).toDouble(),
                minY: 0,
                maxY: _monthlyData.map((e) => e.totalCost).reduce((a, b) => a > b ? a : b) * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(_monthlyData.length, (index) {
                      return FlSpot(index.toDouble(), _monthlyData[index].totalCost);
                    }),
                    isCurved: true,
                    color: const Color(0xFF0A84FF),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF0A84FF),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF0A84FF).withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final data = _monthlyData[spot.x.toInt()];
                        return LineTooltipItem(
                          '${DateFormat('MM/yyyy').format(data.month)}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(data.totalCost),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Trend analysis
          _buildTrendAnalysis(),
        ],
      ),
    );
  }

  /// Build Pie Chart tab
  Widget _buildPieChartTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart title
          const Text(
            '🎯 Phân bổ lương theo phòng ban',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tỷ lệ chi phí lương cho từng phòng ban',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          
          const SizedBox(height: 24),
          
          // Pie chart
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(),
                centerSpaceRadius: 60,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Handle touch
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Legend
          _buildPieChartLegend(),
        ],
      ),
    );
  }

  /// Build pie chart sections
  List<PieChartSectionData> _buildPieChartSections() {
    final total = _departmentData.values.fold<double>(0, (sum, value) => sum + value);
    final colors = [
      const Color(0xFF0A84FF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFFF3B30),
      const Color(0xFF5856D6),
    ];
    
    int colorIndex = 0;
    return _departmentData.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  /// Build pie chart legend
  Widget _buildPieChartLegend() {
    final colors = [
      const Color(0xFF0A84FF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFFF3B30),
      const Color(0xFF5856D6),
    ];
    
    int colorIndex = 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _departmentData.entries.map((entry) {
            final color = colors[colorIndex % colors.length];
            colorIndex++;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(entry.value),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Build summary card
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Build trend analysis
  Widget _buildTrendAnalysis() {
    final firstMonth = _monthlyData.first.totalCost;
    final lastMonth = _monthlyData.last.totalCost;
    final growth = ((lastMonth - firstMonth) / firstMonth * 100);
    final isPositive = growth > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Phân tích xu hướng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                        ),
                      ),
                      Text(
                        'So với ${_selectedTimeRange == '6months' ? '6' : '12'} tháng trước',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isPositive
                ? 'Chi phí lương đang có xu hướng tăng. Cần xem xét các yếu tố như tuyển dụng mới, tăng lương, hoặc thưởng.'
                : 'Chi phí lương đang giảm. Có thể do giảm số lượng nhân viên hoặc các biện pháp tiết kiệm chi phí.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Monthly payroll data model
class MonthlyPayrollData {
  final DateTime month;
  final double totalCost;
  final int employeeCount;

  MonthlyPayrollData({
    required this.month,
    required this.totalCost,
    required this.employeeCount,
  });
}
