$baseUrl = "https://zunrdp-default-rtdb.asia-southeast1.firebasedatabase.app"
$vmID = "ZUN-WIN-" + (Get-Random -Minimum 1000 -Maximum 9999)
$startTime = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()

Write-Host ">>> CONNECTING FIREBASE: $vmID" -ForegroundColor Cyan

while($true) {
    try {
        $ip = (tailscale ip -4).Trim()
        $data = @{
            id = $vmID; os = "Windows"; ip = $ip;
            user = "ADMINZUN"; pass = "ZunRDP@123456";
            status = "running"; startTime = $startTime;
            lastSeen = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
        } | ConvertTo-Json -Compress

        Invoke-RestMethod -Uri "$baseUrl/vms/$vmID.json" -Method Put -Body $data -ContentType "application/json"
        
        $cmd = Invoke-RestMethod -Uri "$baseUrl/commands/$vmID.json" -Method Get
        if ($cmd -eq "kill") { 
            Invoke-RestMethod -Uri "$baseUrl/commands/$vmID.json" -Method Delete
            exit 1 
        }
    } catch { Write-Host "Retrying..." -ForegroundColor Gray }
    Start-Sleep -Seconds 10
}

