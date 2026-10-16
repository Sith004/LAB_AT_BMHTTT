# BÁO CÁO THỰC HÀNH: LAB 6 - CẤU HÌNH TƯỜNG LỬA PFSENSE VÀ QUẢN LÝ CHÍNH SÁCH TRUY CẬP MẠNG

- **Sinh viên thực hiện:** Nguyễn Trọng Thể
- **Mã số sinh viên (MSSV):** 1150080117

---

## 1. TỔNG QUAN KIẾN TRÚC MÔI TRƯỜNG LAB

Hệ thống mạng mô phỏng được triển khai trên nền tảng VMware Workstation gồm 4 phân vùng mạng độc lập, được định tuyến và kiểm soát tập trung bởi Firewall pfSense:
### Bảng phân bổ địa chỉ IP và tài nguyên hệ thống

| Tên thiết bị / Máy ảo | Hệ điều hành | Card mạng (Interface) | Phân vùng mạng (VMnet) | Địa chỉ IP / Subnet Mask | Default Gateway | Vai trò chức năng |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **pfSense-Lab6** | FreeBSD / pfSense | `em0` (WAN)<br>`em1` (LAN)<br>`em2` (MGMT)<br>`em3` (DMZ) | VMnet8 (NAT)<br>VMnet3 (LAN)<br>VMnet1 (Host-Only)<br>VMnet4 (DMZ) | DHCP<br>`10.6.0.1/24`<br>`192.168.56.254/24`<br>`172.16.6.1/24` | Gateway nhà mạng<br>—<br>—<br>— | Router định tuyến & Firewall lọc gói tin Layer 3/4 |
| **DC01** | Windows Server 2025 | Ethernet0 | VMnet3 (LAN) | `10.6.0.10/24` | `10.6.0.1` | Domain Controller (`lab6.test`), DNS, LDAP Directory Server |
| **Client-A** | Windows 11 x64 | Ethernet0 | VMnet3 (LAN) | `10.6.0.21/24` | `10.6.0.1` | Máy trạm người dùng A (DNS: `10.6.0.10`) |
| **Client-B** | Windows 11 x64 | Ethernet0 | VMnet3 (LAN) | `10.6.0.22/24` | `10.6.0.1` | Máy trạm người dùng B (DNS: `10.6.0.10`) |
| **DMZ-WEB** | Ubuntu Server | `ens33` | VMnet4 (DMZ) | `172.16.6.10/24`<br>`172.16.6.20/24`<br>`172.16.6.30/24`<br>`172.16.6.40/24` | `172.16.6.1` | Máy chủ Nginx đa IP mô phỏng các dịch vụ web mục tiêu |

---

## 2. THIẾT LẬP ĐỐI TƯỢNG ĐIỀU KHIỂN (FIREWALL ALIASES & SCHEDULES)

### 2.1. Danh mục Firewall Aliases (`Firewall > Aliases > IP`)

- **`Client_A`** (Type: `Host(s)`): `10.6.0.21` — Định danh máy trạm Client-A.
- **`POLICY_CLIENTS`** (Type: `Host(s)`): `10.6.0.21`, `10.6.0.22` — Nhóm máy trạm áp dụng chính sách chung (lưu trữ động trong pfSense Table).
- **`GENERAL_SITE`** (Type: `Host(s)`): `172.16.6.10` — Website thông thường cho phép truy cập (đối chứng).
- **`JOB_SITE`** (Type: `Host(s)`): `172.16.6.20` — Website tuyển dụng mô phỏng (đối tượng bị cấm của Client-A).
- **`SOCIAL_SITE`** (Type: `Host(s)`): `172.16.6.30` — Mạng xã hội mô phỏng (chỉ mở trong giờ giải lao).
- **`RESTRICTED_SITE`** (Type: `Host(s)`): `172.16.6.40` — Website độc hại/hạn chế (cấm toàn bộ nhóm clients).

### 2.2. Lịch biểu thực thi (Firewall Schedule)

- **`LUNCH_TIME`**: Khung thời gian nghỉ trưa được phép giải trí (ví dụ: `11:30 - 13:00` hàng ngày từ Thứ Hai đến Thứ Sáu).

---

## 3. CÁC TÌNH HUỐNG THỰC HÀNH VÀ KẾT QUẢ KIỂM THỬ

### Tình huống 1: Chặn Client-A truy cập JOB SITE (`172.16.6.20`)

- **Mục tiêu chính sách:** Máy trạm Client-A (`10.6.0.21`) bị chặn tuyệt đối khi truy cập website tìm việc làm (`JOB_SITE`), nhưng vẫn truy cập bình thường các website thông thường (`GENERAL_SITE`).
- **Cấu hình Firewall Rule (`Firewall > Rules > LAN`):**
  1. *Rule Block (Ưu tiên cao hơn - First-Match):*
     - **Action:** `Block` | **Interface:** `LAN` | **Protocol:** `IPv4 TCP`
     - **Source:** `Client_A` | **Destination:** `JOB_SITE` | **Port:** `80 (HTTP)`
     - **Log:** Bật ghi log (`Log packets handled by this rule`)
     - **Description:** `Block Client-A to JOB_SITE TCP/80`
  2. *Rule Pass (Phía dưới):*
     - **Action:** `Pass` | **Interface:** `LAN` | **Protocol:** `IPv4 TCP`
     - **Source:** `Client_A` | **Destination:** `GENERAL_SITE` | **Port:** `80 (HTTP)`
     - **Description:** `Pass Client-A to GENERAL_SITE TCP/80`
- **Kết quả kiểm thử:**
  - Trên Client-A (`10.6.0.21`):
    - `curl.exe -m 3 http://172.16.6.20` $\rightarrow$ Bị chặn, trả về `curl: (28) Connection timed out after 300x milliseconds`.
    - `curl.exe -I http://172.16.6.10` $\rightarrow$ Thành công, nhận mã phản hồi `HTTP/1.1 200 OK` (Welcome to nginx!).
  - **Firewall Log (`Status > System Logs > Firewall`):** Ghi nhận gói tin từ `10.6.0.21` gửi đến `172.16.6.20:80` bị chặn bởi icon dấu chéo đỏ.

---

### Tình huống 2: Cấm RESTRICTED_SITE đối với toàn bộ nhóm máy trạm (`POLICY_CLIENTS`)

- **Mục tiêu chính sách:** Sử dụng Alias nhóm IP để áp dụng một rule chặn duy nhất đến trang hạn chế (`RESTRICTED_SITE` - `172.16.6.40`) cho cả Client-A và Client-B.
- **Cấu hình Firewall Rule (`Firewall > Rules > LAN`):**
  - **Action:** `Block` | **Interface:** `LAN` | **Protocol:** `IPv4 TCP`
  - **Source:** `POLICY_CLIENTS` | **Destination:** `RESTRICTED_SITE` | **Port:** `80 (HTTP)`
  - **Description:** `Block POLICY_CLIENTS to RESTRICTED_SITE TCP/80`
- **Kết quả kiểm thử:**
  - Kiểm tra bảng quản trị pfSense Table (`Diagnostics > Tables > POLICY_CLIENTS`): Xác nhận hệ thống nạp thành công 2 bản ghi IP: `10.6.0.21` và `10.6.0.22`.
  - Trên máy trạm: Lệnh `curl.exe -m 3 http://172.16.6.40` trên cả hai máy đều bị treo 3 giây và báo lỗi `Connection timed out`.

---

### Tình huống 3: Kiểm soát truy cập SOCIAL SITE theo thời gian (Time-based Rule)

- **Mục tiêu chính sách:** Máy trạm Client-B (`10.6.0.22`) chỉ được phép truy cập mạng xã hội (`SOCIAL_SITE` - `172.16.6.30`) trong khung giờ nghỉ trưa đã cấu hình trên Schedule; ngoài giờ nghỉ sẽ tự động bị chặn.
- **Cấu hình Firewall Rule (`Firewall > Rules > LAN`):**
  - **Rule 1 (Pass có Schedule):**
    - **Action:** `Pass` | **Interface:** `LAN` | **Protocol:** `IPv4 TCP`
    - **Source:** `10.6.0.22` | **Destination:** `SOCIAL_SITE` | **Port:** `80 (HTTP)`
    - **Schedule:** Gán lịch biểu `LUNCH_TIME`
    - **Description:** `Pass CLIENT_B to SOCIAL_SITE lunch`
  - **Rule 2 (Block mặc định):**
    - Rule chặn chung nằm phía dưới: `Block other traffic`
- **Kết quả kiểm thử:**
  - *Ngoài giờ nghỉ:* `curl.exe -m 3 http://172.16.6.30` $\rightarrow$ Bị timeout; pfSense System Logs hiển thị icon dấu X đỏ: `7. Block other traffic`.
  - *Trong giờ nghỉ:* `curl.exe` thành công; pfSense System Logs ghi nhận icon tích xanh: `Pass CLIENT_B to SOCIAL_SITE lunch (TCP:SEC)`.

---

### Tình huống 4: Cô lập phân vùng DMZ (DMZ Isolation)

- **Mục tiêu chính sách:** Bảo vệ phân vùng an toàn LAN trước các nguy cơ tấn công leo thang từ vùng máy chủ công cộng DMZ. Máy chủ DMZ-WEB (`172.16.6.10`) bị cấm hoàn toàn hành vi chủ động kết nối ngược vào dải mạng LAN (`10.6.0.0/24`).
- **Cấu hình Firewall Rule (`Firewall > Rules > DMZ`):**
  - **Action:** `Block` | **Interface:** `DMZ` | **Protocol:** `IPv4 *`
  - **Source:** `DMZ net` (hoặc `172.16.6.10`) | **Destination:** `LAN net` (hoặc `10.6.0.0/24`)
  - **Log:** Bật kiểm toán lưu lượng
  - **Description:** `5. Block DMZ to LAN`
- **Kết quả kiểm thử:**
  - Khi máy chủ DMZ phát sinh kết nối DNS/truy vấn tới gateway và máy chủ nội bộ LAN (`10.6.0.1:53 UDP`):
  - **Firewall Log (`Status > System Logs > Firewall`):** Ghi nhận hàng loạt bản ghi bị từ chối từ interface DMZ với rule `5. Block DMZ to LAN`.

---

## 4. KINH NGHIỆM VÀ XỬ LÝ LỖI THỰC TẾ (TROUBLESHOOTING LOG)

Trong quá trình triển khai thực tế trên phòng lab ảo, một số vấn đề kỹ thuật quan trọng đã được phát hiện và xử lý:

1. **Xung đột VMware Virtual Adapter trên máy Host (IP Hijacking):**
   - *Hiện tượng:* Máy ảo DMZ ping `172.16.6.1` trả về `TTL=128` thay vì `TTL=64` của FreeBSD/pfSense; trình duyệt máy thật mở được trang web DMZ nhưng máy ảo LAN thì bị timeout.
   - *Nguyên nhân:* VMware Network Adapter của Windows máy thật tự động chiếm giữ IP `.1` trên switch ảo VMnet của DMZ.
   - *Khắc phục:* Mở `Virtual Network Editor`, bỏ chọn option `Connect a host virtual adapter to this network` trên VMnet tương ứng và tắt card mạng ảo của VMnet đó trên máy thật (`ncpa.cpl`).
2. **Cơ chế First-Match và State Table Caching:**
   - Khi chỉnh sửa hoặc đổi thứ tự rule, pfSense vẫn giữ các phiên kết nối cũ trong bảng State Table dẫn đến việc kết quả kiểm thử không cập nhật ngay.
   - *Khắc phục:* Sau khi bấm **Apply Changes**, luôn thực hiện reset state tại `Diagnostics > States > Reset States`.
3. **PowerShell Alias Conflict:**
   - Trên Windows PowerShell, lệnh `curl` mặc định là alias của `Invoke-WebRequest` khiến cờ `-I` hoặc `-m` bị lỗi tham số.
   - *Khắc phục:* Luôn gọi tường minh trình nhị phân thực thi `curl.exe`.
4. **Cấu hình sai Default Gateway trên máy trạm:**
   - *Hiện tượng:* Máy trạm Client-A đặt gateway nhầm về DC01 (`10.6.0.10`) khiến gói tin sang dải DMZ `172.16.6.0/24` không được định tuyến qua firewall.
   - *Khắc phục:* Trỏ Default Gateway trên toàn bộ máy trạm nội bộ về đúng IP LAN của pfSense (`10.6.0.1`).

---

## 5. KẾT LUẬN

Bài lab đã hoàn thành đầy đủ mục tiêu thiết lập hạ tầng tường lửa pfSense đa vùng, triển khai kiểm soát truy cập định danh qua Aliases, xây dựng chính sách tường lửa theo thời gian (Time-based Scheduling), và bảo vệ cô lập an toàn phân vùng mạng DMZ theo tiêu chuẩn an ninh hệ thống mạng.