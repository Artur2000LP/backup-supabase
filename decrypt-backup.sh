#!/bin/bash
# Script para desencriptar backups de Supabase
# Uso: ./decrypt-backup.sh <fecha-backup> <clave-encriptacion>

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
show_help() {
    echo "🔓 Desencriptador de Backups Supabase"
    echo ""
    echo "Uso: $0 <fecha-backup> [clave-encriptacion]"
    echo ""
    echo "Argumentos:"
    echo "  fecha-backup        Fecha del backup (YYYY-MM-DD) o 'latest'"
    echo "  clave-encriptacion  Clave de encriptación (opcional, la pedirá si no se proporciona)"
    echo ""
    echo "Ejemplos:"
    echo "  $0 2026-01-12"
    echo "  $0 latest"
    echo "  $0 2026-01-12 MiClave_SuperSegura_2026!"
    echo ""
}

# Validar argumentos
if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ $# -lt 1 ]; then
    show_help
    exit 0
fi

BACKUP_DATE=$1
ENCRYPTION_KEY=$2

# Determinar directorio de backup
if [ "$BACKUP_DATE" = "latest" ]; then
    BACKUP_DIR="prisma/backups/latest"
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${RED}❌ Error: No se encontró backup 'latest'${NC}"
        exit 1
    fi
    # Resolver enlace simbólico para obtener fecha real
    REAL_DIR=$(readlink -f "$BACKUP_DIR")
    ACTUAL_DATE=$(basename "$REAL_DIR")
    echo -e "${BLUE}📅 Usando backup más reciente: $ACTUAL_DATE${NC}"
else
    BACKUP_DIR="prisma/backups/$BACKUP_DATE"
fi

# Verificar que existe el directorio
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}❌ Error: No se encontró backup para fecha $BACKUP_DATE${NC}"
    echo -e "${YELLOW}💡 Backups disponibles:${NC}"
    ls -la prisma/backups/ 2>/dev/null || echo "No hay backups disponibles"
    exit 1
fi

# Verificar archivos encriptados
ENCRYPTED_FILES=("$BACKUP_DIR/roles.sql.enc" "$BACKUP_DIR/schema.sql.enc" "$BACKUP_DIR/data.sql.enc")
for file in "${ENCRYPTED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Error: Archivo encriptado no encontrado: $file${NC}"
        exit 1
    fi
done

# Solicitar clave si no se proporcionó
if [ -z "$ENCRYPTION_KEY" ]; then
    echo -e "${YELLOW}🔑 Introduce la clave de encriptación:${NC}"
    read -s ENCRYPTION_KEY
    echo
fi

# Crear directorio para archivos desencriptados
DECRYPTED_DIR="$BACKUP_DIR/decrypted"
mkdir -p "$DECRYPTED_DIR"

echo -e "${BLUE}🔓 Iniciando desencriptación...${NC}"

# Desencriptar archivos
FILES=("roles" "schema" "data")
for file_type in "${FILES[@]}"; do
    encrypted_file="$BACKUP_DIR/${file_type}.sql.enc"
    decrypted_file="$DECRYPTED_DIR/${file_type}.sql"
    
    echo -e "${YELLOW}🔄 Desencriptando $file_type...${NC}"
    
    if echo "$ENCRYPTION_KEY" | gpg --batch --yes --passphrase-fd 0 --decrypt "$encrypted_file" > "$decrypted_file" 2>/dev/null; then
        echo -e "${GREEN}✅ $file_type desencriptado correctamente${NC}"
        # Mostrar tamaño del archivo
        size=$(du -h "$decrypted_file" | cut -f1)
        echo -e "   📊 Tamaño: $size"
    else
        echo -e "${RED}❌ Error desencriptando $file_type - Verifica la clave${NC}"
        rm -f "$decrypted_file"
        exit 1
    fi
done

echo ""
echo -e "${GREEN}🎉 ¡Desencriptación completada!${NC}"
echo -e "${BLUE}📁 Archivos disponibles en: $DECRYPTED_DIR${NC}"
echo ""
echo -e "${YELLOW}📋 Archivos desencriptados:${NC}"
ls -la "$DECRYPTED_DIR/"

echo ""
echo -e "${BLUE}🔧 Para restaurar tu base de datos:${NC}"
echo -e "1. ${YELLOW}Roles:${NC} psql \$DB_URL -f $DECRYPTED_DIR/roles.sql"
echo -e "2. ${YELLOW}Esquema:${NC} psql \$DB_URL -f $DECRYPTED_DIR/schema.sql" 
echo -e "3. ${YELLOW}Datos:${NC} psql \$DB_URL -f $DECRYPTED_DIR/data.sql"

echo ""
echo -e "${RED}⚠️  IMPORTANTE: Los archivos desencriptados contienen datos sensibles.${NC}"
echo -e "${RED}   Elimínalos cuando termines: rm -rf $DECRYPTED_DIR${NC}"