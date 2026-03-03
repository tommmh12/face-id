# Employee Management & Face ID System

> Hệ thống quản lý nhân viên và chấm công bằng nhận diện khuôn mặt, xây dựng bằng Flutter (mobile) + .NET API + AWS Rekognition.

## 1) Giới thiệu nhanh

Đây là dự án mobile phục vụ bài toán nội bộ doanh nghiệp:
- Quản lý hồ sơ nhân viên theo phòng ban
- Đăng ký khuôn mặt cho từng nhân viên
- Check-in / Check-out bằng nhận diện khuôn mặt
- Tính lương theo kỳ với các cấu phần phổ biến tại Việt Nam (thuế, bảo hiểm, OT)

Phiên bản đầy đủ và ổn định nhất trong workspace: **`employee_management_test/`**.

---

## 2) Giá trị sản phẩm

- **Giảm thao tác thủ công** trong chấm công và tổng hợp dữ liệu nhân sự
- **Tăng độ chính xác** nhờ đối sánh khuôn mặt với ngưỡng tin cậy
- **Sẵn sàng mở rộng** (kiến trúc tách lớp rõ ràng: models/services/screens)
- **Tập trung trải nghiệm người dùng**: UI tiếng Việt, phản hồi lỗi rõ ràng, luồng thao tác trực quan

---

## 3) Tech Stack

### Mobile App
- Flutter 3.x, Dart 3.x
- Material Design 3
- HTTP: `dio`, `http`
- Camera/Image: `camera`, `image_picker`, `image`, `flutter_image_compress`
- Utility: `intl`, `shared_preferences`, `uuid`

### Backend & Cloud (tích hợp)
- C# .NET Web API
- SQL Server
- AWS Rekognition (face matching)
- AWS S3 (lưu ảnh đăng ký/chấm công)

---

## 4) Tính năng chính

### 4.1 Quản lý nhân viên
- Danh sách nhân viên, lọc theo phòng ban
- Tạo/cập nhật hồ sơ nhân viên
- Chi tiết nhân viên và trạng thái Face ID

### 4.2 Đăng ký & xác thực khuôn mặt
- Chụp ảnh từ camera để đăng ký Face ID
- Kiểm tra khuôn mặt khi chấm công
- Hỗ trợ đăng ký lại khuôn mặt

### 4.3 Chấm công (Attendance)
- Check-in / Check-out bằng khuôn mặt
- Hiển thị kết quả đối sánh và thời gian chấm công
- Có health-check để kiểm tra API trước khi thao tác

### 4.4 Quản lý bảng lương
- Tạo kỳ lương
- Áp dụng quy tắc lương (base salary, OT, bảo hiểm, thuế)
- Tổng hợp số liệu lương theo kỳ

---

## 5) Kiến trúc & cấu trúc mã nguồn

```text
face-id/
├── employee_management/          # Bản cơ bản
├── employee_management_test/     # Bản đầy đủ, khuyến nghị demo
├── face_id_app/                  # App chấm công tối giản
├── face_id_test/                 # Bản thử nghiệm
├── PROJECT_REPORT.md
├── TECHNICAL_DOCUMENTATION.md
└── USER_MANUAL.md
```

Cấu trúc chính trong app đầy đủ (`employee_management_test/lib`):

```text
lib/
├── config/      # Cấu hình môi trường, API, ngưỡng nhận diện
├── models/      # Entity + DTO request/response
├── services/    # Tầng gọi API (employee/face/payroll)
├── screens/     # UI theo module nghiệp vụ
├── utils/       # Camera helper, tiện ích dùng chung
└── main.dart    # Router + theme + khởi tạo app
```

---

## 6) Luồng nghiệp vụ tiêu biểu

1. Tạo nhân viên và gán phòng ban  
2. Đăng ký khuôn mặt cho nhân viên  
3. Nhân viên check-in/check-out bằng camera  
4. Hệ thống lưu log chấm công + dữ liệu đối sánh  
5. Quản trị tạo kỳ lương và tổng hợp lương theo dữ liệu attendance

---

## 7) Hướng dẫn chạy nhanh (phiên bản khuyến nghị)

### 7.1 Yêu cầu
- Flutter SDK (stable)
- Thiết bị/emulator có camera
- Backend API đang chạy và truy cập được

### 7.2 Chạy app
```bash
cd employee_management_test
flutter pub get
flutter run
```

### 7.3 Cấu hình API
Chỉnh file:
- `employee_management_test/lib/config/app_config.dart`

Thiết lập đúng môi trường:
- `DevConfig.baseUrl` (local)
- hoặc `ProdConfig.baseUrl` (server)

> Lưu ý: app có `apiVersion = 'v1'` và tự build endpoint dạng `.../api/v1`.

### 7.4 Quyền truy cập camera
- Android: cần `CAMERA` + `INTERNET`
- iOS: thêm `NSCameraUsageDescription` trong `Info.plist`

---

## 8) Điểm kỹ thuật nổi bật khi đi phỏng vấn

- Thiết kế theo **service layer** giúp UI tách biệt khỏi networking logic
- Chuẩn hóa request/response bằng DTO, dễ maintain và mở rộng
- Tối ưu luồng camera + nén ảnh trước khi gửi API
- Có xử lý các case dữ liệu không ổn định từ backend (null-safe parsing)
- Quy hoạch dự án theo module nghiệp vụ (employee / face / payroll)

---

## 9) Tài liệu tham khảo trong repo

- `PROJECT_REPORT.md`: báo cáo tổng quan dự án
- `TECHNICAL_DOCUMENTATION.md`: tài liệu kỹ thuật chi tiết
- `USER_MANUAL.md`: hướng dẫn sử dụng theo màn hình
- `employee_management_test/USAGE_GUIDE.md`: hướng dẫn vận hành nhanh

---

## 10) Định hướng phát triển

- Bổ sung cơ chế xác thực người dùng (JWT/RBAC)
- Đồng bộ logs theo thời gian thực
- Tăng coverage test (unit/widget/integration)
- Đóng gói CI/CD cho Android/iOS

---

## 11) Liên hệ

Nếu bạn là nhà tuyển dụng hoặc reviewer kỹ thuật, tôi có thể trình bày thêm:
- Quyết định kiến trúc
- Cách tôi xử lý bug thực tế trong luồng camera/API
- Trade-off giữa tốc độ triển khai và độ ổn định sản phẩm
