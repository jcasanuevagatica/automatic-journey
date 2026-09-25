param([switch]$NoUpdate,[switch]$NoLaunch)
$ErrorActionPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$AppDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceHtml = Join-Path $AppDir 'MiAgenda.html'
$SeedData = Join-Path $AppDir 'datos_oficiales_iniciales.json'
$DataDir = Join-Path $env:LOCALAPPDATA 'MiAgendaDatos'
if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) { $DataDir = Join-Path $env:USERPROFILE 'AppData\Local\MiAgendaDatos' }
$DataFile = Join-Path $DataDir 'datos_oficiales.json'
$RuntimeHtml = Join-Path $DataDir 'MiAgenda_runtime.html'
$EdgeProfile = Join-Path $DataDir 'EdgeProfile'
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null
New-Item -ItemType Directory -Force -Path $EdgeProfile | Out-Null
if (!(Test-Path $DataFile) -and (Test-Path $SeedData)) { Copy-Item -Force $SeedData $DataFile }

function Get-PageText([string]$Url) {
    try {
        $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 6 -Headers @{ 'User-Agent'='Mozilla/5.0 MiAgenda/5.1' }
        $raw = [Net.WebUtility]::HtmlDecode([string]$r.Content)
        $raw = [regex]::Replace($raw,'(?is)<script.*?</script>',' ')
        $raw = [regex]::Replace($raw,'(?is)<style.*?</style>',' ')
        $raw = [regex]::Replace($raw,'(?is)<[^>]+>',' ')
        return [regex]::Replace($raw,'\s+',' ').Trim()
    } catch { return $null }
}
function To-Number([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    try {
        $x = $Text.Replace('.','').Replace(',','.')
        return [double]::Parse($x,[Globalization.CultureInfo]::InvariantCulture)
    } catch { return $null }
}
function First-Value([string]$Text,[string]$Pattern) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $m=[regex]::Match($Text,$Pattern,[Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (!$m.Success) { return $null }
    return To-Number $m.Groups[1].Value
}

try { $data = Get-Content -LiteralPath $DataFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $data = Get-Content -LiteralPath $SeedData -Raw -Encoding UTF8 | ConvertFrom-Json }

$needUpdate = !$NoUpdate
try {
    $last=[datetime]::Parse([string]$data.economic.updatedAt)
    $hasAll=($null -ne $data.economic.uf.value -and $null -ne $data.economic.utm.value -and $null -ne $data.economic.usd.value -and $null -ne $data.economic.eur.value)
    if ($hasAll -and $last.Date -eq (Get-Date).Date) { $needUpdate=$false }
} catch {}

if ($needUpdate) {
    $now=(Get-Date).ToString('o')
    $today=(Get-Date).ToString('yyyy-MM-dd')
    $month=(Get-Date).ToString('yyyy-MM')
    $bc = Get-PageText 'https://www.bcentral.cl/es/'
    if ($bc) {
        $uf  = First-Value $bc 'UF\s*\$?\s*([0-9\.]+,[0-9]+)'
        $utm = First-Value $bc 'UTM(?:\s*\([^\)]*\))?\s*\$?\s*([0-9\.]+,[0-9]+)'
        $usd = First-Value $bc 'D[oó]lar\s+Observado\s*\$?\s*([0-9\.]+,[0-9]+)'
        $eur = First-Value $bc 'Euro\s*\$?\s*([0-9\.]+,[0-9]+)'
        if ($null -ne $uf)  { $data.economic.uf.value=$uf;   $data.economic.uf.asOf=$today;  $data.economic.uf.source='Banco Central de Chile / SII' }
        if ($null -ne $utm) { $data.economic.utm.value=$utm; $data.economic.utm.asOf=$month; $data.economic.utm.source='Banco Central de Chile / SII' }
        if ($null -ne $usd) { $data.economic.usd.value=$usd; $data.economic.usd.asOf=$today; $data.economic.usd.source='Banco Central de Chile' }
        if ($null -ne $eur) { $data.economic.eur.value=$eur; $data.economic.eur.asOf=$today; $data.economic.eur.source='Banco Central de Chile' }
        $data.economic.updatedAt=$now
        $data.economic.source='Banco Central de Chile / SII'
    }
    $sp = Get-PageText 'https://www.spensiones.cl/portal/institucional/594/w3-article-2810.html'
    if ($sp) {
        $names=@('Capital','Cuprum','Habitat','Modelo','PlanVital','Provida','Uno')
        foreach($n in $names) {
            $pat='AFP\s+'+[regex]::Escape($n)+':?\s*([0-9]+,[0-9]+)%'
            $v=First-Value $sp $pat
            if ($null -ne $v) {
                $prop = if ($n -eq 'Uno') {'UNO'} elseif ($n -eq 'PlanVital') {'PlanVital'} else {$n}
                $data.afp.commissions.$prop=$v
            }
        }
        $data.afp.updatedAt=$today
        $data.afp.source='Superintendencia de Pensiones'
    }
    try { $data | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $DataFile -Encoding UTF8 } catch {}
}

if (!(Test-Path $SourceHtml)) { Write-Host 'No se encuentra MiAgenda.html. Reinstala Mi Agenda.'; exit 2 }
try {
    $json = Get-Content -LiteralPath $DataFile -Raw -Encoding UTF8
    $html = Get-Content -LiteralPath $SourceHtml -Raw -Encoding UTF8
    $inject = '<script id="miagenda-official-data">' + [Environment]::NewLine + 'window.MIAGENDA_OFFICIAL_DATA=' + $json + ';' + [Environment]::NewLine + '</script>'
    $html = [regex]::Replace($html,'(?s)<script id="miagenda-official-data">.*?</script>',[Text.RegularExpressions.MatchEvaluator]{ param($m) $inject },1)
    [IO.File]::WriteAllText($RuntimeHtml,$html,(New-Object Text.UTF8Encoding($false)))
} catch { Copy-Item -Force $SourceHtml $RuntimeHtml }

if ($NoLaunch) { exit 0 }

$edgeCandidates=@(
    (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\Application\msedge.exe')
) | Where-Object { $_ -and (Test-Path $_) }
$uri=(New-Object System.Uri($RuntimeHtml)).AbsoluteUri
if ($edgeCandidates.Count -gt 0) {
    $edge=$edgeCandidates[0]
    Start-Process -FilePath $edge -ArgumentList @("--user-data-dir=$EdgeProfile","--app=$uri","--no-first-run")
} else {
    Start-Process -FilePath $RuntimeHtml
}
