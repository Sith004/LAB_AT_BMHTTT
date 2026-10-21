LAB 7 - pfSense Web Protection - NHAT KY THUC HIEN VA TIEN DO (PROGRESS LOG)

Sinh vien thuc hien: Nguyen Trong The
MSSV: 1150080117
Tien do: Da hoan thanh Giai doan Chuan bi, Cau hinh he thong va Kich ban kiem thu 1 den 5.

I. TONG QUAN KIEN TRUC VA TAI NGUYEN DA TRIEN KHAI
1) pfSense-Lab6:
   - Dong vai tro Gateway/Firewall L3/L4, chong bypass proxy va kiem soat Schedule.
   - LAN: 10.6.0.1/24, DMZ: 172.16.6.1/24, MGMT: 192.168.56.254/24.
2) WEB-PROXY (Tao moi):
   - Ubuntu Server 24.04 LTS, IP 10.6.0.30/24, GW 10.6.0.1, DNS 10.6.0.10.
   - Cai dat: Squid (:3128 upstream) + E2Guardian (:8080 listening) + ClamAV Daemon.
   - Da lien ket ClamAV scanner socket (/var/run/clamav/clamd.ctl) vao E2Guardian.
3) DC01:
   - Windows Server 2025 (10.6.0.10), AD/DNS Server.
   - Da khoi tao Zone lab7.test voi cac ban ghi A va ban ghi Wildcard (*) tro ve 172.16.6.10.
4) DMZ-WEB:
   - Ubuntu Server (172.16.6.10), da chay script setup_lab7_dmz_web.sh tao 13 Virtual Hosts.
5) Client-A:
   - Windows 11 (10.6.0.21), da cau hinh Manual Proxy tro ve 10.6.0.30:8080.

II. CAU HINH CHINH SACH VA RULES DA HOAN TAT
1) pfSense (Ep luong qua Proxy va Chong Bypass direct):
   - Tao Aliases: LAB7_CLIENTS (10.6.0.21, 10.6.0.22), LAB7_PROXY (10.6.0.30), WEB_PORTS (80, 443), MAIL_PORTS.
   - Ruleset tren LAN:
     + Rule 1 (Pass): LAN net -> 10.6.0.10 port 53 (DNS).
     + Rule 2 (Pass): LAB7_CLIENTS -> LAB7_PROXY port 8080 (Client dung Proxy).
     + Rule 3 (Pass): LAN net -> Any port MAIL_PORTS.
     + Rule 4 (Block): LAB7_CLIENTS -> Any port WEB_PORTS (Chong bypass di thang 80/443).
     + Rule 5 (Pass): LAB7_PROXY -> Any port WEB_PORTS (Proxy ra Internet).
     + Rule 6 (Pass): LAB7_PROXY -> 172.16.6.10 port 80 (Proxy sang DMZ test).
     + Rule 7 (Block): LAN net -> Any Any (Default Deny).
   - Da Reset States tren pfSense de ap dung rule moi.
2) WEB-PROXY (Squid & E2Guardian):
   - Squid: Chi lang nghe 127.0.0.1:3128, cap quyen localhost, gioi han reply_body_max_size 100 MB.
   - E2Guardian (/etc/e2guardian/e2guardian.conf):
     + Lang nghe 10.6.0.30:8080, day upstream ve 127.0.0.1:3128.
     + Bat contentscanner clamdscan.
   - Filter Group 1 (/etc/e2guardian/e2guardianf1.conf):
     + bypass = 300 (Thoi gian mo tam 5 phut = 300 giay).
     + bypasskey = 'lab7secretkey' (Khoa ma hoa link bypass URL).
     + reportinglevel = 3 (Che do hien thi giao dien HTML day du).
   - Danh sach loc (/etc/e2guardian/lists/):
     + bannedsitelist: china.lab7.test, mideast.lab7.test, jobs.lab7.test, blockedgame.lab7.test, weapons.lab7.test, politics.lab7.test, religion.lab7.test, streaming.lab7.test.
     + exceptionsitelist: normal.lab7.test, education.lab7.test, download.lab7.test.

III. KET QUA THUC HIEN CAC KICH BAN KIEM THU (TEST SCENARIOS)
1) Kich ban 1 (Baseline & Anti-Bypass):
   - Khi Client-A bat proxy 10.6.0.30:8080: Truy cap http://normal.lab7.test thanh cong (200 OK).
   - Khi Client-A tat proxy: curl.exe http://normal.lab7.test bi timeout (pfSense Rule 4 chan).
   - WEB-PROXY curl ra web thanh cong; Firewall log pfSense ghi nhan icon X do chan direct 80.
2) Kich ban 2 (Geo-Sim China & Middle East - Hard Block):
   - Client-A truy cap china.lab7.test va mideast.lab7.test -> Bi E2Guardian chan Access Denied lap tuc.
   - Trang chan tuyet doi khong co nut bypass. Log Proxy ghi nhan *DENIED*.
3) Kich ban 3 (Job Search - Hard Block):
   - Client-A truy cap jobs.lab7.test -> Bi Hard Block boi E2Guardian. Log ghi nhan *DENIED*.
4) Kich ban 4 (Warning / Temporary Bypass):
   - Client-A truy cap weapons.lab7.test va politics.lab7.test -> Hien trang canh bao kem lien ket 'Acknowledge'.
   - Nguoi dung click vao 'Acknowledge' -> Website mo ra thanh cong trong khung thoi gian 5 phut (300s).
5) Kich ban 5 (Education - Whitelist / Exception):
   - Client-A truy cap education.lab7.test -> Vao thang web binh thuong, khong canh bao.
   - Log E2Guardian ghi nhan the *EXCEPTION*.

IV. NHAT KY XU LY SU CO THUC TE (TROUBLESHOOTING LOG)
1) Loi sai chinh ta ten service:
   - Lenh systemctl bao loi "Unit clamav-deamon not found" do go nham "ea" -> Da sua thanh "clamav-daemon".
2) Hien tuong khong ping duoc 10.6.0.1 tu Client-A:
   - Xac dinh do Rule 7 tren pfSense (Default Deny) chan ICMP. Kiem tra dich vu thuc te bang Test-NetConnection 10.6.0.30 -Port 8080 van tra ve True.
3) Loi curl: (6) Could not resolve host tren WEB-PROXY:
   - Nguyen nhan: systemd-resolved tren Ubuntu 24.04 mac dinh chua tro DNS ve DC01.
   - Khac phuc: Chay resolvectl dns de gan 10.6.0.10 va flush-caches.
4) Loi site bi treo hoac bao "The site requested is not responding":
   - Phat hien sai chinh ta "waepons.lab7.test" trong bannedsitelist khien proxy khong nhan dien duoc site canh bao.
   - Phat hien DNS tren DC01 bi thieu record rieng le -> Da khac phuc triet de bang cach them ban ghi Wildcard (*) trong zone lab7.test tro ve 172.16.6.10.
5) Khac phuc khong hien nut Bypass:
   - Kich hoat bypass = 300, bypasskey = 'lab7secretkey', reportinglevel = 3 trong e2guardianf1.conf.
   - Xac dinh nut bypass thuc te hien thi duoi dang chu 'Acknowledge' theo ma nguon template.html.

V. CAC BUOC KE TIEP (NEXT STEPS)
- Trien khai Kich ban 6: Entertainment/Games theo lich bieu Schedule 60 phut tren pfSense.
- Kich ban 7 & 8: Streaming Video canh bao va Blocked Game.
- Kich ban 9: Quet ma doc file test EICAR bang ClamAV content scanning.
- Kich ban 10: Gioi han dung luong file > 100MB qua Squid ACL.
- Hoan thien tra loi 10 cau hoi phan tich ly thuyet trong bao cao.