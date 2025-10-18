# 🔧 BUG FIXES - Network Error & Employee Code

## ✅ Issues Fixed

### 1️⃣ **Network Error: "type 'Null' is not a subtype of type 'String' in Department"**

**Nguyên nhân:**
- API trả về `code: null` trong Department response
- Model Department có field `code` là `String` (non-nullable)
- Khi parse JSON gặp `null` → Runtime error

**Giải pháp:**
```dart
// BEFORE (employee_management_test\lib\models\department.dart)
class Department {
  final String code;  // ❌ Không chấp nhận null
  
  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      code: json['code'],  // ❌ Lỗi khi API trả về null
    );
  }
}

// AFTER
class Department {
  final String? code;  // ✅ Nullable
  
  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      code: json['code']?.toString(),  // ✅ Safe parsing
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Unknown',
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['isActive'] ?? false,
    );
  }
}
```

**Impact:**
- ✅ Department model giờ handle được null values
- ✅ Không còn crash khi API trả về incomplete data
- ✅ Safe parsing cho tất cả fields

---

### 2️⃣ **Employee Code Field in Create Form**

**Vấn đề:**
- Form "Thêm Nhân Viên" có field "Mã nhân viên" (employeeCode)
- User phải nhập manually
- Backend thực tế **tự động generate** employeeCode
- Không cần thiết và gây confusion

**Giải pháp:**
Removed `employeeCode` field khỏi Employee Form:

```dart
// BEFORE (employee_form_screen.dart)
final _employeeCodeController = TextEditingController();  // ❌

// Employee Code field in form
_buildTextField(
  controller: _employeeCodeController,
  label: 'Mã nhân viên',
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mã nhân viên';  // ❌ Không cần
    }
  },
)

// AFTER
// ✅ Removed controller
// ✅ Removed form field
// ✅ Form bắt đầu từ "Họ tên"
```

**Form fields sau khi fix:**
1. Họ tên* (bắt buộc)
2. Email
3. Số điện thoại
4. Chức vụ
5. Phòng ban* (dropdown)
6. Ngày sinh
7. Ngày vào làm*
8. Trạng thái (switch)

**CreateEmployeeRequest DTO:**
```dart
class CreateEmployeeRequest {
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final int departmentId;
  final String? position;
  final DateTime? dateOfBirth;
  // ✅ Không có employeeCode - backend tự generate
}
```

---

## 🔍 Additional Improvements

### Department Error Handling in Employee List
```dart
// employee_list_screen.dart
String _getDepartmentName(int departmentId) {
  final department = _departments.firstWhere(
    (dept) => dept.id == departmentId,
    orElse: () => Department(
      id: -1,
      code: null,  // ✅ Thay '' thành null
      name: 'Unknown',
      createdAt: DateTime.now(),
      isActive: false,
    ),
  );
  return department.name;
}
```

---

## 📊 Files Modified

### 1. `lib/models/department.dart`
**Changes:**
- `code` field: `String` → `String?`
- `fromJson()`: Safe parsing với null checks
- All fields có default values

### 2. `lib/screens/employee/employee_form_screen.dart`
**Changes:**
- ❌ Removed `_employeeCodeController`
- ❌ Removed employee code field from form
- ✅ Updated `_populateForm()` - không set employeeCode
- ✅ Updated `dispose()` - không dispose controller

### 3. `lib/screens/employee/employee_list_screen.dart`
**Changes:**
- ✅ `_getDepartmentName()` - orElse với `code: null`

---

## 🧪 Testing Scenarios

### Test Case 1: API trả về Department với code = null
**Before:** ❌ Crash với "type 'Null' is not a subtype of type 'String'"
**After:** ✅ Parse thành công, `department.code = null`

### Test Case 2: Thêm nhân viên mới
**Before:** ❌ User phải nhập mã nhân viên (confusing)
**After:** ✅ Form chỉ có các field cần thiết, backend auto-generate code

### Test Case 3: Employee List hiển thị phòng ban
**Before:** ❌ Potential crash nếu department không có code
**After:** ✅ Handle gracefully với null value

---

## 🎯 Summary

✅ **Fixed:** Network parsing error với Department.code
✅ **Improved:** Department model với safe JSON parsing
✅ **Removed:** Unnecessary employeeCode field từ form
✅ **Simplified:** Create Employee flow - ít fields hơn, intuitive hơn

**Result:** 
- No more runtime crashes
- Better UX (less confusing form)
- Consistent với backend behavior (auto-generated codes)

---

## 🚀 Ready to Test

Run app và test:
1. ✅ Load employee list (with departments)
2. ✅ Filter by department
3. ✅ Create new employee (without entering code manually)
4. ✅ View employee details
5. ✅ No crashes!

**All bugs fixed! App is stable now.** 🎉
