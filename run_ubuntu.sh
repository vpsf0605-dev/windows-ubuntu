#!/bin/bash
BASE_URL="https://zunrdp-default-rtdb.asia-southeast1.firebasedatabase.app"
VM_ID="ZUN-UB-$RANDOM"
START_TIME=$(date +%s%3N)

while true; do
    IP=$(tailscale ip -4 | head -n 1)
    JSON_DATA="{\"id\":\"$VM_ID\",\"os\":\"Ubuntu\",\"ip\":\"$IP\",\"user\":\"adminzun\",\"pass\":\"ZunRDP@123456\",\"status\":\"running\",\"startTime\":$START_TIME,\"lastSeen\":$(date +%s%3N)}"
    
    curl -X PUT -d "$JSON_DATA" "$BASE_URL/vms/$VM_ID.json"
    
    CMD=$(curl -s "$BASE_URL/commands/$VM_ID.json" | tr -d '"')
    if [[ "$CMD" == "kill" ]]; then
        curl -X DELETE "$BASE_URL/commands/$VM_ID.json"
        exit 1
    fi
    sleep 10
done
