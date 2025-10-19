# ✅ E2E TESTING CHECKLIST

**Ngày thực hiện:** ___________  
**Người thực hiện:** ___________  
**Môi trường:** Flutter 3.9.2 + .NET Core 8.0

---

## 📋 KIỂM THỬ PHẦN 1: LOGIC TÍNH LƯƠNG CỐT LÕI

### Test Case 1.1: Tạo Kỳ Lương Mới
- [ ] **Endpoint:** `POST /api/payroll/periods`
- [ ] **Input:**
  ```json
  {
    "periodName": "Period 4 - Tháng 3/2025",
    "startDate": "2025-03-01T00:00:00Z",
    "endDate": "2025-03-31T23:59:59Z"
  }
  ```
- [ ] **Expected Result:**
  - Response status: 200 OK
  - Response body chứa `id`, `periodName`, `isClosed: false`
- [ ] **Frontend Verification:**
  - Kỳ lương mới hiển thị trong dropdown
  - Có thể chọn kỳ lương mới

**Kết quả:** ⬜ PASS | ⬜ FAIL  
**Ghi chú:** ___________________________________________

---

### Test Case 1.2: Kiểm Tra Empty State
- [ ] **Endpoint:** `GET /api/payroll/records/period/{periodId}`
- [ ] **Input:** `periodId = 4` (kỳ lương vừa tạo)
- [ ] **Expected Result - Backend:**
  ```json
  {
    "success": true,
    "message": "Success",
    "data": {
      "period": {...},
      "records": [],
      "totalRecords": 0
    }
  }
  ```
- [ ] **Expected Result - Frontend:**
  - Hiển thị icon 💸 lớn (không phải error message)
  - Tiêu đề: "Chưa có Bảng lương"
  - Message: 'Kỳ lương "Period 4 - Tháng 3/2025" chưa có dữ liệu tính lương.'
  - Nút "💰 Tính Lương Ngay" hiển thị (vì chưa đóng kỳ)
  - **KHÔNG** hiển thị cảnh báo "🔒 Kỳ lương đã đóng"

**Kết quả:** ⬜ PASS | ⬜ FAIL  
**Ghi chú:** ___________________________________________

---

### Test Case 1.3: Tính Lương Lần Đầu
- [ ] **Endpoint:** `POST /api/payroll/generate/{periodId}`
- [ ] **Input:** `periodId = 4`
- [ ] **Action:** Click nút "💰 Tính Lương Ngay" trên frontend
- [ ] **Expected Confirmation Dialog:**
  - Title: "Xác nhận Tính lương"
  - Content: Tên kỳ lương + ngày
  - Cảnh báo: "⚠️ Hệ thống sẽ tính lương..."
  - Buttons: "Hủy", "Xác nhận"
- [ ] **After Confirmation:**
  - Loading dialog: "Đang tính lương..."
  - API response status: 200 OK
- [ ] **Expected Result - Backend:**
  ```json
  {
    "success": true,
    "message": "Payroll generated successfully",
    "data": {
      "success": true,
      "message": "Tính lương thành công",
      "totalEmployees": 5,
      "successCount": 5,
      "failedCount": 0,
      "errors": []
    }
  }
  ```
- [ ] **Expected Result - Frontend:**
  - SnackBar xanh: "✅ Tính lương thành công cho 5 nhân viên"
  - DataTable hiển thị 5 bản ghi
  - **TẤT CẢ** `netSalary` phải **DƯƠNG** (màu xanh #34C759)
  - **KHÔNG** hiển thị banner cảnh báo lương âm
  - **KHÔNG** có icon ⚠️ trong cột "Lương thực nhận"

**Kết quả:** ⬜ PASS | ⬜ FAIL  
**Ghi chú:** ___________________________________________

---

## 📋 KIỂM THỬ PHẦN 2: TÍCH HỢP THƯỞNG/PHẠT

### Chuẩn bị
- [ ] Chọn 1 nhân viên từ danh sách (ghi lại: `employeeId = _____`, `employeeName = _____`)
- [ ] Ghi lại lương ròng ban đầu: `initialNetSalary = _____`

---

### Test Case 2.1: Thêm Thưởng (BONUS)
- [ ] **Endpoint:** `POST /api/payroll/adjustments`
- [ ] **Input:**
  ```json
  {
    "employeeId": _____, 
    "periodId": 4,
    "adjustmentType": "Bonus",
    "reason": "Test BONUS +2M",
    "amount": 2000000,
    "adjustmentDate": "2025-03-15T00:00:00Z"
  }
  ```
- [ ] **Expected Result - Backend:**
  - Response status: 200 OK
  - Response body chứa `id`, `adjustmentType: "Bonus"`, `amount: 2000000`
- [ ] **Action:** `POST /api/payroll/recalculate/{periodId}`
- [ ] **Expected Result - Frontend:**
  - Reload dữ liệu thành công
  - `newNetSalary` = `initialNetSalary` + 2,000,000
  - Màu sắc vẫn là xanh (nếu vẫn dương)
- [ ] **Detail Screen Verification:**
  - Section "💰 TỔNG THU NHẬP (A)":
    * Dòng "🎁 THƯỞNG": Hiển thị "2,000,000 ₫" màu xanh, bold
  - Section "💵 LƯƠNG THỰC NHẬN": Số tiền tăng thêm 2M

**Kết quả:** ⬜ PASS | ⬜ FAIL  
**Ghi chú:** ___________________________________________

---

### Test Case 2.2: Thêm Phạt (PENALTY)
- [ ] **Endpoint:** `POST /api/payroll/adjustments`
- [ ] **Input:**
  ```json
  {
    "employeeId": _____,
    "periodId": 4,
    "adjustmentType": "Penalty",
    "reason": "Test PENALTY -5M",
    "amount": 5000000,
    "adjustmentDate": "2025-03-20T00:00:00Z"
  }
  ```
- [ ] **Expected Result - Backend:**
  - Response status: 200 OK
  - Response body chứa `adjustmentType: "Penalty"`, `amount: 5000000`
- [ ] **Action:** `POST /api/payroll/recalculate/{periodId}`
- [ ] **Expected Result - Frontend:**
  - `newNetSalary` = (initialNetSalary + 2M) - 5M
  - Nếu `newNetSalary < 0`: Màu đỏ (#FF3B30) + icon ⚠️
  - Nếu `newNetSalary >= 0`: Màu xanh
- [ ] **Detail Screen Verification:**
  - Section "📉 TỔNG KHẤU TRỪ (B)":
    * Dòng "⚠️ Khấu trừ khác": Hiển thị "5,000,000 ₫" màu đỏ, bold
    * Chú thích: "* Bao gồm cả tiền phạt (Penalty)" hiển thị dưới
  - Section "💵 LƯƠNG THỰC NHẬN": Số tiền giảm 5M

**Kết quả:** ⬜ PASS | ⬜ FAIL  
**Ghi chú:** ___________________________________________

---

### Test Case 2.3: Kịch Bản Lương Âm
- [ ] **Mục tiêu:** Tạo PENALTY có giá trị **lớn hơn** `AdjustedGrossIncome`
- [ ] **Cách thực hiện:**
  1. Xem `AdjustedGrossIncome` của nhân viên (e.g., 10,000,000 ₫)
  2. Tạo PENALTY với `amount` = 15,000,000 (lớn hơn Gross)
- [ ] **Input:**
  ```json
  {
    "employeeId": _____,
    "periodId": 4,
    "adjustmentType": "Penalty",
    "reason": "Test Negative Salary",
    "amount": 15000000,
    "adjustmentDate": "2025-03-25T00:00:00Z"
  }
  ```
- [ ] **After Recalculate:**
  - `netSalary` < 0 (e.g., -5,000,000 ₫)
- [ ] **Expected Result - PayrollReportScreen:**
  - **Banner Cảnh Báo** hiển thị ở đầu trang:
    * Background: Gradient đỏ/cam
    * Icon: ⚠️ lớn (size 32)
    * Text: "⚠️ CẢNH BÁO LƯƠNG ÂM"
    * Message: "Có 1 nhân viên có lương ròng âm. Vui lòng kiểm tra lại các Điều chỉnh (Phạt, Khấu trừ)."
  - **DataTable:**
    * Cột "Lương thực nhận": Hiển thị "-5,000,000 ₫" màu **đỏ** (#FF3B30), bold
    * Icon ⚠️ màu đỏ hiển thị trước số tiền
- [ ] **Expected Result - EmployeeSalaryDetailScreenV2:**
  - **Net Salary Card:**
    * Background: Gradient đỏ (red.shade700 → red.shade900)
    * BoxShadow: Màu đỏ
    * Icon: ⚠️ hiển thị bên trái title
    * Title: "💵 LƯƠNG THỰC NHẬN (A - B)"
    * Value: "-5,000,000 ₫" font 36pt, bold, trắng
    * Badge: "⚠️ LƯƠNG ÂM - Vui lòng kiểm tra lại" (background trắng mờ)
  - **Sections THU NHẬP và KHẤU TRỪ:**
    * Hiển thị đúng breakdown
    * KHẤU TRỪ > THU NHẬP

**Kết quả:** ⬜ PASS | ⬜ FAIL  
**Screenshot:** Đính kèm ảnh màn hình  
**Ghi chú:** ___________________________________________

---

### Test Case 2.4: Kiểm Tra Audit Log
- [ ] **Endpoint:** `GET /api/audit`
- [ ] **Query Params:** `?entityType=SalaryAdjustment&periodId=4`
- [ ] **Expected Result:**
  - Audit logs chứa ít nhất 3 bản ghi:
    1. BONUS +2,000,000
    2. PENALTY -5,000,000
    3. PENALTY -15,000,000
  - Mỗi bản ghi có:
    * `action: "Created"`
    * `entityType: "SalaryAdjustment"`
    * `entityId`: ID của adjustment
    * `userId`: User đã tạo
    * `timestamp`: Thời gian tạo
    * `changes`: JSON chứa adjustment details

**Kết quả:** ⬜ PASS | ⬜ FAIL  
**Ghi chú:** ___________________________________________

---

## 📋 KIỂM THỬ PHẦN 3: KIỂM TRA AN TOÀN

### Test Case 3.1: Đóng/Mở Kỳ Lương
- [ ] **Action:** Click nút "Đóng kỳ lương" trong footer
- [ ] **Expected Confirmation Dialog:**
  - Title: "Xác nhận Đóng kỳ lương"
  - Content: "Bạn có chắc chắn...?"
  - Buttons: "Hủy", "Đóng kỳ"
- [ ] **After Confirmation:**
  - Endpoint: `PUT /api/payroll/periods/{periodId}/status`
  - Body: `{ "isClosed": true }`
  - Response status: 200 OK
- [ ] **Expected Result - Frontend:**
  - Reload dữ liệu
  - Nút "Đóng kỳ lương" biến mất
  - **KHÔNG** hiển thị nút "💰 Tính Lương Ngay" trong empty state
  - Empty state hiển thị: "🔒 Kỳ lương đã đóng"
- [ ] **Test Generate Payroll After Closed:**
  - Try: `POST /api/payroll/generate/{periodId}`
  - Expected: Response status 400 Bad Request
  - Expected Message: "Kỳ lương đã được chốt."

**Kết quả:** ⬜ PASS | ⬜ FAIL  
**Ghi chú:** ___________________________________________

---

### Test Case 3.2: Parse An Toàn (Missing Field)
- [ ] **Mục tiêu:** Kiểm tra frontend xử lý an toàn khi backend trả về dữ liệu thiếu trường
- [ ] **Cách test:**
  1. (Backend) Tạm thời modify response để thiếu trường `departmentName` hoặc set = `null`
  2. (Frontend) Gọi `GET /api/payroll/records/period/{periodId}`
- [ ] **Expected Result:**
  - **KHÔNG** crash app
  - **KHÔNG** có exception "Null check operator used on a null value"
  - **KHÔNG** có màn hình trắng
  - Trường bị thiếu hiển thị:
    * Nếu là String: `""` (empty) hoặc `"N/A"`
    * Nếu là Number: `0` hoặc `0.0`
- [ ] **Verification trong DTO:**
  ```dart
  factory PayrollRecordResponse.fromJson(Map<String, dynamic> json) {
    return PayrollRecordResponse(
      employeeName: json['employeeName']?.toString() ?? '', // ✅ Safe
      departmentName: json['departmentName']?.toString() ?? 'N/A', // ✅ Safe
      baseSalaryActual: (json['baseSalaryActual'] ?? 0).toDouble(), // ✅ Safe
      // ...
    );
  }
  ```

**Kết quả:** ⬜ PASS | ⬜ FAIL  
**Ghi chú:** ___________________________________________

---

## 📊 KẾT QUẢ TỔNG HỢP

### Thống Kê
- **Tổng số test cases:** 9
- **PASS:** _____ / 9
- **FAIL:** _____ / 9
- **Tỷ lệ thành công:** _____% 

### Lỗi Phát Hiện
| # | Test Case | Lỗi | Mức độ | Trạng thái |
|---|-----------|-----|--------|------------|
| 1 | | | 🔴 Critical / 🟠 High / 🟡 Medium / 🟢 Low | ⬜ Open / ⬜ Fixed |
| 2 | | | | |
| 3 | | | | |

### Ghi Chú Chung
___________________________________________
___________________________________________
___________________________________________

---

## ✅ CHECKLIST HOÀN TẤT

- [ ] Tất cả test cases đã thực hiện
- [ ] Screenshots đã đính kèm (nếu có lỗi)
- [ ] Lỗi đã được ghi nhận và phân loại
- [ ] Tài liệu đã được review
- [ ] Code đã được commit (nếu có fix)

**Người thực hiện:** ___________  
**Người review:** ___________  
**Ngày hoàn thành:** ___________
