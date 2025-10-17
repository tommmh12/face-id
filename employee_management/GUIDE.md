# 📱 Employee Management System - Hướng dẫn sử dụng

## 🚀 Chạy ứng dụng

### 1. Khởi chạy lần đầu

```bash
# Di chuyển vào thư mục project
cd c:\MyProject\face-id\employee_management

# Cài đặt dependencies
flutter pub get

# Chạy ứng dụng (Android/iOS)
flutter run

# Hoặc chạy trên Chrome
flutter run -d chrome
```

### 2. Kiểm tra thiết bị

```bash
# Xem danh sách thiết bị kết nối
flutter devices

# Chạy trên thiết bị cụ thể
flutter run -d <device_id>
```

## 📖 Hướng dẫn sử dụng từng tính năng

### 🏠 1. DASHBOARD

**Mục đích**: Xem tổng quan hệ thống

**Các thông tin hiển thị**:
- Tổng số nhân viên trong hệ thống
- Số lượng phòng ban
- Số kỳ lương đang chạy
- Trạng thái API (Face Recognition & Payroll)

**Thao tác**:
- Tap vào card để chuyển đến trang tương ứng
- Pull-to-refresh để cập nhật dữ liệu
- Mở drawer menu (☰) để điều hướng

---

### 👥 2. QUẢN LÝ NHÂN VIÊN

#### 2.1. Danh sách nhân viên

**Đường dẫn**: Dashboard → Menu → Nhân viên

**Tính năng**:
- Xem danh sách tất cả nhân viên
- Tìm kiếm theo tên, mã nhân viên, email
- Lọc theo phòng ban
- Xem trạng thái (Active/Inactive)

**Thao tác**:
```
1. Mở trang Nhân viên
2. Nhập từ khóa vào ô tìm kiếm
3. Chọn phòng ban từ dropdown (nếu cần)
4. Tap vào employee card để xem chi tiết
5. Tap nút "➕ Thêm nhân viên" để tạo mới
```

#### 2.2. Thêm nhân viên mới

**Các trường bắt buộc**:
- ✅ Mã nhân viên (Employee Code)
- ✅ Họ và tên (Full Name)
- ✅ Email
- ✅ Phòng ban (Department)

**Các trường tùy chọn**:
- Số điện thoại
- Chức vụ
- Ngày sinh
- Ngày vào làm

**Thao tác**:
```
1. Tap nút "➕ Thêm nhân viên"
2. Điền thông tin vào form
3. Chọn phòng ban từ dropdown
4. Tap "Tạo mới"
5. Đợi thông báo thành công
```

#### 2.3. Chi tiết nhân viên

**Tab 1: Thông tin cá nhân**

**Hiển thị**:
- Ảnh nhận diện khuôn mặt (nếu có)
- Thông tin cơ bản (mã, tên, phòng ban, chức vụ)
- Thông tin liên hệ (email, SĐT)
- Ngày tạo/cập nhật

**Đăng ký khuôn mặt**:
```
1. Mở chi tiết nhân viên
2. Tap "Đăng ký khuôn mặt" hoặc "Cập nhật ảnh"
3. Chọn nguồn:
   - 📷 Chụp ảnh (Camera)
   - 🖼️ Chọn từ thư viện
4. Chụp/chọn ảnh khuôn mặt
5. Đợi upload và xử lý
6. Kiểm tra thông báo kết quả
```

**Lưu ý khi chụp ảnh**:
- ✅ Chụp thẳng mặt, không nghiêng
- ✅ Đủ ánh sáng
- ✅ Không đeo khẩu trang, kính đen
- ✅ Nền đơn giản

**Xác thực khuôn mặt**:
```
1. Tap "Xác thực"
2. Chụp ảnh khuôn mặt hiện tại
3. Hệ thống so sánh với ảnh đã đăng ký
4. Xem kết quả và độ chính xác (%)
```

**Tab 2: Lương & Phụ cấp**

**Hiển thị**:
- Lương cơ bản
- Tỷ lệ OT (Overtime)
- Tỷ lệ bảo hiểm
- Tỷ lệ thuế
- Ngày hiệu lực

**Tạo/Cập nhật quy tắc lương**:
```
1. Chuyển sang tab "Lương & Phụ cấp"
2. Tap "Tạo quy tắc lương" (nếu chưa có)
   HOẶC tap icon ✏️ để sửa
3. Nhập thông tin:
   - Lương cơ bản (VNĐ): ví dụ 15000000
   - Tỷ lệ OT (%): ví dụ 150 (= 150%)
   - Tỷ lệ bảo hiểm (%): ví dụ 10.5 (= 10.5%)
   - Tỷ lệ thuế (%): ví dụ 10 (= 10%)
4. Tap "Lưu"
```

---

### 🏢 3. QUẢN LÝ PHÒNG BAN

**Đường dẫn**: Dashboard → Menu → Phòng ban

**Tính năng**:
- Xem danh sách phòng ban
- Số lượng nhân viên mỗi phòng
- Thông tin quản lý
- Xem danh sách nhân viên theo phòng

**Thao tác**:
```
1. Mở trang Phòng ban
2. Tap vào card phòng ban để mở rộng
3. Đọc mô tả và thông tin quản lý
4. Tap "Xem danh sách nhân viên"
5. Tap vào tên nhân viên để xem chi tiết
```

---

### 💰 4. QUẢN LÝ BẢNG LƯƠNG

**Đường dẫn**: Dashboard → Menu → Bảng lương

#### 4.1. Tab Kỳ lương

**Tạo kỳ lương mới**:
```
1. Tap nút "➕ Tạo kỳ lương"
2. Nhập tên kỳ lương (ví dụ: "Tháng 10/2025")
3. Chọn ngày bắt đầu
4. Chọn ngày kết thúc
5. Tap "Tạo mới"
```

**Tạo bảng lương**:
```
1. Tìm kỳ lương chưa xử lý (Status: Active)
2. Tap vào card để mở rộng
3. Tap "Tạo bảng lương"
4. Xác nhận trong dialog
5. Đợi hệ thống xử lý
6. Kiểm tra thông báo kết quả
```

**Xem tổng hợp lương**:
```
1. Tìm kỳ lương đã xử lý (có "Đã xử lý: [ngày]")
2. Tap vào card để mở rộng
3. Tap "Xem tổng hợp lương"
4. Xem danh sách lương từng nhân viên
```

#### 4.2. Tab Quy tắc lương

**Hiển thị**:
- Danh sách tất cả quy tắc lương
- Tên nhân viên
- Lương cơ bản
- Các tỷ lệ (OT, bảo hiểm, thuế)
- Ngày hiệu lực

**Lưu ý**:
- Quy tắc được đánh dấu "Hiện tại" nếu đang có hiệu lực
- Một nhân viên có thể có nhiều quy tắc lương theo thời gian

---

### ⚙️ 5. CÀI ĐẶT & KIỂM TRA

**Đường dẫn**: Dashboard → Menu → Cài đặt

**Tính năng**:
- Kiểm tra kết nối Face Recognition API
- Kiểm tra kết nối Payroll API
- Xem thông tin hệ thống
- Xem thời gian kiểm tra cuối

**Thao tác**:
```
1. Mở trang Cài đặt
2. Xem trạng thái API:
   - ✅ Màu xanh: Hoạt động bình thường
   - ❌ Màu đỏ: Lỗi kết nối
3. Tap icon 🔄 để kiểm tra lại
4. Pull-to-refresh để cập nhật
```

---

## 🎨 Giao diện

### Màu sắc

- **Xanh dương** (#1A73E8): Chính (Primary)
- **Xanh lá** (#34A853): Thành công (Success)
- **Cam** (#FBBC04): Cảnh báo (Warning)
- **Đỏ** (#EA4335): Lỗi (Error)

### Icons

- 🏠 Dashboard
- 👥 Nhân viên
- 🏢 Phòng ban
- 💰 Bảng lương
- ⚙️ Cài đặt
- 📷 Camera
- 🧠 Xác thực
- ➕ Thêm mới
- ✏️ Chỉnh sửa
- 🔄 Làm mới

---

## ❓ Xử lý lỗi thường gặp

### 1. Lỗi kết nối API

**Hiện tượng**: "Không thể kết nối đến server"

**Giải pháp**:
```
1. Kiểm tra kết nối Internet
2. Kiểm tra Base URL: https://api.studyplannerapp.io.vn
3. Vào Cài đặt → Kiểm tra trạng thái API
4. Liên hệ admin nếu API down
```

### 2. Lỗi đăng ký khuôn mặt

**Hiện tượng**: "Đăng ký khuôn mặt thất bại"

**Giải pháp**:
```
1. Kiểm tra ảnh chụp:
   - Khuôn mặt rõ ràng
   - Đủ ánh sáng
   - Không bị mờ/nhòe
2. Thử chụp lại với điều kiện tốt hơn
3. Kiểm tra quyền Camera trong Settings
```

### 3. Lỗi tạo bảng lương

**Hiện tượng**: "Lỗi tạo bảng lương"

**Nguyên nhân có thể**:
```
- Chưa có quy tắc lương cho nhân viên
- Dữ liệu chấm công chưa đủ
- Kỳ lương đã được xử lý
```

**Giải pháp**:
```
1. Kiểm tra tất cả nhân viên đã có quy tắc lương
2. Kiểm tra dữ liệu attendance
3. Xem chi tiết lỗi trong thông báo
```

---

## 📊 Quy trình nghiệp vụ

### Quy trình onboard nhân viên mới

```
Bước 1: Tạo hồ sơ nhân viên
  ↓
Bước 2: Đăng ký khuôn mặt
  ↓
Bước 3: Thiết lập quy tắc lương
  ↓
Bước 4: Nhân viên sẵn sàng làm việc
```

### Quy trình tính lương hàng tháng

```
Bước 1: Tạo kỳ lương mới (đầu tháng)
  ↓
Bước 2: Nhân viên chấm công trong tháng
  ↓
Bước 3: Cuối tháng → Tạo bảng lương
  ↓
Bước 4: Xem tổng hợp và xuất báo cáo
  ↓
Bước 5: Thanh toán lương
```

---

## 🔒 Bảo mật

### Dữ liệu khuôn mặt

- Ảnh được mã hóa Base64 trước khi gửi
- Lưu trữ trên AWS S3 với encryption
- Chỉ hiển thị cho người có quyền

### Thông tin lương

- API yêu cầu authentication (sẽ thêm trong phiên bản sau)
- Dữ liệu sensitive được mã hóa
- Audit log cho mọi thay đổi

---

## 📞 Hỗ trợ

**Email**: support@example.com  
**API Documentation**: https://api.studyplannerapp.io.vn/swagger  
**Version**: 1.0.0
