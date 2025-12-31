# ========================================================
# ZUNRDP - FIREBASE AGENT (FIXED COMMAND NOT FOUND)
# ========================================================

# 1. Ép buộc sử dụng giao thức bảo mật TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. Cấu hình Firebase
$baseUrl = "https://zunrdp-default-rtdb.asia-southeast1.firebasedatabase.app"
$vmID = "ZUN-WIN-" + (Get-Random -Minimum 1000 -Maximum 9999)
$startTime = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()

# 3. Xác định đường dẫn Tailscale.exe (Sửa lỗi 'not recognized')
$tsExe = "$env:ProgramFiles\Tailscale\Tailscale.exe"

Write-Host "------------------------------------------" -ForegroundColor Cyan
Write-Host ">>> DANG KET NOI FIREBASE: $vmID" -ForegroundColor Cyan
Write-Host "------------------------------------------" -ForegroundColor Cyan

while($true) {
    try {
        # Lấy IP bằng đường dẫn tuyệt đối
        if (Test-Path $tsExe) {
            $ip = (& $tsExe ip -4).Trim()
        } else {
            $ip = "Chưa cài Tailscale"
        }

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

        # Gửi dữ liệu lên Firebase
        $url = "$baseUrl/vms/$vmID.json"
        Invoke-RestMethod -Uri $url -Method Put -Body $payload -ContentType "application/json" -TimeoutSec 10

        # Kiểm tra lệnh Kill từ Dashboard
        $cmdUrl = "$baseUrl/commands/$vmID.json"
        $cmd = Invoke-RestMethod -Uri $cmdUrl -Method Get
        
        if ($cmd -eq "kill") {
            Write-Host "!!! NHAN LENH STOP !!!" -ForegroundColor Red
            Invoke-RestMethod -Uri $cmdUrl -Method Delete
            exit 1
        }
    }
    catch {
        Write-Host "Loi: $($_.Exception.Message)" -ForegroundColor Gray
    }

    Start-Sleep -Seconds 10
}

