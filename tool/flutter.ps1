# Windows convenience wrapper. SDKs and dependency caches stay inside .tools/.
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$sdkRoot = Join-Path $repoRoot '.tools/flutter'
$flutterCommand = Join-Path $sdkRoot 'bin/flutter.bat'
$expected = (Get-Content -LiteralPath (Join-Path $repoRoot '.fvmrc') -Raw | ConvertFrom-Json).flutter

if (-not (Test-Path -LiteralPath $flutterCommand)) {
    $installed = Get-Command flutter -ErrorAction SilentlyContinue
    if (-not $installed) {
        throw 'Flutter SDK is missing. Run .\tool\bootstrap.ps1 or install Flutter 3.47.0.'
    }
    $flutterCommand = $installed.Source
}

$settings = @{
    'PUB_CACHE' = (Join-Path $repoRoot '.tools/pub-cache')
    'GRADLE_USER_HOME' = (Join-Path $repoRoot '.tools/gradle')
    'FLUTTER_SUPPRESS_ANALYTICS' = 'true'
    'DART_SUPPRESS_ANALYTICS' = 'true'
}
$previous = @{}
$result = 1
Push-Location -LiteralPath $repoRoot
try {
    foreach ($name in $settings.Keys) {
        $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, $settings[$name], 'Process')
    }
    $raw = & $flutterCommand --version --machine
    if ($LASTEXITCODE -ne 0) { throw 'Unable to read the Flutter SDK version.' }
    $actual = ($raw | Out-String | ConvertFrom-Json).frameworkVersion
    if ($actual -ne $expected) {
        throw "Expected Flutter $expected but found $actual. Use the SDK pinned in .fvmrc."
    }
    & $flutterCommand @args
    $result = $LASTEXITCODE
}
finally {
    foreach ($name in $previous.Keys) {
        [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process')
    }
    Pop-Location
}
exit $result
