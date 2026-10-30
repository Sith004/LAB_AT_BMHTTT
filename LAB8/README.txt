LAB 8 - DNS Attack & Cache Poisoning - NHAT KY THUC HIEN VA TIEN DO (PROGRESS LOG)

Sinh vien thuc hien: Nguyen Trong The
MSSV: 1150080117
Link video minh chung (Youtube): https://youtu.be/n0DWS6oWaTU
Tien do: Da hoan thanh toan bo cac Task kiem thu (Task 1, Task 2, Task 3) va hoan thien 10 cau hoi phan tich chuyen sau.

I. TONG QUAN KIEN TRUC VA TAI NGUYEN DA TRIEN KHAI
1) pfSense-Lab6:
   - Dong vai tro Gateway/Firewall L3/L4, kiem soat phan vung mang va dinh tuyen.
   - Khoi tao Interface moi "DNSLAB" (Subnet: 10.9.0.0/24, Gateway IP: 10.9.0.1/24) nham co lap hoan toan moi truong tan cong, bao ve vung mang Active Directory tren LAN (10.6.0.0/24).
   - Cac interface lien quan: DMZ (172.16.6.1/24), LAN (10.6.0.1/24), MGMT (192.168.56.254/24).
2) DNS-SERVER (Local Recursive & Caching Resolver):
   - Ubuntu Server 24.04 LTS (tan dung tu may WEB-PROXY), IP 10.9.0.10/24, GW 10.9.0.1.
   - Cai dat: BIND9 (named, bind9utils, dnsutils).
   - Quan ly Forward zone "lab9.test" va Reverse zone "9.10.in-addr.arpa".
   - Dong vai tro Local Caching Resolver chuyen tiep truy van ra Authoritative DNS ngoai DMZ.
3) DMZ-WEB & Simulated Authoritative DNS (Phan vung DMZ):
   - DMZ-WEB: Ubuntu Server (172.16.6.10), chay Web Nginx hop le (www.lab9.test, www.external.lab9.test).
   - Simulated Authoritative DNS: IP 172.16.6.20, nam giu ban ghi goc hop le cua ten mien external.lab9.test.
4) VICTIM (May nan nhan):
   - Ubuntu Desktop/Server, IP 10.9.0.100/24, GW 10.9.0.1, DNS tro ve Resolver 10.9.0.10.
   - Su dung curl, getent hosts, dig de kiem thu phan giai va truy cap web.
5) ATTACKER (May tan cong gia lap):
   - Ubuntu Server/Desktop, IP 10.9.0.200/24 tren cung dải 10.9.0.0/24.
   - Card mang VirtualBox dat che do Promiscuous Mode = "Allow VMs" (hoac "Allow All"), bat promisc on tren enp0s3.
   - Chay Web server gia lap bang Python: python3 -m http.server 80 tra ve "<h1>FAKE SITE 10.9.0.200</h1>".
   - Chay cac script Python Raw Socket (spoof.py, p3.py) de sniff DNS query va inject DNS response gia mao.

II. CAU HINH CHINH SACH VA RULES DA HOAN TAT
1) pfSense (Kiem soat va co lap phan vung DNSLAB):
   - Cau hinh Ruleset tren Interface DNSLAB:
     + Rule 1 (Pass): IPv4 TCP/UDP | Source: 10.9.0.10 -> Destination: 172.16.6.20 port 53 (DNS) [DNS resolver truy van de quy sang simulated authoritative DNS].
     + Rule 2 (Pass): IPv4 TCP | Source: 10.9.0.0/24 -> Destination: 172.16.6.10 port 80 (HTTP) [Victim truy cap website hop le trong DMZ].
     + Rule 3 (Block): IPv4 * | Source: DNSLAB subnets -> Destination: 10.6.0.0/24 [Protect LAB8 LAN-DOMAIN, chong pha hoai Active Directory DC01].
     + Rule 4 (Block): IPv4 * | Source: DNSLAB subnets -> Destination: 192.168.56.0/24 [Protect MGMT].
     + Rule 5 (Block): IPv4 * | Source: DNSLAB subnets -> Destination: * [Default isolation for attack phase - chan toan bo luong di thang ra ngoai].
2) BIND9 tren DNS-SERVER (10.9.0.10):
   - Cau hinh /etc/bind/named.conf.local:
     + zone "lab9.test" { type master; file "/etc/bind/db.lab9.test"; };
     + zone "9.10.in-addr.arpa" { type master; file "/etc/bind/db.10.9.0"; };
   - Cau hinh file zone /etc/bind/db.lab9.test:
     + Ban ghi SOA, NS ns.lab9.test.
     + Ban ghi A: ns (10.9.0.10), www (172.16.6.10), portal (172.16.6.10), victim (10.9.0.100), attacker (10.9.0.200).
   - Cau hinh de quy / chuyen tiep cho phep phan giai ten mien external.lab9.test sang 172.16.6.20.
3) Script tan cong Raw Socket tren ATTACKER:
   - Su dung AF_PACKET (SOCK_RAW) voi protocol 768 (ETH_P_ALL) de bat goi tin tren switch ao L2.
   - Su dung AF_INET (SOCK_RAW, IPPROTO_RAW) de dong goi IP/UDP/DNS thu cong.
   - Script Task 2 (spoof.py): Bat goi DNS query tu Victim (10.9.0.100), gui phan hoi gia voi IP nguon la 10.9.0.10, TXID tuong ung, flags 0x8180, A record tra ve 10.9.0.200.
   - Script Task 3 (p3.py): Bat goi DNS query tu Resolver (10.9.0.10) gui sang 172.16.6.20, gui phan hoi gia voi IP nguon la 172.16.6.20, flags 0x8400 (Authoritative), A record 10.9.0.200 toi 10.9.0.10:53 de dau doc cache.

III. KET QUA THUC HIEN CAC KICH BAN KIEM THU (TEST SCENARIOS)
1) Task 1 (Can thiep cuc bo qua /etc/hosts - Local DNS Tampering):
   - Thuc hien tren Victim: echo "10.9.0.200 www.lab9.test" | sudo tee -a /etc/hosts.
   - Kiem tra phan giai bang getent hosts www.lab9.test -> Tra ve 10.9.0.200.
   - Kiem tra truy cap: curl http://www.lab9.test -> Nhan noi dung trang gia "<h1>FAKE SITE 10.9.0.200</h1>".
   - Kiem tra doi chung: dig @10.9.0.10 www.lab9.test -> Van tra ve IP goc 172.16.6.10 do dig bo qua file hosts va truy van truc tiep toi DNS Server qua UDP/53.
   - Phuc hoi: sudo sed -i '/10.9.0.200/d' /etc/hosts -> getent hosts tro lai 172.16.6.10.
2) Task 2 (Tan cong gia mao DNS truc tiep danh lua Victim - Direct DNS Spoofing):
   - Attacker bat promisc tren enp0s3 va chay script sudo python3 spoof.py.
   - Victim truy van: dig @10.9.0.10 www.external.lab9.test.
   - Script tren Attacker danh chan goi tin, lap tuc inject phan hoi gia mao voi IP nguon 10.9.0.10, A record 10.9.0.200.
   - Ket qua tren Victim: Nhan ve ban ghi A 10.9.0.200 trong vong 2 ms (nhanh hon phan hoi that tu server ngoai).
   - Victim truy cap curl http://www.external.lab9.test bi dieu huong toi FAKE SITE cua Attacker.
   - Pham vi anh huong: Chi danh lua duy nhat may Victim tai thoi diem do, bo nho cache cua BIND9 tren DNS-SERVER van khong bi anh huong.
3) Task 3 (Dau doc bo nho dem DNS Resolver - DNS Cache Poisoning):
   - Attacker cau hinh p3.py nham vao DNS Resolver: Gia mao IP nguon 172.16.6.20, dich 10.9.0.10, flags 0x8400 (Authoritative), ban ghi A tro ve 10.9.0.200.
   - Attacker chay sudo python3 p3.py -> He thong hien thi "READY" va lien tuc "SPOOFED".
   - Victim thuc hien dig @10.9.0.10 www.external.lab9.test, Resolver gui request ra ngoai nhung goi tin gia mao cua Attacker den truoc phan hoi hop le cua 172.16.6.20.
   - BIND9 chap nhan goi tin gia va ghi luu vao bo nho dem (cache).
   - Kiem chung tren DNS-SERVER (10.9.0.10):
     + Chay sudo rndc dumpdb -cache.
     + Kiem tra bang sudo grep external /var/cache/bind/named_dump.db:
       Ghi nhan ban ghi doc hai da duoc cache thanh cong: "www.external.lab9.test. 107 IN A 10.9.0.200".
   - Kiem chung tren Victim va cac client khac:
     + Truy van lai dig @10.9.0.10 www.external.lab9.test tra ve ngay 10.9.0.200 voi query time sieu nhanh (5 ms) tu cache ma khong can Attacker phai tiep tuc spoof goi tin.
     + Toan bo client trong mang dung chung resolver 10.9.0.10 deu bi anh huong trong suot thoi gian ton tai cua TTL.

IV. NHAT KY XU LY SU CO THUC TE (TROUBLESHOOTING LOG)
1) Tranh chap tien trinh khoa goi cai dat (apt/dpkg lock):
   - Trieu chung: Khi cai bind9 bao loi "Waiting for cache lock: Could not get lock /var/lib/dpkg/lock-frontend... held by process 2301 (unattended-upgr)".
   - Khac phuc: Do tien trinh unattended-upgrades cua Ubuntu dang chay ngam khi moi boot. Cho 24 giay de tien trinh hoan tat, sau do apt tiep tuc cai dat thanh cong.
2) Loi cu phap lenh dinh tuyen tren Ubuntu:
   - Trieu chung: Go nham lenh "sudo ip route replace default viia 10.9.0.1 dev enp0s3" -> Bao loi "either 'to' is duplicate, or 'viia' is a garbage".
   - Khac phuc: Chinh sua go dung cu phap "via 10.9.0.1".
3) Hien tuong ping pfSense Gateway (10.9.0.1) bi 100% packet loss:
   - Trieu chung: Ping tu 10.9.0.10 toi 10.9.0.1 bi fail hoan toan.
   - Kiem tra: Chay "ip neigh" thay ARP da hoc duoc dia chi MAC 08:00:27:16:5d:c8 cua pfSense -> Ket noi vat ly va Layer 2 hoan toan thong suot. Nguyen nhan do Firewall Rule pfSense tren interface DNSLAB chua cho phep ICMP (Default Deny).
4) Loi chinh ta va cu phap file cau hinh Zone BIND9:
   - May chu khong tim thay file: Do go nham ten file "db.lab9,test" (dau phay) -> Dung lenh mv doi lai thanh "db.lab9.test".
   - Loi thieu dau cham ket thuc FQDN: named-checkzone canh bao "a.alb9.test,,lab9.test: bad name" va "NS 'ns.lab9.test.lab9.test' has no address records" do thieu dau cham cuoi "ns.lab9.test.".
   - Loi sai truong ban ghi: Canh bao "unknown RR type '172.16.6.10'" do thieu dinh nghia "IN A".
   - Loi go nham ten service: "sudo systemctl restart bin9" bao loi unit not found -> Sua thanh "bind9".
   - Khac phuc triet de: Dung sed -i chuan hoa toan bo file zone, kiem tra lai bang named-checkzone cho ket qua "loaded serial 1 OK".
5) Loi cu phap va quyen socket trong script Python spoofing:
   - Loi cu phap: Thieu dau hai cham o menh de "if b'external' in p and p[36:38] == b'\x00\x35';" trong spoof.py -> Da sua bang lenh sed -i 's/;/:/'.
   - Loi khong bat duoc goi tin: Khi dung protocol 0x0800 socket khong nhan dien day du goi tin L2 tren VirtualBox -> Sua thanh 768 (ETH_P_ALL) dong thoi chay "sudo ip link set enp0s3 promisc on" ket hop bat VirtualBox Promiscuous Mode = Allow VMs.
6) Loi Timeout khi phan giai de quy ra DMZ:
   - Trieu chung: Truy van dig @127.0.0.1 www.external.lab9.test ban dau bi timeout do pfSense rule hoac cache cu chua khoi tao.
   - Khac phuc: Kiem tra lai pfSense Rule 1 (cho phep 10.9.0.10 sang 172.16.6.20:53), chay "sudo rndc flush" de lam sach cache va thuc hien truy van lai thanh cong.

V. TRA LOI 10 CAU HOI PHAN TICH CHUYEN SAU VA BIEN PHAP PHONG VE
1. Tai sao /etc/hosts co the anh huong trinh duyet nhung dig @DNS-SERVER van tra ket qua DNS goc?
   - Tra loi: Trinh duyet dung co che phan giai cua he dieu hanh nen luon uu tien doc file /etc/hosts truoc khi gui truy van ra mang. Nguoc lai, lenh dig bo qua hoan toan file hosts va gui goi tin truy van truc tiep toi may chu DNS chi dinh qua cong UDP/53.
2. Nhung truong nao cua DNS/UDP phai khop de mot phan hoi gia co co hoi duoc chap nhan?
   - Tra loi: Goi phan hoi gia bat buoc phai khop chinh xac dia chi IP nguon/dich, cong nguon UDP 53, cong dich UDP ngau nhien cua ben gui, cung chuoi Transaction ID (TXID) 16-bit va noi dung phan cau hoi (Question section).
3. Tai sao Task 2 chi anh huong Victim hien tai, trong khi Task 3 co the anh huong nhieu client dung cung resolver?
   - Tra loi: Task 2 gui phan hoi gia truc tiep den may Victim nen chi danh lua duoc duy nhat ung dung tren may do tai thoi diem truy van. Trong khi do, Task 3 dau doc truc tiep vao bo nho cache cua BIND9 tren DNS-SERVER, khien tat ca cac client khac khi hoi cung ten mien deu se nhan ve IP gia tu cache.
4. Vai tro cua TTL trong cache poisoning la gi?
   - Tra loi: TTL quyet dinh khoang thoi gian ban ghi doc duoc phep luu giu trong bo nho cache cua may chu DNS. TTL cang lon thi thoi gian nan nhan bi dieu huong sang trang web gia mao cang dai ma ke tan cong khong can phai lien tuc gui them goi tin gia.
5. Tai sao VirtualBox Promiscuous Mode = Allow VMs can thiet trong bai nay?
   - Tra loi: Mang ao VirtualBox hoat dong nhu mot switch chuyen mach L2 thong thuong chi gui goi unicast toi dung MAC dich, nen Attacker bat buoc phai bat Promiscuous Mode de co the bat duoc cac goi tin unicast giua Victim va DNS Server nham lay Transaction ID va cong UDP phuc vu tan cong.
6. Vi sao LAB 9 dung mang DNSLAB rieng thay vi tan cong truc tiep DC01 DNS cua LAN-DOMAIN?
   - Tra loi: Mang DNSLAB rieng giup co lap hoan toan moi truong tan cong bang tuong lua pfSense, tranh lam gian doan hay pha hong he thong Active Directory cot loi tren DC01 cua mang LAN-DOMAIN ke thua tu cac bai lab truoc.
7. Khac nhau giua authoritative DNS, recursive resolver va caching resolver?
   - Tra loi: Authoritative DNS nam giu du lieu goc chinh thuc cua mot ten mien, Recursive Resolver dong vai tro trung gian di tim kiem de quy giup client tu cac may chu ben ngoai, con Caching Resolver luu tam ket qua da tim duoc vao bo nho dem de tra loi tuc thi cho cac truy van sau.
8. DNSSEC giai quyet van de gi va vi sao zone .test unsigned trong LAB 9 khong tu duoc bao ve?
   - Tra loi: DNSSEC giai quyet triet de van de gia mao DNS bang chu ky so mat ma de xac thuc tinh toan ven cua phan hoi. Tuy nhien, zone .test trong bai la zone noi bo chua duoc ky so (unsigned), nen BIND9 tu dong coi day la vung du lieu khong an toan thong thuong va chap nhan phan hoi gia ma khong the kiem tra chu ky.
9. Tai sao chi chan UDP/53 la chua du neu muon kiem soat DNS trong mang hien dai?
   - Tra loi: Chi chan UDP/53 la chua du vi DNS hien dai co the tu dong chuyen sang TCP/53 khi du lieu lon, hoac duoc ma hoa hoan toan qua giao thuc DNS over HTTPS (DoH - cong 443), DNS over TLS (DoT - cong 853) khien tuong lua thong thuong khong the nhan dien de ngan chan.
10. Neu toi thieu bon bien phap hardening sau khi hoan thanh bai.
   - Tra loi: Bon bien phap gom:
     + Trien khai DNSSEC bat buoc xac thuc chu ky so tren toan bo he thong DNS.
     + Bat lai va duy tri co che DNS Cookie tren BIND9.
     + Tat Promiscuous Mode tren switch ao ket hop cau hinh DHCP Snooping / Dynamic ARP Inspection (DAI) tren switch L2 de chong nghe len va gia mao IP/MAC noi bo.
     + Toi da hoa viec ngau nhien hoa cong nguon UDP (Source Port Randomization) cung Transaction ID (TXID) 16-bit de vo hieu hoa cac cuoc tan cong do doan goi tin.
