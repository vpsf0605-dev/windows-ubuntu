#!/bin/bash

# ========================================================
# ZUNRDP - FIREBASE AGENT (UBUNTU)
# ========================================================

# 1. Cấu hình Firebase
BASE_URL="https://zunrdp-default-rtdb.asia-southeast1.firebasedatabase.app"
VM_ID="ZUN-UB-$(openssl rand -hex 2 | tr '[:lower:]' '[:upper:]')"
START_TIME=$(date +%s%3N)

echo "------------------------------------------"
echo ">>> DANG KET NOI FIREBASE: $VM_ID"
echo "------------------------------------------"

while true; do
    try {
        # 2. Lấy IP Tailscale (Sử dụng đường dẫn tuyệt đối nếu cần)
        IP=$(/usr/bin/tailscale ip -4 | head -n 1)
        
        # Nếu chưa có IP Tailscale thì đợi
        if [ -z "$IP" ]; then IP="Chờ Tailscale..."; fi

        # 3. Chuẩn bị dữ liệu JSON
        CURRENT_TIME=$(date +%s%3N)
        JSON_DATA=$(cat <<EOF
{
  "id": "$VM_ID",
  "os": "Ubuntu",
  "ip": "$IP",
  "user": "adminzun",
  "pass": "ZunRDP@123456",
  "status": "running",
  "startTime": $START_TIME,
  "lastSeen": $CURRENT_TIME
}
EOF
)

        # 4. Gửi dữ liệu lên Firebase (PUT)
        curl -s -X PUT -H "Content-Type: application/json" \
             -d "$JSON_DATA" \
             "$BASE_URL/vms/$VM_ID.json" > /dev/null

        # 5. Kiểm tra lệnh Kill từ Dashboard
        CMD=$(curl -s "$BASE_URL/commands/$VM_ID.json" | tr -d '"')
        
        if [ "$CMD" == "kill" ]; then
            echo "!!! NHAN LENH STOP !!!"
            curl -s -X DELETE "$BASE_URL/commands/$VM_ID.json" > /dev/null
            exit 1
        fi
    }
    catch {
        echo "Dang ket noi lai..."
    }

    # Nghỉ 10 giây mỗi chu kỳ
    sleep 10
done

