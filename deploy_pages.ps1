# Демо-версияро (бе сервер) ба GitHub Pages мефиристад: https://bamazaev.github.io/tillo.tj/
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$out = Join-Path $env:TEMP 'tillo_pages'

# Маълумот ва суратҳои демо: backend/seed_photos -> frontend/web/demo
Push-Location "$root\backend"
.\.venv\Scripts\python.exe -m tools.export_demo ..\frontend\assets\demo\data.json
Pop-Location

Push-Location "$root\frontend"
flutter build web --release --dart-define=DEMO=true --base-href /tillo.tj/
Pop-Location

if (Test-Path $out) { Remove-Item -Recurse -Force $out }
Copy-Item -Recurse "$root\frontend\build\web" $out
Copy-Item "$out\index.html" "$out\404.html"      # пайвандҳои дохилӣ (/item/5) дар Pages
New-Item -ItemType File "$out\.nojekyll" | Out-Null

$rev = git -C $root rev-parse --short HEAD
Push-Location $out
git init -q -b gh-pages
git add -A
git commit -q -m "Deploy demo $rev"
git push -f https://github.com/Bamazaev/tillo.tj.git gh-pages
Pop-Location
Write-Host "Tayyor: https://bamazaev.github.io/tillo.tj/" -ForegroundColor Yellow
