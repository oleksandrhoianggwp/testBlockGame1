$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$GodotExecutable = if ($env:GODOT_PATH) { $env:GODOT_PATH } else { (Get-Command godot -ErrorAction SilentlyContinue).Source }
if (-not $GodotExecutable -or -not (Test-Path -LiteralPath $GodotExecutable)) { throw 'Godot 4.7.2 not found. Set GODOT_PATH.' }
$VersionOutput = & $GodotExecutable --version
if ($VersionOutput -notmatch '^4\.7\.2') { throw "Godot 4.7.2 required; found $VersionOutput" }
Push-Location $ProjectRoot
try {
    & $GodotExecutable --headless --path . --editor --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
    & $GodotExecutable --headless --path . --script res://tests/run_all.gd
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
    & $GodotExecutable --headless --path . --script res://tools/level_baker/bake_campaign.gd
    if ($LASTEXITCODE -ne 0) { throw 'Campaign validation failed.' }
    New-Item -ItemType Directory -Force -Path build | Out-Null
    & $GodotExecutable --headless --path . --export-debug 'Android Debug' build/lost-and-sorted-debug.apk
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path build/lost-and-sorted-debug.apk)) { throw 'Android debug export failed. Verify JDK 17, SDK API 36, export templates, and Gradle build template.' }
    Write-Host 'APK ready: build/lost-and-sorted-debug.apk'
} finally { Pop-Location }

