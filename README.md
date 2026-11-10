# CTSV Mobile

Khung ứng dụng Android cho dự án Công tác Sinh viên DUT. Repository được tạo
bằng Flutter chính thức, tách riêng backend `../ctsv` và web `../fe`.

## Công nghệ

| Thành phần | Phiên bản / cấu hình |
| --- | --- |
| Flutter | **3.47.0 stable**, pin trong `.fvmrc` |
| Dart | **3.13.0**, đi kèm Flutter 3.47.0; không cài SDK Dart riêng |
| Android compile SDK | **35** |
| Android target SDK | **35** |
| Android tối thiểu | API **24** (Android 7.0), theo nền Flutter này |
| Android application ID | `vn.edu.dut.ctsv.mobile` |
| Android host | Kotlin, Java bytecode 17 |
| Android build | AGP 9.1.0, Gradle 9.3.1 theo template Flutter 3.47.0 |
| Giao diện | Material 3, ngôn ngữ mặc định tiếng Việt |

Nguồn: [Flutter 3.47 release notes](https://docs.flutter.dev/release/release-notes/release-notes-3.47.0),
[Flutter SDK archive](https://docs.flutter.dev/install/archive),
[Android API 35](https://developer.android.com/about/versions/15/setup-sdk).
Giữ nguyên Dart đi kèm SDK và commit `pubspec.lock` để cả nhóm dùng cùng dependency.

## Phạm vi hiện có

Chỉ dự kiến triển khai hai chức năng trên mobile:

- **SHCN-01 — Xem lịch SHCN.**
- **HBTT-02 — Xem thông báo học bổng tài trợ.**

DRL, miễn giảm học phí, KKHT, du học và ký số chỉ có nút giữ chỗ bị vô hiệu hóa;
không triển khai nghiệp vụ của các mục này.

- App shell với thanh điều hướng Trang chủ, Lịch SHCN và Học bổng.
- Theme, bản địa hóa, cấu hình API theo môi trường và đường dẫn API backend.
- Các trang SHCN/HBTT là placeholder để triển khai tiếp; chưa gọi API, chưa có
  đăng nhập hoặc dữ liệu sinh viên giả.
- Unit/widget test cho cấu hình và điều hướng.

`CtsvApp` nhận `AppConfig` tại điểm khởi tạo để sau này truyền cấu hình vào API
client/repository. Chưa thêm thư viện quản lý state, HTTP hoặc code generation
khi chưa có luồng cần dùng chúng.

## Chạy trên Windows

Cần Git, Android Studio hoặc Android SDK, JDK 17 trở lên và một thiết bị Android
hoặc emulator. Trong Android SDK Manager, cài **Android SDK Platform 35**, SDK
Build-Tools **35.0.0** và Platform-Tools. Chấp nhận license bằng công cụ Android
SDK trên máy nếu công cụ build yêu cầu. Flutter có thể yêu cầu thêm NDK theo
template khi build lần đầu; không cần đổi `compileSdk` hay `targetSdk` vì việc đó.

Mở terminal trong thư mục `mobile`:

```powershell
# Clone Flutter đúng phiên bản vào .tools/flutter và tải package.
# Bỏ qua nếu đã có .tools/flutter và pubspec.lock được resolve trên máy này.
.\tool\bootstrap.ps1

.\tool\flutter.ps1 --version
.\tool\flutter.ps1 doctor -v
.\tool\flutter.ps1 devices
.\tool\flutter.ps1 run --dart-define-from-file=config/dev.example.json
```

Wrapper dùng SDK và cache trong `.tools/`, kiểm phiên bản trước khi chạy, không
sửa PATH toàn hệ thống. `.tools/` không được đưa lên Git. Nếu PowerShell chặn
script, có thể gọi `powershell -ExecutionPolicy Bypass -File .\tool\flutter.ps1 devices`
cho riêng tiến trình đó.

Nếu đã dùng FVM, chạy `fvm install` rồi `fvm flutter pub get` và `fvm flutter run`.
Đặt đường dẫn SDK của IDE về `.fvm/flutter_sdk` khi chọn FVM. Cấu hình VS Code
đi kèm mặc định dùng `.tools/flutter`.

## Địa chỉ backend

`API_BASE_URL` là **origin**, không thêm `/api`; ví dụ `http://10.0.2.2:8080`.

- Android emulator: `10.0.2.2` trỏ về máy chạy backend.
- Điện thoại thật: dùng IP LAN của máy chạy Spring Boot, cùng mạng và mở cổng 8080.
- Có thể dùng `adb reverse tcp:8080 tcp:8080` qua USB rồi cấu hình `http://127.0.0.1:8080`.
- Bản release dùng HTTPS; chỉ manifest **debug** cho phép HTTP để phát triển local.

Tạo cấu hình riêng từ bản mẫu và không commit địa chỉ/mật khẩu nội bộ:

```powershell
Copy-Item config/dev.example.json config/dev.local.json
# Sửa API_BASE_URL trong dev.local.json cho thiết bị đang dùng.
.\tool\flutter.ps1 run --dart-define-from-file=config/dev.local.json
```

`config/*.local.json` đã được ignore. Dart define được nhúng vào ứng dụng nên
chỉ dùng cho cấu hình công khai; không để mật khẩu, JWT secret hoặc khóa ký ở đó.

Endpoint đã định vị tại `lib/core/network/api_endpoints.dart`: auth, lịch SHCN,
thông báo HBTT. Khi nối đăng nhập cần xử lý Bearer access token, cookie refresh,
xoay phiên và yêu cầu Origin/CSRF của backend hiện tại; skeleton chưa triển khai
transport hay lưu token. Không dùng dữ liệu demo của web thay kết quả API.

## Cấu trúc

```text
lib/
  main.dart
  app/                 # MaterialApp, app shell, theme
  core/config/         # Cấu hình public từ dart-define
  core/network/        # Hợp đồng đường dẫn API
  features/
    home/presentation/
    shcn/presentation/
    scholarships/presentation/
  shared/widgets/
android/               # Host Android, compile/target API 35
config/                # Cấu hình mẫu, không có thông tin đăng nhập
test/                  # Unit và widget test
tool/                  # Bootstrap và wrapper Windows
```

Khi bắt đầu một nghiệp vụ, thêm `data/` cho DTO/API/repository và phần state vào
nghiệp vụ tương ứng khi cần. Logic dùng chung mới đưa vào `core` hoặc `shared`.

## Kiểm tra và build

```powershell
.tools\flutter\bin\dart.bat format --output=none --set-exit-if-changed lib test
.\tool\flutter.ps1 analyze
.\tool\flutter.ps1 test
.\tool\flutter.ps1 build apk --debug --dart-define-from-file=config/dev.example.json
```

APK debug: `build/app/outputs/flutter-apk/app-debug.apk`.
Gói `integration_test` đi kèm Flutter 3.47.0 yêu cầu compile SDK 36, nên khung
API 35 này chưa đưa gói đó vào dependency. Kiểm thử trên thiết bị sẽ được bổ sung
khi chọn công cụ phù hợp; unit/widget test hiện tại chưa kiểm chứng nghiệp vụ với backend.
Bản release hiện dùng khóa debug của template để kiểm tra cục bộ; cần cấu hình
upload key riêng trước khi phát hành, không đưa keystore hoặc mật khẩu lên Git.
