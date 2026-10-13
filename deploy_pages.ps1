# Демо-версияро (бе сервер) ба GitHub Pages мефиристад: https://bamazaev.github.io/tillo.tj/
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$out = Join-Path $env:TEMP 'tillo_pages'
# Рақами нав барои ҳар нашр — браузер файлҳои кӯҳнаро аз кеш намегирад.
$build = Get-Date -Format 'yyyyMMddHHmmss'

# Маълумот ва суратҳои демо: backend/seed_photos -> frontend/web/demo
Push-Location "$root\backend"
.\.venv\Scripts\python.exe -m tools.export_demo ..\frontend\assets\demo\data.json
Pop-Location

Push-Location "$root\frontend"
flutter build web --release --dart-define=DEMO=true --dart-define=BUILD_ID=$build --base-href /tillo.tj/
Pop-Location

if (Test-Path $out) { Remove-Item -Recurse -Force $out }
Copy-Item -Recurse "$root\frontend\build\web" $out

# Cache-busting: main.dart.js?v=… ва flutter_bootstrap.js?v=…
$boot = "$out\flutter_bootstrap.js"
(Get-Content $boot -Raw -Encoding UTF8).Replace('"mainJsPath":"main.dart.js"', "`"mainJsPath`":`"main.dart.js?v=$build`"") |
    Set-Content $boot -Encoding UTF8 -NoNewline
$index = "$out\index.html"
(Get-Content $index -Raw -Encoding UTF8).Replace('href="main.dart.js"', "href=`"main.dart.js?v=$build`"").Replace('src="flutter_bootstrap.js"', "src=`"flutter_bootstrap.js?v=$build`"") |
    Set-Content $index -Encoding UTF8 -NoNewline

Copy-Item $index "$out\404.html"      # пайвандҳои дохилӣ (/item/5) дар Pages
New-Item -ItemType File "$out\.nojekyll" | Out-Null

$rev = git -C $root rev-parse --short HEAD
Push-Location $out
git init -q -b gh-pages
git add -A
git commit -q -m "Deploy demo $rev ($build)"
git push -f https://github.com/Bamazaev/tillo.tj.git gh-pages
Pop-Location
Write-Host "Tayyor: https://bamazaev.github.io/tillo.tj/  (build $build)" -ForegroundColor Yellow
