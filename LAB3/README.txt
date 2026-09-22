# BÁO CÁO THỰC HÀNH LAB 3: NHẬN DIỆN VÀ ỨNG PHÓ CÁC MỐI ĐE DỌA ĐẾN AN TOÀN THÔNG TIN

- **Môn học:** An toàn Hệ thống Thông tin
- **Họ và tên:** Nguyễn Trọng Thể
- **Mã số sinh viên (MSSV):** [Điền MSSV của bạn vào đây]
- **Lớp / Học phần:** [Điền mã lớp của bạn vào đây]
- **Môi trường thực hành:** VMware Workstation Pro 26H1 trên Windows 11

---

## 1. Thông số môi trường chuẩn hóa

Hệ thống được dựng và chuẩn hóa theo quy chuẩn bài thực hành:
- **Ảo hóa:** VMware Workstation Pro 26H1 (Chế độ mạng: Host-only).
- **Hệ điều hành máy ảo (Guest OS):** Windows 11 25H2 x64, OS build 26200.9445 (KB5124008).
- **Endpoint Protection:** Microsoft Defender Antivirus (Real-time protection và Tamper Protection luôn bật).
- **Shell thực thi:** Windows PowerShell 5.1 (Run as administrator).
- **Python:** 3.14.7.
- **Wireshark:** 4.6.8 Stable tích hợp Npcap.
- **Bộ công cụ Sysinternals:**
  - Sysmon v15.22 (Schema 4.90).
  - Autoruns v14.3[cite: 1].
  - Process Explorer v17.14[cite: 1].

---

## 2. Các bước dựng môi trường và thiết lập Baseline

1. **Khởi tạo VM & Snapshot:** Tạo máy ảo Windows 11 cấu hình 2 vCPU, 6 GB RAM, 64 GB Disk, gắn card mạng ở chế độ Host-only, kiểm tra phiên bản qua `winver` và tạo snapshot sạch ban đầu `LAB3_CLEAN_20260914`[cite: 1].
2. **Khởi tạo thư mục:** Tạo cấu trúc thư mục làm việc `C:\LAB3` gồm `Evidence`, `Tools`, `Downloads`, `Assets` và ghi nhận mốc thời gian bắt đầu `start_time.txt`[cite: 1].
3. **Giải nén dữ liệu lab:** Chép tệp `LAB3_Threats_Assets.zip` vào `C:\LAB3\Downloads`, kiểm tra mã hash SHA-256 và giải nén vào thư mục `C:\LAB3` để tạo `lab3_assets`[cite: 1].
4. **Cài đặt công cụ:** Cài đặt Python 3.14.7, Wireshark 4.6.8, giải nén bộ Sysinternals (Sysmon, Autoruns, Process Explorer) vào `C:\LAB3\Tools` và kiểm tra phiên bản[cite: 1].
5. **Thu thập Baseline ban đầu:** Xuất trạng thái ban đầu của hệ điều hành, Defender, Firewall, cấu hình mạng và danh sách tiến trình vào thư mục `C:\LAB3\Evidence`[cite: 1]:
   - `baseline_os.txt`[cite: 1]
   - `baseline_defender.txt`[cite: 1]
   - `baseline_firewall.txt`[cite: 1]
   - `baseline_network.txt`[cite: 1]
   - `baseline_processes.txt`[cite: 1]

---

## 3. Tiến độ thực hiện & Kết quả đánh giá (PASS / FAIL)

| Nội dung / Tình huống | Phạm vi thực hiện | Kết quả | Ghi chú & Minh chứng |
| :--- | :--- | :---: | :--- |
| **0. Baseline** | Thu thập trạng thái Defender, Firewall, Process, Network trước khi thao tác | **PASS** | Đầy đủ 5 file text và ảnh `H3_Baseline_Defender_Firewall.png`[cite: 1]. |
| **TH1: Risk Register & Nguồn đe dọa** | Lập bảng Risk Register 5 tài sản; phân loại 5 tình huống nguồn đe dọa | **PASS** | Hoàn thành trong báo cáo Word theo chuẩn Asset → Vulnerability → Threat → Risk → Control[cite: 1]. |
| **TH2: Mã độc (EICAR)** | Kiểm chứng Real-time Protection bằng chuỗi EICAR an toàn | **PASS** | Defender phát hiện và ngăn chặn tức thì; log `defender_eicar.txt` và ảnh `H4_ProtectionHistory_EICAR.png`[cite: 1]. |
| **TH3: Mật khẩu & Keylogging** | Bật Audit Logon, tạo `lab3user`, sinh log 4624/4625/4648, xoay vòng mật khẩu | **PASS** | Xác thực thành công/thất bại có kiểm soát; vô hiệu hóa credential cũ; lưu `auth_events_before_rotation.txt` và ảnh `H5_Event4625.png`[cite: 1]. |
| **TH4: Backdoor & Persistence** | Nhận diện Scheduled Task, Registry Run và Listener 8080 | *Chưa thực hiện* | Dừng lại do hết thời gian làm bài; chưa cài Sysmon và HTTP listener[cite: 1]. |
| **TH5: Sniffing / MITM / Spoofing** | Bắt gói HTTP loopback vs HTTPS TLS qua Wireshark | *Chưa thực hiện* | Dừng lại do hết thời gian làm bài[cite: 1]. |
| **TH6: DoS / DDoS / Mail Bombing** | Chạy local load test và phân tích tập dữ liệu offline | *Chưa thực hiện* | Dừng lại do hết thời gian làm bài[cite: 1]. |
| **TH7: Social Engineering** | Phân tích mẫu `phishing_email.txt` và phân loại kịch bản | *Chưa thực hiện* | Dừng lại do hết thời gian làm bài[cite: 1]. |

---

## 4. Các sự cố kỹ thuật gặp phải và biện pháp khắc phục

Trong quá trình thực hành từ bước Baseline đến Tình huống 3, hệ thống xuất hiện một số lỗi cú pháp và xác thực, đã được xử lý cụ thể như sau:

1. **Lỗi tham số `Path` khi khởi tạo thư mục (`New-Item`):**
   - *Hiện tượng:* Lệnh bị ngắt dòng do ký tự backtick (`` ` ``) dẫn đến lỗi `Cannot bind argument to parameter 'Path' because it is an empty array`[cite: 2].
   - *Khắc phục:* Gộp toàn bộ tham số đường dẫn trên cùng một dòng lệnh liên tục[cite: 1].
2. **Lỗi giải nén tệp `Expand-Archive`:**
   - *Hiện tượng:* Tham số `-DestinationPath` bị tách rời giá trị `C:\LAB3` do dán lệnh ngắt dòng[cite: 3].
   - *Khắc phục:* Thực thi lệnh trên một dòng duy nhất: `Expand-Archive -Path C:\LAB3\Downloads\LAB3_Threats_Assets.zip -DestinationPath C:\LAB3 -Force`[cite: 1].
3. **Lỗi cú pháp kích hoạt kiểm toán (`auditpol`):**
   - *Hiện tượng:* Chạy lệnh `auditpol` với cặp ngoặc nhọn `{GUID}` không bọc nháy kép khiến PowerShell nhận diện sai tham số, xuất hiện lỗi `Error 0x00000057: The parameter is incorrect`[cite: 4].
   - *Khắc phục:* Gọi trực tiếp tên subcategory bằng cú pháp: `auditpol /set /subcategory:"Logon" /success:enable /failure:enable`[cite: 1].
4. **Lỗi bộ đệm bàn phím khi nhập mật khẩu qua `runas`:**
   - *Hiện tượng:* Thao tác dán (paste) hoặc nhấn Enter sớm khi `runas` yêu cầu mật khẩu gây ra lỗi `RUNAS ERROR: Unable to acquire user password`[cite: 5].
   - *Khắc phục:* Đặt lại mật khẩu rõ ràng bằng lệnh `net user lab3user <password>`, sau đó gõ trực tiếp từng ký tự mật khẩu từ bàn phím khi terminal nhắc[cite: 1].

---

## 5. Danh mục minh chứng và Băm toàn vẹn (SHA-256)

Trước khi đóng gói thư mục nộp bài, toàn bộ các tệp nhật ký và hình ảnh minh chứng trong thư mục `C:\LAB3\Evidence` được tính toán mã hash SHA-256 và lưu vào file `evidence_sha256.csv`[cite: 1]:

- Lệnh thực thi xuất mã hash[cite: 1]:
  ```powershell
  Get-ChildItem C:\LAB3\Evidence -File | Get-FileHash -Algorithm SHA256 | Export-Csv C:\LAB3\Evidence\evidence_sha256.csv -NoTypeInformation -Encoding UTF8