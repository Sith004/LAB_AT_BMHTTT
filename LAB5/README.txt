# BÁO CÁO THỰC HÀNH LAB 3: TƯỜNG LỬA pfSense (SETUP ĐẾN TÌNH HUỐNG 3)


* **Sinh viên thực hiện:** Nguyễn Trọng Thể  
* **Mã số sinh viên (MSSV):** 1150080117  
* **Môi trường ảo hóa:** VMware Workstation  
* **Phiên bản Firewall:** pfSense CE 2.7.2-RELEASE (amd64)  

---

## I. MÔ HÌNH VÀ THÔNG SỐ MẠNG (TOPOLOGY)

### 1. Phân bổ Virtual Network trên VMware
* **VMnet1 (Host-only):** Mạng **LAN** — Subnet: `10.0.0.0/8`, DHCP: **Disabled**.
* **VMnet2 (Host-only):** Mạng **DMZ** — Subnet: `172.16.0.0/16`, DHCP: **Disabled**.
* **Bridged Adapter:** Mạng **WAN** kết nối trực tiếp với router vật lý (nhận IP DHCP dải `192.168.1.x`).

### 2. Bảng phân bổ địa chỉ IP các máy trạm và giao diện
| Thiết bị / Máy ảo | Giao diện mạng / VMnet | Địa chỉ IPv4 | Subnet Mask | Default Gateway | DNS Server |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **pfSense** | Adapter 1 (Bridged) | DHCP (WAN) | Tự động | Upstream | Upstream |
| **pfSense** | Adapter 2 (VMnet1) | `10.0.0.1` | `255.0.0.0` (/8) | — | — |
| **pfSense** | Adapter 3 (VMnet2) | `172.16.0.1` | `255.255.0.0` (/16) | — | — |
| **Host thật (Admin)**| VMnet1 | `10.0.0.100` | `255.0.0.0` (/8) | Không đặt | Không đặt |
| **Domain Controller**| VMnet1 | `10.0.0.2` | `255.0.0.0` (/8) | `10.0.0.1` | `10.0.0.2` |
| **LAN-Test (Kali)**  | VMnet1 | `10.0.0.3` | `255.0.0.0` (/8) | `10.0.0.1` | `8.8.8.8` |
| **DMZ-Web (WinSvr)** | VMnet2 | `172.16.0.2` | `255.255.0.0` (/16)| `172.16.0.1` | `8.8.8.8` |

---

## II. THIẾT LẬP MÔI TRƯỜNG NỀN TẢNG (INITIAL SETUP)

### 1. Cấu hình cổng LAN trên Console pfSense
1. Trên menu console pfSense, chọn option **`2) Set interface(s) IP address`**.
2. Chọn interface **LAN** (em1/vtnet1):
   * IPv4: `10.0.0.1`
   * Subnet bit count: `8`
   * Enable DHCP: `n`
   * Revert HTTP: `n`

### 2. Kích hoạt giao diện DMZ trên WebGUI
1. Từ máy thật truy cập WebGUI: `https://10.0.0.1`.
2. Truy cập **Interfaces** → **Assignments**, thêm card thứ 3 (em2) làm **OPT1**.
3. Cấu hình **Interfaces** → **OPT1**:
   * Enable: Tick chọn **Enable interface**
   * Description: `DMZ`
   * IPv4 Configuration Type: `Static IPv4`
   * IPv4 Address: `172.16.0.1` / `16`
   * Bấm **Save** → **Apply Changes**.

### 3. Cấu hình Outbound NAT và Chuẩn hóa Rule LAN
1. **Outbound NAT:** 
   * Truy cập **Firewall** → **NAT** → **Outbound**, chọn chế độ **Hybrid Outbound NAT rule generation**.
   * Bấm **Save** → **Apply Changes**. Hệ thống tự động sinh rule NAT cho cả `10.0.0.0/8` và `172.16.0.0/16`.
2. **Chuẩn hóa Rule LAN:**
   * Truy cập **Firewall** → **Rules** → **LAN**.
   * Nhấn **Disable** cả 2 rule mặc định (*Default allow LAN to any IPv4* và *IPv6*).
   * **Bắt buộc giữ lại Anti-Lockout Rule** để không bị mất quyền truy cập WebGUI.
3. **Cấu hình Rule ban đầu cho DMZ:**
   * Truy cập **Firewall** → **Rules** → **DMZ**.
   * Thêm rule: Action = `Pass`, Protocol = `IPv4 *`, Source = `DMZ net` (hoặc `*`), Destination = `*`, Description = `Allow DMZ to Internet`.
   * Bấm **Save** → **Apply Changes**.

---

## III. TÌNH HUỐNG 1 (T1): CHẶN ICMP NHƯNG CHO PHÉP WEB/DNS

### 1. Mục tiêu
Chặn lưu lượng Ping (ICMP) từ mạng LAN ra ngoài, nhưng các máy trạm trong LAN vẫn duyệt được Web (HTTP/HTTPS) và phân giải tên miền (DNS).

### 2. Cấu hình Ruleset (`Firewall` → `Rules` → `LAN`)
Thiết lập 3 rule theo đúng thứ tự ưu tiên từ trên xuống:
1. **Rule 1 (Top):** `Block` | Protocol: `ICMP` | Source: `LAN net` | Destination: `Any`
2. **Rule 2:** `Pass` | Protocol: `TCP/UDP` | Port: `53` (DNS) | Source: `LAN net` | Destination: `Any`
3. **Rule 3:** `Pass` | Protocol: `TCP` | Port: `80, 443` (HTTP/HTTPS) | Source: `LAN net` | Destination: `Any`
*(Vào `Diagnostics` → `States` → `Reset States` sau khi Apply Changes).*

### 3. Kiểm thử trên Domain Controller (`10.0.0.2`)
* **Lệnh 1 (Ping):** `ping 8.8.8.8` → **FAIL** (`Request timed out` do bị Rule 1 chặn).
* **Lệnh 2 (DNS):** `nslookup example.com 8.8.8.8` → **PASS** (Phân giải thành công qua Port 53).
* **Lệnh 3 (Web):** `curl.exe -4 https://example.com` → **PASS** (Trả về mã HTML qua Port 443).

---

## IV. TÌNH HUỐNG 2 (T2): CHỈ CHO MỘT HOST CỤ THỂ RA INTERNET

### 1. Mục tiêu
Chỉ cấp quyền cho máy Domain Controller (`10.0.0.2`) ra ngoài Internet. Toàn bộ các máy trạm khác thuộc mạng LAN (đại diện là Kali Linux `10.0.0.3`) bị chặn hoàn toàn.

### 2. Chuẩn bị máy trạm kiểm thử thứ hai (`LAN-Test` - Kali Linux)
Gán card mạng máy Kali vào **VMnet1** và cấu hình IP tĩnh trên Terminal:
```bash
# Ngăn NetworkManager xóa cấu hình IP tĩnh
sudo nmcli device set eth0 managed no

# Gán IP 10.0.0.3/8 và Default Gateway 10.0.0.1
sudo ip addr add 10.0.0.3/8 dev eth0
sudo ip route add default via 10.0.0.1