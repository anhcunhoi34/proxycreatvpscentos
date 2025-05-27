#!/bin/bash

# ========== ⚙️ Cấu hình ==========
PORT=8989
USERS=("user1:pass1" "user2:pass2" "anhcunhoi35:anhcunhoi35")

# ========== 🧱 Cài gói cần thiết ==========
yum install -y gcc make pam-devel libtool automake curl tar iptables-services

# ========== ⬇️ Tải và biên dịch Dante ==========
cd /tmp
curl -O https://www.inet.no/dante/files/dante-1.4.2.tar.gz
tar zxvf dante-1.4.2.tar.gz
cd dante-1.4.2
./configure
make
make install

# ========== 🧑‍🔧 Tạo user đăng nhập ==========
for i in "${USERS[@]}"; do
  USERNAME=$(echo $i | cut -d':' -f1)
  PASSWORD=$(echo $i | cut -d':' -f2)
  useradd -M -s /sbin/nologin $USERNAME 2>/dev/null
  echo "$USERNAME:$PASSWORD" | chpasswd
done

# ========== ⚙️ Tạo file cấu hình /etc/sockd.conf ==========
IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
cat <<EOF > /etc/sockd.conf
logoutput: /var/log/sockd.log
internal: 0.0.0.0 port = $PORT
external: $IFACE
method: username
user.notprivileged: nobody

client pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: connect disconnect
}

pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  protocol: tcp udp
  method: username
  log: connect disconnect
}
EOF

# ========== 🔧 Tạo service systemd ==========
cat <<EOF > /etc/systemd/system/sockd.service
[Unit]
Description=Dante SOCKS5 Proxy Server
After=network.target

[Service]
ExecStart=/usr/local/sbin/sockd -f /etc/sockd.conf
User=nobody

[Install]
WantedBy=multi-user.target
EOF

# ========== 🔥 Mở port với iptables ==========
iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
service iptables save
systemctl enable iptables
systemctl restart iptables

# ========== 🚀 Khởi động Dante ==========
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable sockd
systemctl restart sockd

# ========== ✅ Hoàn tất ==========
echo -e "\n✅ SOCKS5 Proxy đã sẵn sàng!"
echo "➡ IP VPS: $(curl -s ifconfig.me)"
echo "➡ Port: $PORT"
echo "➡ User đăng nhập:"
for i in "${USERS[@]}"; do
  echo "   - $i"
done
