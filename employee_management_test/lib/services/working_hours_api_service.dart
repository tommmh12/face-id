import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/secure_storage_service.dart';
import '../models/dto/working_hours_dtos.dart';

/// 🕐 Working Hours API Service
/// Handles all working hours and working days calculations
class WorkingHoursApiService {
  final String _baseUrl = ApiConfig.baseUrl;

  /// 🔐 Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorageService.readToken();
    print("🔐 [STORAGE] Token retrieved: ${token?.length ?? 0} chars, starts with: ${token?.substring(0, 20) ?? 'null'}...");
    
    if (token != null) {
      print("🔍 [SecureStorage] JWT Token retrieved from secure storage");
      print("🔍 [AUTH] Retrieved token from storage: ✅ Found");
      print("🔐 [AUTH] Token added to headers: Bearer ${token.substring(0, 20)}...");
    } else {
      print("❌ [AUTH] No token found in secure storage");
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 🔄 Handle HTTP requests with error handling
  Future<T> _handleRequest<T>(
    Future<http.Response> request,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await request;
      
      print("┌─────────────────────────────────────────────────────────────────────────────");
      print("│ ✅ API RESPONSE");
      print("├─────────────────────────────────────────────────────────────────────────────");
      print("│ Endpoint: Response");
      print("│ Status: ${response.statusCode}");
      print("│ Response Body:");
      print("│ ${response.body}");
      print("└─────────────────────────────────────────────────────────────────────────────");

      if (response.statusCode == 200) {
        print("✅ SUCCESS: [HTTP] Request thành công - Status 200");
        
        final Map<String, dynamic> json = jsonDecode(response.body);
        
        // Check if response has 'data' field (API wrapper)
        if (json.containsKey('data')) {
          print(">>> [handleRequest] Extracted data for fromJson: ${json['data']}");
          return fromJson(json['data'] as Map<String, dynamic>);
        } else {
          // Direct response
          return fromJson(json);
        }
      } else {
        print("❌ ERROR: [HTTP] Request failed - Status ${response.statusCode}");
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print("💥 [API] Exception occurred: $e");
      rethrow;
    }
  }

  /// 🕐 Tính toán giờ làm việc cho một ngày cụ thể
  Future<WorkingHoursResult> calculateDailyWorkingHours(int employeeId, DateTime date) async {
    final headers = await _getHeaders();
    final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    print("🚀 API Request: GET /payroll/working-hours/employee/$employeeId/date/$formattedDate");
    
    return await _handleRequest(
      http.get(
        Uri.parse('$_baseUrl/payroll/working-hours/employee/$employeeId/date/$formattedDate'),
        headers: headers,
      ),
      (json) => WorkingHoursResult.fromJson(json),
    );
  }

  /// 🕐 Tính toán giờ làm việc cho một khoảng thời gian  
  Future<List<WorkingHoursResult>> calculateWorkingHoursPeriod(
    int employeeId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    final headers = await _getHeaders();
    final formattedStartDate = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
    final formattedEndDate = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
    
    print("🚀 API Request: GET /payroll/working-hours/employee/$employeeId/period");
    print("   Start: $formattedStartDate, End: $formattedEndDate");
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payroll/working-hours/employee/$employeeId/period?startDate=$formattedStartDate&endDate=$formattedEndDate'),
        headers: headers,
      );

      print("📥 API Response: /payroll/working-hours/employee/$employeeId/period");
      print("   Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        
        // Extract dailyRecords from response
        final List<dynamic> dailyRecords = json['dailyRecords'] as List<dynamic>;
        
        return dailyRecords
            .map((record) => WorkingHoursResult.fromJson(record as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print("❌ Error calculating working hours period: $e");
      rethrow;
    }
  }

  /// 📊 Tính số ngày công cho nhân viên trong khoảng thời gian
  Future<WorkingDaysCalculationResult> calculateWorkingDays(
    int employeeId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    final headers = await _getHeaders();
    final formattedStartDate = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
    final formattedEndDate = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
    
    print("🚀 API Request: GET /payroll/working-days/employee/$employeeId/period");
    print("   Start: $formattedStartDate, End: $formattedEndDate");
    
    return await _handleRequest(
      http.get(
        Uri.parse('$_baseUrl/payroll/working-days/employee/$employeeId/period?startDate=$formattedStartDate&endDate=$formattedEndDate'),
        headers: headers,
      ),
      (json) => WorkingDaysCalculationResult.fromJson(json),
    );
  }

  /// 📊 Tính số ngày công theo tháng (Quick Monthly Summary)
  Future<WorkingDaysCalculationResult> calculateMonthlyWorkingDays(
    int employeeId, 
    int year, 
    int month
  ) async {
    final headers = await _getHeaders();
    
    print("🚀 API Request: GET /payroll/working-days/employee/$employeeId/month/$year/$month");
    
    return await _handleRequest(
      http.get(
        Uri.parse('$_baseUrl/payroll/working-days/employee/$employeeId/month/$year/$month'),
        headers: headers,
      ),
      (json) => WorkingDaysCalculationResult.fromJson(json),
    );
  }

  /// 📊 Lấy thống kê giờ làm việc từ tháng X đến hiện tại
  Future<WorkingHoursPeriodSummary> getWorkingHoursSummaryFromMonth(
    int employeeId,
    String employeeName,
    int fromYear,
    int fromMonth,
  ) async {
    try {
      final now = DateTime.now();
      final fromDate = DateTime(fromYear, fromMonth, 1);
      final toDate = DateTime(now.year, now.month, now.day); // Current date
      
      print("🔄 Calculating working hours summary for employee $employeeId");
      print("   From: $fromMonth/$fromYear to ${now.month}/${now.year}");
      
      final monthlySummaries = <MonthlyWorkingHoursSummary>[];
      var totalHours = 0.0;
      var totalWorkingDays = 0.0;
      var monthCount = 0;
      
      // Iterate through each month from fromDate to current month
      var currentDate = DateTime(fromYear, fromMonth, 1);
      
      while (currentDate.isBefore(DateTime(now.year, now.month + 1, 1))) {
        try {
          print("📊 Processing month: ${currentDate.month}/${currentDate.year}");
          
          final monthResult = await calculateMonthlyWorkingDays(
            employeeId, 
            currentDate.year, 
            currentDate.month
          );
          
          final monthlyHours = monthResult.totalStandardHours + monthResult.totalOvertimeHours;
          totalHours += monthlyHours;
          totalWorkingDays += monthResult.totalWorkingDays;
          monthCount++;
          
          final monthNames = [
            '', 'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
            'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
          ];
          
          final monthSummary = MonthlyWorkingHoursSummary(
            employeeId: employeeId,
            employeeName: employeeName,
            year: currentDate.year,
            month: currentDate.month,
            monthName: monthNames[currentDate.month],
            workingDaysResult: monthResult,
            calculatedAt: DateTime.now(),
          );
          
          monthlySummaries.add(monthSummary);
          
          print("✅ Month ${currentDate.month}/${currentDate.year}: ${monthlyHours.toStringAsFixed(1)}h, ${monthResult.totalWorkingDays.toStringAsFixed(1)} days");
          
        } catch (e) {
          print("⚠️ Error processing month ${currentDate.month}/${currentDate.year}: $e");
          // Continue with next month even if one fails
        }
        
        // Move to next month
        if (currentDate.month == 12) {
          currentDate = DateTime(currentDate.year + 1, 1, 1);
        } else {
          currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
        }
      }
      
      final averageHoursPerMonth = monthCount > 0 ? totalHours / monthCount : 0.0;
      final averageWorkingDaysPerMonth = monthCount > 0 ? totalWorkingDays / monthCount : 0.0;
      
      print("📊 Summary completed: ${totalHours.toStringAsFixed(1)}h total, ${totalWorkingDays.toStringAsFixed(1)} days total");
      
      return WorkingHoursPeriodSummary(
        employeeId: employeeId,
        employeeName: employeeName,
        fromDate: fromDate,
        toDate: toDate,
        monthlySummaries: monthlySummaries,
        totalHours: totalHours,
        totalWorkingDays: totalWorkingDays,
        averageHoursPerMonth: averageHoursPerMonth,
        averageWorkingDaysPerMonth: averageWorkingDaysPerMonth,
        calculatedAt: DateTime.now(),
      );
      
    } catch (e) {
      print("❌ Error getting working hours summary: $e");
      rethrow;
    }
  }

  /// 🕐 Xem thông tin cấu hình giờ hành chính
  Future<Map<String, dynamic>> getWorkingHoursConfiguration() async {
    final headers = await _getHeaders();
    
    print("🚀 API Request: GET /payroll/working-hours/configuration");
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payroll/working-hours/configuration'),
        headers: headers,
      );

      print("📥 API Response: /payroll/working-hours/configuration");
      print("   Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return json['configuration'] as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print("❌ Error getting working hours configuration: $e");
      rethrow;
    }
  }
}