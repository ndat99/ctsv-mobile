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

Điểm rèn luyện và miễn giảm học phí chỉ mở màn hình thông báo chưa triển khai.
KKHT, du học và ký số chỉ có nút giữ chỗ bị vô hiệu hóa;
không triển khai nghiệp vụ của các mục này.

- Thanh điều hướng gồm SHCN, Điểm rèn luyện, Trang chủ, MGHP và Học bổng;
  nút Trang chủ nằm giữa, nhô lên theo cung tròn.
- Theme, bản địa hóa, cấu hình API theo môi trường và đường dẫn API backend.
- Đăng nhập thật bằng tài khoản backend, kiểm thông tin `/me`, khôi phục phiên,
  làm mới access token và đăng xuất.
- HBTT-02 dùng API thật để xem danh sách có phân trang, làm mới, xem chi tiết
  thông báo, điều kiện và thông tin biểu mẫu kèm theo; tìm kiếm theo tên học bổng
  hoặc nhà tài trợ.
- SHCN-01 dùng API thật để xem danh sách và chi tiết lịch của lớp, phân trang,
  làm mới, xem trạng thái lịch/phòng, link họp và yêu cầu đổi lịch kèm theo.
- Unit/widget test cho cấu hình, đăng nhập, điều hướng, xem lịch SHCN và học bổng.

`CtsvApp` nhận `AppConfig` tại điểm khởi tạo. Auth dùng `ChangeNotifier`, HTTP
client có thể thay bằng mock trong test và kho phiên Android qua MethodChannel.

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

`AUTH_ORIGIN` là giá trị header `Origin` mà backend cho phép qua
`AUTH_ALLOWED_ORIGINS`. Mặc định `http://localhost:5173` khớp cấu hình backend
hiện tại; đây không phải địa chỉ emulator. Khi triển khai thật, thay bằng một
origin đã được backend cho phép. App gửi `X-CSRF-Protection: 1` cho auth write.

Tạo cấu hình riêng từ bản mẫu và không commit địa chỉ/mật khẩu nội bộ:

```powershell
Copy-Item config/dev.example.json config/dev.local.json
# Sửa API_BASE_URL trong dev.local.json cho thiết bị đang dùng.
.\tool\flutter.ps1 run --dart-define-from-file=config/dev.local.json
```

`config/*.local.json` đã được ignore. Dart define được nhúng vào ứng dụng nên
chỉ dùng cho cấu hình công khai; không để mật khẩu, JWT secret hoặc khóa ký ở đó.

## Sử dụng đăng nhập

1. Chạy backend `../ctsv` với cấu hình SQL Server và JWT hiện có. HTTP local cần
   profile `dev` hoặc `AUTH_COOKIE_SECURE=false`; production dùng HTTPS và cookie Secure.
2. Chọn `API_BASE_URL` phù hợp emulator/điện thoại; giữ `AUTH_ORIGIN` khớp allowlist backend.
3. Chạy app, nhập tài khoản backend đang hoạt động. Có thể dùng tài khoản sinh viên
   đã được quản trị tạo; các tài khoản dev chỉ tồn tại nếu máy đã bật seed tương ứng.
4. Thành công sẽ mở Trang chủ với username từ server. Nút Đăng xuất ở góc phải.

Không có tài khoản/mật khẩu mặc định nhúng trong app và không triển khai đăng ký,
quên mật khẩu hoặc Office 365 trong phần này.

Access token chỉ ở RAM. Cookie refresh được lưu thành payload mã hóa AES-256-GCM
trong thư mục `noBackupFilesDir`; khóa không xuất ra ngoài Android Keystore.
Không lưu mật khẩu, access token hoặc quyền người dùng vào file. Mỗi lần mở app
lấy lại tài khoản từ `/me`, không tin thông tin người dùng lưu cũ.

Auth sử dụng `/api/auth/login`, `/refresh`, `/me`, `/logout`. Nhiều request 401
đồng thời dùng chung một lần refresh và mỗi request chỉ thử lại một lần. Lỗi mạng,
timeout, sai thông tin hoặc lỗi nghiệp vụ không tự gửi lại đăng nhập. Khi khôi phục
phiên gặp lỗi mạng, có thể Thử lại hoặc chọn Đăng nhập lại để xóa phiên local.
Đăng xuất luôn xóa phiên trên thiết bị trước; nếu mất kết nối khi thu hồi trên
server, app hiển thị rõ cảnh báo này.

## Xem thông báo học bổng tài trợ (HBTT-02)

Sau khi đăng nhập, chọn **Học bổng** ở thanh điều hướng hoặc thẻ trên Trang chủ.
Tài khoản cần quyền `HB_TT_XEM` và liên kết hồ sơ sinh viên hợp lệ. Backend tiếp
tục kiểm tra quyền và liên kết hồ sơ cho từng request.

- Danh sách dùng `GET /api/hoc-bong/tai-tro/thong-bao?page=0&size=12`.
  Nút Trước/Sau chuyển trang; nút Làm mới hoặc kéo xuống tải lại trang đầu.
- Nhập tên học bổng hoặc nhà tài trợ, bấm **Tìm kiếm** hoặc phím tìm kiếm trên
  bàn phím để gửi `q` đến API, tìm trên toàn bộ danh sách trước khi phân trang.
  Từ khóa tối đa 200 ký tự, bỏ khoảng trắng hai đầu. Tìm mới hoặc xóa tìm kiếm
  quay về trang đầu. Nút Trước/Sau xóa từ khóa và tải trang tương ứng của toàn bộ
  danh sách; làm mới và quay lại từ chi tiết giữ từ khóa đang áp dụng.
  Nút **Xóa tìm kiếm** trong ô nhập trả về toàn bộ danh sách công khai.
- Chạm thông báo để gọi `GET /api/hoc-bong/tai-tro/thong-bao/{id}`. Chi tiết
  gồm nhà tài trợ, năm học, giá trị, thời gian, trạng thái, nội dung/điều kiện
  và thông tin cần chuẩn bị theo biểu mẫu. Biểu mẫu chỉ để đọc.
- Giờ hiển thị cố định theo Việt Nam (UTC+7). Nhãn nhận hồ sơ lấy từ
  `dangNhanHoSo` do backend trả về; không tự quyết định dựa vào đồng hồ thiết bị.
- Có trạng thái đang tải, rỗng, lỗi mạng/thử lại, không đủ quyền và thông báo
  không còn công khai. Không dùng dữ liệu mẫu thay cho lỗi hoặc danh sách rỗng.
- Màn hình chi tiết nằm trong phiên hiện tại; hết phiên hoặc đăng xuất sẽ đóng
  cả danh sách/chi tiết. Không lưu thông báo xuống thiết bị.

Phần này chỉ xem thông báo, chưa triển khai đăng ký/nộp hồ sơ (HBTT-01).
Theo yêu cầu chuẩn bị kiểm thử, việc xóa từ khóa khi chuyển trang được giữ làm
kịch bản đã biết: case kỳ vọng giữ bộ lọc khi phân trang sẽ FAILED. Test widget
`search resets pagination and survives detail, refresh and clear on a small screen`
vẫn kiểm kỳ vọng giữ từ khóa, nên sẽ thất bại với hành vi hiện tại.

Để xem dữ liệu trên máy, backend phải chạy và có thông báo đã phát hành; thông
báo nháp không xuất hiện trong API dành cho sinh viên. Test tự động dùng HTTP
giả lập, chưa thay thế kiểm tra với SQL Server và tài khoản sinh viên thực tế.

## Xem lịch SHCN (SHCN-01)

Sau khi đăng nhập, chọn **Lịch SHCN** trên thanh điều hướng hoặc thẻ ở Trang chủ.
Tài khoản sinh viên cần quyền `SHCN_LICH_XEM` và liên kết hồ sơ sinh viên.
Backend xác định lớp từ hồ sơ trong token; app không gửi mã lớp hoặc mã sinh viên
để tự chọn phạm vi dữ liệu.

- Danh sách gọi `GET /api/shcn/lich-hop?page=0&size=20`, dùng `total` để phân
  trang. Nút Trước/Sau chuyển trang; Làm mới hoặc kéo xuống quay về trang đầu.
- Chọn **Xem chi tiết** để tải `GET /api/shcn/lich-hop/{id}`: đợt, lớp, học kỳ,
  lần họp, ngày/tiết, hình thức, phòng/link, mã GVCN và trạng thái chốt/phòng.
- Nhãn **Lịch đã công bố** dựa trên `loaiLich=LICH_CONG_BO`. Nguyện vọng được
  ghi rõ chưa công bố; phòng dự kiến không hiển thị như phòng chính thức.
  Giữ các trạng thái chưa xếp, đang xếp, đang giữ, xếp thất bại và hủy phòng.
- Ngày họp giữ nguyên ngày lịch của backend, không đổi theo múi giờ thiết bị.
  Các mốc xác nhận/gửi/xử lý/hạn chốt hiển thị theo giờ Việt Nam (UTC+7).
- Lịch trực tuyến đã công bố có nút **Sao chép link họp** trong chi tiết.
  Chỉ sao chép link HTTP(S) hợp lệ, không có thông tin đăng nhập trong URL;
  lịch hủy hoặc chưa công bố không có nút này.
- Yêu cầu đổi lịch chỉ để đọc: ngày/tiết đề nghị, lý do, trạng thái và kết quả
  xử lý. Đề nghị đang chờ không thay thế ngày/tiết lịch hiện tại.
- Có trạng thái tải, rỗng, lỗi/thử lại và lịch không còn thuộc phạm vi được xem.
  Hết phiên hoặc đăng xuất đóng cả danh sách/chi tiết; không lưu lịch trên máy.

Phần sinh viên không có thao tác chốt, gửi yêu cầu đổi lịch, điểm danh hoặc lập
biên bản. Backend phải chạy với dữ liệu lớp/đợt phù hợp để xem lịch thực tế.
Unit/widget test dùng HTTP giả lập, chưa thay thế kiểm tra với tài khoản thật.

## Cấu trúc

```text
lib/
  main.dart
  app/                 # MaterialApp, app shell, theme
  core/config/         # Cấu hình public từ dart-define
  core/network/        # Hợp đồng đường dẫn API
  features/
    auth/              # Dữ liệu auth, điều phối phiên và trang đăng nhập
    home/presentation/
    shcn/              # DTO, API đọc danh sách/chi tiết và giao diện SHCN-01
    scholarships/      # DTO, API đọc danh sách/chi tiết và giao diện HBTT-02
  shared/widgets/
android/               # Host Android, compile/target API 35
config/                # Cấu hình mẫu, không có thông tin đăng nhập
test/                  # Unit và widget test
tool/                  # Bootstrap và wrapper Windows
```

Khi bắt đầu một nghiệp vụ, thêm `data/` cho DTO/API/repository và phần state vào
nghiệp vụ tương ứng khi cần. Logic dùng chung mới đưa vào `core` hoặc `shared`.

`android/.../SecureSessionStore.kt` chỉ phục vụ lưu phiên Android. Mở rộng sang
iOS sau này cần bổ sung Keychain và phần host iOS tương ứng.

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
