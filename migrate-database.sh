#!/bin/bash

# Supabase Database Migration Script
# Usage: ./migrate-database.sh <source-backup-dir> <target-db-url> [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RESTORE_ROLES=true
RESTORE_SCHEMA=true
RESTORE_DATA=true
DRY_RUN=false
VERBOSE=false

# Function to display help
show_help() {
    echo "Supabase Database Migration Tool"
    echo ""
    echo "Usage: $0 <backup-dir> <target-db-url> [options]"
    echo ""
    echo "Arguments:"
    echo "  backup-dir     Path to backup directory (e.g., ./prisma/backups/2026-01-12)"
    echo "  target-db-url  Target Supabase database URL"
    echo ""
    echo "Options:"
    echo "  --no-roles     Skip restoring roles"
    echo "  --no-schema    Skip restoring schema"
    echo "  --no-data      Skip restoring data"
    echo "  --dry-run      Show what would be restored without executing"
    echo "  --verbose      Show detailed output"
    echo "  --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 ./prisma/backups/latest postgresql://user:pass@host:5432/postgres"
    echo "  $0 ./prisma/backups/2026-01-12 \$TARGET_DB_URL --no-data"
    echo "  $0 ./my-backup \$TARGET_DB_URL --dry-run --verbose"
}

# Function to log messages
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${BLUE}[$timestamp] INFO:${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[$timestamp] SUCCESS:${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[$timestamp] WARNING:${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[$timestamp] ERROR:${NC} $message"
            ;;
    esac
}

# Function to check if file exists
check_file() {
    local file=$1
    local type=$2
    
    if [ -f "$file" ]; then
        log "SUCCESS" "$type backup file found: $file"
        return 0
    else
        log "WARNING" "$type backup file not found: $file"
        return 1
    fi
}

# Function to execute or dry run
execute_or_dry_run() {
    local command=$1
    local description=$2
    
    if [ "$DRY_RUN" = true ]; then
        log "INFO" "[DRY RUN] Would execute: $description"
        if [ "$VERBOSE" = true ]; then
            echo "Command: $command"
        fi
    else
        log "INFO" "Executing: $description"
        if [ "$VERBOSE" = true ]; then
            echo "Command: $command"
        fi
        eval "$command"
        log "SUCCESS" "Completed: $description"
    fi
}

# Parse arguments
BACKUP_DIR=""
TARGET_DB_URL=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-roles)
            RESTORE_ROLES=false
            shift
            ;;
        --no-schema)
            RESTORE_SCHEMA=false
            shift
            ;;
        --no-data)
            RESTORE_DATA=false
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        -*)
            log "ERROR" "Unknown option $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$BACKUP_DIR" ]; then
                BACKUP_DIR=$1
            elif [ -z "$TARGET_DB_URL" ]; then
                TARGET_DB_URL=$1
            else
                log "ERROR" "Too many arguments"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$BACKUP_DIR" ] || [ -z "$TARGET_DB_URL" ]; then
    log "ERROR" "Missing required arguments"
    show_help
    exit 1
fi

# Validate backup directory
if [ ! -d "$BACKUP_DIR" ]; then
    log "ERROR" "Backup directory not found: $BACKUP_DIR"
    exit 1
fi

# Resolve latest if needed
if [ "$(basename "$BACKUP_DIR")" = "latest" ]; then
    if [ -L "$BACKUP_DIR" ]; then
        RESOLVED_DIR=$(readlink "$BACKUP_DIR")
        BACKUP_DIR="$(dirname "$BACKUP_DIR")/$RESOLVED_DIR"
        log "INFO" "Resolved 'latest' to: $BACKUP_DIR"
    fi
fi

log "INFO" "Starting database migration process..."
log "INFO" "Backup directory: $BACKUP_DIR"
log "INFO" "Target database: ${TARGET_DB_URL%@*}@***" # Hide password in logs

# Check for manifest file
MANIFEST_FILE="$BACKUP_DIR/manifest.json"
if [ -f "$MANIFEST_FILE" ]; then
    log "INFO" "Found backup manifest"
    if [ "$VERBOSE" = true ]; then
        cat "$MANIFEST_FILE"
    fi
fi

# Test database connection
log "INFO" "Testing database connection..."
if ! execute_or_dry_run "supabase db execute --db-url '$TARGET_DB_URL' --command 'SELECT 1;'" "Database connection test"; then
    log "ERROR" "Failed to connect to target database"
    exit 1
fi

# Prepare file paths
ROLES_FILE="$BACKUP_DIR/roles.sql"
SCHEMA_FILE="$BACKUP_DIR/schema.sql"
DATA_FILE="$BACKUP_DIR/data.sql"

# Check which files exist
FILES_TO_RESTORE=""
[ "$RESTORE_ROLES" = true ] && check_file "$ROLES_FILE" "Roles" && FILES_TO_RESTORE="$FILES_TO_RESTORE roles"
[ "$RESTORE_SCHEMA" = true ] && check_file "$SCHEMA_FILE" "Schema" && FILES_TO_RESTORE="$FILES_TO_RESTORE schema"
[ "$RESTORE_DATA" = true ] && check_file "$DATA_FILE" "Data" && FILES_TO_RESTORE="$FILES_TO_RESTORE data"

if [ -z "$FILES_TO_RESTORE" ]; then
    log "ERROR" "No valid backup files found to restore"
    exit 1
fi

log "INFO" "Files to restore:$FILES_TO_RESTORE"

# Confirm before proceeding (unless dry run)
if [ "$DRY_RUN" = false ]; then
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: This will modify the target database!${NC}"
    echo -e "Target: ${TARGET_DB_URL%@*}@***"
    echo -e "Files:$FILES_TO_RESTORE"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "Migration cancelled by user"
        exit 0
    fi
fi

# Restore roles
if [ "$RESTORE_ROLES" = true ] && [ -f "$ROLES_FILE" ]; then
    execute_or_dry_run "supabase db execute --db-url '$TARGET_DB_URL' -f '$ROLES_FILE'" "Restore roles"
fi

# Restore schema
if [ "$RESTORE_SCHEMA" = true ] && [ -f "$SCHEMA_FILE" ]; then
    execute_or_dry_run "supabase db execute --db-url '$TARGET_DB_URL' -f '$SCHEMA_FILE'" "Restore schema"
fi

# Restore data
if [ "$RESTORE_DATA" = true ] && [ -f "$DATA_FILE" ]; then
    execute_or_dry_run "supabase db execute --db-url '$TARGET_DB_URL' -f '$DATA_FILE'" "Restore data"
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    log "INFO" "Dry run completed successfully"
else
    log "SUCCESS" "🎉 Database migration completed successfully!"
fi

echo ""
log "INFO" "Migration summary:"
log "INFO" "  Source: $BACKUP_DIR"
log "INFO" "  Target: ${TARGET_DB_URL%@*}@***"
log "INFO" "  Roles: $RESTORE_ROLES"
log "INFO" "  Schema: $RESTORE_SCHEMA"
log "INFO" "  Data: $RESTORE_DATA"