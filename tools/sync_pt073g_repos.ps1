#Requires -Version 5.1
param(
  [switch]$DryRun,
  [switch]$NoClean,
  [string]$WorkspaceRoot = 'D:\rustapp',
  [string]$PlansRoot = 'D:\ai-lib-plans'
)

$ErrorActionPreference = 'Stop'
$ConflictRunbook = 'active/projects/ai-protocol/PT-073g-CONFLICT-RUNBOOK.md'

$Baseline = @{
  'ai-lib-plans'        = 'c55b9dc'
  'ai-lib-constitution' = '081bc81'
  'eos'                 = '1427438'
  'ai-protocol'         = '65857ef'
  'ai-lib-rust'         = '2f331b4'
  'ai-lib-python'       = 'c3f4d53'
  'ai-lib-ts'           = 'aa3f5fa'
  'ai-lib-go'           = '2cf42c6'
  'velaclaw'            = 'd6e8f6a'
  'ailib.info'          = 'ab86b8f'
  'ai-lib-benchmark'    = 'e65830a'
}

function Write-Log($msg) { Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg" }

function Stop-Gov002([string]$Msg) {
  Write-Log "GOV-002: $Msg"
  Write-Log "See: $PlansRoot\$ConflictRunbook"
  throw $Msg
}

function Invoke-Git {
  param([string]$Repo, [string[]]$GitArgs, [switch]$AllowFail)
  if ($DryRun) { Write-Log "DRY-RUN: git -C $Repo $($GitArgs -join ' ')"; return }
  & git -C $Repo @GitArgs
  if (-not $AllowFail -and $LASTEXITCODE -ne 0) { throw "git failed in $Repo : $($GitArgs -join ' ')" }
}

function Test-GitQuiet([string]$Path) {
  if (Test-Path (Join-Path $Path '.git/MERGE_HEAD')) { Stop-Gov002 "$Path merge in progress" }
  if ((Test-Path (Join-Path $Path '.git/rebase-merge')) -or (Test-Path (Join-Path $Path '.git/rebase-apply'))) {
    Stop-Gov002 "$Path rebase in progress"
  }
}

function Test-WorkingTreeDirty([string]$Path) {
  return [bool](git -C $Path status --porcelain)
}

function Resolve-RepoPath([string]$Name) {
  switch ($Name) {
    'ai-lib-plans' { return $PlansRoot }
    'ai-lib-constitution' {
      foreach ($p in @('D:\ai-lib-constitution', (Join-Path $WorkspaceRoot '..\ai-lib-constitution'))) {
        if (Test-Path (Join-Path $p '.git')) { return $p }
      }
      return 'D:\ai-lib-constitution'
    }
    default {
      foreach ($p in @((Join-Path $WorkspaceRoot $Name), "D:\$Name", "D:\rustapp\$Name")) {
        if (Test-Path (Join-Path $p '.git')) { return $p }
      }
      throw "Repo not found: $Name"
    }
  }
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

function Sync-Dual([string]$Name) {
  $path = Resolve-RepoPath $Name
  Write-Log "=== $Name (dual) $path ==="
  if (-not (Test-Path (Join-Path $path '.git'))) { Write-Log 'SKIP: missing'; return }
  Test-GitQuiet $path

  Invoke-Git $path @('fetch', '--all', '--prune')

  $hasLan = $false; $hasOrigin = $false
  git -C $path rev-parse lan/main 2>$null | Out-Null; if ($LASTEXITCODE -eq 0) { $hasLan = $true }
  git -C $path rev-parse origin/main 2>$null | Out-Null; if ($LASTEXITCODE -eq 0) { $hasOrigin = $true }

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
      git -C $path log --oneline --left-right lan/main...origin/main | Select-Object -First 20
      Stop-Gov002 "$Name lan/origin both ahead — manual merge per runbook section 2"
    }
    if (Test-WorkingTreeDirty $path) {
      Write-Log 'WARN: dirty working tree — skip reset (commit/stash first)'
    } else {
      Invoke-Git $path @('checkout', 'main') -AllowFail
      Invoke-Git $path @('reset', '--hard', 'lan/main')
    }
  } elseif ($hasLan) {
    if (-not (Test-WorkingTreeDirty $path)) {
      Invoke-Git $path @('checkout', 'main') -AllowFail
      Invoke-Git $path @('reset', '--hard', 'lan/main')
    }
  } elseif (-not (Test-WorkingTreeDirty $path)) {
    Invoke-Git $path @('checkout', 'main') -AllowFail
    Invoke-Git $path @('reset', '--hard', 'origin/main')
  }

  if (-not $NoClean) { Invoke-Git $path @('clean', '-fd') }
  Test-Baseline $Name $path
}

function Sync-Public([string]$Name) {
  $path = Resolve-RepoPath $Name
  Write-Log "=== $Name (public) $path ==="
  if (-not (Test-Path (Join-Path $path '.git'))) { Write-Log 'SKIP: missing'; return }
  Test-GitQuiet $path

  Invoke-Git $path @('fetch', 'origin', '--prune')
  Invoke-Git $path @('checkout', 'main') -AllowFail

  $ahead = [int](git -C $path rev-list --count origin/main..HEAD)
  $behind = [int](git -C $path rev-list --count HEAD..origin/main)

  git -C $path diff --quiet origin/main..HEAD
  $sameTree = ($LASTEXITCODE -eq 0)

  if ($sameTree) {
    Write-Log "tree matches origin/main (ahead=$ahead behind=$behind) — reset OK"
    Invoke-Git $path @('reset', '--hard', 'origin/main')
  } elseif ($ahead -gt 0) {
    git -C $path diff origin/main..HEAD --stat | Select-Object -First 30
    Stop-Gov002 "$Name local tree differs from origin/main — runbook section 3"
  } else {
    Invoke-Git $path @('reset', '--hard', 'origin/main')
  }

  if (-not $NoClean) { Invoke-Git $path @('clean', '-fd') }
  Test-Baseline $Name $path
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
