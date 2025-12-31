#!/bin/bash

# ========================================================
# ZUNRDP - FIREBASE AGENT (UBUNTU - WITH RESET)
# ========================================================

BASE_URL="https://zunrdp-default-rtdb.asia-southeast1.firebasedatabase.app"
VM_ID="ZUN-UB-$(openssl rand -hex 2 | tr '[:lower:]' '[:upper:]')"
START_TIME=$(date +%s%3N)

echo "------------------------------------------"
echo ">>> AGENT STARTED: $VM_ID"
echo "------------------------------------------"

while true; do
    # 1. Lấy IP Tailscale
    IP=$(/usr/bin/tailscale ip -4 | head -n 1)
    if [ -z "$IP" ]; then IP="Waiting..."; fi

    # 2. Gửi dữ liệu lên Firebase
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
    curl -s -X PUT -H "Content-Type: application/json" -d "$JSON_DATA" "$BASE_URL/vms/$VM_ID.json" > /dev/null

    # 3. Kiểm tra lệnh từ Dashboard (Reset hoặc Kill)
    CMD=$(curl -s "$BASE_URL/commands/$VM_ID.json" | tr -d '"')
    
    if [ "$CMD" != "null" ] && [ -n "$CMD" ]; then
        if [ "$CMD" == "kill" ]; then
            echo "!!! RECEIVED TERMINATE COMMAND !!!"
            curl -s -X DELETE "$BASE_URL/commands/$VM_ID.json" > /dev/null
            exit 1
        elif [ "$CMD" == "restart" ]; then
            echo "!!! RECEIVED REBOOT COMMAND !!!"
            curl -s -X DELETE "$BASE_URL/commands/$VM_ID.json" > /dev/null
            sudo reboot
        fi
    fi

    sleep 10
done

