#requires -Version 5.1
<#
.SYNOPSIS
    Windows short-term disk cleanup for development machines (safe, repeatable).

.DESCRIPTION
    中文说明：
    - 默认 **演练模式**（只报告、不删除），需加 `-Execute` 才真正清理。
    - **常规** 清理白名单路径（用户 Temp、可选 `%WINDIR%\\Temp`、npm/pip 与可选开发者缓存），不触碰仓库与 IDE 扩展目录。
    - **可选高烈度**（须管理员 + `-Execute`，单独开关）：`Windows.old`、WinSxS（DISM）、整盘卷影副本、传递优化缓存、`SoftwareDistribution\\Download`。
    - 每次运行记录目标盘 **可用空间前后对比**，便于验证效果。
    - 长期迁盘/换机不属于本脚本范围。

.PARAMETER Execute
    执行真实清理。省略时等价于演练（不删除文件，仍估算临时目录体积并跑只读的 cache 查询类命令时需注意：npm/pip 在演练模式下不执行清理子命令）。

.PARAMETER DriveLetter
    报告可用空间所用的盘符，默认 `C`（系统盘）。

.PARAMETER ClearRecycleBin
    与 `-Execute` 联用：清空回收站（`-Execute` 未指定时忽略）。

.PARAMETER IncludeWindowsTemp
    与 `-Execute` 联用：尝试清理 `%WINDIR%\Temp`。建议管理员身份运行；权限不足时跳过并提示。

.PARAMETER IncludeAwsCliCache
    与 `-Execute` 联用：删除 `%USERPROFILE%\.aws\cli\cache` 下文件（不删除 credentials/config）。

.PARAMETER IncludeNuGetHttpCache
    与 `-Execute` 联用：删除 `%LOCALAPPDATA%\NuGet\v3-cache`（HTTP 缓存，可重建）。

.PARAMETER IncludeWindowsOldRemoval
    与 `-Execute` 联用且 **须管理员**：删除 `%SystemDrive%\Windows.old`（大版本升级残留）。演练模式下仅估算体积（若存在）。
    使用 takeown/icacls + rd；无法再回滚到旧系统。

.PARAMETER IncludeDismComponentCleanup
    与 `-Execute` 联用且 **须管理员**：`DISM /Online /Cleanup-Image /StartComponentCleanup` 收缩 WinSxS 中已取代的更新组件。

.PARAMETER IncludeDismResetBase
    与 `-Execute` 联用且 **须管理员**：`DISM ... /StartComponentCleanup /ResetBase` — **更激进**，清理后通常无法再卸载此前安装的累积更新；若与 `IncludeDismComponentCleanup` 同时指定，以本项为准（一条 DISM 命令）。

.PARAMETER IncludeDeliveryOptimizationCache
    与 `-Execute` 联用且 **建议管理员**：清空 Windows 传递优化缓存（优先 `Delete-DeliveryOptimizationCache`；不可用时尝试删除缓存目录）。

.PARAMETER IncludeVolumeShadowCopies
    与 `-Execute` 联用且 **须管理员**：`vssadmin delete shadows /For=<盘>: /All` — 删除该盘 **全部** 卷影副本（系统还原点），属备份类空间回收。

.PARAMETER IncludeWindowsUpdateDownloadCache
    与 `-Execute` 联用且 **须管理员**：短时停止 `wuauserv` 后清空 `%SystemRoot%\SoftwareDistribution\Download`（已下载更新包缓存，可重建；请勿在系统正在安装更新时执行）。

.EXAMPLE
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/win_dev_disk_cleanup.ps1

.EXAMPLE
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/win_dev_disk_cleanup.ps1 -Execute -ClearRecycleBin

.NOTES
    风险提示：清理临时目录可能导致少量程序丢失未保存临时文件；请在关闭 IDE/安装程序后再执行 `-Execute`。
    高烈度开关会移除系统备份/旧安装痕迹；执行前请确认无需还原点与回滚旧 Windows。
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch] $Execute,
    [ValidatePattern('^[A-Za-z]$')]
    [string] $DriveLetter = 'C',
    [switch] $ClearRecycleBin,
    [switch] $IncludeWindowsTemp,
    [switch] $IncludeAwsCliCache,
    [switch] $IncludeNuGetHttpCache,
    [switch] $IncludeWindowsOldRemoval,
    [switch] $IncludeDismComponentCleanup,
    [switch] $IncludeDismResetBase,
    [switch] $IncludeDeliveryOptimizationCache,
    [switch] $IncludeVolumeShadowCopies,
    [switch] $IncludeWindowsUpdateDownloadCache
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-VolumeFreeBytes {
    param([string] $Letter)
    $drive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$($Letter.TrimEnd(':')):'" -ErrorAction SilentlyContinue
    if ($null -eq $drive) {
        throw "Drive ${Letter}: not found (Win32_LogicalDisk)."
    }
    return [int64]$drive.FreeSpace
}

function Format-Gb {
    param([int64] $Bytes)
    return [math]::Round($Bytes / 1GB, 3)
}

function Get-NormalizedExistingPaths {
    param([string[]] $Paths)
    $out = New-Object System.Collections.Generic.List[string]
    $seen = @{}
    foreach ($raw in $Paths) {
        if ([string]::IsNullOrWhiteSpace($raw)) { continue }
        if (-not (Test-Path -LiteralPath $raw)) { continue }
        $full = [System.IO.Path]::GetFullPath($raw.TrimEnd('\', '/'))
        $key = $full.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        $out.Add($full) | Out-Null
    }
    return $out
}

function Measure-TreeBytes {
    param([string] $RootPath)
    if (-not (Test-Path -LiteralPath $RootPath)) { return 0L }
    $sum = 0L
    Get-ChildItem -LiteralPath $RootPath -Recurse -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
        $sum += $_.Length
    }
    return $sum
}

function Clear-DirectoryContents {
    param([string] $RootPath)
    if (-not (Test-Path -LiteralPath $RootPath)) { return }
    Get-ChildItem -LiteralPath $RootPath -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
        } catch {
            # Locked files: skip (common under Temp).
        }
    }
}

function Test-IsAdministrator {
    $cur = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($cur)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-NpmCacheClean {
    $npm = Get-Command npm -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $npm) {
        Write-Host '[skip] npm not found in PATH.'
        return
    }
    Write-Host "[npm] cache clean --force via $($npm.Source)"
    & $npm.Source 'cache' 'clean' '--force'
}

function Invoke-PipCachePurge {
    $candidates = @(
        @{ Name = 'py'; Args = @('-m', 'pip', 'cache', 'purge') },
        @{ Name = 'python';  Args = @('-m', 'pip', 'cache', 'purge') },
        @{ Name = 'python3'; Args = @('-m', 'pip', 'cache', 'purge') }
    )
    foreach ($c in $candidates) {
        $cmd = Get-Command ($c.Name) -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -eq $cmd) { continue }
        Write-Host "[pip] cache purge via $($cmd.Source)"
        & $cmd.Source @($c.Args)
        return
    }
    $pip = Get-Command pip -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $pip) {
        Write-Host "[pip] cache purge via $($pip.Source)"
        & $pip.Source 'cache' 'purge'
        return
    }
    Write-Host '[skip] pip / python -m pip not found in PATH.'
}

function Get-WindowsOldPath {
    return Join-Path $env:SystemDrive 'Windows.old'
}

function Get-DeliveryOptimizationCachePath {
    return Join-Path $env:WINDIR 'ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache'
}

function Get-WindowsUpdateDownloadPath {
    return Join-Path $env:WINDIR 'SoftwareDistribution\Download'
}

function Invoke-DismAnalyzeComponentStore {
    $dism = Join-Path $env:WINDIR 'System32\dism.exe'
    if (-not (Test-Path -LiteralPath $dism)) {
        Write-Warning 'DISM executable not found.'
        return
    }
    Write-Host '[DISM] AnalyzeComponentStore (read-only, may require elevation)...'
    & $dism '/Online' '/Cleanup-Image' '/AnalyzeComponentStore'
}

function Invoke-DismStartComponentCleanup {
    param([switch] $ResetBase)
    $dism = Join-Path $env:WINDIR 'System32\dism.exe'
    $dismArgs = @('/Online', '/Cleanup-Image', '/StartComponentCleanup', '/NoRestart')
    if ($ResetBase) { $dismArgs += '/ResetBase' }
    Write-Host ('[DISM] ' + ($dismArgs -join ' '))
    & $dism @dismArgs
}

function Remove-WindowsOldTree {
    param([string] $Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "[skip] Windows.old not present: $Path"
        return
    }
    $takeown = Join-Path $env:WINDIR 'System32\takeown.exe'
    $icacls = Join-Path $env:WINDIR 'System32\icacls.exe'
    if (-not (Test-Path -LiteralPath $takeown) -or -not (Test-Path -LiteralPath $icacls)) {
        throw "takeown.exe / icacls.exe not found under $($env:WINDIR)\System32."
    }
    Write-Host '[Windows.old] takeown -> icacls -> rd /s /q (may take several minutes)...'
    $p1 = Start-Process -FilePath $takeown -ArgumentList @('/f', $Path, '/r', '/d', 'y') -Wait -PassThru -NoNewWindow
    if ($p1.ExitCode -ne 0) { Write-Warning "takeown exited $($p1.ExitCode); continuing." }
    $p2 = Start-Process -FilePath $icacls -ArgumentList @($Path, '/grant', '*S-1-5-32-544:F', '/t', '/c', '/q') -Wait -PassThru -NoNewWindow
    if ($p2.ExitCode -ne 0) { Write-Warning "icacls exited $($p2.ExitCode); continuing." }
    $p3 = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', 'rd', '/s', '/q', $Path) -Wait -PassThru -NoNewWindow
    if ($p3.ExitCode -ne 0 -and (Test-Path -LiteralPath $Path)) {
        throw "Removing Windows.old failed (exit $($p3.ExitCode)). Folder may still exist: $Path"
    }
    Write-Host '[Windows.old] done.'
}

function Invoke-DeleteAllVolumeShadowCopies {
    param([string] $DriveLetterForVss)
    $vol = ($DriveLetterForVss.TrimEnd(':').ToUpperInvariant() + ':')
    $vssadmin = Join-Path $env:WINDIR 'System32\vssadmin.exe'
    if (-not (Test-Path -LiteralPath $vssadmin)) {
        throw "vssadmin.exe not found under $($env:WINDIR)\System32."
    }
    Write-Host "[vssadmin] delete shadows /For=$vol /All /Quiet"
    & $vssadmin @('delete', 'shadows', "/For=$vol", '/All', '/Quiet')
}

function Clear-WindowsUpdateDownloadFolder {
    param([string] $DownloadPath)
    Write-Host '[wuauserv] stop -> clear Download -> start'
    $wasRunning = $false
    $svc = Get-Service -Name 'wuauserv' -ErrorAction SilentlyContinue
    if ($null -eq $svc) {
        Write-Warning 'wuauserv not found; skipping SoftwareDistribution\Download.'
        return
    }
    $wasRunning = ($svc.Status -eq 'Running')
    if ($wasRunning) {
        Stop-Service -Name 'wuauserv' -Force -ErrorAction Stop
    }
    try {
        if (Test-Path -LiteralPath $DownloadPath) {
            Clear-DirectoryContents -RootPath $DownloadPath
        }
    } finally {
        if ($wasRunning) {
            try {
                Start-Service -Name 'wuauserv' -ErrorAction Stop
                Write-Host '[wuauserv] running again.'
            } catch {
                Write-Warning "Could not restart wuauserv: $($_.Exception.Message)"
            }
        }
    }
}

function Clear-DeliveryOptimizationCacheLayer {
    param([string] $CachePath)
    $docmd = Get-Command Delete-DeliveryOptimizationCache -ErrorAction SilentlyContinue
    if ($null -ne $docmd) {
        Write-Host '[DeliveryOptimization] Delete-DeliveryOptimizationCache -Force'
        try {
            & Delete-DeliveryOptimizationCache -Force
        } catch {
            Write-Warning "Delete-DeliveryOptimizationCache failed: $($_.Exception.Message); trying manual path."
            if (Test-Path -LiteralPath $CachePath) { Clear-DirectoryContents -RootPath $CachePath }
        }
        return
    }
    if (Test-Path -LiteralPath $CachePath) {
        Write-Host "[DeliveryOptimization] manual: $CachePath"
        Clear-DirectoryContents -RootPath $CachePath
    } else {
        Write-Host '[skip] Delivery Optimization cache path missing and cmdlet unavailable.'
    }
}

# --- Deduped user temp roots ---
$tempCandidates = @(
    [System.IO.Path]::GetTempPath()
    (Join-Path $env:LOCALAPPDATA 'Temp')
)
$tempRoots = Get-NormalizedExistingPaths $tempCandidates

$winTemp = Join-Path $env:WINDIR 'Temp'
$awsCache = Join-Path $env:USERPROFILE '.aws\cli\cache'
$nugetCache = Join-Path $env:LOCALAPPDATA 'NuGet\v3-cache'
$windowsOld = Get-WindowsOldPath
$doCache = Get-DeliveryOptimizationCachePath
$wuDownload = Get-WindowsUpdateDownloadPath

$before = Get-VolumeFreeBytes -Letter $DriveLetter
Write-Host "=== win_dev_disk_cleanup ==="
Write-Host ("Drive {0}: free {1} GB (before {2} bytes)" -f $DriveLetter, (Format-Gb $before), $before)
Write-Host ("Mode: {0}" -f $(if ($Execute) { 'EXECUTE (destructive steps enabled for whitelisted targets)' } else { 'DRY-RUN (no file deletion; npm/pip cache commands skipped)' }))

Write-Host "`n-- Estimates (recursive file sum; may take ~1-3 min on large Temp) --"
$estTotal = 0L
foreach ($tr in $tempRoots) {
    $b = Measure-TreeBytes -RootPath $tr
    $estTotal += $b
    Write-Host ("Temp candidate {0} -> ~{1} GB" -f $tr, (Format-Gb $b))
}
if ($IncludeWindowsTemp -and (Test-Path -LiteralPath $winTemp)) {
    $b = Measure-TreeBytes -RootPath $winTemp
    Write-Host ("Windows Temp {0} -> ~{1} GB (IncludeWindowsTemp)" -f $winTemp, (Format-Gb $b))
}
if ($IncludeAwsCliCache -and (Test-Path -LiteralPath $awsCache)) {
    $b = Measure-TreeBytes -RootPath $awsCache
    Write-Host ("AWS CLI cache {0} -> ~{1} GB" -f $awsCache, (Format-Gb $b))
}
if ($IncludeNuGetHttpCache -and (Test-Path -LiteralPath $nugetCache)) {
    $b = Measure-TreeBytes -RootPath $nugetCache
    Write-Host ("NuGet v3-cache {0} -> ~{1} GB" -f $nugetCache, (Format-Gb $b))
}
if ($IncludeWindowsOldRemoval -and (Test-Path -LiteralPath $windowsOld)) {
    Write-Host "Windows.old: measuring (may take several minutes on large trees)..."
    $b = Measure-TreeBytes -RootPath $windowsOld
    $estTotal += $b
    Write-Host ("Windows.old {0} -> ~{1} GB" -f $windowsOld, (Format-Gb $b))
} elseif ($IncludeWindowsOldRemoval) {
    Write-Host "Windows.old: not present; nothing to reclaim."
}
if ($IncludeDeliveryOptimizationCache -and (Test-Path -LiteralPath $doCache)) {
    $b = Measure-TreeBytes -RootPath $doCache
    $estTotal += $b
    Write-Host ("Delivery Optimization cache {0} -> ~{1} GB" -f $doCache, (Format-Gb $b))
}
if ($IncludeWindowsUpdateDownloadCache -and (Test-Path -LiteralPath $wuDownload)) {
    $b = Measure-TreeBytes -RootPath $wuDownload
    $estTotal += $b
    Write-Host ("Windows Update Download {0} -> ~{1} GB" -f $wuDownload, (Format-Gb $b))
}

if ($IncludeDismComponentCleanup -or $IncludeDismResetBase) {
    if (Test-IsAdministrator) {
        try {
            Invoke-DismAnalyzeComponentStore
        } catch {
            Write-Warning "DISM AnalyzeComponentStore: $($_.Exception.Message)"
        }
    } else {
        Write-Warning 'DISM AnalyzeComponentStore skipped in dry-run (run elevated to preview WinSxS reclaim hint).'
    }
}
if ($IncludeVolumeShadowCopies) {
    if (Test-IsAdministrator) {
        $volShadow = $DriveLetter.TrimEnd(':').ToUpperInvariant() + ':'
        $vssList = Join-Path $env:WINDIR 'System32\vssadmin.exe'
        if (Test-Path -LiteralPath $vssList) {
            Write-Host "[vssadmin] list shadows /For=$volShadow (dry-run)"
            try {
                & $vssList @('list', 'shadows', "/For=$volShadow")
            } catch {
                Write-Warning "vssadmin list: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Warning 'vssadmin list shadows skipped in dry-run (requires Administrator).'
    }
}

Write-Host ("Estimated reclaimable from listed trees (upper bound; DISM/vss reclaim not counted in sum): ~{0} GB" -f (Format-Gb $estTotal))

if (-not $Execute) {
    Write-Host "`n[DRY-RUN] No changes made. Re-run with -Execute to apply (see INDEX.md / .NOTES for flags)."
    $after = Get-VolumeFreeBytes -Letter $DriveLetter
    Write-Host ("Drive {0}: free {1} GB (after {2} bytes) - unchanged expected" -f $DriveLetter, (Format-Gb $after), $after)
    exit 0
}

Write-Host "`n-- EXECUTE: system / elevated reclaim (optional switches) --"
if ($IncludeWindowsUpdateDownloadCache) {
    if (-not (Test-IsAdministrator)) {
        Write-Warning 'IncludeWindowsUpdateDownloadCache requires Administrator; skipping.'
    } else {
        try {
            Clear-WindowsUpdateDownloadFolder -DownloadPath $wuDownload
        } catch {
            Write-Warning "WU Download cache clear failed: $($_.Exception.Message)"
        }
    }
}

if ($IncludeDismComponentCleanup -or $IncludeDismResetBase) {
    if (-not (Test-IsAdministrator)) {
        Write-Warning 'DISM StartComponentCleanup requires Administrator; skipping.'
    } else {
        try {
            Invoke-DismStartComponentCleanup -ResetBase:$IncludeDismResetBase
        } catch {
            Write-Warning "DISM StartComponentCleanup failed: $($_.Exception.Message)"
        }
    }
}

if ($IncludeWindowsOldRemoval) {
    if (-not (Test-IsAdministrator)) {
        Write-Warning 'IncludeWindowsOldRemoval requires Administrator; skipping.'
    } else {
        try {
            Remove-WindowsOldTree -Path $windowsOld
        } catch {
            Write-Warning "Windows.old removal failed: $($_.Exception.Message)"
        }
    }
}

if ($IncludeVolumeShadowCopies) {
    if (-not (Test-IsAdministrator)) {
        Write-Warning 'IncludeVolumeShadowCopies requires Administrator; skipping.'
    } else {
        try {
            Invoke-DeleteAllVolumeShadowCopies -DriveLetterForVss $DriveLetter
        } catch {
            Write-Warning "Volume shadow delete failed: $($_.Exception.Message)"
        }
    }
}

if ($IncludeDeliveryOptimizationCache) {
    try {
        Clear-DeliveryOptimizationCacheLayer -CachePath $doCache
    } catch {
        Write-Warning "Delivery Optimization cleanup failed: $($_.Exception.Message)"
    }
}

Write-Host "`n-- EXECUTE: clearing whitelisted directories --"
foreach ($tr in $tempRoots) {
    Write-Host "Clearing: $tr"
    Clear-DirectoryContents -RootPath $tr
}

if ($IncludeWindowsTemp) {
    if (-not (Test-IsAdministrator)) {
        Write-Warning "IncludeWindowsTemp requested but not running elevated; skipping $winTemp (retry as Administrator)."
    } elseif (Test-Path -LiteralPath $winTemp) {
        Write-Host "Clearing (elevated): $winTemp"
        Clear-DirectoryContents -RootPath $winTemp
    }
}

if ($IncludeAwsCliCache -and (Test-Path -LiteralPath $awsCache)) {
    Write-Host "Clearing AWS CLI cache: $awsCache"
    Clear-DirectoryContents -RootPath $awsCache
}

if ($IncludeNuGetHttpCache -and (Test-Path -LiteralPath $nugetCache)) {
    Write-Host "Clearing NuGet HTTP cache: $nugetCache"
    Clear-DirectoryContents -RootPath $nugetCache
}

Write-Host "`n-- Package manager caches (rebuild on next use) --"
try {
    Invoke-NpmCacheClean
} catch {
    Write-Warning "npm cache clean failed: $($_.Exception.Message)"
}
try {
    Invoke-PipCachePurge
} catch {
    Write-Warning "pip cache purge failed: $($_.Exception.Message)"
}

if ($ClearRecycleBin) {
    try {
        Write-Host ("Clearing Recycle Bin for drive {0}" -f $DriveLetter)
        if (Get-Command Clear-RecycleBin -ErrorAction SilentlyContinue) {
            Clear-RecycleBin -DriveLetter $DriveLetter -Force -ErrorAction Stop
        } else {
            Write-Warning 'Clear-RecycleBin cmdlet not available on this PowerShell build.'
        }
    } catch {
        Write-Warning "Recycle Bin clear failed: $($_.Exception.Message)"
    }
}

$after = Get-VolumeFreeBytes -Letter $DriveLetter
$delta = $after - $before
Write-Host "`n=== Summary ==="
Write-Host ("Drive {0}: free {1} GB (after {2} bytes)" -f $DriveLetter, (Format-Gb $after), $after)
Write-Host ("Delta free space: {0} GB ({1} bytes)" -f (Format-Gb $delta), $delta)
if ($delta -lt 0) {
    Write-Warning 'Free space dropped versus snapshot (other processes may be writing; or cleanup removed little while Windows did compaction elsewhere).'
}
exit 0
