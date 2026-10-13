# Tillo.tj: сохтан ва оғоз кардан
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not (Test-Path "$root\backend\.venv")) {
    python -m venv "$root\backend\.venv"
    & "$root\backend\.venv\Scripts\pip.exe" install -r "$root\backend\requirements.txt"
}
Push-Location "$root\frontend"
flutter build web --release
Pop-Location
Push-Location "$root\backend"
Write-Host "Tillo.tj: http://localhost:8000" -ForegroundColor Yellow
& .venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000
Pop-Location
