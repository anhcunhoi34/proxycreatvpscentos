Upload file proxy lên root VPS
Chạy lệnh sau:
------------------------------
yum install dos2unix -y
dos2unix install_proxy.sh
chmod +x install_proxy.sh
sudo ./install_proxy.sh
------------------------------
Cài Dante Socks
-----------------------------------------------------------
cd /tmp
curl -O https://repo.ius.io/ius-release-el7.rpm
yum install -y gcc make rpm-build
yum install -y libtool automake gcc-c++ pam-devel

# Cài Dante từ source (phiên bản open-source 1.4.2)
curl -O https://www.inet.no/dante/files/dante-1.4.2.tar.gz
tar zxvf dante-1.4.2.tar.gz
cd dante-1.4.2

./configure
make
make install
nano /etc/systemd/system/sockd.service
-----------------------------------------------------------
Copy nội dung
[Unit]
Description=Dante SOCKS5 Server
After=network.target

[Service]
ExecStart=/usr/local/sbin/sockd -f /etc/sockd.conf
User=nobody

[Install]
WantedBy=multi-user.target
-----------------------------------------------------------
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable sockd
systemctl restart sockd
-----------------------------------------------------------
Open Firewall
iptables -I INPUT -p tcp --dport 8989 -j ACCEPT
service iptables save
