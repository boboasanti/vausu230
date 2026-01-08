# Connect:Direct Log Import Script

## Overview

The `import_cd_logs.sh` script is designed to import logs from Connect:Direct node **CLDBATCHPROD**. It supports importing multiple log types including statistics logs, process logs, and activity logs.

## Features

- **Multiple Log Type Support**: Import statistics logs (`stats.log`), process logs (`process.log`), and activity logs (`activity.log`)
- **Flexible Configuration**: Customize source, destination, and node name
- **Selective Import**: Import all logs or specific log types
- **Backup Capability**: Create timestamped backups of existing logs before importing
- **Error Handling**: Comprehensive validation and error reporting
- **Import Statistics**: Summary of successful, failed, and skipped imports
- **Colored Output**: Easy-to-read colored console output

## Requirements

- Unix/Linux operating system
- Bash shell
- Read permissions on source log directory
- Write permissions on destination log directory

## Installation

1. Copy the script to your desired location:
   ```bash
   cp import_cd_logs.sh /usr/local/bin/
   ```

2. Make the script executable:
   ```bash
   chmod +x /usr/local/bin/import_cd_logs.sh
   ```

## Usage

### Basic Syntax

```bash
./import_cd_logs.sh [OPTIONS]
```

### Options

| Option | Description |
|--------|-------------|
| `-s, --source DIR` | Source directory containing Connect:Direct logs (required) |
| `-d, --destination DIR` | Destination directory for imported logs (default: `/var/log/connectdirect`) |
| `-n, --node NAME` | Connect:Direct node name (default: `CLDBATCHPROD`) |
| `-t, --type TYPE` | Specific log type to import: `stats`, `process`, or `activity` (optional) |
| `-b, --backup` | Create backup of existing logs before import |
| `-h, --help` | Display help message |

### Examples

#### Import All Logs

Import all log types from the source directory:

```bash
./import_cd_logs.sh --source /opt/cd/logs
```

#### Import Specific Log Type

Import only statistics logs:

```bash
./import_cd_logs.sh --source /opt/cd/logs --type stats
```

#### Import with Backup

Import all logs and create backups of existing logs:

```bash
./import_cd_logs.sh --source /opt/cd/logs --backup
```

#### Custom Destination

Import logs to a custom destination directory:

```bash
./import_cd_logs.sh --source /opt/cd/logs --destination /custom/log/path
```

#### Change Node Name

Import logs from a different Connect:Direct node:

```bash
./import_cd_logs.sh --source /opt/cd/logs --node CDPRODNODE01
```

#### Combined Options

Import only process logs with backup to a custom location:

```bash
./import_cd_logs.sh --source /opt/cd/logs --destination /var/log/cd --type process --backup
```

## Log Types

The script supports importing the following log types:

### 1. Statistics Logs (`stats.log`)
Contains statistical information about Connect:Direct operations:
- Number of files transferred
- Data volume
- Transfer speeds
- Success rates

### 2. Process Logs (`process.log`)
Contains information about individual processes:
- Job start and completion
- File transfer status
- Process errors and warnings

### 3. Activity Logs (`activity.log`)
Contains general activity information:
- Node startup/shutdown
- Configuration changes
- Connection events
- Health checks

## Output

The script provides colored output for easy readability:

- **GREEN [INFO]**: Informational messages
- **YELLOW [WARNING]**: Warning messages
- **RED [ERROR]**: Error messages

### Import Summary

At the end of execution, the script displays a summary:

```
==========================================
[INFO] Import Summary
==========================================
  Successfully imported: 3 log(s)
  Failed to import:      0 log(s)
  Skipped (not found):   0 log(s)
==========================================
```

## Backup Files

When the `--backup` option is used, the script creates timestamped backups:

- Location: `<destination_dir>/backup/`
- Format: `<log_filename>.<timestamp>.bak`
- Example: `stats.log.20260108_143045.bak`

## Exit Codes

| Exit Code | Description |
|-----------|-------------|
| 0 | Success - All logs imported successfully |
| 1 | Error - One or more logs failed to import or validation error |

## Troubleshooting

### Permission Denied Error

If you encounter permission denied errors:

```bash
# Ensure you have read permissions on source directory
chmod +r /path/to/source/*

# Ensure you have write permissions on destination directory
chmod +w /path/to/destination
```

### Source Directory Not Found

Verify the source directory path:

```bash
ls -la /path/to/source
```

### Logs Not Found in Source

The script will skip logs that don't exist in the source directory and display a warning. This is normal behavior if not all log types are present.

## Best Practices

1. **Use Backup Option**: Always use `--backup` when importing to directories with existing logs
2. **Verify Source**: Ensure the source directory contains the expected log files before running
3. **Check Permissions**: Verify read/write permissions before execution
4. **Review Summary**: Always check the import summary for any skipped or failed imports
5. **Regular Imports**: Schedule regular imports using cron for automated log collection

## Scheduling with Cron

To automatically import logs daily at 2 AM:

```bash
# Edit crontab
crontab -e

# Add the following line
0 2 * * * /usr/local/bin/import_cd_logs.sh --source /opt/cd/logs --backup >> /var/log/cd_import.log 2>&1
```

## Support

For issues or questions, please refer to the script's help documentation:

```bash
./import_cd_logs.sh --help
```
