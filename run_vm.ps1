# Cấu hình
$serverUrl = "https://nodejs-1--rdp26082007.replit.app"
$charSet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
$vmID = "ZUN-" + (-join (1..6 | % { $charSet[(Get-Random -Maximum $charSet.Length)] }))

# Bỏ qua kiểm tra SSL nếu cần
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host ">>> KET NOI DASHBOARD ID: $vmID" -ForegroundColor Cyan

while($true) {
    try {
        # Lấy IP Tailscale
        $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like "*Tailscale*"}).IPAddress
        if (!$ip) { $ip = "Chưa có IP" }

        # Tính Uptime
        $uptime = "{0:hh}h {0:mm}m" -f ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime)

        $payload = @{
            id     = $vmID
            os     = "Windows"
            ip     = $ip
            user   = "ADMINZUN"
            pass   = "ZunRDP@123456"
            status = "running"
            uptime = $uptime
        } | ConvertTo-Json

        # Gửi Update
        Invoke-RestMethod -Uri "$serverUrl/api/update" -Method Post -Body $payload -ContentType "application/json" -TimeoutSec 5

        # Lấy Lệnh
        $res = Invoke-RestMethod -Uri "$serverUrl/api/command/$vmID" -Method Get -TimeoutSec 5
        if ($res.command -eq "kill") { 
            Write-Host "!!! LENH KILL !!!" -ForegroundColor Red
            exit 1 
        }
        if ($res.command -eq "restart") { Restart-Computer -Force }
    }
    catch {
        Write-Host "Dang thu lai ket noi..." -ForegroundColor Gray
    }
    Start-Sleep -Seconds 10
}

