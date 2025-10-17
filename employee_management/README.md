# Employee Management System - Flutter App

## 📱 Giới thiệu

Ứng dụng quản lý nhân viên được xây dựng bằng **Flutter 3.x** với Material Design 3, kết nối đến **Face Recognition Attendance System API** (.NET 8).

## 🎯 Tính năng chính

### 1. 🏠 Dashboard
- Tổng quan hệ thống (số nhân viên, phòng ban, kỳ lương)
- Kiểm tra trạng thái API (Face API, Payroll API)
- Truy cập nhanh đến các chức năng chính
- Navigation drawer menu

### 2. 👥 Quản lý nhân viên
- **Danh sách nhân viên**: Hiển thị tất cả nhân viên với thông tin cơ bản
- **Tìm kiếm & Lọc**: Theo tên, mã nhân viên, email, phòng ban
- **Thêm nhân viên mới**: Form tạo hồ sơ nhân viên
- **Chi tiết nhân viên**: 
  - Thông tin cá nhân đầy đủ
  - Ảnh nhận diện khuôn mặt
  - Đăng ký/Cập nhật khuôn mặt (Camera/Gallery)
  - Xác thực khuôn mặt
  - Cấu hình lương cá nhân

### 3. 🏢 Quản lý phòng ban
- Danh sách phòng ban với số lượng nhân viên
- Xem danh sách nhân viên theo phòng ban
- Thông tin quản lý phòng ban

### 4. 💰 Quản lý bảng lương
- **Kỳ lương**:
  - Tạo kỳ lương mới
  - Xem danh sách kỳ lương (Active/Processed)
  - Tạo bảng lương cho kỳ
  - Xem tổng hợp lương
  
- **Quy tắc lương**:
  - Lương cơ bản
  - Tỷ lệ làm thêm giờ (OT)
  - Tỷ lệ bảo hiểm
  - Tỷ lệ thuế
  - Ngày hiệu lực

### 5. ⚙️ Cài đặt & Kiểm tra
- Kiểm tra trạng thái Face Recognition API
- Kiểm tra trạng thái Payroll API
- Thông tin hệ thống

## 📡 API Base URL

```
https://api.studyplannerapp.io.vn
```

## 🚀 Cài đặt và Chạy

### Bước 1: Cài đặt dependencies
```bash
flutter pub get
```

### Bước 2: Chạy ứng dụng
```bash
flutter run
```

### Bước 3: Build APK
```bash
flutter build apk --release
```

## 📦 Dependencies chính

- **dio** ^5.4.0 - REST API client
- **image_picker** ^1.0.7 - Chụp/chọn ảnh cho Face Recognition
- **cached_network_image** ^3.3.1 - Cache ảnh từ server
- **intl** ^0.19.0 - Format ngày tháng, tiền tệ
- **provider** ^6.1.1 - State management
- **logger** ^2.0.2+1 - Logging

## 🎨 Design System

- **Primary Color**: #1A73E8 (Blue)
- **Font**: Roboto/Inter
- **Style**: Material Design 3

---

**Version**: 1.0.0  
**Ngày tạo**: 17/10/2025

