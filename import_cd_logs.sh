#!/bin/bash

################################################################################
# Script: import_cd_logs.sh
# Description: Import logs from Connect:Direct node CLDBATCHPROD
# Supported log types:
#   - Statistics logs (stats.log)
#   - Process logs (process.log)
#   - Activity logs (activity.log)
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CD_NODE="CLDBATCHPROD"
LOG_DESTINATION="/var/log/connectdirect"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR=""

# Log types to import
declare -a LOG_TYPES=("stats.log" "process.log" "activity.log")

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Import logs from Connect:Direct node CLDBATCHPROD

OPTIONS:
    -s, --source DIR       Source directory containing Connect:Direct logs
                           (required)
    -d, --destination DIR  Destination directory for imported logs
                           (default: ${LOG_DESTINATION})
    -n, --node NAME        Connect:Direct node name
                           (default: ${CD_NODE})
    -t, --type TYPE        Specific log type to import (stats, process, activity)
                           If not specified, all log types will be imported
    -b, --backup           Create backup of existing logs before import
    -h, --help             Display this help message

EXAMPLES:
    # Import all logs from source directory
    $0 --source /opt/cd/logs

    # Import only statistics logs with backup
    $0 --source /opt/cd/logs --type stats --backup

    # Import to custom destination
    $0 --source /opt/cd/logs --destination /custom/path

EOF
    exit 0
}

# Function to validate source directory
validate_source() {
    local src_dir=$1
    if [ ! -d "$src_dir" ]; then
        print_error "Source directory does not exist: $src_dir"
        return 1
    fi
    if [ ! -r "$src_dir" ]; then
        print_error "Source directory is not readable: $src_dir"
        return 1
    fi
    return 0
}

# Function to create destination directory
create_destination() {
    local dest_dir=$1
    if [ ! -d "$dest_dir" ]; then
        print_info "Creating destination directory: $dest_dir"
        mkdir -p "$dest_dir" 2>/dev/null
        if [ $? -ne 0 ]; then
            print_error "Failed to create destination directory: $dest_dir"
            return 1
        fi
    fi
    return 0
}

# Function to backup existing log file
backup_log() {
    local log_file=$1
    local dest_dir=$2
    if [ -f "$log_file" ]; then
        local backup_dir="${dest_dir}/backup"
        mkdir -p "$backup_dir" 2>/dev/null
        local backup_file="${backup_dir}/$(basename $log_file).${TIMESTAMP}.bak"
        print_info "Backing up existing log: $(basename $log_file) -> $backup_file"
        cp "$log_file" "$backup_file"
        if [ $? -eq 0 ]; then
            print_info "Backup created successfully: $backup_file"
            return 0
        else
            print_error "Failed to create backup: $backup_file"
            return 1
        fi
    fi
    return 0
}

# Function to import a specific log file
import_log() {
    local src_file=$1
    local dest_file=$2
    local log_type=$3
    
    if [ ! -f "$src_file" ]; then
        print_warning "Source log file not found: $src_file"
        return 1
    fi
    
    print_info "Importing $log_type from: $src_file"
    print_info "Destination: $dest_file"
    
    # Copy the log file
    cp "$src_file" "$dest_file"
    if [ $? -eq 0 ]; then
        local file_size=$(du -h "$dest_file" | cut -f1)
        print_info "Successfully imported $log_type (Size: $file_size)"
        
        # Display basic statistics
        local line_count=$(wc -l < "$dest_file")
        print_info "Log contains $line_count lines"
        return 0
    else
        print_error "Failed to import $log_type"
        return 1
    fi
}

# Function to process all logs
process_logs() {
    local source_dir=$1
    local dest_dir=$2
    local specific_type=$3
    local do_backup=$4
    
    local success_count=0
    local fail_count=0
    local skip_count=0
    
    print_info "Starting log import from Connect:Direct node: $CD_NODE"
    print_info "Source: $source_dir"
    print_info "Destination: $dest_dir"
    echo ""
    
    for log_file in "${LOG_TYPES[@]}"; do
        local log_type=$(basename "$log_file" .log)
        
        # Skip if specific type is requested and this is not it
        if [ -n "$specific_type" ] && [ "$log_type" != "$specific_type" ]; then
            continue
        fi
        
        local src_path="${source_dir}/${log_file}"
        local dest_path="${dest_dir}/${log_file}"
        
        # Backup if requested
        if [ "$do_backup" = true ]; then
            backup_log "$dest_path" "$dest_dir"
        fi
        
        # Import the log
        if import_log "$src_path" "$dest_path" "$log_type"; then
            ((success_count++))
        else
            if [ -f "$src_path" ]; then
                ((fail_count++))
            else
                ((skip_count++))
            fi
        fi
        echo ""
    done
    
    # Print summary
    echo "=========================================="
    print_info "Import Summary"
    echo "=========================================="
    echo -e "  Successfully imported: ${GREEN}${success_count}${NC} log(s)"
    if [ $fail_count -gt 0 ]; then
        echo -e "  Failed to import:      ${RED}${fail_count}${NC} log(s)"
    fi
    if [ $skip_count -gt 0 ]; then
        echo -e "  Skipped (not found):   ${YELLOW}${skip_count}${NC} log(s)"
    fi
    echo "=========================================="
    
    if [ $fail_count -gt 0 ]; then
        return 1
    fi
    return 0
}

# Main script
main() {
    local source_dir=""
    local dest_dir="$LOG_DESTINATION"
    local specific_type=""
    local do_backup=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--source)
                source_dir="$2"
                shift 2
                ;;
            -d|--destination)
                dest_dir="$2"
                shift 2
                ;;
            -n|--node)
                CD_NODE="$2"
                shift 2
                ;;
            -t|--type)
                specific_type="$2"
                shift 2
                ;;
            -b|--backup)
                do_backup=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    # Validate required parameters
    if [ -z "$source_dir" ]; then
        print_error "Source directory is required"
        echo ""
        usage
    fi
    
    # Validate source directory
    if ! validate_source "$source_dir"; then
        exit 1
    fi
    
    # Create destination directory if needed
    if ! create_destination "$dest_dir"; then
        exit 1
    fi
    
    # Process logs
    if process_logs "$source_dir" "$dest_dir" "$specific_type" "$do_backup"; then
        print_info "Log import completed successfully"
        exit 0
    else
        print_error "Log import completed with errors"
        exit 1
    fi
}

# Run main function
main "$@"
