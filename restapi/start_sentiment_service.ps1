$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath
$pythonExe = Join-Path $rootPath ".venv\Scripts\python.exe"
$serviceScript = Join-Path $scriptPath "api\services\sentimentJournal.py"

Write-Host "Starting Sentiment Analysis Service..." 
Write-Host "Python: $pythonExe"
Write-Host "Script: $serviceScript" 

# Check if service is already running
$existingProcess = Get-NetTCPConnection -LocalPort 5000 -State Listen -ErrorAction SilentlyContinue
if ($existingProcess) {
    $pid = $existingProcess.OwningProcess
    Write-Host "Service already running on port 5000 (PID: $pid)" 
    $response = Read-Host "Kill and restart? (y/n)"
    if ($response -eq 'y') {
        Stop-Process -Id $pid -Force
        Write-Host "Stopped existing service" 
        Start-Sleep -Seconds 2
    } else {
        Write-Host "Exiting..." 
        exit 0
    }
}

# Start the service in a new background job
$job = Start-Job -ScriptBlock {
    param($python, $script, $root)
    Set-Location $root
    & $python $script
} -ArgumentList $pythonExe, $serviceScript, $rootPath

Write-Host "Service started in background job (ID: $($job.Id))" 
Write-Host "Waiting for service to initialize..."
Start-Sleep -Seconds 3

# Test the service
try {
    $response = Invoke-RestMethod -Uri "http://127.0.0.1:5000/health" -Method Get -ErrorAction Stop
    Write-Host "Service is running successfully!" 
    Write-Host "  Endpoint: http://127.0.0.1:5000" 
    Write-Host "  Job ID: $($job.Id)" 
    Write-Host ""
    Write-Host "To stop the service, run: Stop-Job -Id $($job.Id); Remove-Job -Id $($job.Id)" 
} catch {
    Write-Host "Service failed to start or is not responding" 
    Write-Host "  Error: $_" 
    Write-Host ""
    Write-Host "Check job output: Receive-Job -Id $($job.Id)" 
}
