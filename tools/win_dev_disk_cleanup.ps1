#requires -Version 5.1
<#
.SYNOPSIS
    Windows short-term disk cleanup for development machines (safe, repeatable).

.DESCRIPTION
    中文说明：
    - 默认 **演练模式**（只报告、不删除），需加 `-Execute` 才真正清理。
    - 仅清理白名单路径（用户临时目录、可选系统 Temp、包管理器缓存等），不触碰项目目录与注册表。
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

.EXAMPLE
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/win_dev_disk_cleanup.ps1

.EXAMPLE
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/win_dev_disk_cleanup.ps1 -Execute -ClearRecycleBin

.NOTES
    风险提示：清理临时目录可能导致少量程序丢失未保存临时文件；请在关闭 IDE/安装程序后再执行 `-Execute`。
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch] $Execute,
    [ValidatePattern('^[A-Za-z]$')]
    [string] $DriveLetter = 'C',
    [switch] $ClearRecycleBin,
    [switch] $IncludeWindowsTemp,
    [switch] $IncludeAwsCliCache,
    [switch] $IncludeNuGetHttpCache
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

# --- Deduped user temp roots ---
$tempCandidates = @(
    [System.IO.Path]::GetTempPath()
    (Join-Path $env:LOCALAPPDATA 'Temp')
)
$tempRoots = Get-NormalizedExistingPaths $tempCandidates

$winTemp = Join-Path $env:WINDIR 'Temp'
$awsCache = Join-Path $env:USERPROFILE '.aws\cli\cache'
$nugetCache = Join-Path $env:LOCALAPPDATA 'NuGet\v3-cache'

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
Write-Host ("Estimated reclaimable from listed trees (upper bound; locks reduce actual): ~{0} GB" -f (Format-Gb $estTotal))

if (-not $Execute) {
    Write-Host "`n[DRY-RUN] No changes made. Re-run with -Execute to apply (see INDEX.md / .NOTES for flags)."
    $after = Get-VolumeFreeBytes -Letter $DriveLetter
    Write-Host ("Drive {0}: free {1} GB (after {2} bytes) - unchanged expected" -f $DriveLetter, (Format-Gb $after), $after)
    exit 0
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
