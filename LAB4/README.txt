LAB 4 -- KHẢO SÁT VÀ ĐÁNH GIÁ BỀ MẶT MẠNG BẰNG NMAP

1. Thông tin sinh viên

Họ và tên: Nguyễn Trọng Thể

MSSV: 1150080117

Môn học: An toàn hệ thống thông tin

Bài thực hành: Lab 4 -- Khảo sát và đánh giá bề mặt mạng bằng
Nmap

2. Nội dung Lab

Lab thực hành khảo sát và đánh giá bề mặt mạng trong một môi trường mạng
ảo được cô lập bằng Host-Only.

Các nội dung theo tài liệu Lab gồm:

Cài đặt và kiểm tra Nmap trên Kali/Windows.

Thiết lập mạng Host-Only cho các máy ảo.

Xác định địa chỉ IP và subnet mask của các thiết bị.

Kiểm tra kết nối giữa máy quét và máy đích.

Thực hiện Host Discovery bằng Nmap.

Thực hiện các kỹ thuật TCP/UDP scan.

Phát hiện phiên bản dịch vụ và hệ điều hành.

Khảo sát bằng một số NSE script.

Lưu và sử dụng kết quả quét làm minh chứng.

Phân tích kết quả và đánh giá bề mặt mạng trong môi trường lab.

Phạm vi thực hành chỉ giới hạn trong mạng Host-Only và các máy ảo được
sử dụng cho bài lab.

3. Môi trường thực hành

Mạng Host-Only được cấu hình sử dụng subnet:

Network:     192.168.66.0/24
Subnet Mask: 255.255.255.0

Danh sách thiết bị

Thiết bị          IP thực tế        Subnet Mask       Vai trò

Windows Host      192.168.66.1      255.255.255.0     Host

Kali VM           192.168.66.133    255.255.255.0     Máy quét

Metasploitable 2  192.168.66.134    255.255.255.0     Máy đích

Sơ đồ logic

                 Host-Only / VMnet1
                    192.168.66.0/24
                           |
        +------------------+------------------+
        |                  |                  |
   Windows Host         Kali VM        Metasploitable 2
   192.168.66.1       192.168.66.133      192.168.66.134
                           |
                           |
                    Windows VM (11)
                     192.168.66.132

4. Kết quả thực hiện

4.1. Kiểm tra cấu hình Kali

Kali được cấu hình trên mạng Host-Only và nhận địa chỉ:

IP:           192.168.66.133
Subnet Mask:  255.255.255.0
CIDR:         /24
Network:      192.168.66.0/24
Broadcast:    192.168.66.255

Kiểm tra bằng:

ip -br addr

và:

ip route

Kết quả xác nhận card mạng eth0 sử dụng địa chỉ 192.168.66.133/24.

4.2. Kiểm tra Metasploitable 2

Metasploitable 2 được cài đặt và kết nối vào cùng mạng Host-Only.

Địa chỉ IP:

192.168.66.134/24

Kiểm tra bằng:

ifconfig

hoặc:

ip addr

4.3. Kiểm tra kết nối Kali → Metasploitable 2

Từ Kali thực hiện:

ping -c 4 192.168.66.134

Kết quả: Kali kết nối được với Metasploitable 2.

Điều này xác nhận máy quét và máy đích chính của bài lab đang hoạt động
trên cùng mạng Host-Only.

4.4. Windows VM

Windows VM được cấu hình:

IP:           192.168.66.132
Subnet Mask:  255.255.255.0

Tuy nhiên, tại thời điểm thực hành, Kali không nhận được phản hồi ICMP
từ Windows VM:

4 packets transmitted, 0 received, 100% packet loss

Windows VM được thiết lập Network Profile ở chế độ Private và đã bật
rule:

File and Printer Sharing (Echo Request - ICMPv4-In)

Nhưng vẫn chưa xác nhận được kết nối ICMP hai chiều.

Trạng thái: Chưa xử lý tiếp vì Windows VM không phải máy đích chính
cần hoàn thành trong phiên thực hành này.

4.5. Bắt đầu Host Discovery bằng Nmap

Trên Kali đã thực hiện lệnh:

sudo nmap -sn 192.168.66.0/24

Mục đích của lệnh là phát hiện các host đang hoạt động trong mạng
192.168.66.0/24.

Sau đó thử sử dụng timing nhanh hơn:

sudo nmap -sn -T4 192.168.66.0/24

Tại thời điểm kết thúc buổi thực hành, quá trình Host Discovery chưa
hoàn tất và chưa có kết quả quét đầy đủ để kết luận danh sách host hoạt
động.

Trạng thái: Đã bắt đầu thực hiện nhưng chưa hoàn thành.

5. Các lệnh đã sử dụng

Kali -- kiểm tra IP

ip -br addr

Kali -- kiểm tra route

ip route

Kali -- kiểm tra kết nối Metasploitable 2

ping -c 4 192.168.66.134

Nmap -- Host Discovery

sudo nmap -sn 192.168.66.0/24

Nmap -- Host Discovery với timing nhanh hơn

sudo nmap -sn -T4 192.168.66.0/24

6. Minh chứng

Các minh chứng đã thực hiện trong buổi lab gồm:

Cấu hình IP của Kali.

Cấu hình IP của Metasploitable 2.

Bảng địa chỉ IP và subnet mask của môi trường lab.

Kết quả ping từ Kali đến Metasploitable 2.

Cấu hình IP của Windows VM.

Kết quả kiểm tra kết nối Kali đến Windows VM.

Quá trình thực hiện lệnh Nmap Host Discovery.

Ảnh chụp màn hình được lưu cùng thư mục Lab để sử dụng khi cần đối chiếu
hoặc viết báo cáo.

7. Kết quả tổng kết

Nội dung                   Trạng thái

Thiết lập mạng Host-Only   Hoàn thành
Kali VM                    Hoàn thành
Metasploitable 2           Hoàn thành
Xác định IP/subnet         Hoàn thành
Kali → Metasploitable 2    Ping thành công
Windows VM                 Đã cấu hình
Kali → Windows VM          Chưa kết nối được bằng ICMP
Host Discovery -sn       Đã thực hiện, chưa hoàn tất
TCP/UDP scan               Chưa thực hiện
Service detection -sV    Chưa thực hiện
OS detection -O          Chưa thực hiện
NSE script                 Chưa thực hiện
Export kết quả Nmap        Chưa thực hiện

8. Ghi chú khi chạy lại

Khởi động môi trường

Khởi động Kali VM.

Khởi động Metasploitable 2.

Đảm bảo các máy sử dụng mạng Host-Only/VMnet1.

Kiểm tra IP bằng:

ip -br addr

trên Kali và:

ifconfig

trên Metasploitable 2.

Kiểm tra kết nối

Từ Kali:

ping -c 4 192.168.66.134

Nếu ping thành công thì có thể tiếp tục các bước Nmap.

Host Discovery

sudo nmap -sn 192.168.66.0/24

Nếu cần tăng tốc độ trong mạng lab:

sudo nmap -sn -T4 192.168.66.0/24

Lưu ý

Chỉ thực hiện quét trong mạng Host-Only của bài lab.

Không sử dụng các lệnh quét trên hệ thống hoặc mạng không được phép.

Khi hoàn thành từng nội dung, cần lưu ảnh chụp màn hình và kết quả
lệnh để làm minh chứng.

Các bước TCP/UDP scan, service detection, OS detection và NSE chưa
được thực hiện trong phiên lab này.

9. Trạng thái cuối buổi

Môi trường Lab 4 đã được thiết lập và máy quét Kali đã kết nối thành
công với máy đích Metasploitable 2.

Phần còn lại sẽ tiếp tục từ Host Discovery bằng Nmap, sau đó thực
hiện các kỹ thuật TCP/UDP scan, phát hiện dịch vụ, phát hiện hệ điều
hành và NSE theo nội dung của Lab 4.