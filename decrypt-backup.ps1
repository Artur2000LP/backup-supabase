# Script para desencriptar backups de Supabase (PowerShell)
# Uso: .\decrypt-backup.ps1 -BackupDate "2026-01-12" [-EncryptionKey "clave"]

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupDate,
    
    [Parameter(Mandatory=$false)]
    [string]$EncryptionKey,
    
    [switch]$Help
)

# Colores para output
$Colors = @{
    Red = "Red"
    Green = "Green" 
    Yellow = "Yellow"
    Blue = "Blue"
    Gray = "Gray"
}

function Write-ColorLog {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Show-Help {
    Write-ColorLog "🔓 Desencriptador de Backups Supabase" "Blue"
    Write-Host ""
    Write-ColorLog "Uso: .\decrypt-backup.ps1 -BackupDate <fecha> [-EncryptionKey <clave>]" "Yellow"
    Write-Host ""
    Write-ColorLog "Parámetros:" "Blue"
    Write-Host "  -BackupDate        Fecha del backup (YYYY-MM-DD) o 'latest'"
    Write-Host "  -EncryptionKey     Clave de encriptación (opcional)"
    Write-Host ""
    Write-ColorLog "Ejemplos:" "Yellow"
    Write-Host '  .\decrypt-backup.ps1 -BackupDate "2026-01-12"'
    Write-Host '  .\decrypt-backup.ps1 -BackupDate "latest"'
    Write-Host ""
}

if ($Help) {
    Show-Help
    exit 0
}

# Determinar directorio de backup
if ($BackupDate -eq "latest") {
    $BackupDir = "prisma\backups\latest"
    if (-not (Test-Path $BackupDir)) {
        Write-ColorLog "❌ Error: No se encontró backup 'latest'" "Red"
        exit 1
    }
    # Resolver enlace para obtener fecha real
    $RealDir = Get-Item $BackupDir | Select-Object -ExpandProperty Target
    if ($RealDir) {
        $ActualDate = Split-Path $RealDir -Leaf
        Write-ColorLog "📅 Usando backup más reciente: $ActualDate" "Blue"
    }
} else {
    $BackupDir = "prisma\backups\$BackupDate"
}

# Verificar directorio
if (-not (Test-Path $BackupDir)) {
    Write-ColorLog "❌ Error: No se encontró backup para fecha $BackupDate" "Red"
    Write-ColorLog "💡 Backups disponibles:" "Yellow"
    if (Test-Path "prisma\backups") {
        Get-ChildItem "prisma\backups" | ForEach-Object { Write-Host "  - $($_.Name)" }
    } else {
        Write-Host "No hay backups disponibles"
    }
    exit 1
}

# Verificar archivos encriptados
$EncryptedFiles = @(
    "$BackupDir\roles.sql.enc",
    "$BackupDir\schema.sql.enc", 
    "$BackupDir\data.sql.enc"
)

foreach ($file in $EncryptedFiles) {
    if (-not (Test-Path $file)) {
        Write-ColorLog "❌ Error: Archivo encriptado no encontrado: $file" "Red"
        exit 1
    }
}

# Solicitar clave si no se proporcionó
if (-not $EncryptionKey) {
    Write-ColorLog "🔑 Introduce la clave de encriptación:" "Yellow"
    $EncryptionKey = Read-Host -AsSecureString
    $EncryptionKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($EncryptionKey))
}

# Verificar que GPG esté disponible
try {
    $null = Get-Command gpg -ErrorAction Stop
} catch {
    Write-ColorLog "❌ Error: GPG no está instalado. Instálalo desde: https://gpg4win.org/" "Red"
    exit 1
}

# Crear directorio para archivos desencriptados
$DecryptedDir = "$BackupDir\decrypted"
New-Item -ItemType Directory -Path $DecryptedDir -Force | Out-Null

Write-ColorLog "🔓 Iniciando desencriptación..." "Blue"

# Desencriptar archivos
$FileTypes = @("roles", "schema", "data")
$Success = $true

foreach ($fileType in $FileTypes) {
    $encryptedFile = "$BackupDir\$fileType.sql.enc"
    $decryptedFile = "$DecryptedDir\$fileType.sql"
    
    Write-ColorLog "🔄 Desencriptando $fileType..." "Yellow"
    
    try {
        # Usar GPG para desencriptar
        $process = Start-Process -FilePath "gpg" -ArgumentList @(
            "--batch", 
            "--yes", 
            "--passphrase", $EncryptionKey,
            "--decrypt", $encryptedFile
        ) -RedirectStandardOutput $decryptedFile -RedirectStandardError $null -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0 -and (Test-Path $decryptedFile)) {
            Write-ColorLog "✅ $fileType desencriptado correctamente" "Green"
            $size = [math]::Round((Get-Item $decryptedFile).Length / 1KB, 2)
            Write-Host "   📊 Tamaño: ${size} KB"
        } else {
            Write-ColorLog "❌ Error desencriptando $fileType - Verifica la clave" "Red"
            $Success = $false
            break
        }
    } catch {
        Write-ColorLog "❌ Error: $($_.Exception.Message)" "Red"
        $Success = $false
        break
    }
}

if ($Success) {
    Write-Host ""
    Write-ColorLog "🎉 ¡Desencriptación completada!" "Green"
    Write-ColorLog "📁 Archivos disponibles en: $DecryptedDir" "Blue"
    Write-Host ""
    Write-ColorLog "📋 Archivos desencriptados:" "Yellow"
    Get-ChildItem $DecryptedDir | ForEach-Object { 
        $size = [math]::Round($_.Length / 1KB, 2)
        Write-Host "  - $($_.Name) (${size} KB)"
    }
    
    Write-Host ""
    Write-ColorLog "🔧 Para restaurar tu base de datos:" "Blue"
    Write-Host "1. Roles: psql `$DB_URL -f $DecryptedDir\roles.sql" -ForegroundColor Yellow
    Write-Host "2. Esquema: psql `$DB_URL -f $DecryptedDir\schema.sql" -ForegroundColor Yellow
    Write-Host "3. Datos: psql `$DB_URL -f $DecryptedDir\data.sql" -ForegroundColor Yellow
    
    Write-Host ""
    Write-ColorLog "⚠️  IMPORTANTE: Los archivos desencriptados contienen datos sensibles." "Red"
    Write-ColorLog "   Elimínalos cuando termines: Remove-Item -Recurse -Force $DecryptedDir" "Red"
} else {
    Write-ColorLog "💥 Desencriptación falló. Verifica la clave de encriptación." "Red"
    exit 1
}