Write-Host "Starting Face Recognition Service..." -ForegroundColor Cyan
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)

Set-Location $projectRoot

$envPath = Join-Path $projectRoot "deepface_env\Scripts\Activate.ps1"

if (Test-Path $envPath) {
    Write-Host "Activating deepface_env..." -ForegroundColor Yellow
    & $envPath
} else {
    Write-Host "Warning: deepface_env not found at $envPath" -ForegroundColor Red
    Write-Host "Attempting to run with system Python..." -ForegroundColor Yellow
}
Write-Host "Starting face recognition service on port 5004..." -ForegroundColor Green
python restapi\api\services\face_recognition_service.py
#THIS WAS MADE BY CHAT TO HELP ME SPEED UP DEVELOPMENT