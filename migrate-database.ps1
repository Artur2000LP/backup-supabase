# Supabase Database Migration Script for Windows PowerShell
# Usage: .\migrate-database.ps1 -BackupDir <path> -TargetDbUrl <url> [options]

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupDir,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetDbUrl,
    
    [switch]$NoRoles,
    [switch]$NoSchema,
    [switch]$NoData,
    [switch]$DryRun,
    [switch]$Verbose,
    [switch]$Help
)

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Gray = "Gray"
}

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { $Colors.Blue }
        "SUCCESS" { $Colors.Green }
        "WARNING" { $Colors.Yellow }
        "ERROR" { $Colors.Red }
        default { $Colors.Gray }
    }
    
    Write-Host "[$timestamp] $Level`: $Message" -ForegroundColor $color
}

function Show-Help {
    Write-Host "Supabase Database Migration Tool for Windows" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage: .\migrate-database.ps1 -BackupDir <path> -TargetDbUrl <url> [options]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -BackupDir     Path to backup directory"
    Write-Host "  -TargetDbUrl   Target Supabase database URL"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -NoRoles       Skip restoring roles"
    Write-Host "  -NoSchema      Skip restoring schema"
    Write-Host "  -NoData        Skip restoring data"
    Write-Host "  -DryRun        Show what would be restored without executing"
    Write-Host "  -Verbose       Show detailed output"
    Write-Host "  -Help          Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\migrate-database.ps1 -BackupDir '.\prisma\backups\latest' -TargetDbUrl 'postgresql://user:pass@host:5432/postgres'"
    Write-Host "  .\migrate-database.ps1 -BackupDir '.\prisma\backups\2026-01-12' -TargetDbUrl `$env:TARGET_DB_URL -NoData"
}

function Test-File {
    param(
        [string]$Path,
        [string]$Type
    )
    
    if (Test-Path $Path) {
        Write-Log "SUCCESS" "$Type backup file found: $Path"
        return $true
    } else {
        Write-Log "WARNING" "$Type backup file not found: $Path"
        return $false
    }
}

function Invoke-Command {
    param(
        [string]$Command,
        [string]$Description
    )
    
    if ($DryRun) {
        Write-Log "INFO" "[DRY RUN] Would execute: $Description"
        if ($Verbose) {
            Write-Host "Command: $Command" -ForegroundColor Gray
        }
    } else {
        Write-Log "INFO" "Executing: $Description"
        if ($Verbose) {
            Write-Host "Command: $Command" -ForegroundColor Gray
        }
        
        try {
            Invoke-Expression $Command
            Write-Log "SUCCESS" "Completed: $Description"
        } catch {
            Write-Log "ERROR" "Failed: $Description - $($_.Exception.Message)"
            throw
        }
    }
}

# Show help if requested
if ($Help) {
    Show-Help
    exit 0
}

# Validate parameters
if (-not $BackupDir -or -not $TargetDbUrl) {
    Write-Log "ERROR" "Missing required parameters"
    Show-Help
    exit 1
}

# Validate backup directory
if (-not (Test-Path $BackupDir -PathType Container)) {
    Write-Log "ERROR" "Backup directory not found: $BackupDir"
    exit 1
}

# Resolve latest if needed
if ((Split-Path $BackupDir -Leaf) -eq "latest") {
    $linkTarget = Get-Item $BackupDir | Select-Object -ExpandProperty Target
    if ($linkTarget) {
        $BackupDir = Join-Path (Split-Path $BackupDir -Parent) $linkTarget
        Write-Log "INFO" "Resolved 'latest' to: $BackupDir"
    }
}

Write-Log "INFO" "Starting database migration process..."
Write-Log "INFO" "Backup directory: $BackupDir"
$maskedUrl = $TargetDbUrl -replace '://[^:]+:[^@]+@', '://***:***@'
Write-Log "INFO" "Target database: $maskedUrl"

# Check for manifest file
$manifestFile = Join-Path $BackupDir "manifest.json"
if (Test-Path $manifestFile) {
    Write-Log "INFO" "Found backup manifest"
    if ($Verbose) {
        Get-Content $manifestFile | Write-Host
    }
}

# Test database connection
Write-Log "INFO" "Testing database connection..."
try {
    $testCommand = "supabase db execute --db-url '$TargetDbUrl' --command 'SELECT 1;'"
    Invoke-Command -Command $testCommand -Description "Database connection test"
} catch {
    Write-Log "ERROR" "Failed to connect to target database"
    exit 1
}

# Prepare file paths
$rolesFile = Join-Path $BackupDir "roles.sql"
$schemaFile = Join-Path $BackupDir "schema.sql"
$dataFile = Join-Path $BackupDir "data.sql"

# Check which files exist
$filesToRestore = @()
if (-not $NoRoles -and (Test-File -Path $rolesFile -Type "Roles")) {
    $filesToRestore += "roles"
}
if (-not $NoSchema -and (Test-File -Path $schemaFile -Type "Schema")) {
    $filesToRestore += "schema"
}
if (-not $NoData -and (Test-File -Path $dataFile -Type "Data")) {
    $filesToRestore += "data"
}

if ($filesToRestore.Count -eq 0) {
    Write-Log "ERROR" "No valid backup files found to restore"
    exit 1
}

Write-Log "INFO" "Files to restore: $($filesToRestore -join ', ')"

# Confirm before proceeding (unless dry run)
if (-not $DryRun) {
    Write-Host ""
    Write-Host "⚠️  WARNING: This will modify the target database!" -ForegroundColor Yellow
    Write-Host "Target: $maskedUrl"
    Write-Host "Files: $($filesToRestore -join ', ')"
    Write-Host ""
    
    $confirmation = Read-Host "Continue? (y/N)"
    if ($confirmation -notmatch '^[Yy]$') {
        Write-Log "INFO" "Migration cancelled by user"
        exit 0
    }
}

# Restore roles
if (-not $NoRoles -and (Test-Path $rolesFile)) {
    $command = "supabase db execute --db-url '$TargetDbUrl' -f '$rolesFile'"
    Invoke-Command -Command $command -Description "Restore roles"
}

# Restore schema
if (-not $NoSchema -and (Test-Path $schemaFile)) {
    $command = "supabase db execute --db-url '$TargetDbUrl' -f '$schemaFile'"
    Invoke-Command -Command $command -Description "Restore schema"
}

# Restore data
if (-not $NoData -and (Test-Path $dataFile)) {
    $command = "supabase db execute --db-url '$TargetDbUrl' -f '$dataFile'"
    Invoke-Command -Command $command -Description "Restore data"
}

Write-Host ""
if ($DryRun) {
    Write-Log "INFO" "Dry run completed successfully"
} else {
    Write-Log "SUCCESS" "🎉 Database migration completed successfully!"
}

Write-Host ""
Write-Log "INFO" "Migration summary:"
Write-Log "INFO" "  Source: $BackupDir"
Write-Log "INFO" "  Target: $maskedUrl"
Write-Log "INFO" "  Roles: $(-not $NoRoles)"
Write-Log "INFO" "  Schema: $(-not $NoSchema)"
Write-Log "INFO" "  Data: $(-not $NoData)"