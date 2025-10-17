# Model Changes Summary - Fix Null Safety Issues

## 🔧 Vấn đề

Lỗi: `type 'Null' is not a subtype of type 'String' in type cast`

**Nguyên nhân**: API backend trả về nhiều field `null` nhưng Flutter models đang expect required `String` → Crash khi parse JSON.

---

## ✅ Giải pháp đã thực hiện

### 1. Employee Model (`employee_model.dart`)

**Thay đổi chính:**
- ✅ `email`: `String` → `String?` (nullable)
- ✅ `createdAt`: `required DateTime` → `DateTime?` (nullable)
- ✅ Thêm fields từ API docs:
  - `departmentCode: String?`
  - `isFaceRegistered: bool`
  - `faceRegisteredAt: DateTime?`

**Safe Parsing:**
```dart
factory Employee.fromJson(Map<String, dynamic> json) {
  return Employee(
    id: json['id'] as int? ?? 0,
    employeeCode: json['employeeCode'] as String? ?? '',
    fullName: json['fullName'] as String? ?? 'Unknown',
    email: json['email'] as String?,  // Nullable
    phoneNumber: json['phoneNumber'] as String?,
    departmentId: json['departmentId'] as int? ?? 0,
    departmentCode: json['departmentCode'] as String?,
    departmentName: json['departmentName'] as String?,
    position: json['position'] as String?,
    dateOfBirth: json['dateOfBirth'] != null 
        ? _parseDateTime(json['dateOfBirth'])
        : null,
    joinDate: json['joinDate'] != null
        ? _parseDateTime(json['joinDate'])
        : null,
    faceImageUrl: json['faceImageUrl'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    isFaceRegistered: json['isFaceRegistered'] as bool? ?? false,
    faceRegisteredAt: json['faceRegisteredAt'] != null
        ? _parseDateTime(json['faceRegisteredAt'])
        : null,
    createdAt: json['createdAt'] != null
        ? _parseDateTime(json['createdAt'])
        : null,
    updatedAt: json['updatedAt'] != null
        ? _parseDateTime(json['updatedAt'])
        : null,
  );
}

static DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  try {
    if (value is String) {
      return DateTime.parse(value);
    }
    return null;
  } catch (e) {
    print('Error parsing date: $value - $e');
    return null;
  }
}
```

**Key Changes:**
- ✅ Tất cả fields dùng `as Type?` thay vì `as Type`
- ✅ Fallback values với `?? defaultValue`
- ✅ Safe DateTime parsing với try-catch
- ✅ Print errors để debug

---

### 2. Department Model (`department_model.dart`)

**Khớp với API Docs:**
```json
{
  "id": 1,
  "code": "IT",
  "name": "Information Technology",
  "description": "IT Department",
  "employeeCount": 15
}
```

**Model mới:**
```dart
class Department {
  final int id;
  final String code;              // departmentCode → code
  final String name;              // departmentName → name
  final String? description;
  final int employeeCount;

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String?,
      employeeCount: json['employeeCount'] as int? ?? 0,
    );
  }
}
```

**Removed fields** (không có trong API response):
- ❌ `departmentCode` → `code`
- ❌ `departmentName` → `name`
- ❌ `managerId`
- ❌ `managerName`
- ❌ `isActive`
- ❌ `createdAt`
- ❌ `updatedAt`

---

### 3. UI Updates

#### employee_list_page.dart
```dart
// Search filter - handle nullable email
final matchesSearch = _searchQuery.isEmpty ||
    emp.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
    emp.employeeCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
    (emp.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

// Department dropdown
..._departments.map((dept) => DropdownMenuItem(
      value: dept.id,
      child: Text(dept.name),  // departmentName → name
    )),
```

#### employee_detail_page.dart
```dart
_buildInfoRow('Email', _employee!.email ?? 'N/A'),  // Handle nullable
```

#### department_page.dart
```dart
// Display department info
Text(department.name),       // departmentName → name
Text('Mã: ${department.code}'),  // departmentCode → code

// Removed manager section
// if (department.managerName != null) ... ❌ REMOVED
```

---

## 🎯 Pattern - Safe JSON Parsing

**Luôn sử dụng pattern này:**

```dart
factory Model.fromJson(Map<String, dynamic> json) {
  return Model(
    // Required int/String với fallback
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? 'Unknown',
    
    // Optional fields
    email: json['email'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    
    // Bool với default
    isActive: json['isActive'] as bool? ?? true,
    
    // DateTime với safe parsing
    createdAt: json['createdAt'] != null
        ? _parseDateTime(json['createdAt'])
        : null,
  );
}

static DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  try {
    if (value is String) {
      return DateTime.parse(value);
    }
    return null;
  } catch (e) {
    print('Error parsing date: $value - $e');
    return null;
  }
}
```

---

## 📊 Benefits

✅ **No more crashes** khi API trả về `null`
✅ **Graceful degradation** với fallback values
✅ **Debug-friendly** với error logging
✅ **Type-safe** với proper nullable types
✅ **API-aligned** models khớp với backend docs

---

## 🧪 Testing

Sau khi sửa, test các scenarios:

1. ✅ **Empty database** - App không crash, hiện empty state
2. ✅ **Partial data** - Fields `null` hiển thị "N/A"
3. ✅ **Full data** - Tất cả fields hiển thị đúng
4. ✅ **Search** - Tìm kiếm với nullable email
5. ✅ **Filter** - Lọc theo department

---

## 🔍 Debug Commands

**Xem response data:**
```dart
print('DEBUG: Response keys: ${response.keys}');
print('DEBUG: Response data type: ${response['data'].runtimeType}');
print('DEBUG: Raw JSON: ${json.encode(response)}');
```

**Test parsing:**
```dart
try {
  final employee = Employee.fromJson(json);
  print('✅ Parsed successfully: ${employee.fullName}');
} catch (e) {
  print('❌ Parse error: $e');
  print('JSON: ${json.encode(json)}');
}
```

---

## 📝 Next Steps

Nếu vẫn có lỗi:

1. **Kiểm tra console log** - Tìm "RESPONSE DATA:" hoặc "ERROR"
2. **Test API trực tiếp:**
   ```bash
   curl https://api.studyplannerapp.io.vn/api/Employee/departments
   curl https://api.studyplannerapp.io.vn/api/Employee
   ```
3. **So sánh response** với model fields
4. **Update model** nếu API response khác docs

---

## ✨ Result

**Before:** ❌ Crash with `type 'Null' is not a subtype of type 'String'`

**After:** ✅ App hoạt động mượt mà, handle null values gracefully!
