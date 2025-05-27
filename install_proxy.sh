#!/bin/bash

# === 🔧 CẤU HÌNH TÙY CHỈNH ===
PORT=8989  # ⚠️ Thay đổi port tại đây
USERS=("anhcunhoi35:anhcunhoi35")  # ⚠️ Thêm/sửa user tại đây

# === 🛠️ Cài đặt Dante SOCKS5 ===
yum install epel-release -y
yum install dante-server -y

# Backup cấu hình cũ nếu có
mv /etc/sockd.conf /etc/sockd.conf.bak 2>/dev/null

# Lấy tên interface mạng (ví dụ eth0)
IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

# Ghi file cấu hình sockd.conf mới
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

# === 👤 Tạo user proxy ===
for i in "${USERS[@]}"; do
  USERNAME=$(echo $i | cut -d':' -f1)
  PASSWORD=$(echo $i | cut -d':' -f2)
  useradd -M -s /sbin/nologin $USERNAME 2>/dev/null
  echo "$USERNAME:$PASSWORD" | chpasswd
done

# === 🔓 Mở port firewall ===
firewall-cmd --permanent --add-port=${PORT}/tcp
firewall-cmd --reload

# === ▶️ Khởi động dịch vụ ===
systemctl enable sockd
systemctl restart sockd

# === ✅ Hiển thị thông tin ===
echo "✅ SOCKS5 Proxy đã sẵn sàng!"
echo "➡ IP VPS của bạn: $(curl -s ifconfig.me)"
echo "➡ Port: $PORT"
echo "➡ Danh sách user:"
for i in "${USERS[@]}"; do
  echo "   - $i"
done