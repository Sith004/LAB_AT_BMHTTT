   - Nguyen nhan: Sinh vien go nham dai dia chi "10.9.0.10/24" (IP may) thay vi "10.9.0.0/24" (dia chi mang) trong danh sach ACL allow-query/recursion.
   - Khac phuc: Sua lai thanh "10.9.0.0/24;" va khoi dong lai service thanh cong.
5) Script auth_dns_relay_lab10.py bao loi "OSError: [Errno 99] Cannot assign requested address":
   - Trieu chung: Chay script tren DMZ_WEB bi vang loi socket bind.
   - Nguyen nhan: Dia chi IP alias 172.16.6.20 bi mat sau khi may ao Ubuntu khoi dong lai.
   - Khac phuc: Chay lenh "sudo ip addr add 172.16.6.20/24 dev ens33" de tao lai IP ao cho may chu DNS Authoritative.
6) WEB-PROXY khong ket noi duoc sang 172.16.6.20 ("Host unreachable"):
   - Trieu chung: Truy van dig tu WEB-PROXY toi 172.16.6.20 bi loi unreachable.
   - Nguyen nhan: Bang dinh tuyen cua WEB-PROXY van luu entry cu "172.16.6.0/24 via 10.6.0.1".
   - Khac phuc: Cap nhat lai route qua gateway moi: "sudo ip route replace 172.16.6.0/24 via 10.9.0.1 dev ens33".
7) Truy van dig bao loi "status: SERVFAIL" (EDE: 22 - No Reachable Authority):
   - Trieu chung: Truy van baseline bi tra ve SERVFAIL du script relay da chay.
   - Nguyen nhan: Trong file auth_dns_relay_lab10.py go nham dong kiem tra "if addr[0] != RESOLVER_PORT: continue" thay vi kiem tra IP "if addr[0] != RESOLVER: continue", lam relay bo qua toan bo query hop le.
   - Khac phuc: Sua bien kiem tra dung thanh RESOLVER, dig lap tuc tra ve NOERROR cung IP 172.16.6.10.
8) Kali chay attack script bao loi "trigger reply timed out / NOT YET":
   - Trieu chung: Kali gui hang loat batch guesses nhung ben relay khong co log HIT, attack bao NOT YET.
   - Nguyen nhan: Tren pfSense tab ATTACKNET, luat cho phep ket noi toi 172.16.6.20 port 5300 bi chon nham giao thuc "IPv4 TCP" trong khi script relay lang nghe tren "UDP".
   - Khac phuc: Chinh sua Protocol cua rule tren pfSense thanh "IPv4 UDP" (hoac "TCP/UDP") va Apply Changes. Ngay lap tuc relay ghi nhan [HIT] va Kali bao [SUCCESS].
9) Lenh tcpdump tren WEB-PROXY bao loi "tcpdump: can't parse filter expression: syntax error":
   - Trieu chung: Chay "sudo tcpdump -ni any host 172.16.6.20 udp port 53" bi bao loi cu phap filter.
   - Nguyen nhan: Thieu toan tu logic "and" giua menh de chi dinh host va port.
   - Khac phuc: Bo sung tu khoa "and" va boc trong dau ngoac kep: 'sudo tcpdump -ni any "host 172.16.6.20 and udp port 53"'.