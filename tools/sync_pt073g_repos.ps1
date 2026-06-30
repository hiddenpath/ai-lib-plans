#Requires -Version 5.1
<#
.SYNOPSIS
  Align PT-073g audit repos for multi-machine execution (lan + GitHub).
.DESCRIPTION
  Private repos (ai-lib-plans, ai-lib-constitution, eos): bidirectional lan <-> origin sync.
  Public repos: reset --hard origin/main (ailib-official).
.PARAMETER DryRun
  Print actions only.
.PARAMETER NoClean
  Skip git clean -fd.
.PARAMETER WorkspaceRoot
  Default D:\rustapp
.PARAMETER PlansRoot
  Default D:\ai-lib-plans
#>
param(
  [switch]$DryRun,
  [switch]$NoClean,
  [string]$WorkspaceRoot = 'D:\rustapp',
  [string]$PlansRoot = 'D:\ai-lib-plans'
)

$ErrorActionPreference = 'Stop'

$Baseline = @{
  'ai-lib-plans'       = 'e0afebf'
  'ai-lib-constitution'= '081bc81'
  'eos'                = '1427438'
  'ai-protocol'        = '65857ef'
  'ai-lib-rust'        = '2f331b4'
  'ai-lib-python'      = 'c3f4d53'
  'ai-lib-ts'          = 'aa3f5fa'
  'ai-lib-go'          = '2cf42c6'
  'velaclaw'           = 'd6e8f6a'
  'ailib.info'         = 'ab86b8f'
  'ai-lib-benchmark'   = 'e65830a'
}

function Write-Log($msg) { Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg" }

function Invoke-Git {
  param([string]$Repo, [string[]]$GitArgs, [switch]$AllowFail)
  if ($DryRun) { Write-Log "DRY-RUN: git -C $Repo $($GitArgs -join ' ')"; return }
  & git -C $Repo @GitArgs
  if (-not $AllowFail -and $LASTEXITCODE -ne 0) { throw "git failed in $Repo : $($GitArgs -join ' ')" }
}

function Resolve-RepoPath([string]$Name) {
  switch ($Name) {
    'ai-lib-plans' { return $PlansRoot }
    'ai-lib-constitution' {
      foreach ($p in @(
        'D:\ai-lib-constitution',
        (Join-Path $WorkspaceRoot '..\ai-lib-constitution'),
        (Join-Path $WorkspaceRoot 'ai-lib-constitution')
      )) { if (Test-Path (Join-Path $p '.git')) { return $p } }
      return 'D:\ai-lib-constitution'
    }
    default {
      $candidates = @(
        (Join-Path $WorkspaceRoot $Name),
        "D:\$Name",
        "D:\rustapp\$Name"
      )
      foreach ($p in $candidates) {
        if (Test-Path (Join-Path $p '.git')) { return $p }
      }
      throw "Repo not found: $Name (tried $($candidates -join ', '))"
    }
  }
}

function Sync-Dual([string]$Name) {
  $path = Resolve-RepoPath $Name
  Write-Log "=== $Name (dual) $path ==="
  if (-not (Test-Path (Join-Path $path '.git'))) { Write-Log "SKIP: missing"; return }

  Invoke-Git $path @('fetch', '--all', '--prune')

  $hasLan = $false
  $hasOrigin = $false
  git -C $path rev-parse lan/main 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { $hasLan = $true }
  git -C $path rev-parse origin/main 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { $hasOrigin = $true }

  if ($hasLan -and $hasOrigin) {
    $aheadLan = [int](git -C $path rev-list --count origin/main..lan/main)
    $aheadOrigin = [int](git -C $path rev-list --count lan/main..origin/main)
    if ($aheadLan -gt 0 -and $aheadOrigin -eq 0) {
      Write-Log "push origin ($aheadLan from lan)"
      Invoke-Git $path @('push', 'origin', 'lan/main:main')
    } elseif ($aheadOrigin -gt 0 -and $aheadLan -eq 0) {
      Write-Log "push lan ($aheadOrigin from origin)"
      Invoke-Git $path @('push', 'lan', 'origin/main:main')
    } elseif ($aheadLan -gt 0 -and $aheadOrigin -gt 0) {
      throw "$Name lan/origin diverged"
    }
    Invoke-Git $path @('checkout', 'main') -AllowFail
    Invoke-Git $path @('reset', '--hard', 'lan/main')
  } elseif ($hasLan) {
    Invoke-Git $path @('checkout', 'main') -AllowFail
    Invoke-Git $path @('reset', '--hard', 'lan/main')
  } else {
    Invoke-Git $path @('checkout', 'main') -AllowFail
    Invoke-Git $path @('reset', '--hard', 'origin/main')
  }

  if (-not $NoClean) { Invoke-Git $path @('clean', '-fd') }
  Test-Baseline $Name $path
}

function Sync-Public([string]$Name) {
  $path = Resolve-RepoPath $Name
  Write-Log "=== $Name (public) $path ==="
  if (-not (Test-Path (Join-Path $path '.git'))) { Write-Log "SKIP: missing"; return }
  Invoke-Git $path @('fetch', 'origin', '--prune')
  Invoke-Git $path @('checkout', 'main') -AllowFail
  Invoke-Git $path @('reset', '--hard', 'origin/main')
  if (-not $NoClean) { Invoke-Git $path @('clean', '-fd') }
  Test-Baseline $Name $path
}

function Test-Baseline([string]$Name, [string]$Path) {
  $short = (git -C $Path rev-parse --short HEAD).Trim()
  $base = $Baseline[$Name]
  if ($base -and $short -ne $base) {
    Write-Log "WARN: $Name HEAD=$short baseline=$base"
    if ($env:STRICT_BASELINE -eq '1') { throw "baseline mismatch: $Name" }
  } else {
    Write-Log "OK: $Name @ $short"
  }
  Invoke-Git $Path @('status', '-sb')
}

$failed = 0
foreach ($n in @('ai-lib-plans', 'ai-lib-constitution', 'eos')) {
  try { Sync-Dual $n } catch { Write-Log "ERROR: $_"; $failed++ }
}
foreach ($n in @('ai-protocol', 'ai-lib-rust', 'ai-lib-python', 'ai-lib-ts', 'ai-lib-go', 'velaclaw', 'ailib.info', 'ai-lib-benchmark')) {
  try { Sync-Public $n } catch { Write-Log "ERROR: $_"; $failed++ }
}

if ($failed -gt 0) { exit 1 }
Write-Log 'PT-073g repos aligned.'
