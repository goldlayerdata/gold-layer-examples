# Contoso (SQLBI Contoso Data Generator V2) - build the dataset into datasets/contoso/data/latest/
#
#   .\generate.ps1                                   defaults: 1M orders, PARQUET, 2018-01-01 -> 2027-12-31
#   .\generate.ps1 -EndYear 2030                     roll the window forward
#   .\generate.ps1 -Orders 10000000 -CustomerPct 0.8 bigger (SQLBI uses 0.8 at 10M, 1.0 at 100M)
#   .\generate.ps1 -Archive                          also snapshot to data/runs/<date>-<scale>/
#
# Recipe (tracked):  config.json + data.xlsx in this folder (from SQLBI, MIT licence).
# Engine (local):    DatabaseGenerator.exe + cache\ in <repo>/.engine/contoso/ (git-ignored), or $env:CONTOSO_GEN_HOME.
#                    Setup and cache recovery: see ../README.md, "Engine setup".
param(
    [int]    $EndYear     = 2027,
    [int]    $Years       = 10,
    [int]    $Orders      = 1000000,
    [double] $CustomerPct = 0.05,
    [ValidateSet('PARQUET','DELTATABLE','CSV')]
    [string] $Format      = 'PARQUET',
    [string] $CutAfter    = '',          # end the data on a specific day instead of 31 Dec, e.g. 2027-06-30
    [string] $EngineDir   = $(if ($env:CONTOSO_GEN_HOME) { $env:CONTOSO_GEN_HOME } else { Join-Path $PSScriptRoot '..\..\..\.engine\contoso' }),
    [switch] $Archive
)

$ErrorActionPreference = 'Stop'
$here    = $PSScriptRoot
$exe     = Join-Path $EngineDir 'DatabaseGenerator.exe'
$cache   = Join-Path $EngineDir 'cache'
$outRoot = [IO.Path]::GetFullPath((Join-Path $here '..\data'))
$staging = Join-Path $outRoot '_staging'
$latest  = Join-Path $outRoot 'latest'

if (-not (Test-Path $exe)) { throw "Engine not found: $exe  (download DatabaseGenerator.winx64.zip - see ../README.md, Engine setup)" }

$start = '{0}-01-01' -f ($EndYear - $Years + 1)
if (-not $CutAfter) { $CutAfter = "$EndYear-12-31" }
$scale = if ($Orders -ge 1000000) { '{0}m' -f ($Orders / 1000000) } else { '{0}k' -f ($Orders / 1000) }

Write-Host "Contoso $Format $scale : $start -> $CutAfter" -ForegroundColor Cyan
$sw = [Diagnostics.Stopwatch]::StartNew()

# Build into _staging so a failed run never leaves latest/ half-written.
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force -Confirm:$false }
New-Item -ItemType Directory -Force $staging, $cache | Out-Null

# First run downloads ~30 static files from GitHub into the cache. GitHub sometimes returns 504s;
# files already downloaded are skipped, so a retry carries on where it stopped.
$maxTries = 5
for ($try = 1; $try -le $maxTries; $try++) {
    & $exe (Join-Path $here 'config.json') (Join-Path $here 'data.xlsx') "$staging\" "$cache\" `
        "param:OutputFormat=$Format" `
        "param:OrdersCount=$Orders" `
        "param:CustomerPercentage=$CustomerPct" `
        "param:StartDT=$start" `
        "param:YearsCount=$Years" `
        "param:CutDateBefore=$start" `
        "param:CutDateAfter=$CutAfter" | Out-Null
    if ($LASTEXITCODE -eq 0) { break }
    if ($try -eq $maxTries) { throw "Generator failed (exit $LASTEXITCODE) after $maxTries tries - see $staging\_log.log" }
    Write-Host "Attempt $try failed (exit $LASTEXITCODE) - retrying in 10s..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}

# --- manifest: what was built, from the engine's own log ---
$log = Get-Content (Join-Path $staging '_log.log')
function Get-LogCount([string] $label) {
    $m = $log | Select-String -Pattern "> ${label}:\s+(\d+)" | Select-Object -Last 1
    if ($m) { [long] $m.Matches[0].Groups[1].Value } else { $null }
}
$files = Get-ChildItem $staging -Recurse -File | Where-Object Name -ne '_log.log' | Sort-Object FullName | ForEach-Object {
    [ordered] @{ file = $_.FullName.Substring($staging.Length + 1).Replace('\', '/'); bytes = $_.Length }
}
$manifest = [ordered] @{
    job          = 'contoso'
    generated_on = (Get-Date).ToString('yyyy-MM-dd')
    engine       = [ordered] @{
        name    = 'SQLBI Contoso Data Generator V2'
        version = (Get-Item $exe).VersionInfo.FileVersion
        source  = 'https://github.com/sql-bi/Contoso-Data-Generator-V2'
        seed    = 'engine-internal fixed seeds: same inputs = same orders and rows; a few attributes (online flag) vary slightly run to run'
    }
    params       = [ordered] @{
        OutputFormat = $Format; OrdersCount = $Orders; CustomerPercentage = $CustomerPct
        StartDT = $start; YearsCount = $Years; CutDateBefore = $start; CutDateAfter = $CutAfter
    }
    date_range   = [ordered] @{ first_order = $start; last_order = $CutAfter }
    counts       = [ordered] @{
        orders       = Get-LogCount 'Orders'
        online_orders = Get-LogCount 'Online orders'
        order_rows   = Get-LogCount 'OrdersRows'
    }
    files        = $files
}
$json = ($manifest | ConvertTo-Json -Depth 5) -replace "`r`n", "`n"
[IO.File]::WriteAllText((Join-Path $staging '_manifest.json'), $json + "`n")

# --- swap staging -> latest, optional snapshot ---
if (Test-Path $latest) { Remove-Item $latest -Recurse -Force -Confirm:$false }
Move-Item $staging $latest
if ($Archive) {
    $snap = Join-Path $outRoot ("runs\{0}-{1}" -f (Get-Date).ToString('yyyy-MM-dd'), $scale)
    if (Test-Path $snap) { Remove-Item $snap -Recurse -Force -Confirm:$false }
    New-Item -ItemType Directory -Force (Split-Path $snap) | Out-Null
    Copy-Item $latest $snap -Recurse
    Write-Host "Snapshot -> $snap"
}

Write-Host ("Done in {0:n0}s: {1:n0} orders, {2:n0} rows -> {3}" -f `
    $sw.Elapsed.TotalSeconds, $manifest.counts.orders, $manifest.counts.order_rows, $latest) -ForegroundColor Green
