# ========================================================
# ZUNRDP - FIREBASE AGENT (WINDOWS PREMIUM)
# ========================================================

# 1. Thiết lập bảo mật và Encoding để tránh lỗi font/kết nối
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 2. Cấu hình Firebase
$baseUrl = "https://zunrdp-default-rtdb.asia-southeast1.firebasedatabase.app"
$vmID = "ZUN-WIN-" + (Get-Random -Minimum 1000 -Maximum 9999)
$startTime = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()

# 3. Xác định đường dẫn Tailscale
$tsExe = "$env:ProgramFiles\Tailscale\Tailscale.exe"

Write-Host "------------------------------------------" -ForegroundColor Cyan
Write-Host ">>> AGENT IS ACTIVE: $vmID" -ForegroundColor Cyan
Write-Host "------------------------------------------" -ForegroundColor Cyan

while($true) {
    try {
        # Lấy địa chỉ IP Tailscale
        if (Test-Path $tsExe) {
            $ip = (& $tsExe ip -4).Trim()
        } else {
            $ip = "Waiting for Tailscale..."
        }

        # Tạo gói dữ liệu JSON
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

        # Đẩy dữ liệu lên Firebase
        $url = "$baseUrl/vms/$vmID.json"
        Invoke-RestMethod -Uri $url -Method Put -Body $payload -ContentType "application/json" -TimeoutSec 10

        # KIỂM TRA LỆNH TỪ DASHBOARD (AGENT COMMAND CENTER)
        $cmdUrl = "$baseUrl/commands/$vmID.json"
        $cmd = Invoke-RestMethod -Uri $cmdUrl -Method Get
        
        if ($cmd -and $cmd -ne "null") {
            if ($cmd -eq "kill") {
                Write-Host "!!! RECEIVED TERMINATE COMMAND !!!" -ForegroundColor Red
                Invoke-RestMethod -Uri $cmdUrl -Method Delete # Xóa lệnh sau khi nhận
                exit 1 # Thoát Workflow
            }
            elseif ($cmd -eq "restart") {
                Write-Host "!!! RECEIVED REBOOT COMMAND !!!" -ForegroundColor Yellow
                Invoke-RestMethod -Uri $cmdUrl -Method Delete # Xóa lệnh trước khi reboot
                Restart-Computer -Force # Khởi động lại máy ảo
            }
        }
    }
    catch {
        Write-Host "Connecting to Firebase..." -ForegroundColor Gray
    }

    # Nghỉ 10 giây trước khi gửi tín hiệu tiếp theo
    Start-Sleep -Seconds 10
}

