# README - Lab Telnet

## 1. Thông tin sinh viên

- **Họ và tên:** Nguyễn Trọng Thể
- **Mã số sinh viên:** 1150080117
- **Tên bài Lab:** Thực hành Telnet và phân tích lưu lượng mạng bằng Wireshark

---

## 2. Mô hình thực hành

Bài Lab được thực hiện trên mô hình gồm 3 thiết bị:

| Thiết bị | Vai trò | Địa chỉ IP |
|---|---|---|
| Windows Server 2008 | Telnet Server | 192.168.66.130 |
| Máy thật Windows | Telnet Client | 192.168.66.1 |
| Kali Linux | Máy phân tích lưu lượng | 192.168.66.129 |

- **Mạng:** 192.168.66.0/24
- **Subnet Mask:** 255.255.255.0
- **Môi trường mạng:** VMware VMnet1 (Host-only)

---

## 3. Nội dung đã thực hiện

### 3.1. Cấu hình mạng

- Cấu hình Windows Server 2008 với địa chỉ IP `192.168.66.130`.
- Cấu hình máy thật với địa chỉ IP `192.168.66.1`.
- Cấu hình Kali Linux với địa chỉ IP `192.168.66.129`.
- Kiểm tra kết nối giữa các thiết bị bằng lệnh `ping`.
- Cho phép ICMP trên Windows Server Firewall để các thiết bị trong Lab có thể kiểm tra kết nối.

### 3.2. Cấu hình Telnet Server

Trên Windows Server 2008:

- Tạo tài khoản sử dụng cho bài Lab.
- Cài đặt Telnet Server.
- Khởi động dịch vụ Telnet.
- Kiểm tra dịch vụ Telnet và cổng TCP 23.
- Thêm tài khoản Lab vào nhóm `TelnetClients`.
- Kiểm tra khả năng kết nối Telnet từ máy thật đến Windows Server.

### 3.3. Thực hiện phiên Telnet

Từ máy thật Windows, kết nối đến Windows Server bằng:

```text
telnet 192.168.66.130 23
