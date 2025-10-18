# 📱 HƯỚNG DẪN SỬ DỤNG NHANH

## 🎯 Các Chức Năng Mới

### 1. Xem Chi Tiết Nhân Viên
```
Home → Quản Lý Nhân Viên → Click vào bất kỳ nhân viên nào
```

**Màn hình hiển thị:**
- ✅ Profile card gradient với avatar
- ✅ Thông tin cơ bản (tên, email, SĐT, chức vụ)
- ✅ Phòng ban
- ✅ Trạng thái Face ID
- ✅ Ngày vào làm, ngày tạo hồ sơ

**Actions:**
- Menu (⋮) → Chỉnh sửa / Cập nhật Face ID / Xóa
- Bottom buttons → "Chỉnh sửa" | "Face ID"

---

### 2. Thêm Nhân Viên Mới
```
Home → Quản Lý Nhân Viên → Nút "+" (góc dưới bên phải)
```

**Form nhập liệu:**
- Mã nhân viên* (bắt buộc)
- Họ tên* (bắt buộc)
- Email (có validate format)
- Số điện thoại
- Chức vụ
- Phòng ban* (dropdown - bắt buộc)
- Ngày sinh (date picker)
- Ngày vào làm* (date picker - bắt buộc)
- Trạng thái (switch on/off)

Click **"Thêm Nhân Viên"** để lưu.

---

### 3. Chỉnh Sửa Nhân Viên

**Cách 1:** Từ List Screen
```
Employee List → Click nhân viên → Menu (⋮) → Chỉnh sửa
```

**Cách 2:** Từ Detail Screen
```
Employee Detail → Bottom button "Chỉnh sửa"
hoặc
Employee Detail → Menu (⋮) → Chỉnh sửa
```

Form sẽ tự động điền dữ liệu hiện tại, chỉnh sửa và click **"Cập Nhật"**.

---

### 4. Xóa Nhân Viên
```
Employee Detail → Menu (⋮) → Xóa
```
- Popup xác nhận sẽ hiện ra
- Click "Xóa" để confirm hoặc "Hủy"

> ⚠️ **Lưu ý:** Chức năng xóa chưa kết nối API (hiện popup thông báo)

---

### 5. Cập Nhật Face ID
```
Employee Detail → Menu (⋮) → Cập nhật Face ID
hoặc
Employee Detail → Bottom button "Face ID"
```
- Popup xác nhận đăng ký lại
- Click "Đăng ký lại" → Chuyển đến màn hình Face Registration

---

### 6. Quản Lý Phòng Ban (MỚI!)
```
Home → Quản Lý Phòng Ban
```

**Danh sách phòng ban:**
- Hiển thị tất cả phòng ban với card design
- Thông tin: Tên, Mô tả, ID, Ngày tạo

**Thêm phòng ban mới:**
```
Click nút "Thêm Phòng Ban" (góc dưới) → Nhập tên + mô tả → Thêm
```

**Chỉnh sửa phòng ban:**
```
Menu (⋮) trên mỗi card → Chỉnh sửa
```

**Xóa phòng ban:**
```
Menu (⋮) trên mỗi card → Xóa → Xác nhận
```

> ⚠️ **Lưu ý:** Create/Update/Delete department chưa kết nối API

---

## 🔄 Flow Hoàn Chỉnh

### Quy Trình Quản Lý Nhân Viên Mới

1️⃣ **Tạo Phòng Ban** (nếu chưa có)
```
Home → Quản Lý Phòng Ban → "+" → Nhập tên phòng ban
```

2️⃣ **Thêm Nhân Viên**
```
Home → Quản Lý Nhân Viên → "+" → Điền form → Chọn phòng ban → Thêm
```

3️⃣ **Đăng Ký Face ID**
```
Employee Detail → "Face ID" button → Chụp ảnh khuôn mặt
```

4️⃣ **Chấm Công**
```
Home → Chấm Công Face ID → Check In/Out
```

5️⃣ **Xem Báo Cáo Lương**
```
Home → Quản Lý Lương → Xem payroll
```

---

## 🎨 Tips & Tricks

### Navigation Nhanh
- **Từ List → Detail:** Click trực tiếp vào employee card
- **Từ Detail → Edit:** Click bottom button "Chỉnh sửa" (nhanh hơn menu)
- **Từ Detail → Face ID:** Click bottom button "Face ID"

### Filter & Search
- **Lọc theo phòng ban:** Dùng dropdown ở đầu Employee List
- **Refresh list:** Click icon refresh (↻) trên app bar

### Form Input
- **Date picker:** Click vào field ngày → Chọn từ calendar
- **Dropdown:** Click vào field phòng ban → Chọn từ list
- **Switch:** Toggle on/off cho trạng thái hoạt động

### Error Handling
- **Validation errors:** Hiển thị đỏ dưới input field
- **API errors:** SnackBar màu đỏ ở bottom
- **Success:** SnackBar màu xanh ở bottom

---

## 📊 Screen Map

```
Home Screen (5 cards)
├─ Quản Lý Nhân Viên
│  ├─ Employee List
│  │  ├─ Employee Detail ← MỚI
│  │  │  ├─ Employee Form (Edit)
│  │  │  └─ Face Registration
│  │  │
│  │  └─ Employee Form (Create)
│  │
│  └─ Employee Create Screen (legacy)
│
├─ Quản Lý Phòng Ban ← MỚI
│  └─ Department List + Dialog Forms
│
├─ Đăng Ký Face ID
│  └─ Face Register Screen
│
├─ Chấm Công Face ID
│  └─ Face Check-in Screen
│
└─ Quản Lý Lương
   └─ Payroll Dashboard
```

---

## ✅ Checklist Sử Dụng

### Lần Đầu Setup
- [ ] Tạo ít nhất 2-3 phòng ban
- [ ] Thêm 5-10 nhân viên test
- [ ] Đăng ký Face ID cho ít nhất 2 nhân viên
- [ ] Test chấm công với Face ID
- [ ] Xem payroll dashboard

### Hằng Ngày
- [ ] Check in sáng (Face ID)
- [ ] Check out tối (Face ID)
- [ ] Xem attendance report

### Hằng Tháng
- [ ] Review danh sách nhân viên
- [ ] Update thông tin nếu có thay đổi
- [ ] Generate payroll
- [ ] Export báo cáo

---

## 🐛 Troubleshooting

### Không thấy nhân viên trong list?
- Kiểm tra filter phòng ban (đổi về "Tất cả")
- Click refresh button
- Kiểm tra kết nối API

### Form không submit được?
- Kiểm tra các trường bắt buộc (*) đã điền đủ
- Email phải đúng format (@)
- Phải chọn phòng ban

### Face ID không hoạt động?
- Kiểm tra quyền camera
- Đảm bảo đủ ánh sáng
- Mặt nhìn thẳng vào camera

### Navigation bị lỗi?
- Quay lại Home và thử lại
- Restart app nếu cần

---

## 📞 Support

Nếu gặp vấn đề:
1. Check EMPLOYEE_CRUD_COMPLETE.md để hiểu rõ flow
2. Xem logs trong console
3. Test API endpoints với /api-test screen

---

**Chúc sử dụng hiệu quả! 🎉**
