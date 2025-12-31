# ========================================================
# ZUNRDP - FIREBASE AGENT (FIXED CONNECT)
# ========================================================

# 1. Ép buộc sử dụng giao thức bảo mật cao nhất để tránh lỗi Retrying
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. Cấu hình (Đảm bảo KHÔNG có dấu / ở cuối link)
$baseUrl = "https://zunrdp-default-rtdb.asia-southeast1.firebasedatabase.app"
$vmID = "ZUN-WIN-" + (Get-Random -Minimum 1000 -Maximum 9999)
$startTime = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()

Write-Host "------------------------------------------" -ForegroundColor Cyan
Write-Host ">>> DANG KET NOI FIREBASE: $vmID" -ForegroundColor Cyan
Write-Host "------------------------------------------" -ForegroundColor Cyan

while($true) {
    try {
        # Lấy IP từ Tailscale
        $ip = (tailscale ip -4).Trim()
        if (!$ip) { $ip = "Chờ Tailscale..." }

        # Chuẩn bị dữ liệu JSON
        $payload = @{
            id        = $vmID
            os        = "Windows"
            ip        = $ip
            user      = "ADMINZUN"
            pass      = "ZunRDP@123456"
            status    = "running"
            startTime = $startTime
            lastSeen  = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
        } | ConvertTo-Json -Compress

        # Gửi dữ liệu lên Firebase (Dùng PUT để tạo/cập nhật)
        $url = "$baseUrl/vms/$vmID.json"
        Invoke-RestMethod -Uri $url -Method Put -Body $payload -ContentType "application/json" -TimeoutSec 10

        # Kiểm tra lệnh Kill từ Dashboard
        $cmdUrl = "$baseUrl/commands/$vmID.json"
        $cmd = Invoke-RestMethod -Uri $cmdUrl -Method Get
        
        if ($cmd -eq "kill") {
            Write-Host "!!! NHAN LENH STOP TU DASHBOARD !!!" -ForegroundColor Red
            # Xóa lệnh sau khi nhận
            Invoke-RestMethod -Uri $cmdUrl -Method Delete
            exit 1
        }
    }
    catch {
        # Hiện lỗi chi tiết để debug thay vì chỉ hiện Retrying
        Write-Host "Loi: $($_.Exception.Message)" -ForegroundColor Gray
    }

    # Gửi tin hiệu mỗi 10 giây
    Start-Sleep -Seconds 10
}

