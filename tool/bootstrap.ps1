$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$sdkRoot = Join-Path $repoRoot '.tools/flutter'
$version = (Get-Content -LiteralPath (Join-Path $repoRoot '.fvmrc') -Raw | ConvertFrom-Json).flutter

if (-not (Test-Path -LiteralPath (Join-Path $sdkRoot 'bin/flutter.bat'))) {
    New-Item -ItemType Directory -Path (Join-Path $repoRoot '.tools') -Force | Out-Null
    & git clone --depth 1 --branch $version https://github.com/flutter/flutter.git $sdkRoot
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & git -C $sdkRoot switch -c stable
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

& (Join-Path $PSScriptRoot 'flutter.ps1') pub get
exit $LASTEXITCODE
