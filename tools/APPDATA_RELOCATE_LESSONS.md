# AppData Relocate 实战经验总结

> 2026-05-10 | Cursor / Chrome / VS Code 从 C: 迁移到 D: 的完整实战记录
> 详见：[迁移脚本](win_appdata_relocate_to_drive.ps1)

---

## 1. 核心教训：进程必须完全退出

**症状**：迁移后 Cursor 报 `state.vscdb` 损坏，提示重新登录，历史会话丢失。

**根因**：Electron 应用（Cursor/VS Code/Chrome）使用 SQLite + WAL 模式存储状态。
`robocopy` 在应用运行时复制数据，会捕获到 **不一致的 WAL/SHM 快照**——数据库文件本身是旧版本，
WAL 文件中有未提交的写入，两者不匹配时 SQLite 判定为损坏。

**处理过程**：
1. 确认 junction 本身正常工作（文件系统层面的重定向没问题）
2. `state.vscdb` 的 SQLite header 正常，`cursorDiskKV` 表 39.8 万行数据完整
3. 残留的 `state.vscdb-shm`（32768 bytes）和 `state.vscdb-wal`（0 bytes）表明 WAL 模式未正常关闭
4. 用 Python `sqlite3` + `ATTACH DATABASE` 重建 DB 后，Cursor 仍然报错
5. 最终发现：C 盘备份中的同一份数据可以工作——说明问题不是 `state.vscdb` 本身，而是 **D 盘目标路径有残留的旧版文件**（robocopy 因权限问题未能覆盖）

**教训**：
- 迁移前必须用 `Get-Process` 确认目标进程已完全退出（包括后台进程，如 Cursor 的 `CraspadiPad` 子进程等）
- 迁移后必须清理目标路径中的所有 WAL/SHM/LOCK 残留文件
- 迁移后**验证**：用 `sqlite3 $db ".integrity_check"` 验证 DB 完整性

## 2. Electron CacheStorage 的 NTFS 特殊权限

**症状**：`Remove-Item -Recurse -Force` 和 `takeown` + `icacls` 均无法删除
`D:\ProfileMigrate\AppData\Roaming\Cursor\WebStorage\*\CacheStorage\*\` 下的文件。

**根因**：Chrome/Electron 的 IndexedDB CacheStorage 在 NTFS 上设置了
`FILE_ATTRIBUTE_ACCESS_BASED_ENTRY_LEVEL` 等特殊属性，普通管理员权限也无法强制删除。
即使 `takeown /R` + `icacls /grant:F` 也无法绕过。

**解决方案**：
- **不要试图删除旧路径**。改用**全新的子路径**来避免旧权限污染。
- 例如旧路径 `Cursor` 不可删，则新建 `Cursor_v2` → 复制数据 → 重新指向 junction。
- 迁移脚本应默认使用带时间戳的路径，避免与旧路径重名。

## 3. `Start-Process` + robocopy 参数引号问题

**症状**：`Invoke-RobocopyMirror` 函数中 `Start-Process` 传递的数组参数 `$arg`
包含空格路径时，robocopy 报 "invalid parameter #3" 错误（路径被截断）。

**根因**：`Start-Process` 的 `-ArgumentList` 参数传递方式在 PowerShell 5.1 中
对包含空格的路径处理有缺陷——`$arg` 数组的元素在内部被错误拼接。

**解决方案**：
- 方案 A：用 `cmd /c "robocopy ..."` 代替 `Start-Process`
- 方案 B：手动用 `& robocopy $src $dst ...` 直接调用（传参数组时用 `--%` 停止解析）
- 脚本中 `Invoke-RobocopyMirror` 函数需要修复

## 4. 安全迁移流程（修正版）

### 正确步骤

```powershell
# 0. 完全退出目标应用（检查任务管理器无残留进程）
# 1. 改名原目录为备份（瞬间完成，不占额外空间）
Rename-Item -Path "$env:APPDATA\Cursor" -Destination "$env:APPDATA\Cursor_backup_$ts"
# 2. 使用全新的 D 盘路径（避开旧路径的权限污染）
$newDst = "D:\ProfileMigrate\CursorData"
New-Item -ItemType Directory -Path $newDst -Force
# 3. 从备份复制到新路径
robocopy "$env:APPDATA\Cursor_backup_$ts" $newDst /E /COPY:DAT /DCOPY:DAT
# 4. 验证 DB 完整性
sqlite3 "$newDst\User\globalStorage\state.vscdb" "SELECT count(*), typeof(key) FROM cursorDiskKV;"
# 5. 清理残留 WAL/SHM
Remove-Item "$newDst\User\globalStorage\state.vscdb-shm" -Force -ErrorAction SilentlyContinue
Remove-Item "$newDst\User\globalStorage\state.vscdb-wal" -Force -ErrorAction SilentlyContinue
# 6. 创建 junction
cmd /c "mklink /J `"$env:APPDATA\Cursor`" `"$newDst`""
# 7. 验证通过 junction 访问
sqlite3 "$env:APPDATA\Cursor\User\globalStorage\state.vscdb" ".integrity_check"
# 8. 启动应用验证功能正常
# 9. 确认正常后删除 C 盘备份
Remove-Item "$env:APPDATA\Cursor_backup_$ts" -Recurse -Force
```

### 验证清单

- [ ] `sqlite3 $db ".integrity_check"` 返回 `ok`
- [ ] 应用启动后不报存储错误
- [ ] 历史会话/配置/登录状态完整
- [ ] 无残留 `*-shm` / `*-wal` / `LOCK` 文件
- [ ] C 盘空闲空间至少增加备份目录大小

## 5. 迁移脚本待修复项

1. `Invoke-RobocopyMirror` 函数：`Start-Process` 改为直接 `robocopy` 调用
2. 迁移目标路径：增加时间戳后缀，避免与旧路径冲突
3. 迁移完成后：自动清理目标路径中的 WAL/SHM/LOCK 残留文件
4. SQLite 完整性验证：迁移完成后自动执行 `sqlite3 $db ".integrity_check"`
