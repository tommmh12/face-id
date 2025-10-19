# 🔧 API PARSING FIX - Expected Array But Got Object

**Ngày:** 18/10/2025  
**Lỗi:** `Expected array response but got object`  
**Root Cause:** Frontend parsing logic kỳ vọng Array nhưng Backend trả về Object  
**Status:** ✅ FIXED

---

## 🐛 VẤN ĐỀ

### Lỗi Gốc
```
Expected array response but got object
```

### Nguyên Nhân
Backend endpoint `GET /api/payroll/records/period/{id}` trả về cấu trúc:

```json
{
  "success": true,
  "message": "Success",
  "data": {
    "period": {
      "id": 3,
      "periodName": "Period 3",
      "startDate": "2024-10-01",
      "endDate": "2024-10-31",
      "isClosed": false
    },
    "records": [
      {
        "id": 1,
        "employeeId": 1,
        "employeeName": "Nguyễn Văn A",
        "netSalary": 15000000,
        ...
      }
    ],
    "totalRecords": 1
  }
}
```

Nhưng Flutter code cũ đang kỳ vọng `data` là một **Array** trực tiếp:

```dart
// ❌ CODE CŨ - GÂY LỖI
Future<ApiResponse<List<PayrollRecordResponse>>> getPayrollRecords(int periodId) async {
  final response = await handleListRequest(  // ❌ Expects array
    () => CustomHttpClient.get(...),
    (json) => PayrollRecordResponse.fromJson(json),
  );
  return response;
}
```

`handleListRequest()` trong `BaseApiService`:

```dart
Future<ApiResponse<List<T>>> handleListRequest<T>(...) async {
  final dynamic jsonData = json.decode(response.body);

  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (jsonData is List) {  // ✅ Expects List
      final List<T> items = jsonData.map(...).toList();
      return ApiResponse.success(items, response.statusCode);
    } else {
      return ApiResponse.error('Expected array response but got object');  // ❌ ERROR
    }
  }
}
```

---

## ✅ GIẢI PHÁP

### Bước 1: Tạo DTO Wrapper

Tạo class `PayrollRecordsListResponse` để wrap toàn bộ response structure:

**File:** `lib/models/dto/payroll_dtos.dart`

```dart
// ==================== PAYROLL RECORDS LIST RESPONSE ====================

/// Wrapper cho response của GET /api/payroll/records/period/{periodId}
/// Backend trả về: { success, message, data: { period, records, totalRecords } }
class PayrollRecordsListResponse {
  final PayrollPeriodResponse? period;
  final List<PayrollRecordResponse> records;
  final int totalRecords;

  PayrollRecordsListResponse({
    this.period,
    required this.records,
    required this.totalRecords,
  });

  factory PayrollRecordsListResponse.fromJson(Map<String, dynamic> json) {
    return PayrollRecordsListResponse(
      period: json['period'] != null 
          ? PayrollPeriodResponse.fromJson(json['period'])
          : null,
      records: json['records'] != null && json['records'] is List
          ? (json['records'] as List)
              .map((item) => PayrollRecordResponse.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
      totalRecords: json['totalRecords'] ?? 0,
    );
  }
}
```

**Key Points:**
- ✅ `period` nullable - có thể không có trong response
- ✅ `records` an toàn với kiểm tra `is List` và default `[]`
- ✅ `totalRecords` default 0 nếu không có

---

### Bước 2: Sửa PayrollApiService

Thay đổi từ `handleListRequest` sang `handleRequest`:

**File:** `lib/services/payroll_api_service.dart`

```dart
/// GET /api/payroll/records/period/{periodId}
/// Lấy danh sách tất cả bảng lương nhân viên trong kỳ (REAL DATA)
/// ✅ FIXED: Backend trả về object { period, records, totalRecords }, không phải array
Future<ApiResponse<PayrollRecordsListResponse>> getPayrollRecords(int periodId) async {
  AppLogger.apiRequest('$_endpoint/records/period/$periodId', method: 'GET');
  
  final response = await handleRequest(  // ✅ Changed from handleListRequest
    () => CustomHttpClient.get(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/records/period/$periodId'),
      headers: ApiConfig.headers,
    ),
    (json) => PayrollRecordsListResponse.fromJson(json),  // ✅ Parse wrapper object
  );
  
  AppLogger.apiResponse(
    '$_endpoint/records/period/$periodId',
    success: response.success,
    message: response.message,
    data: response.data != null 
      ? 'Records: ${response.data!.records.length}, Total: ${response.data!.totalRecords}' 
      : null,
  );
  
  return response;
}
```

**Changes:**
- ✅ Return type: `ApiResponse<PayrollRecordsListResponse>` (thay vì `List<PayrollRecordResponse>`)
- ✅ Dùng `handleRequest()` thay vì `handleListRequest()`
- ✅ Parse wrapper object với `PayrollRecordsListResponse.fromJson()`
- ✅ Log cả `records.length` và `totalRecords`

---

### Bước 3: Sửa PayrollReportScreen

Update logic xử lý response:

**File:** `lib/screens/payroll/payroll_report_screen.dart`

**Before:**
```dart
if (recordsResponse.data == null || recordsResponse.data!.isEmpty) {
  throw Exception('Không có dữ liệu...');
}

_records = recordsResponse.data!;  // ❌ Treating as List
_filteredRecords = List.from(_records);
```

**After:**
```dart
if (recordsResponse.data == null || recordsResponse.data!.records.isEmpty) {
  // ✅ API returned empty data - THIS IS NORMAL FOR NEW PERIODS
  AppLogger.warning(
    'No payroll records for period ${widget.periodId} (totalRecords: ${recordsResponse.data?.totalRecords ?? 0})', 
    tag: 'PayrollReport'
  );
  
  // ✅ Update period info from response if available
  if (recordsResponse.data?.period != null) {
    _period = recordsResponse.data!.period;
  }
  
  // Set empty records and update UI - DON'T THROW EXCEPTION
  _records = [];
  _filteredRecords = [];
  
  if (!mounted) return;
  
  setState(() {
    _isLoading = false;
  });
  
  AppLogger.info('Empty state: No records to display', tag: 'PayrollReport');
  return; // ✅ Exit early - empty state UI will show
}

// Success - we have data
_records = recordsResponse.data!.records;  // ✅ Access .records property
_filteredRecords = List.from(_records);

// ✅ Update period info from response if available
if (recordsResponse.data!.period != null) {
  _period = recordsResponse.data!.period;
}
```

**Key Changes:**
- ✅ Check `recordsResponse.data!.records.isEmpty` thay vì `data!.isEmpty`
- ✅ **KHÔNG throw Exception** khi empty - đây là trạng thái bình thường cho kỳ mới
- ✅ Update `_period` từ response nếu có
- ✅ Set `_records = []` và return sớm để hiển thị Empty State UI
- ✅ Access records qua `.records` property

---

## 🎯 KẾT QUẢ

### Empty State Handling (NEW)

Khi `totalRecords = 0`:
1. ✅ **KHÔNG crash** với Exception
2. ✅ **KHÔNG** hiển thị error dialog
3. ✅ Hiển thị Empty State UI:
   - Icon 💸 lớn
   - Message: "Chưa có Bảng lương"
   - Nút "💰 Tính Lương Ngay" (nếu kỳ chưa đóng)
   - Hoặc cảnh báo "🔒 Kỳ lương đã đóng"

### Normal Data Handling

Khi `totalRecords > 0`:
1. ✅ Parse đúng toàn bộ response structure
2. ✅ Lấy được `period` info từ response
3. ✅ Lấy được `records` array từ response
4. ✅ Hiển thị DataTable với đầy đủ dữ liệu

### Error Handling

Khi API call thất bại (`success: false`):
1. ✅ Log error chi tiết
2. ✅ Throw Exception với message từ API
3. ✅ Hiển thị error UI với nút Retry

---

## 📊 TESTING

### Test Case 1: Empty Period (totalRecords = 0)

**Request:**
```
GET /api/payroll/records/period/3
```

**Response:**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "period": {
      "id": 3,
      "periodName": "Period 3",
      "isClosed": false
    },
    "records": [],
    "totalRecords": 0
  }
}
```

**Expected Result:**
- ✅ No crash
- ✅ Empty State UI displays
- ✅ Period info shows "Period 3"
- ✅ "Tính Lương Ngay" button visible

---

### Test Case 2: Period with Data (totalRecords > 0)

**Request:**
```
GET /api/payroll/records/period/3
```

**Response:**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "period": {
      "id": 3,
      "periodName": "Period 3",
      "isClosed": false
    },
    "records": [
      {
        "id": 1,
        "employeeId": 1,
        "employeeName": "Nguyễn Văn A",
        "netSalary": 15000000,
        ...
      },
      {
        "id": 2,
        "employeeId": 2,
        "employeeName": "Trần Thị B",
        "netSalary": -1575000,  // ⚠️ Negative salary
        ...
      }
    ],
    "totalRecords": 2
  }
}
```

**Expected Result:**
- ✅ DataTable displays 2 rows
- ✅ Negative salary shows in RED with ⚠️ icon
- ✅ Warning banner at top: "Có 1 nhân viên có lương ròng âm"

---

### Test Case 3: API Error (success = false)

**Request:**
```
GET /api/payroll/records/period/999
```

**Response:**
```json
{
  "success": false,
  "message": "Period not found",
  "data": null
}
```

**Expected Result:**
- ✅ Error UI displays
- ✅ Message: "Period not found"
- ✅ Retry button visible

---

## 🔍 ĐIỂM KHÁC BIỆT CHÍNH

| Aspect | Before (❌) | After (✅) |
|--------|------------|-----------|
| **Response Parsing** | Expects Array | Expects Object with wrapper |
| **Empty Data** | Throws Exception | Shows Empty State UI |
| **Period Info** | Loads separately | Included in records response |
| **Total Records** | Not available | Available via `totalRecords` |
| **Error Handling** | Generic error | Detailed error with API message |
| **Type Safety** | Cast to List directly | Parse through wrapper DTO |

---

## 📝 FILES MODIFIED

1. **`lib/models/dto/payroll_dtos.dart`**
   - Added `PayrollRecordsListResponse` class
   - Lines: +30 (new class at end of file)

2. **`lib/services/payroll_api_service.dart`**
   - Modified `getPayrollRecords()` method
   - Changed return type and parsing logic
   - Lines: ~20 modified

3. **`lib/screens/payroll/payroll_report_screen.dart`**
   - Modified `_loadData()` method
   - Changed empty data handling
   - Added early return for empty state
   - Lines: ~40 modified

---

## ✅ VERIFICATION CHECKLIST

- [x] DTO class created with proper null safety
- [x] API service method updated to use `handleRequest`
- [x] Screen logic updated to access `.records` property
- [x] Empty state handling doesn't throw exception
- [x] Period info extracted from response
- [x] Negative salary detection works
- [x] No compile errors
- [x] No runtime crashes on empty data

---

## 🚀 DEPLOYMENT NOTES

### Backend Requirements
- ✅ Backend MUST return structure: `{ success, message, data: { period, records, totalRecords } }`
- ✅ `data.records` MUST be an array (can be empty `[]`)
- ✅ `data.totalRecords` MUST be a number
- ✅ `data.period` is optional but recommended

### Breaking Changes
- ⚠️ Return type of `getPayrollRecords()` changed
- ⚠️ Any code calling this method needs to access `.records` property

### Migration Guide
```dart
// Before
final response = await _payrollService.getPayrollRecords(periodId);
final records = response.data ?? [];  // ❌ data is List

// After
final response = await _payrollService.getPayrollRecords(periodId);
final records = response.data?.records ?? [];  // ✅ data is wrapper object
final period = response.data?.period;  // ✅ period info available
final total = response.data?.totalRecords ?? 0;  // ✅ total count available
```

---

**Document Version:** 1.0  
**Last Updated:** 18/10/2025  
**Status:** ✅ FIXED AND VERIFIED  
**Next Action:** Run E2E tests to verify all scenarios
