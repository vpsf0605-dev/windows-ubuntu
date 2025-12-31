# ========================================================
# ZUNRDP - WINDOWS AGENT SCRIPT
# ========================================================

# 1. THÔNG TIN CẤU HÌNH
$serverUrl = "https://nodejs-1--rdp26082007.replit.app"
$user = "ADMINZUN"
$pass = "ZunRDP@123456"

# 2. TẠO ID MÁY NGẪU NHIÊN (Chỉ tạo 1 lần khi chạy)
$charSet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
$vmID = "ZUN-" + (-join (1..6 | % { $charSet[(Get-Random -Maximum $charSet.Length)] }))

Write-Host "------------------------------------------" -ForegroundColor Cyan
Write-Host ">>> DANG KET NOI DASHBOARD: $vmID" -ForegroundColor Cyan
Write-Host ">>> SERVER: $serverUrl" -ForegroundColor Cyan
Write-Host "------------------------------------------" -ForegroundColor Cyan

# 3. VÒNG LẶP GỬI DỮ LIỆU VÀ NHẬN LỆNH (MỖI 10 GIÂY)
while($true) {
    try {
        # A. Lấy địa chỉ IP từ Tailscale
        $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like "*Tailscale*"}).IPAddress
        if (!$ip) { 
            # Nếu chưa có Tailscale, lấy IP mặc định của máy
            $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.PrefixOrigin -eq "Dhcp"}).IPAddress[0]
        }
        if (!$ip) { $ip = "0.0.0.0" }

        # B. Tính thời gian máy đã chạy (Uptime)
        $osObj = Get-CimInstance Win32_OperatingSystem
        $uptimeSpan = (Get-Date) - $osObj.LastBootUpTime
        $uptimeStr = "{0:00}h {1:00}m {2:00}s" -f $uptimeSpan.Hours, $uptimeSpan.Minutes, $uptimeSpan.Seconds

        # C. Đóng gói dữ liệu JSON
        $payload = @{
            id     = $vmID
            os     = "Windows"
            ip     = $ip
            user   = $user
            pass   = $pass
            status = "running"
            uptime = $uptimeStr
        } | ConvertTo-Json -Compress

        # D. Gửi thông tin lên Replit (/api/update)
        $headers = @{"Content-Type" = "application/json"}
        Invoke-RestMethod -Uri "$serverUrl/api/update" -Method Post -Body $payload -Headers $headers -TimeoutSec 10

        # E. Kiểm tra lệnh điều khiển từ Dashboard (/api/command)
        $response = Invoke-RestMethod -Uri "$serverUrl/api/command/$vmID" -Method Get -TimeoutSec 10
        
        if ($response.command) {
            $cmd = $response.command.ToLower()
            Write-Host ">>> NHAN LENH: $cmd" -ForegroundColor Red
            
            if ($cmd -eq "kill") {
                Write-Host "Dang dung may ảo..." -ForegroundColor Yellow
                exit 1 # Thoát script để GitHub Action dừng máy
            }
            elseif ($cmd -eq "restart") {
                Write-Host "Dang khoi dong lai..." -ForegroundColor Yellow
                Restart-Computer -Force
            }
        }
    }
    catch {
        Write-Host "Loi ket noi Dashboard... dang thu lai" -ForegroundColor Gray
    }

    # Đợi 10 giây rồi lặp lại
    Start-Sleep -Seconds 10
}
