#requires -Version 5.1
<#
.SYNOPSIS
    Relocate heavy profile folders from C: to another drive using directory junctions (or env vars for Rust).

.DESCRIPTION
    中文说明：
    - 将 **Cursor / VS Code / Chrome User Data** 等大目录 **复制到 D:（或指定根目录）** 后，在原位置建立 **目录联接（junction）**，应用仍读写原路径，实际数据在目标盘。
    - **Rust**：推荐 **搬家 + 设置用户环境变量** `RUSTUP_HOME` / `CARGO_HOME`（并修正 PATH 中的 `.cargo\bin`），**不用** junction，避免与 rustup 假设冲突。
    - 默认 **演练**；加 **`-Execute`** 才执行 **robocopy、重命名原目录、mklink**（Rust 另写环境变量）。
    - 执行前须 **完全退出** 对应进程（脚本可选强制检查）。

    **已知坑**：见 `APPDATA_RELOCATE_LESSONS.md`。
    - Electron（Cursor/VS Code/Chrome）的 WAL 模式 SQLite：进程未完全退出时 robocopy 会复制不一致快照导致 DB 损坏。
    - CacheStorage NTFS 权限：`Remove-Item -Recurse -Force` + `takeown` 均无法删除，必须用**全新路径**避免冲突。
    - `Start-Process` + robocopy 参数引号问题：路径含空格时失败，需改用直接调用。

    **WinSxS**：无法整体迁到其它盘；只能 **管理员** 下用 `DISM /StartComponentCleanup`（或 `/ResetBase`）收缩，勿手动删 `C:\Windows\WinSxS`。请用 `win_dev_disk_cleanup.ps1` 的 `-IncludeDismComponentCleanup` 等。

.PARAMETER TargetRoot
    目标根目录，例如 `D:\ProfileMigrate`。其下会创建 `AppData\Roaming\Cursor` 等镜像路径。

.PARAMETER Execute
    真正执行迁移；未指定时只打印计划与路径。

.PARAMETER All
    等价于同时启用 Cursor、VS Code、Chrome、Rust。

.PARAMETER Cursor
    迁移 `%APPDATA%\Cursor`。

.PARAMETER VSCode
    迁移 `%APPDATA%\Code`。

.PARAMETER ChromeUserData
    迁移 `%LOCALAPPDATA%\Google\Chrome\User Data`。

.PARAMETER Rust
    将 `%USERPROFILE%\.rustup`、`.cargo` 复制到 `TargetRoot\Rust\`，并设置用户级 `RUSTUP_HOME` / `CARGO_HOME` 与 PATH（关闭所有终端后再开新会话验证）。

.PARAMETER SkipProcessCheck
    不检查相关进程是否仍运行（不推荐）。

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File tools/win_appdata_relocate_to_drive.ps1 -TargetRoot D:\ProfileMigrate -All

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File tools/win_appdata_relocate_to_drive.ps1 -TargetRoot D:\ProfileMigrate -All -Execute

.NOTES
    备份：原目录会重命名为 `*_relocate_backup_yyyyMMddHHmmss`；确认无误后可手动删除备份以释放 C: 空间。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $TargetRoot,

    [switch] $Execute,
    [switch] $All,
    [switch] $Cursor,
    [switch] $VSCode,
    [switch] $ChromeUserData,
    [switch] $Rust,
    [switch] $SkipProcessCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($All) {
    $Cursor = $true
    $VSCode = $true
    $ChromeUserData = $true
    $Rust = $true
}

if (-not ($Cursor -or $VSCode -or $ChromeUserData -or $Rust)) {
    Write-Host 'Choose at least one: -Cursor -VSCode -ChromeUserData -Rust, or -All.'
    exit 1
}

$TargetRoot = [System.IO.Path]::GetFullPath($TargetRoot.TrimEnd('\', '/'))

function Test-RobocopySuccess {
    param([int] $ExitCode)
    # Robocopy: 0-7 = success bitflags; >=8 = failure
    return ($ExitCode -lt 8)
}

function Assert-ProcessesClosed {
    param(
        [string[]] $Names,
        [string] $Label
    )
    $running = @()
    foreach ($n in $Names) {
        $running += @(Get-Process -Name $n -ErrorAction SilentlyContinue)
    }
    if ($running.Count -gt 0) {
        $msg = "Close these processes before migrate ($Label): $($Names -join ', '). Still running: $($running.Name -join ', ')"
        throw $msg
    }
}

function Invoke-RobocopyMirror {
    param([string] $Src, [string] $Dst)
    if (-not (Test-Path -LiteralPath $Src)) {
        Write-Host "[skip] Source missing: $Src"
        return $false
    }
    $parent = Split-Path -Parent $Dst
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Write-Host "[robocopy] $Src -> $Dst"
    # NOTE: Use & direct call instead of Start-Process to avoid argument quoting issues
    # with spaces in paths (see APPDATA_RELOCATE_LESSONS.md §3)
    robocopy $Src $Dst /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /MT:8 /XJ /NDL /NFL /NP
    $ec = $LASTEXITCODE
    if (-not (Test-RobocopySuccess $ec)) {
        throw "robocopy failed with exit code $ec"
    }
    return $true
}

function Invoke-JunctionRelocate {
    param(
        [string] $SourceDir,
        [string] $DestDir,
        [string] $Label
    )

    Write-Host "`n=== $Label ==="
    if (-not (Test-Path -LiteralPath $SourceDir)) {
        Write-Host "[skip] $SourceDir absent"
        return
    }

    $item = Get-Item -LiteralPath $SourceDir -Force
    if ($item.LinkType) {
        throw "Source is already a link ($($item.LinkType)): $SourceDir"
    }

    if (-not $Execute) {
        Write-Host "[DRY-RUN] Would mirror -> $DestDir then junction $SourceDir -> $DestDir"
        return
    }

    if (-not (Invoke-RobocopyMirror -Src $SourceDir -Dst $DestDir)) {
        return
    }
    $ts = Get-Date -Format 'yyyyMMddHHmmss'
    $bak = "${SourceDir}_relocate_backup_$ts"
    Write-Host "[step] Move $SourceDir -> $bak"
    Move-Item -LiteralPath $SourceDir -Destination $bak

    $cmdLine = "mklink /J `"$SourceDir`" `"$DestDir`""
    $proc = Start-Process -FilePath cmd.exe -ArgumentList @('/c', $cmdLine) -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -ne 0) {
        Write-Warning "mklink failed (exit $($proc.ExitCode)); restoring..."
        if (Test-Path -LiteralPath $SourceDir) {
            Remove-Item -LiteralPath $SourceDir -Force -Recurse -ErrorAction SilentlyContinue
        }
        Move-Item -LiteralPath $bak -Destination $SourceDir
        throw "mklink failed; original folder restored at $SourceDir"
    }
    Write-Host "[ok] Junction $SourceDir -> $DestDir ; backup at $bak (delete manually after verification)."
    # Clear WAL/SHM/LOCK residues that cause "storage corrupted" on Electron apps
    Clear-WalShmResidue -Dir $DestDir
}

function Clear-WalShmResidue {
    param([string] $Dir)
    # Electron apps leave WAL/SHM/LOCK files that cause "storage corrupted" on next launch
    Get-ChildItem -LiteralPath $Dir -Recurse -Force -Include '*.shm', '*.wal', 'LOCK' -Depth 5 -ErrorAction SilentlyContinue |
        Where-Object { -not $_.PSIsContainer } |
        ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
        }
    Write-Host "[clean] WAL/SHM/LOCK residues removed under $Dir"
}

function Invoke-RustRelocate {
    param([string] $Root)

    $rustupSrc = Join-Path $env:USERPROFILE '.rustup'
    $cargoSrc = Join-Path $env:USERPROFILE '.cargo'
    $rustupDst = Join-Path $Root 'Rust\.rustup'
    $cargoDst = Join-Path $Root 'Rust\.cargo'

    Write-Host "`n=== Rust (RUSTUP_HOME / CARGO_HOME) ==="
    if (-not ((Test-Path -LiteralPath $rustupSrc) -or (Test-Path -LiteralPath $cargoSrc))) {
        Write-Host '[skip] Neither .rustup nor .cargo present under profile.'
        return
    }

    if (-not $Execute) {
        Write-Host "[DRY-RUN] Would robocopy .rustup -> $rustupDst , .cargo -> $cargoDst ; set user env ; adjust PATH."
        return
    }

    if (Test-Path -LiteralPath $rustupSrc) {
        $null = Invoke-RobocopyMirror -Src $rustupSrc -Dst $rustupDst
    }
    if (Test-Path -LiteralPath $cargoSrc) {
        $null = Invoke-RobocopyMirror -Src $cargoSrc -Dst $cargoDst
    }

    $ts = Get-Date -Format 'yyyyMMddHHmmss'
    $rustBak = Join-Path $env:USERPROFILE (".rustup_relocate_backup_$ts")
    $cargoBak = Join-Path $env:USERPROFILE (".cargo_relocate_backup_$ts")
    if (Test-Path -LiteralPath $rustupSrc) {
        Move-Item -LiteralPath $rustupSrc -Destination $rustBak
    }
    if (Test-Path -LiteralPath $cargoSrc) {
        Move-Item -LiteralPath $cargoSrc -Destination $cargoBak
    }

    [System.Environment]::SetEnvironmentVariable('RUSTUP_HOME', $rustupDst, 'User')
    [System.Environment]::SetEnvironmentVariable('CARGO_HOME', $cargoDst, 'User')

    $oldBin = Join-Path $env:USERPROFILE '.cargo\bin'
    $newBin = Join-Path $cargoDst 'bin'
    $userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    if ([string]::IsNullOrEmpty($userPath)) { $userPath = '' }
    $parts = $userPath -split ';' | Where-Object { $_ -and ($_ -ne $oldBin) -and ($_ -ne $newBin) }
    $newPath = ($newBin, ($parts -join ';') ) -join ';'
    $newPath = $newPath.TrimEnd(';')
    [System.Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')

    Write-Host "[ok] User env RUSTUP_HOME=$rustupDst , CARGO_HOME=$cargoDst"
    Write-Host "[ok] PATH prepended with $newBin"
    Write-Host "Log off and on (or reboot), open NEW terminal, run:  where.exe rustc"
    if (Test-Path -LiteralPath $rustBak) {
        Write-Host "Rust backup: $rustBak (delete after verification)."
    }
    if (Test-Path -LiteralPath $cargoBak) {
        Write-Host "Cargo backup: $cargoBak (delete after verification)."
    }
}

# --- optional process guard ---
if ($Execute -and -not $SkipProcessCheck) {
    if ($Cursor) {
        Assert-ProcessesClosed -Names @('Cursor') -Label 'Cursor'
    }
    if ($VSCode) {
        Assert-ProcessesClosed -Names @('Code') -Label 'VS Code'
    }
    if ($ChromeUserData) {
        Assert-ProcessesClosed -Names @('chrome') -Label 'Chrome'
    }
    if ($Rust) {
        Assert-ProcessesClosed -Names @('rustc', 'cargo', 'rustup') -Label 'Rust toolchain'
    }
}

Write-Host "=== win_appdata_relocate_to_drive ==="
Write-Host "TargetRoot: $TargetRoot"
Write-Host ("Mode: {0}" -f ($(if ($Execute) { 'EXECUTE' } else { 'DRY-RUN' })))

if ($Cursor) {
    $dest = Join-Path $TargetRoot 'AppData\Roaming\Cursor'
    Invoke-JunctionRelocate -SourceDir (Join-Path $env:APPDATA 'Cursor') -DestDir $dest -Label 'Cursor (Roaming)'
}

if ($VSCode) {
    $dest = Join-Path $TargetRoot 'AppData\Roaming\Code'
    Invoke-JunctionRelocate -SourceDir (Join-Path $env:APPDATA 'Code') -DestDir $dest -Label 'VS Code (Roaming)'
}

if ($ChromeUserData) {
    $dest = Join-Path $TargetRoot 'AppData\Local\Google\Chrome\User Data'
    Invoke-JunctionRelocate -SourceDir (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data') -DestDir $dest -Label 'Chrome User Data'
}

if ($Rust) {
    Invoke-RustRelocate -Root $TargetRoot
}

if (-not $Execute) {
    Write-Host "`n[DRY-RUN] Done. Re-run with -Execute after closing apps."
} else {
    Write-Host "`nDone. WinSxS: use win_dev_disk_cleanup.ps1 -IncludeDismComponentCleanup (elev)."
}
exit 0
