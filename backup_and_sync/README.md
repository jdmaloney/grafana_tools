# Grafana Backup & Sync

## Assumptions
- For backup passwordless SSH is to be enabled beween host source and destination server (just needs to be one-way passwordless)
- For syncing both Grafana instances must use the same backing database type and have it located at the same path if using sqlite3


## Usage

### Backup
- Fill in variables as needed
- `./grafana_backup.sh`

### Restore
- Fill in variables as needed
- `./grafana_restore.sh /path/to/backup/file`

### Sync
- Fill in variables as needed
- `./grafana_sync.sh`
