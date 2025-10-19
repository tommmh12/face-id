# 🚀 Quick Reference - API Configuration

## ✅ ĐÃ SỬA XONG

### **Production API**:
```
https://api.studyplannerapp.io.vn/api
```

### **Files Đã Sửa**:
1. ✅ `lib/config/api_config.dart` - Line 17 (FILE CHÍNH)
2. ✅ `lib/config/app_config.dart` - DevConfig & ProdConfig

---

## 📱 TEST ACCOUNT

```
Username: ADM-2025-0003
Password: (your production password)
```

---

## 🔍 KIỂM TRA

### **Trong Flutter Logs**:

✅ **ĐÚNG** - Phải thấy:
```
START: User Login
Identifier: ADM-2025-0003
Request URL: https://api.studyplannerapp.io.vn/api/Employee/login
```

❌ **SAI** - Không được thấy:
```
uri=http://localhost:5000/api/Employee/login
uri=http://10.0.2.2:5000/api/Employee/login
SocketException: Connection refused
```

---

## 🔧 NẾU VẪN LỖI

### **1. Check Production API**:
```bash
curl https://api.studyplannerapp.io.vn/api/Employee/health
```

### **2. Check Internet (Emulator)**:
- Settings → Wi-Fi → Check connected
- Try browser in emulator

### **3. Check SSL Certificate**:
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<application
  android:usesCleartextTraffic="true"
  ...>
```

### **4. Check Endpoint Exists**:
```bash
curl -X POST https://api.studyplannerapp.io.vn/api/Employee/login \
  -H "Content-Type: application/json" \
  -d '{"identifier":"ADM-2025-0003","password":"your_password"}'
```

---

## 🎯 NEXT STEPS

1. ⏳ Wait for app to finish building
2. ✅ Test login với production account
3. ✅ Verify LoadingService overlay appears
4. ✅ Verify ApiErrorHandler shows messages
5. ✅ Check navigation to AdminDashboard

---

**Báo cáo chi tiết**: Xem `API_CONFIG_AUDIT.md`
