# Git Repository Backup Architecture

## Active: 2026-06-05

## Destinations
- **gitmirror01**: `git-server:/mnt/backup/gitmirror01/` (USB HDD 500G, NTFS)
- **gitmirror02**: `pi@192.168.2.13:/gitmirror02/` (SD card 106G)

## Backup Strategy
| Type | Repos | Trigger | Destinations |
|------|-------|---------|-------------|
| Real-time | ai-lib-constitution, ai-lib-plans, papers | post-receive hook | gitmirror01 + 02 |
| Daily @ 11:00 | All 7 repos | cron (git-server) | gitmirror01 + 02 |

## Recovery
```bash
git clone /mnt/backup/gitmirror01/<repo>.bundle <target-dir>
# Or from piubt:
git clone /gitmirror02/<repo>.bundle <target-dir>
```
