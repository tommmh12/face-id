# HƯỚNG DẪN SỬ DỤNG - ỨNG DỤNG QUẢN LÝ NHÂN VIÊN & CHẤM CÔNG KHUÔN MẶT

## 📱 GIỚI THIỆU ỨNG DỤNG

**Employee Management & Face ID** là ứng dụng di động hiện đại giúp doanh nghiệp quản lý nhân viên và chấm công tự động bằng công nghệ nhận diện khuôn mặt.

### ✨ Tính năng chính
- 👥 **Quản lý nhân viên**: Tạo hồ sơ, phân chia phòng ban
- 🔐 **Nhận diện khuôn mặt**: Đăng ký và chấm công bằng Face ID  
- ⏰ **Chấm công tự động**: Check-in/Check-out nhanh chóng
- 💰 **Quản lý lương**: Tính toán lương tự động theo quy định Việt Nam
- 📊 **Báo cáo**: Thống kê và tổng hợp dữ liệu

---

## 🚀 BẮT ĐẦU SỬ DỤNG

### Yêu cầu hệ thống
- **Android**: 8.0+ (API level 26+)
- **iOS**: 12.0+
- **Camera**: Có camera trước/sau
- **Internet**: Kết nối mạng ổn định

### Cài đặt ứng dụng
1. Tải file APK hoặc cài từ App Store
2. Cấp quyền camera khi ứng dụng yêu cầu
3. Đảm bảo kết nối internet
4. Mở ứng dụng và bắt đầu sử dụng

---

## 🏠 TRANG CHỦ - DASHBOARD

### Màn hình chính
Khi mở ứng dụng, bạn sẽ thấy trang Dashboard với:

```
┌─────────────────────────────────────┐
│  Employee Management & Face ID      │
├─────────────────────────────────────┤
│                                     │
│  📊 Tổng quan                       │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │   25    │ │    5    │ │    3    ││
│  │Nhân viên│ │Phòng ban│ │Kỳ lương ││
│  └─────────┘ └─────────┘ └─────────┘│
│                                     │
│  🔧 Trạng thái hệ thống             │
│  • Face API: ✅ Hoạt động           │
│  • Payroll API: ✅ Hoạt động       │
│                                     │
│  ⚡ Truy cập nhanh                   │
│  [👥 Nhân viên] [📷 Chấm công]      │
│  [💰 Bảng lương] [⚙️ Cài đặt]       │
└─────────────────────────────────────┘
```

### Thanh điều hướng
- **☰ Menu**: Mở menu bên trái
- **🔄 Refresh**: Làm mới dữ liệu
- **📱 Home**: Về trang chủ

---

## 👥 QUẢN LÝ NHÂN VIÊN

### 1. Xem danh sách nhân viên

**Cách truy cập**: Trang chủ → "Quản lý nhân viên" hoặc Menu → "Nhân viên"

```
┌─────────────────────────────────────┐
│  🔍 [Tìm kiếm nhân viên...]         │
│  🏢 [Tất cả phòng ban ▼]            │
├─────────────────────────────────────┤
│  👤 Nguyễn Văn A      [🔐 Face ID]  │
│     EMP001 • IT Dept  [📱 Detail]   │
├─────────────────────────────────────┤
│  👤 Trần Thị B        [❌ No Face]  │
│     EMP002 • HR Dept  [📱 Detail]   │
├─────────────────────────────────────┤
│  👤 Lê Văn C          [🔐 Face ID]  │
│     EMP003 • Finance  [📱 Detail]   │
└─────────────────────────────────────┘
```

**Chức năng**:
- **Tìm kiếm**: Gõ tên, mã nhân viên hoặc email
- **Lọc phòng ban**: Chọn phòng ban từ dropdown
- **Trạng thái Face ID**: 
  - 🔐 = Đã đăng ký khuôn mặt
  - ❌ = Chưa đăng ký khuôn mặt
- **Chi tiết**: Xem thông tin đầy đủ nhân viên

### 2. Thêm nhân viên mới

**Cách thực hiện**: Danh sách nhân viên → Nút "+" (góc dưới phải)

```
┌─────────────────────────────────────┐
│  Thêm nhân viên mới                 │
├─────────────────────────────────────┤
│  📝 Thông tin cơ bản                │
│  ┌─────────────────────────────────┐ │
│  │ Họ và tên *                     │ │
│  │ [________________]              │ │
│  └─────────────────────────────────┘ │
│  ┌─────────────────────────────────┐ │
│  │ Mã nhân viên *                  │ │
│  │ [EMP004_________]               │ │
│  └─────────────────────────────────┘ │
│  ┌─────────────────────────────────┐ │
│  │ Email                           │ │
│  │ [user@company.com]              │ │
│  └─────────────────────────────────┘ │
│  ┌─────────────────────────────────┐ │
│  │ Số điện thoại                   │ │
│  │ [0123456789____]                │ │
│  └─────────────────────────────────┘ │
│  ┌─────────────────────────────────┐ │
│  │ Phòng ban *                     │ │
│  │ [IT Department ▼]               │ │
│  └─────────────────────────────────┘ │
│                                     │
│      [Hủy]              [Lưu]      │
└─────────────────────────────────────┘
```

**Các trường bắt buộc (*)**:
- Họ và tên
- Mã nhân viên (duy nhất)
- Phòng ban

**Lưu ý**: Sau khi tạo nhân viên thành công, bạn cần đăng ký khuôn mặt để sử dụng chấm công.

### 3. Xem chi tiết nhân viên

**Cách truy cập**: Danh sách → Chọn nhân viên → "Detail"

Màn hình chi tiết có 3 tab:

#### Tab 1: Thông tin cá nhân
```
┌─────────────────────────────────────┐
│  👤 Nguyễn Văn A                    │
│  📧 nguyenvana@company.com          │
│  📱 0123-456-789                    │
├─────────────────────────────────────┤
│  🏢 Phòng ban: IT Department        │
│  💼 Vị trí: Senior Developer        │
│  📅 Ngày vào: 01/01/2023            │
│  📍 Địa chỉ: 123 Main St, Hanoi    │
│  🎂 Sinh nhật: 15/05/1990           │
└─────────────────────────────────────┘
```

#### Tab 2: Face ID
```
┌─────────────────────────────────────┐
│  🔐 Trạng thái Face ID              │
│                                     │
│  ✅ Đã đăng ký khuôn mặt            │
│  📅 Ngày đăng ký: 15/10/2025       │
│  🖼️ [Ảnh khuôn mặt đã lưu]          │
│                                     │
│  [📷 Đăng ký lại]  [🔍 Kiểm tra]   │
└─────────────────────────────────────┘
```

#### Tab 3: Cấu hình lương
```
┌─────────────────────────────────────┐
│  💰 Quy tắc tính lương              │
│                                     │
│  💵 Lương cơ bản: 15,000,000 ₫      │
│  ⏰ Hệ số OT: 1.5x                  │
│  🏥 BHXH: 8%                        │
│  🏥 BHYT: 1.5%                      │
│  💼 BHTN: 1%                        │
│  💸 Thuế TNCN: 10%                  │
│                                     │
│      [Chỉnh sửa]                    │
└─────────────────────────────────────┘
```

---

## 📷 ĐĂNG KÝ KHUÔN MẶT (FACE ID)

### 1. Đăng ký Face ID lần đầu

**Cách truy cập**: 
- Chi tiết nhân viên → Tab "Face ID" → "Đăng ký Face ID"
- Hoặc Menu → "Đăng ký Face ID"

```
┌─────────────────────────────────────┐
│  📷 Đăng ký khuôn mặt               │
├─────────────────────────────────────┤
│  👤 Chọn nhân viên:                 │
│  ┌─────────────────────────────────┐ │
│  │ [Nguyễn Văn A - EMP001 ▼]       │ │
│  └─────────────────────────────────┘ │
│                                     │
│  📸 Camera Preview                  │
│  ┌─────────────────────────────────┐ │
│  │                                 │ │
│  │        ┌───────────┐            │ │
│  │        │           │            │ │
│  │        │   👤 ?    │            │ │
│  │        │           │            │ │
│  │        └───────────┘            │ │
│  │                                 │ │
│  └─────────────────────────────────┘ │
│                                     │
│  💡 Hướng dẫn:                      │
│  • Đặt khuôn mặt vào khung hình     │
│  • Đảm bảo ánh sáng đủ sáng         │
│  • Nhìn thẳng vào camera            │
│                                     │
│        [📷 Chụp ảnh]                │
└─────────────────────────────────────┘
```

**Quy trình đăng ký**:
1. Chọn nhân viên từ dropdown
2. Cho phép truy cập camera khi được hỏi
3. Đưa khuôn mặt vào khung định vị
4. Đảm bảo ánh sáng tốt và nhìn thẳng camera
5. Nhấn "Chụp ảnh"
6. Chờ hệ thống xử lý và upload lên cloud
7. Nhận thông báo thành công

### 2. Đăng ký lại Face ID

**Khi nào cần đăng ký lại**:
- Thay đổi ngoại hình (cắt tóc, râu ria, kính...)
- Ảnh cũ không rõ nét
- Tỷ lệ nhận diện thấp

**Quy trình tương tự đăng ký lần đầu**, hệ thống sẽ thay thế ảnh cũ bằng ảnh mới.

---

## ⏰ CHẤM CÔNG BẰNG KHUÔN MẶT

### 1. Màn hình chấm công

**Cách truy cập**: Trang chủ → "Chấm công" hoặc Menu → "Chấm công"

```
┌─────────────────────────────────────┐
│  ⏰ Chấm công khuôn mặt             │
├─────────────────────────────────────┤
│  🕐 08:30:25 - 18/10/2025           │
│                                     │
│  🔘 Vào làm    ○ Tan ca             │
│                                     │
│  📸 Camera Preview                  │
│  ┌─────────────────────────────────┐ │
│  │                                 │ │
│  │        ┌───────────┐            │ │
│  │        │           │            │ │
│  │        │   👤 ?    │            │ │
│  │        │           │            │ │
│  │        └───────────┘            │ │
│  │                                 │ │
│  └─────────────────────────────────┘ │
│                                     │
│  💡 Hướng dẫn:                      │
│  • Chọn loại chấm công (Vào/Ra)    │
│  • Đưa khuôn mặt vào khung          │
│  • Nhấn nút chấm công               │
│                                     │
│       [🔍 Chấm công]                │
└─────────────────────────────────────┘
```

### 2. Quy trình chấm công

#### Bước 1: Chọn loại chấm công
- **🔘 Vào làm**: Check-in buổi sáng
- **○ Tan ca**: Check-out buổi chiều

#### Bước 2: Định vị khuôn mặt
- Đưa khuôn mặt vào khung định vị
- Đảm bảo ánh sáng đủ sáng
- Khuôn mặt phải rõ nét và nhìn thẳng

#### Bước 3: Thực hiện chấm công
- Nhấn nút "Chấm công"
- Chờ hệ thống nhận diện (2-3 giây)
- Xem kết quả

### 3. Kết quả chấm công

#### Thành công (Confidence ≥ 85%)
```
┌─────────────────────────────────────┐
│  ✅ Chấm công thành công!           │
├─────────────────────────────────────┤
│  👤 Nguyễn Văn A                    │
│  🆔 EMP001                          │
│  🏢 IT Department                   │
│                                     │
│  ⏰ 08:30:25 - 18/10/2025           │
│  📊 Độ tin cậy: 92.5%               │
│                                     │
│  📸 Ảnh đã được lưu an toàn         │
│                                     │
│         [✅ Hoàn thành]              │
└─────────────────────────────────────┘
```

#### Thất bại (Confidence < 85%)
```
┌─────────────────────────────────────┐
│  ❌ Không nhận diện được khuôn mặt   │
├─────────────────────────────────────┤
│  🔍 Độ tin cậy: 67.2% (cần ≥85%)    │
│                                     │
│  💡 Gợi ý:                          │
│  • Đảm bảo ánh sáng đủ sáng         │
│  • Khuôn mặt nhìn thẳng camera      │
│  • Không đeo khẩu trang/kính râm    │
│  • Đăng ký lại Face ID nếu cần      │
│                                     │
│     [🔄 Thử lại]  [📷 Đăng ký lại] │
└─────────────────────────────────────┘
```

---

## 🏢 QUẢN LÝ PHÒNG BAN

### Xem danh sách phòng ban

**Cách truy cập**: Menu → "Phòng ban"

```
┌─────────────────────────────────────┐
│  🏢 Quản lý phòng ban               │
├─────────────────────────────────────┤
│  📊 IT Department               [▼] │
│      Công nghệ thông tin            │
│      👥 15 nhân viên                │
│      👨‍💼 Quản lý: Nguyễn Văn A         │
├─────────────────────────────────────┤
│  📊 Human Resources             [▼] │
│      Nhân sự                        │
│      👥 5 nhân viên                 │
│      👨‍💼 Quản lý: Trần Thị B          │
├─────────────────────────────────────┤
│  📊 Finance                     [▼] │
│      Tài chính kế toán              │
│      👥 8 nhân viên                 │
│      👨‍💼 Quản lý: Lê Văn C           │
└─────────────────────────────────────┘
```

**Chức năng**:
- **[▼]**: Mở rộng để xem danh sách nhân viên trong phòng ban
- **Số lượng nhân viên**: Hiển thị tổng số người trong phòng ban
- **Thông tin quản lý**: Người phụ trách phòng ban

---

## 💰 QUẢN LÝ BẢNG LƯƠNG

### 1. Dashboard bảng lương

**Cách truy cập**: Menu → "Bảng lương"

```
┌─────────────────────────────────────┐
│  💰 Quản lý bảng lương              │
├─────────────────────────────────────┤
│  📅 Kỳ lương:                       │
│  ┌─────────────────────────────────┐ │
│  │ [October 2025 ▼]                │ │
│  └─────────────────────────────────┘ │
│                                     │
│  📊 Tổng quan tài chính             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │1.5 tỷ ₫ │ │150M ₫   │ │1.35 tỷ₫ ││
│  │Tổng gross│ │Thuế+BH  │ │Thực lĩnh││
│  └─────────┘ └─────────┘ └─────────┘│
│                                     │
│  ⚡ Thao tác nhanh                   │
│  [📊 Tạo kỳ lương] [💻 Tính lương]  │
│  [📄 Xem báo cáo] [⚙️ Quy tắc]      │
└─────────────────────────────────────┘
```

### 2. Tạo kỳ lương mới

**Cách thực hiện**: Dashboard → "Tạo kỳ lương"

```
┌─────────────────────────────────────┐
│  📅 Tạo kỳ lương mới                │
├─────────────────────────────────────┤
│  📝 Tên kỳ lương:                   │
│  ┌─────────────────────────────────┐ │
│  │ [November 2025_______]          │ │
│  └─────────────────────────────────┘ │
│                                     │
│  📅 Từ ngày:                        │
│  ┌─────────────────────────────────┐ │
│  │ [01/11/2025] 📅                 │ │
│  └─────────────────────────────────┘ │
│                                     │
│  📅 Đến ngày:                       │
│  ┌─────────────────────────────────┐ │
│  │ [30/11/2025] 📅                 │ │
│  └─────────────────────────────────┘ │
│                                     │
│      [Hủy]              [Tạo]      │
└─────────────────────────────────────┘
```

### 3. Tính lương tự động

**Cách thực hiện**: Dashboard → "Tính lương"

```
┌─────────────────────────────────────┐
│  💻 Tính lương tự động              │
├─────────────────────────────────────┤
│  📅 Kỳ: October 2025                │
│  👥 Nhân viên: 25 người             │
│                                     │
│  🔄 Đang tính toán...               │
│  ████████████░░░░ 75%               │
│                                     │
│  ✅ Đã xử lý: 19/25 nhân viên       │
│  📊 Tiến độ:                        │
│  • Lương cơ bản: ✅ Hoàn thành      │
│  • Chấm công: ✅ Hoàn thành         │
│  • Làm thêm giờ: 🔄 Đang tính       │
│  • Thuế TNCN: ⏳ Chờ xử lý          │
│  • Bảo hiểm: ⏳ Chờ xử lý           │
└─────────────────────────────────────┘
```

### 4. Xem báo cáo lương

#### Tổng hợp kỳ lương
```
┌─────────────────────────────────────┐
│  📊 Báo cáo tổng hợp - Oct 2025     │
├─────────────────────────────────────┤
│  👥 Tổng số nhân viên: 25           │
│  💰 Tổng chi phí lương: 1.5 tỷ ₫    │
│                                     │
│  📈 Chi tiết:                       │
│  • Lương cơ bản: 1.2 tỷ ₫          │
│  • Phụ cấp: 180 triệu ₫            │
│  • Làm thêm giờ: 120 triệu ₫       │
│                                     │
│  📉 Khấu trừ:                       │
│  • Thuế TNCN: 75 triệu ₫           │
│  • BHXH: 60 triệu ₫                │
│  • BHYT: 18 triệu ₫                │
│  • BHTN: 12 triệu ₫                │
│                                     │
│  💵 Thực lĩnh: 1.35 tỷ ₫           │
│                                     │
│     [📄 Xuất PDF] [📧 Gửi mail]    │
└─────────────────────────────────────┘
```

#### Lương cá nhân
```
┌─────────────────────────────────────┐
│  👤 Nguyễn Văn A - EMP001           │
│  💰 Bảng lương October 2025         │
├─────────────────────────────────────┤
│  💵 Thu nhập:                       │
│  • Lương cơ bản: 15,000,000 ₫      │
│  • Phụ cấp ăn trưa: 1,000,000 ₫    │
│  • Phụ cấp đi lại: 500,000 ₫       │
│  • Làm thêm giờ: 2,000,000 ₫       │
│  ────────────────────────────       │
│  Tổng thu nhập: 18,500,000 ₫       │
│                                     │
│  📉 Khấu trừ:                       │
│  • Thuế TNCN: 1,200,000 ₫          │
│  • BHXH (8%): 1,200,000 ₫          │
│  • BHYT (1.5%): 225,000 ₫          │
│  • BHTN (1%): 150,000 ₫            │
│  ────────────────────────────       │
│  Tổng khấu trừ: 2,775,000 ₫        │
│                                     │
│  💰 Thực lĩnh: 15,725,000 ₫        │
│                                     │
│     [📄 In phiếu lương]             │
└─────────────────────────────────────┘
```

---

## ⚙️ CÀI ĐẶT & KIỂM TRA HỆ THỐNG

### 1. Health Check - Kiểm tra trạng thái

**Cách truy cập**: Menu → "Cài đặt" → "Kiểm tra hệ thống"

```
┌─────────────────────────────────────┐
│  🔧 Kiểm tra trạng thái hệ thống    │
├─────────────────────────────────────┤
│  📡 Kết nối API                     │
│                                     │
│  🔐 Face Recognition API            │
│  ├─ Trạng thái: ✅ Hoạt động        │
│  ├─ Phản hồi: 250ms                │
│  └─ Lần check cuối: 09:15:30       │
│                                     │
│  💰 Payroll API                     │
│  ├─ Trạng thái: ✅ Hoạt động        │
│  ├─ Phản hồi: 180ms                │
│  └─ Lần check cuối: 09:15:32       │
│                                     │
│  📱 Thông tin ứng dụng              │
│  ├─ Phiên bản: 1.0.0               │
│  ├─ Build: 2025.10.18              │
│  └─ Platform: Android 14           │
│                                     │
│        [🔄 Kiểm tra lại]            │
└─────────────────────────────────────┘
```

### 2. Cài đặt chung

```
┌─────────────────────────────────────┐
│  ⚙️ Cài đặt ứng dụng                │
├─────────────────────────────────────┤
│  🌐 Cấu hình API                    │
│  ├─ Server: api.studyplannerapp.io │
│  ├─ Timeout: 30 giây               │
│  └─ Auto retry: Bật                │
│                                     │
│  📷 Cài đặt camera                  │
│  ├─ Chất lượng: Cao (HD)           │
│  ├─ Flash: Tự động                 │
│  └─ Lưu ảnh local: Tắt             │
│                                     │
│  🔔 Thông báo                       │
│  ├─ Chấm công thành công: Bật       │
│  ├─ Lỗi hệ thống: Bật              │
│  └─ Âm thanh: Bật                  │
│                                     │
│  🗂️ Dữ liệu                         │
│  ├─ Cache size: 25.6 MB            │
│  ├─ [🗑️ Xóa cache]                 │
│  └─ [📤 Xuất dữ liệu]               │
└─────────────────────────────────────┘
```

---

## ❓ XỬ LÝ SỰ CỐ & KHẮC PHỤC LỖI

### Lỗi thường gặp

#### 1. Không thể truy cập camera
**Triệu chứng**: Màn hình đen, thông báo "Camera không khả dụng"

**Cách khắc phục**:
1. Kiểm tra quyền camera trong Cài đặt điện thoại
2. Tắt các ứng dụng khác đang sử dụng camera
3. Khởi động lại ứng dụng
4. Khởi động lại điện thoại nếu cần

#### 2. Không kết nối được API
**Triệu chứng**: Thông báo "Lỗi kết nối mạng"

**Cách khắc phục**:
1. Kiểm tra kết nối internet (WiFi/4G)
2. Thử truy cập website khác để test mạng
3. Vào Cài đặt → "Kiểm tra hệ thống"
4. Liên hệ IT nếu API server down

#### 3. Face ID không nhận diện
**Triệu chứng**: Độ tin cậy thấp (<85%), không match được

**Cách khắc phục**:
1. Đảm bảo ánh sáng đủ sáng
2. Khuôn mặt nhìn thẳng camera
3. Không đeo khẩu trang, kính râm
4. Đăng ký lại Face ID với ảnh rõ nét hơn
5. Thử nhiều góc độ khác nhau

#### 4. Ứng dụng bị treo/crash
**Cách khắc phục**:
1. Force close ứng dụng và mở lại
2. Xóa cache trong Cài đặt
3. Khởi động lại điện thoại
4. Cập nhật phiên bản mới nếu có

### Liên hệ hỗ trợ

**Khi nào cần liên hệ**:
- Lỗi hệ thống nghiêm trọng
- Mất dữ liệu quan trọng
- Cần thêm tính năng mới
- Đào tạo sử dụng

**Thông tin liên hệ**:
- 📧 Email: support@company.com
- 📞 Hotline: 1900-xxxx
- 💬 Chat: Trong ứng dụng
- 🌐 Website: support.company.com

---

## 📋 CHECKLIST SỬ DỤNG HÀNG NGÀY

### Quản lý nhân sự
- [ ] Kiểm tra nhân viên mới cần tạo hồ sơ
- [ ] Đảm bảo tất cả nhân viên đã đăng ký Face ID
- [ ] Cập nhật thông tin thay đổi (phòng ban, vị trí...)
- [ ] Kiểm tra trạng thái active/inactive

### Chấm công
- [ ] Kiểm tra thiết bị chấm công hoạt động bình thường
- [ ] Xem báo cáo chấm công ngày
- [ ] Xử lý các trường hợp chấm công bất thường
- [ ] Backup dữ liệu chấm công

### Bảng lương (cuối tháng)
- [ ] Tạo kỳ lương mới cho tháng tiếp theo
- [ ] Chạy tính lương tự động
- [ ] Kiểm tra và xác nhận kết quả
- [ ] Xuất báo cáo cho kế toán
- [ ] Thông báo lương cho nhân viên

### Bảo trì hệ thống (hàng tuần)
- [ ] Kiểm tra Health Check API
- [ ] Xóa cache và dữ liệu tạm
- [ ] Backup dữ liệu quan trọng
- [ ] Cập nhật phần mềm nếu có

---

## 🎯 TIPS SỬ DỤNG HIỆU QUẢ

### Tối ưu hóa Face ID
1. **Ánh sáng tốt**: Đăng ký và chấm công ở nơi có ánh sáng đủ
2. **Góc độ chuẩn**: Khuôn mặt nhìn thẳng, không nghiêng
3. **Cập nhật thường xuyên**: Đăng ký lại khi thay đổi ngoại hình
4. **Backup**: Lưu ảnh Face ID ở nhiều góc độ khác nhau

### Quản lý dữ liệu
1. **Đồng bộ thường xuyên**: Kết nối internet ổn định
2. **Backup định kỳ**: Xuất dữ liệu hàng tuần
3. **Kiểm tra tính nhất quán**: So sánh với hệ thống HR khác
4. **Lưu trữ an toàn**: Không lưu thông tin nhạy cảm local

### Bảo mật
1. **Đăng xuất sau sử dụng**: Nếu dùng thiết bị chung
2. **Cập nhật thường xuyên**: Luôn dùng phiên bản mới nhất
3. **Quyền hạn**: Chỉ cấp quyền cần thiết cho từng người
4. **Báo cáo lỗi**: Thông báo ngay khi phát hiện bất thường

---

**Phiên bản hướng dẫn**: 1.0.0  
**Ngày cập nhật**: 18/10/2025  
**Áp dụng cho**: Employee Management & Face ID App v1.0.0