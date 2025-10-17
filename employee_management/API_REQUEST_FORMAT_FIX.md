# API Request Format Fix - PascalCase for .NET

## 🔴 Vấn đề

**Lỗi 400 Bad Request:**
```json
{
  "errors": {
    "ImageBase64": ["The ImageBase64 field is required."]
  }
}
```

**Nguyên nhân**: 
- .NET API expect **PascalCase** keys (`ImageBase64`, `EmployeeId`, `FullName`)
- Flutter đang gửi **camelCase** keys (`imageBase64`, `employeeId`, `fullName`)

---

## ✅ Giải pháp - Sửa tất cả Request Models

### 1. VerifyFaceRequest

**❌ Before:**
```dart
class VerifyFaceRequest {
  final int employeeId;
  final String faceImageBase64;
  
  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'faceImageBase64': faceImageBase64,
    };
  }
}
```

**✅ After (theo API docs):**
```dart
class VerifyFaceRequest {
  final String imageBase64;  // Chỉ cần imageBase64, không cần employeeId!
  
  Map<String, dynamic> toJson() {
    return {
      'ImageBase64': imageBase64,  // PascalCase
    };
  }
}
```

**API endpoint:** `POST /api/Employee/verify-face`
```json
{
  "imageBase64": "iVBORw0KG..."
}
```

---

### 2. RegisterFaceRequest

**❌ Before:**
```dart
Map<String, dynamic> toJson() {
  return {
    'employeeId': employeeId,
    'faceImageBase64': faceImageBase64,
  };
}
```

**✅ After:**
```dart
Map<String, dynamic> toJson() {
  return {
    'EmployeeId': employeeId,              // PascalCase
    'FaceImageBase64': faceImageBase64,    // PascalCase
  };
}
```

---

### 3. CreateEmployeeRequest

**❌ Before:**
```dart
class CreateEmployeeRequest {
  final String employeeCode;  // ❌ API không accept field này!
  final String fullName;
  final String email;
  // ...
  
  Map<String, dynamic> toJson() {
    return {
      'employeeCode': employeeCode,
      'fullName': fullName,
      'email': email,
      // ... camelCase
    };
  }
}
```

**✅ After (theo API docs):**
```dart
class CreateEmployeeRequest {
  // ✅ Xóa employeeCode - Backend tự generate!
  final String fullName;
  final String email;
  final String? phoneNumber;
  final int departmentId;
  final String? position;
  final DateTime? dateOfBirth;
  final DateTime? joinDate;
  
  Map<String, dynamic> toJson() {
    return {
      'FullName': fullName,                      // PascalCase
      'Email': email,                            // PascalCase
      'PhoneNumber': phoneNumber,                // PascalCase
      'DepartmentId': departmentId,              // PascalCase
      'Position': position,                      // PascalCase
      'DateOfBirth': dateOfBirth?.toIso8601String(),
      'JoinDate': joinDate?.toIso8601String(),
    };
  }
}
```

---

### 4. CreatePayrollPeriodRequest

**✅ Fixed:**
```dart
Map<String, dynamic> toJson() {
  return {
    'PeriodName': periodName,                    // PascalCase
    'StartDate': startDate.toIso8601String(),    // PascalCase
    'EndDate': endDate.toIso8601String(),        // PascalCase
  };
}
```

---

### 5. CreatePayrollRuleRequest

**❌ Before (sai structure):**
```dart
class CreatePayrollRuleRequest {
  final int employeeId;
  final double baseSalary;
  final double overtimeRate;
  final double insuranceRate;
  final double taxRate;
  final DateTime effectiveFrom;
}
```

**✅ After (theo API docs):**
```dart
class CreatePayrollRuleRequest {
  final int employeeId;
  final double baseSalary;
  final int standardWorkingDays;
  final double socialInsuranceRate;
  final double healthInsuranceRate;
  final double unemploymentInsuranceRate;
  final double personalDeduction;
  final int numberOfDependents;
  final double dependentDeduction;
  
  CreatePayrollRuleRequest({
    required this.employeeId,
    required this.baseSalary,
    this.standardWorkingDays = 22,
    this.socialInsuranceRate = 8.0,
    this.healthInsuranceRate = 1.5,
    this.unemploymentInsuranceRate = 1.0,
    this.personalDeduction = 11000000,
    this.numberOfDependents = 0,
    this.dependentDeduction = 4400000,
  });

  Map<String, dynamic> toJson() {
    return {
      'EmployeeId': employeeId,
      'BaseSalary': baseSalary,
      'StandardWorkingDays': standardWorkingDays,
      'SocialInsuranceRate': socialInsuranceRate,
      'HealthInsuranceRate': healthInsuranceRate,
      'UnemploymentInsuranceRate': unemploymentInsuranceRate,
      'PersonalDeduction': personalDeduction,
      'NumberOfDependents': numberOfDependents,
      'DependentDeduction': dependentDeduction,
    };
  }
}
```

---

## 📋 UI Updates

### employee_list_page.dart

**Xóa field Employee Code** (backend tự generate):
```dart
// ❌ REMOVED
TextFormField(
  controller: _employeeCodeController,
  decoration: InputDecoration(labelText: 'Mã nhân viên *'),
),

// ✅ Chỉ giữ các field cần thiết
CreateEmployeeRequest(
  fullName: _fullNameController.text,
  email: _emailController.text,
  phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
  departmentId: _selectedDepartmentId!,
  position: _positionController.text.isNotEmpty ? _positionController.text : null,
  dateOfBirth: _dateOfBirth,
  joinDate: _joinDate ?? DateTime.now(),
)
```

---

### employee_detail_page.dart

**1. Verify Face - Xóa employeeId:**
```dart
// ❌ Before
final request = VerifyFaceRequest(
  employeeId: widget.employeeId!,
  faceImageBase64: base64Image,
);

// ✅ After
final request = VerifyFaceRequest(
  imageBase64: base64Image,
);
```

**2. Payroll Rule - Đơn giản hóa form:**
```dart
// ❌ REMOVED - Không cho phép user nhập các rates
TextFormField(controller: _overtimeRateController...),
TextFormField(controller: _insuranceRateController...),
TextFormField(controller: _taxRateController...),

// ✅ Chỉ nhập Base Salary - các rates dùng default
final request = CreatePayrollRuleRequest(
  employeeId: widget.employeeId,
  baseSalary: double.parse(_baseSalaryController.text),
  // Các fields khác dùng default values
);
```

---

## 🎯 Pattern - PascalCase cho .NET APIs

**Quy tắc:**
- ✅ Tất cả JSON keys gửi lên .NET API phải **PascalCase**
- ✅ Response từ .NET có thể **camelCase** hoặc **PascalCase** - handle flexible

**Template:**
```dart
class MyRequest {
  final String myField;
  final int anotherField;
  
  Map<String, dynamic> toJson() {
    return {
      'MyField': myField,          // ✅ PascalCase
      'AnotherField': anotherField, // ✅ PascalCase
    };
  }
}
```

---

## 🧪 Testing

**Test với log:**
```dart
final request = VerifyFaceRequest(imageBase64: base64Image);
print('Request JSON: ${json.encode(request.toJson())}');
// Output: {"ImageBase64":"iVBORw0KG..."}
```

**Expected API behavior:**
- ✅ 200 OK: Face verified successfully
- ✅ 400 Bad Request với error message chi tiết nếu sai format

---

## 📊 Summary

| Request Model | Changes | Reason |
|--------------|---------|--------|
| VerifyFaceRequest | Removed `employeeId`, changed key casing | API only needs `ImageBase64` |
| RegisterFaceRequest | Changed key casing to PascalCase | .NET API requirement |
| CreateEmployeeRequest | Removed `employeeCode`, PascalCase | Backend auto-generates code |
| CreatePayrollPeriodRequest | PascalCase keys | .NET API requirement |
| CreatePayrollRuleRequest | Complete restructure + PascalCase | Match API docs structure |

---

## ✅ Result

**Before:** ❌ 400 Bad Request - `{"errors": {"ImageBase64": ["field required"]}}`

**After:** ✅ Request gửi đúng format → API xử lý thành công!

---

## 🔍 Debug Tips

**Nếu vẫn lỗi 400:**
1. Check console log `ERROR DATA: {...}`
2. So sánh keys trong error với API docs
3. Verify PascalCase vs camelCase
4. Kiểm tra required fields có đủ không

**Test API trực tiếp:**
```bash
curl -X POST https://api.studyplannerapp.io.vn/api/Employee/verify-face \
  -H "Content-Type: application/json" \
  -d '{"ImageBase64":"..."}'
```
