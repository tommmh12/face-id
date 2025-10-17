# API Response Format Reference

## ⚠️ QUAN TRỌNG: Backend .NET Response Format

Backend .NET API **KHÔNG ĐỒNG NHẤT** response format giữa các endpoint:

---

## 1. GET Endpoints (Trả về dữ liệu trực tiếp)

### ✅ Array Endpoints
Các endpoint GET danh sách trả về **array trực tiếp**, KHÔNG có wrapper:

```json
// GET /api/Employee/departments
[
  {
    "id": 1,
    "code": "IT",
    "name": "Information Technology",
    "description": "IT Department",
    "employeeCount": 15
  }
]

// GET /api/Employee
[{...}, {...}]

// GET /api/Payroll/periods
[{...}, {...}]

// GET /api/Payroll/rules
[{...}, {...}]

// GET /api/Payroll/allowances/employee/{id}
[{...}, {...}]
```

### ✅ Object Endpoints
Các endpoint GET single item trả về **object trực tiếp**:

```json
// GET /api/Employee/{id}
{
  "id": 1,
  "employeeCode": "IT-2025-0001",
  "fullName": "John Doe",
  ...
}

// GET /api/Payroll/rules/employee/{employeeId}
{
  "id": 1,
  "employeeId": 1,
  "baseSalary": 20000000,
  ...
}

// GET /api/Payroll/records/period/{periodId}/employee/{employeeId}
{
  "id": 1,
  "employeeId": 1,
  "netSalary": 17709545.46,
  ...
}
```

### ✅ Complex Object Endpoints
Một số endpoint trả về object có nested structure:

```json
// GET /api/Payroll/summary/{periodId}
{
  "periodId": 1,
  "periodName": "January 2025",
  "totalEmployees": 25,
  "totalNetSalary": 442738635.50,
  "records": [
    {...},
    {...}
  ]
}
```

---

## 2. POST Endpoints (Có wrapper `success`)

POST endpoints trả về format có wrapper:

```json
// POST /api/Employee
{
  "success": true,
  "message": "Employee created successfully",
  "employeeId": 1,
  "employeeCode": "IT-2025-0001"
}

// POST /api/Employee/register-face
{
  "success": true,
  "message": "Face registered successfully",
  "employee": {
    "id": 1,
    "employeeCode": "IT-2025-0001",
    ...
  }
}

// POST /api/Employee/verify-face
{
  "success": true,
  "status": "matched",
  "message": "Face verified successfully",
  "confidence": 98.5,
  "matchedEmployee": {
    "employeeId": 1,
    ...
  }
}

// POST /api/Payroll/generate/{periodId}
{
  "success": true,
  "message": "Payroll generated successfully for 25 employees",
  "totalEmployees": 25,
  "successCount": 25,
  "failureCount": 0,
  "errors": [],
  "records": [...]
}
```

---

## 3. Flutter ApiClient Handling

Trong `lib/core/api_client.dart`, method `_handleResponse()` đã wrap array thành object:

```dart
Map<String, dynamic> _handleResponse(Response response) {
  _logger.d('Response type: ${response.data.runtimeType}');
  
  if (response.data is Map<String, dynamic>) {
    return response.data as Map<String, dynamic>;
  }
  
  // Nếu API trả về array trực tiếp, wrap nó vào object
  if (response.data is List) {
    return {
      'success': true,
      'data': response.data,
    };
  }
  
  return {'data': response.data};
}
```

**Kết quả**: 
- GET array → Wrap thành `{success: true, data: [...]}`
- GET object → Wrap thành `{data: {...}}`
- POST → Giữ nguyên format từ backend

---

## 4. Service Layer Handling

### Department Service
```dart
Future<List<Department>> getAllDepartments() async {
  final response = await _apiClient.get('/api/Employee/departments');
  
  // Response đã được wrap thành {success: true, data: [...]}
  if (response.containsKey('data') && response['data'] != null) {
    final data = response['data'];
    if (data is List) {
      return data.map((json) => Department.fromJson(json)).toList();
    }
  }
  return [];
}
```

### Employee Service
```dart
// GET List
Future<List<Employee>> getAllEmployees() async {
  final response = await _apiClient.get('/api/Employee');
  if (response.containsKey('data') && response['data'] is List) {
    return (response['data'] as List)
        .map((json) => Employee.fromJson(json))
        .toList();
  }
  return [];
}

// GET Single
Future<Employee> getEmployeeById(int id) async {
  final response = await _apiClient.get('/api/Employee/$id');
  
  // Có thể wrapped hoặc trực tiếp
  if (response.containsKey('data') && response['data'] is Map) {
    return Employee.fromJson(response['data']);
  }
  return Employee.fromJson(response);
}
```

### Payroll Service
```dart
// GET Summary (có nested structure)
Future<List<PayrollRecord>> getPayrollSummary(int periodId) async {
  final response = await _apiClient.get('/api/Payroll/summary/$periodId');
  
  // Kiểm tra key 'records' trực tiếp
  if (response.containsKey('records') && response['records'] is List) {
    return (response['records'] as List)
        .map((json) => PayrollRecord.fromJson(json))
        .toList();
  }
  
  // Hoặc wrapped trong {data: {records: [...]}}
  if (response.containsKey('data') && response['data'] is Map) {
    final dataMap = response['data'] as Map<String, dynamic>;
    if (dataMap.containsKey('records') && dataMap['records'] is List) {
      return (dataMap['records'] as List)
          .map((json) => PayrollRecord.fromJson(json))
          .toList();
    }
  }
  
  return [];
}
```

---

## 5. Error Responses

### 404 Not Found
```json
{
  "message": "Employee not found"
}
```

### 400 Bad Request (có errors array)
```json
{
  "success": false,
  "message": "Error description",
  "errors": ["Detailed error 1", "Detailed error 2"]
}
```

---

## 6. Health Check Endpoints

```json
// GET /api/Face/health
{
  "status": "healthy",
  "timestamp": "2025-01-17T12:00:00Z"
}

// GET /api/Payroll/health
{
  "status": "healthy",
  "service": "Payroll Service",
  "timestamp": "2025-01-17T12:00:00Z",
  "features": [...]
}
```

---

## 📋 Summary

| Endpoint Type | Backend Response | ApiClient Wraps To | Service Handles |
|--------------|------------------|-------------------|-----------------|
| GET Array | `[...]` | `{success: true, data: [...]}` | `response['data']` |
| GET Object | `{...}` | `{data: {...}}` | `response['data']` or `response` |
| GET Complex | `{records: [...]}` | `{data: {records: [...]}}` | `response['records']` or `response['data']['records']` |
| POST Success | `{success: true, ...}` | `{success: true, ...}` | `response['success']` |
| POST Error | `{success: false, ...}` | `{success: false, ...}` | Check `response['success']` |

---

## ✅ Best Practice

**LUÔN kiểm tra cả 2 cases trong service:**

```dart
Future<T> getData() async {
  final response = await _apiClient.get('/api/...');
  
  // Case 1: Wrapped trong {data: ...}
  if (response.containsKey('data') && response['data'] != null) {
    return parseData(response['data']);
  }
  
  // Case 2: Response trực tiếp
  return parseData(response);
}
```

**Debug bằng print:**
```dart
print('DEBUG: Response keys: ${response.keys}');
print('DEBUG: Response data type: ${response['data'].runtimeType}');
```

---

## 🔧 Testing

**Hot reload để xem log:**
1. Nhấn `r` trong terminal Flutter
2. Mở trang Department/Employee
3. Xem console log:
   - `RESPONSE DATA: [...]` → Array trực tiếp
   - `Response type: List` → Đã wrap thành `{data: [...]}`

**Test với curl:**
```bash
curl https://api.studyplannerapp.io.vn/api/Employee/departments
curl https://api.studyplannerapp.io.vn/api/Employee/1
```
