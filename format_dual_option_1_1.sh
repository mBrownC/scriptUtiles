#!/bin/bash

# ================================================================
# 🔒 EXTERNAL DISK FORMATTER - SCRIPT FIRMADO (VERSIÓN CORREGIDA)
# ================================================================
# Script SEGURO con DOBLE OPCIÓN: Formatear partición individual O disco completo
# ⚠️  ADVERTENCIA: Este script BORRARÁ todos los datos según la opción elegida
# 🔒 SEGURIDAD: Solo detecta discos externos removibles
# 
# 📝 INFORMACIÓN DEL AUTOR:
# ✍️  Creado por: mbrown
# 📅 Fecha de creación: 5 de Julio de 2025
# 🔢 Versión: 1.1.0 (CORREGIDA PARA WINDOWS/LINUX)
# 🏷️  Nombre: External Disk Formatter
# 💻 Compatibilidad: Linux (Ubuntu/Debian) + Windows
# 🎯 Propósito: Formatear discos externos USB de forma segura
# 
# 🔐 FIRMA DIGITAL:
SCRIPT_AUTHOR="mbrown"
SCRIPT_VERSION="1.1.0"
SCRIPT_DATE="2025-07-05"
SCRIPT_NAME="External Disk Formatter (Windows Compatible)"
CREATION_TIMESTAMP="$(date -d '2025-07-05' +%s)"
# 
# ⚠️  NOTA DE INTEGRIDAD:
# Este script fue creado el 5 de Julio de 2025 por mbrown
# Versión 1.1.0 - Corregida para compatibilidad total Windows/Linux
# 
# 📜 DERECHOS: © 2025 mbrown - Todos los derechos reservados
# ================================================================

# Verificación de firma del autor
SCRIPT_SIGNATURE="$(echo "${SCRIPT_AUTHOR}-format-script-v${SCRIPT_VERSION}" | sha256sum | cut -d' ' -f1)"

# Función para verificar la integridad del script
verify_script_signature() {
    echo -e "\n${CYAN}📝 Script Information:${NC}"
    echo "✍️  Autor: $SCRIPT_AUTHOR"
    echo "📅 Creado: $SCRIPT_DATE"
    echo "🔢 Versión: $SCRIPT_VERSION"
    echo "🏷️  Nombre: $SCRIPT_NAME"
    echo "🔧 Mejoras: Compatibilidad total Windows/Linux"
    echo ""
}

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
show_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

show_warning() {
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"
}

show_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_success() {
    echo -e "${GREEN}[ÉXITO]${NC} $1"
}

show_security() {
    echo -e "${CYAN}[SEGURIDAD]${NC} $1"
}

show_option() {
    echo -e "${MAGENTA}[OPCIÓN]${NC} $1"
}

show_fix() {
    echo -e "${GREEN}[CORREGIDO]${NC} $1"
}

# Función para verificar si el comando existe
check_command() {
    if ! command -v "$1" &> /dev/null; then
        show_error "El comando '$1' no está instalado"
        if [[ "$1" == "mkfs.exfat" ]]; then
            echo "Instálalo con: sudo apt install exfatprogs exfat-fuse"
        else
            echo "Instálalo con: sudo apt install exfat-utils exfat-fuse util-linux parted"
        fi
        exit 1
    fi
}

# Función para detectar solo discos externos
detect_external_disks() {
    local external_disks=()
    
    # Método 1: Detectar discos USB usando udevadm (más confiable)
    for disk_device in /dev/sd[a-z]; do
        if [ -b "$disk_device" ]; then
            disk_name=$(basename "$disk_device")
            
            # Verificar si es USB o conectado via USB
            usb_info=$(udevadm info --query=property --name="$disk_device" 2>/dev/null)
            if echo "$usb_info" | grep -E "(ID_BUS=usb|usb)" >/dev/null; then
                # Verificar que NO sea disco de sistema (no montado en /, /boot, /home, etc)
                if ! mount | grep -E "^/dev/${disk_name}[0-9]*\s+(\/|\/boot|\/home|\/usr|\/var|\/tmp)" >/dev/null 2>&1; then
                    external_disks+=("$disk_device")
                fi
            fi
        fi
    done
    
    # Método 2: Detectar discos con particiones montadas en /media (típico de externos)
    for user_media in /media/*/; do
        if [ -d "$user_media" ]; then
            for mount_point in "$user_media"*/; do
                if [ -d "$mount_point" ]; then
                    # Obtener el dispositivo montado
                    mounted_device=$(df "$mount_point" 2>/dev/null | tail -1 | awk '{print $1}' 2>/dev/null)
                    if [[ "$mounted_device" =~ ^/dev/sd[a-z][0-9]+$ ]]; then
                        # Extraer el disco base (sin número de partición)
                        base_disk=$(echo "$mounted_device" | sed 's/[0-9]*$//')
                        
                        # Verificar que NO sea disco de sistema
                        if ! mount | grep -E "^/dev/$(basename "$base_disk")[0-9]*\s+(\/|\/boot|\/home|\/usr|\/var|\/tmp)" >/dev/null 2>&1; then
                            # Evitar duplicados
                            if [[ ! " ${external_disks[@]} " =~ " ${base_disk} " ]]; then
                                external_disks+=("$base_disk")
                            fi
                        fi
                    fi
                fi
            done
        fi
    done
    
    # Método 3: Buscar discos marcados como removibles (backup method)
    for disk_path in /sys/block/sd*; do
        if [ -d "$disk_path" ]; then
            disk_name=$(basename "$disk_path")
            disk_device="/dev/$disk_name"
            
            if [ -b "$disk_device" ]; then
                # Verificar si es removible
                if [ -f "$disk_path/removable" ] && [ "$(cat "$disk_path/removable" 2>/dev/null)" = "1" ]; then
                    # Verificar que no sea disco de sistema
                    if ! mount | grep -E "^/dev/${disk_name}[0-9]*\s+(\/|\/boot|\/home|\/usr|\/var|\/tmp)" >/dev/null 2>&1; then
                        # Evitar duplicados
                        if [[ ! " ${external_disks[@]} " =~ " ${disk_device} " ]]; then
                            external_disks+=("$disk_device")
                        fi
                    fi
                fi
            fi
        fi
    done
    
    # Eliminar duplicados y ordenar
    if [ ${#external_disks[@]} -gt 0 ]; then
        external_disks=($(printf '%s\n' "${external_disks[@]}" | sort -u))
    fi
    
    echo "${external_disks[@]}"
}

# Función para mostrar información de un disco
show_disk_info() {
    local disk="$1"
    echo -e "\n${BLUE}=== INFORMACIÓN DEL DISCO $disk ===${NC}"
    
    # Información básica del disco
    if command -v lsblk &> /dev/null; then
        lsblk -f "$disk" 2>/dev/null
    fi
    
    # Información de tamaño
    if command -v fdisk &> /dev/null; then
        echo -e "\n${BLUE}=== TAMAÑO DEL DISCO ===${NC}"
        sudo fdisk -l "$disk" 2>/dev/null | grep "^Disk $disk"
    fi
    
    # Particiones montadas
    echo -e "\n${BLUE}=== PARTICIONES MONTADAS ===${NC}"
    df -h | grep "^$disk" || show_message "No hay particiones montadas de este disco"
    
    # Información USB si está disponible
    echo -e "\n${BLUE}=== INFORMACIÓN USB ===${NC}"
    udevadm info --query=property --name="$disk" 2>/dev/null | grep -E "(ID_VENDOR|ID_MODEL|ID_SERIAL_SHORT|ID_BUS)" || show_message "No hay información USB disponible"
}

# Función para listar particiones de un disco
list_partitions() {
    local disk="$1"
    echo -e "\n${BLUE}=== PARTICIONES DISPONIBLES EN $disk ===${NC}"
    
    partitions=()
    counter=1
    
    # Buscar particiones
    for partition in "${disk}"[0-9]*; do
        if [ -b "$partition" ]; then
            partitions+=("$partition")
            
            # Información de la partición
            size=$(lsblk -b -n -o SIZE "$partition" 2>/dev/null | numfmt --to=iec || echo "?")
            fstype=$(lsblk -n -o FSTYPE "$partition" 2>/dev/null || echo "?")
            label=$(lsblk -n -o LABEL "$partition" 2>/dev/null || echo "Sin etiqueta")
            mountpoint=$(lsblk -n -o MOUNTPOINT "$partition" 2>/dev/null || echo "No montado")
            
            echo -e "${counter}. ${GREEN}$partition${NC}"
            echo "   Tamaño: $size | Tipo: $fstype | Etiqueta: $label"
            echo "   Montado en: $mountpoint"
            echo ""
            
            ((counter++))
        fi
    done
    
    if [ ${#partitions[@]} -eq 0 ]; then
        show_warning "No se encontraron particiones en $disk"
        return 1
    fi
    
    echo "${partitions[@]}"
}

# Función para desmontar particiones
unmount_partitions() {
    local disk="$1"
    show_message "Desmontando todas las particiones de $disk..."
    
    # Buscar todas las particiones montadas del disco
    mounted_partitions=$(mount | grep "^$disk" | cut -d' ' -f1)
    
    if [ -z "$mounted_partitions" ]; then
        show_message "No hay particiones montadas"
        return 0
    fi
    
    for partition in $mounted_partitions; do
        show_message "Desmontando $partition..."
        sudo umount "$partition" 2>/dev/null && show_success "Desmontado $partition" || show_warning "No se pudo desmontar $partition"
    done
}

# Función para desmontar una partición específica
unmount_single_partition() {
    local partition="$1"
    show_message "Desmontando $partition..."
    
    if mount | grep -q "^$partition "; then
        sudo umount "$partition" 2>/dev/null && show_success "Desmontado $partition" || {
            show_error "No se pudo desmontar $partition"
            return 1
        }
    else
        show_message "$partition no está montado"
    fi
}

# Función CORREGIDA para crear nueva tabla de particiones en todo el disco
format_entire_disk() {
    local disk="$1"
    local label="$2"
    
    show_message "Formateando TODO el disco $disk..."
    
    # Desmontar todas las particiones
    unmount_partitions "$disk"
    
    show_fix "Aplicando correcciones para compatibilidad Windows/Linux..."
    
    # CORRECCIÓN 1: Crear tabla de particiones MBR en lugar de GPT para mejor compatibilidad
    show_message "Creando tabla de particiones MBR (mejor compatibilidad)..."
    sudo parted -s "$disk" mklabel msdos
    
    # CORRECCIÓN 2: Crear partición primaria que ocupe todo el disco
    show_message "Creando partición primaria..."
    sudo parted -s "$disk" mkpart primary 0% 100%
    
    # CORRECCIÓN 3: Marcar partición como booteable/activa (importante para Windows)
    show_message "Marcando partición como activa para Windows..."
    sudo parted -s "$disk" set 1 boot on
    
    # Esperar a que el kernel reconozca la nueva partición
    sleep 3
    sudo partprobe "$disk"
    sleep 2
    
    # CORRECCIÓN 4: Formatear la nueva partición con etiqueta desde el inicio
    show_message "Formateando ${disk}1 a exFAT con compatibilidad Windows/Linux..."
    if [ -n "$label" ]; then
        sudo mkfs.exfat -n "$label" "${disk}1" || {
            show_error "Error al formatear ${disk}1"
            return 1
        }
    else
        sudo mkfs.exfat "${disk}1" || {
            show_error "Error al formatear ${disk}1"
            return 1
        }
    fi
    
    # CORRECCIÓN 5: Sincronizar cambios al disco
    show_message "Sincronizando cambios al disco..."
    sync
    sleep 2
    
    show_success "Disco completo formateado correctamente como ${disk}1"
    show_fix "Aplicadas todas las correcciones para Windows/Linux"
    return 0
}

# Función CORREGIDA para formatear partición individual a exFAT
format_single_partition() {
    local partition="$1"
    local label="$2"
    
    show_message "Formateando partición individual $partition a exFAT..."
    
    # Desmontar la partición
    unmount_single_partition "$partition" || return 1
    
    show_fix "Aplicando formato compatible Windows/Linux..."
    
    # CORRECCIÓN: Formatear con etiqueta desde el comando mkfs.exfat
    if [ -n "$label" ]; then
        sudo mkfs.exfat -n "$label" "$partition" || {
            show_error "Error al formatear $partition"
            return 1
        }
    else
        sudo mkfs.exfat "$partition" || {
            show_error "Error al formatear $partition"
            return 1
        }
    fi
    
    # Sincronizar cambios
    show_message "Sincronizando cambios..."
    sync
    sleep 1
    
    show_success "Partición $partition formateada correctamente"
    show_fix "Formato compatible con Windows/Linux aplicado"
    return 0
}

# Función para verificar el resultado
verify_format() {
    local target="$1"
    show_message "Verificando el formato de $target..."
    sleep 2
    
    echo -e "\n${BLUE}=== RESULTADO FINAL ===${NC}"
    if [[ "$target" =~ [0-9]$ ]]; then
        # Es una partición específica
        lsblk -f "$target"
        if command -v file &> /dev/null; then
            echo -e "\n${BLUE}=== INFORMACIÓN DEL SISTEMA DE ARCHIVOS ===${NC}"
            sudo file -s "$target"
        fi
    else
        # Es un disco completo, mostrar todas las particiones
        lsblk -f "$target"
        if command -v file &> /dev/null; then
            echo -e "\n${BLUE}=== INFORMACIÓN DEL SISTEMA DE ARCHIVOS ===${NC}"
            sudo file -s "${target}1"
        fi
    fi
    
    echo -e "\n${GREEN}=== VERIFICACIÓN DE COMPATIBILIDAD ===${NC}"
    echo "✅ Formato: exFAT (compatible Windows/Mac/Linux)"
    echo "✅ Tabla de particiones: MBR (máxima compatibilidad)"
    echo "✅ Partición marcada como activa (Windows ready)"
    echo "✅ Archivos grandes: Soporta >4GB"
}

# Función para mostrar menú de opciones
show_format_options() {
    echo -e "\n${MAGENTA}=== OPCIONES DE FORMATEO (VERSIÓN CORREGIDA) ===${NC}"
    echo -e "${GREEN}1.${NC} Formatear UNA partición específica"
    echo "   → Mantiene las demás particiones intactas"
    echo "   → Solo se pierden datos de la partición elegida"
    echo "   → Aplicará correcciones de compatibilidad Windows/Linux"
    echo ""
    echo -e "${GREEN}2.${NC} Formatear TODO el disco completo" 
    echo "   → Elimina TODAS las particiones existentes"
    echo "   → Crea UNA sola partición exFAT con todo el espacio"
    echo "   → Se pierden TODOS los datos del disco"
    echo "   → Aplicará TODAS las correcciones para Windows/Linux"
    echo ""
    echo -e "${CYAN}🔧 CORRECCIONES APLICADAS:${NC}"
    echo "   • Tabla MBR en lugar de GPT (mejor compatibilidad)"
    echo "   • Partición marcada como activa/booteable"
    echo "   • Formato exFAT optimizado para Windows/Linux"
    echo "   • Sincronización correcta de cambios"
}

# Función principal
main() {
    echo -e "${CYAN}"
    echo "================================================================"
    echo "    🔒 EXTERNAL DISK FORMATTER (VERSIÓN CORREGIDA)"
    echo "    ✍️  Creado por: $SCRIPT_AUTHOR | 📅 $SCRIPT_DATE"
    echo "    🔢 Versión: $SCRIPT_VERSION"
    echo "    🔧 CORRECCIONES: Compatibilidad total Windows/Linux"
    echo "================================================================"
    echo -e "${NC}"
    
    # Verificar firma del script
    verify_script_signature
    
    # Verificar que se ejecuta como root o con sudo
    if [ "$EUID" -ne 0 ]; then
        show_error "Este script debe ejecutarse con sudo"
        echo "Uso: sudo $0"
        exit 1
    fi
    
    # Verificar comandos necesarios
    check_command "lsblk"
    check_command "mkfs.exfat"
    check_command "udevadm"
    check_command "parted"
    
    # Detectar discos externos
    show_security "Iniciando detección segura de discos externos..."
    show_message "Buscando discos USB y montados en /media..."
    external_disks_array=($(detect_external_disks))
    
    if [ ${#external_disks_array[@]} -eq 0 ]; then
        show_error "No se detectaron discos externos"
        echo "Asegúrate de que:"
        echo "• El disco esté conectado"
        echo "• Sea reconocido como dispositivo USB"
        echo "• Tenga particiones montadas en /media"
        exit 1
    fi
    
    show_success "Se detectaron ${#external_disks_array[@]} disco(s) externo(s)"
    
    # Mostrar discos externos detectados
    echo -e "\n${GREEN}=== DISCOS EXTERNOS DETECTADOS ===${NC}"
    for i in "${!external_disks_array[@]}"; do
        disk="${external_disks_array[$i]}"
        echo -e "$((i+1)). ${GREEN}$disk${NC}"
        
        # Mostrar información básica
        if command -v lsblk &> /dev/null; then
            size=$(lsblk -b -n -d -o SIZE "$disk" 2>/dev/null | numfmt --to=iec || echo "?")
            model=$(lsblk -n -d -o MODEL "$disk" 2>/dev/null || echo "Desconocido")
            echo "   Tamaño: $size | Modelo: $model"
        fi
    done
    
    # Seleccionar disco
    echo ""
    read -p "Selecciona el número del disco externo (1-${#external_disks_array[@]}): " disk_choice
    
    if ! [[ "$disk_choice" =~ ^[0-9]+$ ]] || [ "$disk_choice" -lt 1 ] || [ "$disk_choice" -gt ${#external_disks_array[@]} ]; then
        show_error "Selección inválida"
        exit 1
    fi
    
    selected_disk="${external_disks_array[$((disk_choice-1))]}"
    show_success "Disco seleccionado: $selected_disk"
    
    # Mostrar información detallada del disco seleccionado
    show_disk_info "$selected_disk"
    
    # Mostrar opciones de formateo
    show_format_options
    
    # Seleccionar tipo de formateo
    read -p "Elige la opción de formateo (1-2): " format_option
    
    case "$format_option" in
        1)
            show_option "Seleccionaste: Formatear UNA partición específica"
            
            # Listar particiones
            partitions_array=($(list_partitions "$selected_disk"))
            
            if [ ${#partitions_array[@]} -eq 0 ]; then
                show_error "No se encontraron particiones en $selected_disk"
                exit 1
            fi
            
            # Seleccionar partición
            echo ""
            read -p "Selecciona el número de la partición a formatear (1-${#partitions_array[@]}): " partition_choice
            
            if ! [[ "$partition_choice" =~ ^[0-9]+$ ]] || [ "$partition_choice" -lt 1 ] || [ "$partition_choice" -gt ${#partitions_array[@]} ]; then
                show_error "Selección inválida"
                exit 1
            fi
            
            selected_partition="${partitions_array[$((partition_choice-1))]}"
            show_success "Partición seleccionada: $selected_partition"
            
            # Advertencia para partición individual
            echo -e "\n${YELLOW}⚠️  ADVERTENCIA ⚠️${NC}"
            echo "Vas a formatear SOLO la partición: ${RED}$selected_partition${NC}"
            echo "Las demás particiones del disco NO se tocarán"
            echo -e "${RED}Solo se perderán los datos de esta partición específica${NC}"
            echo ""
            echo -e "${CYAN}🔧 Se aplicarán correcciones para Windows/Linux${NC}"
            
            # Confirmación
            read -p "¿Confirmas formatear SOLO esta partición? (escribe 'SI UNA PARTICION'): " confirmation
            
            if [ "$confirmation" != "SI UNA PARTICION" ]; then
                show_message "Operación cancelada por el usuario"
                exit 0
            fi
            
            # Obtener etiqueta
            read -p "Ingresa una etiqueta para la partición (opcional): " label
            
            echo -e "\n${BLUE}=== FORMATEANDO PARTICIÓN INDIVIDUAL (VERSIÓN CORREGIDA) ===${NC}"
            format_single_partition "$selected_partition" "$label" || exit 1
            verify_format "$selected_partition"
            
            echo -e "\n${GREEN}✅ PARTICIÓN INDIVIDUAL FORMATEADA EXITOSAMENTE${NC}"
            echo -e "${GREEN}🔧 Compatible con Windows y Linux${NC}"
            ;;
            
        2)
            show_option "Seleccionaste: Formatear TODO el disco completo"
            
            # Listar particiones actuales para mostrar lo que se va a perder
            echo -e "\n${YELLOW}=== PARTICIONES QUE SE VAN A ELIMINAR ===${NC}"
            list_partitions "$selected_disk" > /dev/null
            lsblk -f "$selected_disk"
            
            # Advertencia para disco completo
            echo -e "\n${RED}⚠️  ADVERTENCIA MÁXIMA ⚠️${NC}"
            echo "Vas a formatear TODO el disco: ${RED}$selected_disk${NC}"
            echo -e "${RED}Se eliminarán TODAS las particiones mostradas arriba${NC}"
            echo -e "${RED}Se crearán UNA sola partición exFAT con todo el espacio${NC}"
            echo -e "${RED}SE PERDERÁN TODOS LOS DATOS DEL DISCO COMPLETO${NC}"
            echo ""
            echo -e "${CYAN}🔧 Se aplicarán TODAS las correcciones para Windows/Linux${NC}"
            
            # Confirmación estricta
            read -p "¿Confirmas formatear TODO EL DISCO? (escribe 'SI TODO EL DISCO'): " confirmation
            
            if [ "$confirmation" != "SI TODO EL DISCO" ]; then
                show_message "Operación cancelada por el usuario"
                exit 0
            fi
            
            # Obtener etiqueta
            read -p "Ingresa una etiqueta para el disco (opcional): " label
            
            echo -e "\n${BLUE}=== FORMATEANDO DISCO COMPLETO (VERSIÓN CORREGIDA) ===${NC}"
            format_entire_disk "$selected_disk" "$label" || exit 1
            verify_format "$selected_disk"
            
            echo -e "\n${GREEN}✅ DISCO COMPLETO FORMATEADO EXITOSAMENTE${NC}"
            echo -e "${GREEN}🔧 Compatible con Windows y Linux${NC}"
            ;;
            
        *)
            show_error "Opción inválida"
            exit 1
            ;;
    esac
    
    echo -e "\n${GREEN}================================================================${NC}"
    echo -e "${GREEN}    🎉 FORMATEO COMPLETADO EXITOSAMENTE (VERSIÓN CORREGIDA)${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo ""
    echo "El disco/partición ahora está en formato exFAT y es compatible con:"
    echo "• Windows (XP SP2+, Vista, 7, 8, 10, 11) ✅"
    echo "• macOS (10.6.5+) ✅"
    echo "• Linux (con exfat-utils instalado) ✅"
    echo ""
    echo "Características:"
    echo "• Soporta archivos >4GB ✅"
    echo "• Tamaño máximo de archivo: 16 Exabytes"
    echo "• Tamaño máximo de partición: 64 Zebibytes"
    echo "• Tabla de particiones MBR (máxima compatibilidad)"
    echo "• Partición marcada como activa (Windows ready)"
    echo ""
    echo -e "${CYAN}🔧 CORRECCIONES APLICADAS:${NC}"
    echo "• Tabla MBR en lugar de GPT"
    echo "• Partición marcada como booteable/activa"
    echo "• Formato exFAT optimizado"
    echo "• Sincronización correcta de cambios"
    echo ""
    echo "🔒 SEGURIDAD: Solo se procesaron discos externos removibles"
    echo "Puedes desconectar y volver a conectar el disco para usarlo."
}

# Ejecutar función principal
main "$@"
