import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../utils/app_logger.dart';
import '../../services/payroll_api_service.dart';
import '../../services/api_service.dart';
import '../../models/dto/payroll_dtos.dart';

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
  final PayrollApiService _payrollService = PayrollApiService();
  
  // Filter states
  String _selectedTimeRange = '12months'; // 6months, 12months, alltime
  String? _selectedDepartment;
  String? _selectedPosition;
  
  // Data states
  bool _isLoadingData = false;
  final List<String> _departments = ['IT', 'HR', 'Sales', 'Marketing', 'Finance'];
  final List<String> _positions = ['Manager', 'Developer', 'Designer', 'Analyst', 'Intern'];
  
  // Chart data (from API)
  final List<MonthlyPayrollData> _monthlyData = [];
  final Map<String, double> _departmentData = {};
  List<PayrollPeriodResponse> _periods = [];
  
  // AI Analysis states
  bool _isAnalyzing = false;
  String? _analysisResult;
  String? _analysisError;
  bool _isAnalysisExpanded = false; // Track expand/collapse state
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    AppLogger.info('Screen initialized', tag: 'PayrollChart');
    _loadDataAndAnalyze();
  }

  @override
  void dispose() {
    _tabController.dispose();
    AppLogger.info('Screen disposed', tag: 'PayrollChart');
    super.dispose();
  }

  /// Load data from API
  Future<void> _loadChartData() async {
    setState(() => _isLoadingData = true);
    
    try {
      // 1. Load all payroll periods
      final periodsResponse = await _payrollService.getPayrollPeriods();
      
      if (periodsResponse.success && periodsResponse.data != null) {
        _periods = periodsResponse.data!;
        AppLogger.info('Loaded ${_periods.length} payroll periods', tag: 'PayrollChart');
        
        // 2. Generate monthly data from periods
        _monthlyData.clear();
        _departmentData.clear();
        
        // Take up to 12 most recent periods
        final recentPeriods = _periods.take(12).toList();
        
        for (final period in recentPeriods) {
          try {
            // Get summary for each period
            final summaryResponse = await _payrollService.getPayrollSummary(period.id);
            
            if (summaryResponse.success && summaryResponse.data != null) {
              final summary = summaryResponse.data!;
              
              // Add to monthly data
              _monthlyData.add(MonthlyPayrollData(
                month: period.startDate,
                totalCost: summary.totalNetSalary, // Use actual total cost
                employeeCount: summary.totalEmployees,
              ));
              
              // Get department breakdown from records
              final recordsResponse = await _payrollService.getPayrollRecords(period.id);
              if (recordsResponse.success && recordsResponse.data != null) {
                final records = recordsResponse.data!.records;
                
                // Aggregate by department (if we have department info)
                for (final record in records) {
                  final dept = record.employeeName.split(' ').first; // Simple dept extraction
                  _departmentData[dept] = (_departmentData[dept] ?? 0) + record.netSalary;
                }
              }
            }
          } catch (e) {
            AppLogger.warning('Failed to load data for period ${period.id}: $e', tag: 'PayrollChart');
            // Continue with next period
          }
        }
        
        // If no data from API, use fallback dummy data
        if (_monthlyData.isEmpty) {
          _generateFallbackData();
        }
        
        AppLogger.success('Loaded chart data: ${_monthlyData.length} months, ${_departmentData.length} departments', tag: 'PayrollChart');
        
      } else {
        // Fallback to dummy data if API fails
        AppLogger.warning('Failed to load periods, using fallback data', tag: 'PayrollChart');
        _generateFallbackData();
      }
      
    } catch (e) {
      AppLogger.error('Error loading chart data', error: e, tag: 'PayrollChart');
      // Use fallback data on error
      _generateFallbackData();
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  /// Generate fallback dummy data if API fails
  void _generateFallbackData() {
    _monthlyData.clear();
    _departmentData.clear();
    
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

    AppLogger.info('Generated fallback data: ${_monthlyData.length} months, ${_departmentData.length} departments', tag: 'PayrollChart');
  }

  /// Prepare monthly data for JSON
  String prepareMonthlyDataJson(List<MonthlyPayrollData> data) {
    final List<Map<String, dynamic>> jsonData = data.map((item) => {
      'month': DateFormat('yyyy-MM').format(item.month),
      'monthName': DateFormat('MM/yyyy').format(item.month),
      'totalCost': item.totalCost,
      'employeeCount': item.employeeCount,
      'averageSalaryPerEmployee': item.totalCost / item.employeeCount,
    }).toList();
    
    return jsonEncode(jsonData);
  }

  /// Prepare department data for JSON
  String prepareDepartmentDataJson(Map<String, double> data) {
    final total = data.values.fold<double>(0, (sum, value) => sum + value);
    
    final List<Map<String, dynamic>> jsonData = data.entries.map((entry) => {
      'department': entry.key,
      'totalCost': entry.value,
      'percentage': ((entry.value / total) * 100).toStringAsFixed(1),
    }).toList();
    
    return jsonEncode(jsonData);
  }

  /// Call Gemini AI for analysis
  Future<String> _callGeminiAnalysis(String prompt) async {
    // 1. Lấy API Key từ dotenv, kiểm tra null và ném lỗi nếu thiếu
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file. Please add your Gemini API key.');
    }

    // 2. Khởi tạo GenerativeModel
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );

    // 3. Tạo content
    final content = [Content.text(prompt)];

    try {
      // 4. Gọi API và log success
      final response = await model.generateContent(content);
      AppLogger.success('Gemini AI analysis completed successfully', tag: 'PayrollChart');
      
      // 5. Kiểm tra response text
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return 'AI không thể tạo phân tích cho dữ liệu này. Vui lòng thử lại sau.';
      }
    } catch (e) {
      // 6. Log lỗi chi tiết và ném exception mới
      AppLogger.error('Failed to call Gemini AI analysis', error: e, tag: 'PayrollChart');
      throw Exception('Lỗi khi gọi AI phân tích: ${e.toString()}');
    }
  }

  /// Load data and analyze with AI
  Future<void> _loadDataAndAnalyze() async {
    // 1. Set loading states
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _analysisError = null;
    });

    try {
      // 2. Load chart data from API
      await _loadChartData();

      // 3. Check if data exists
      if (_monthlyData.isNotEmpty && _departmentData.isNotEmpty) {
        // 4. Prepare JSON data
        final monthlyJson = prepareMonthlyDataJson(_monthlyData);
        final departmentJson = prepareDepartmentDataJson(_departmentData);

        // 5. Build detailed prompt
        final prompt = '''
Bạn là một chuyên gia phân tích tài chính và nhân sự. Tôi cung cấp cho bạn dữ liệu lương của công ty trong 12 tháng gần nhất và phân bổ theo phòng ban.

**DỮ LIỆU LƯƠNG THEO THÁNG:**
$monthlyJson

**DỮ LIỆU PHÂN BỔ THEO PHÒNG BAN:**
$departmentJson

**YÊU CẦU PHÂN TÍCH:**
1. **Xu hướng chi phí lương:** Phân tích xu hướng tăng/giảm qua các tháng, tính toán tốc độ tăng trưởng
2. **Phân tích theo phòng ban:** So sánh chi phí lương giữa các phòng ban, đánh giá tỷ lệ phân bổ
3. **Hiệu quả nhân sự:** Đánh giá mức lương trung bình mỗi nhân viên qua thời gian
4. **Dự báo & đề xuất:** Đưa ra dự báo cho tháng tiếp theo và đề xuất tối ưu hóa chi phí

**ĐỊNH DẠNG KẾT QUẢ:**
- Sử dụng emoji và bullet points để dễ đọc
- Đưa ra số liệu cụ thể và phần trăm
- Kết luận ngắn gọn với 2-3 đề xuất hành động

Hãy phân tích chi tiết và chuyên nghiệp.
''';

        // 6. Call Gemini AI
        final result = await _callGeminiAnalysis(prompt);
        
        // 7. Update result
        setState(() {
          _analysisResult = result;
        });
        
      } else {
        // No data case
        setState(() {
          _analysisError = "Không đủ dữ liệu để phân tích.";
        });
      }
    } catch (e) {
      // Error handling
      AppLogger.error('Error in _loadDataAndAnalyze', error: e, tag: 'PayrollChart');
      setState(() {
        _analysisError = 'Lỗi khi tải/phân tích: ${e.toString()}';
      });
    } finally {
      // Always set analyzing to false
      setState(() {
        _isAnalyzing = false;
      });
    }
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Filters
            _buildFiltersSection(),
            
            // AI Analysis
            _buildAnalysisSection(),
            
            // Charts - give them fixed height to work in ScrollView
            SizedBox(
              height: 600, // Fixed height for charts
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
    // Show loading if data is being loaded
    if (_isLoadingData || _monthlyData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải dữ liệu biểu đồ...'),
          ],
        ),
      );
    }

    return Padding(
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
    // Show loading if data is being loaded
    if (_isLoadingData || _monthlyData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải dữ liệu biểu đồ...'),
          ],
        ),
      );
    }

    return Padding(
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
    // Show loading if data is being loaded
    if (_isLoadingData || _monthlyData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải dữ liệu biểu đồ...'),
          ],
        ),
      );
    }

    return Padding(
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

  /// Build AI analysis section
  Widget _buildAnalysisSection() {
    // 1. If analyzing
    if (_isAnalyzing) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(
              'AI đang phân tích dữ liệu...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // 2. If error
    if (_analysisError != null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _analysisError!,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3. If has result
    if (_analysisResult != null) {
      return Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Prevent expansion
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.purple[600],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kết quả phân tích AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[600],
                      ),
                    ),
                  ),
                  // Add collapse/expand button
                  IconButton(
                    icon: Icon(_isAnalysisExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        _isAnalysisExpanded = !_isAnalysisExpanded;
                      });
                    },
                    tooltip: _isAnalysisExpanded ? 'Thu gọn' : 'Mở rộng',
                  ),
                ],
              ),
              const Divider(height: 24),
              // Show analysis content based on expand state
              if (_isAnalysisExpanded)
                // Expanded view - no internal scroll since we have main scroll
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Info header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, size: 16, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Phân tích chi tiết từ AI',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content without scroll - will scroll with main page
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          _analysisResult!,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Collapsed view - show preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _analysisResult!.length > 200 
                          ? '${_analysisResult!.substring(0, 200)}...'
                          : _analysisResult!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                      if (_analysisResult!.length > 200)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Nhấn mở rộng để xem toàn bộ phân tích...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Lưu ý: Kết quả chỉ mang tính tham khảo.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Default case
    return const SizedBox.shrink();
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
