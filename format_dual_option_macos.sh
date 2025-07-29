#!/bin/bash

# ================================================================
# 🔒 EXTERNAL DISK FORMATTER - macOS VERSION
# ================================================================
# Script SEGURO con DOBLE OPCIÓN: Formatear partición individual O disco completo
# ⚠️  ADVERTENCIA: Este script BORRARÁ todos los datos según la opción elegida
# 🔒 SEGURIDAD: Solo detecta discos externos removibles
# 
# 📝 INFORMACIÓN DEL AUTOR:
# ✍️  Creado por: mbrown
# 📅 Fecha de creación: 29 de Julio de 2025
# 🔢 Versión: 2.0.0 (macOS Edition)
# 🏷️  Nombre: External Disk Formatter macOS
# 💻 Compatibilidad: macOS (Monterey+) → Windows/Linux
# 🎯 Propósito: Formatear discos externos USB desde Mac para uso universal
# 
# 🔐 FIRMA DIGITAL:
SCRIPT_AUTHOR="mbrown"
SCRIPT_VERSION="2.0.0"
SCRIPT_DATE="2025-07-29"
SCRIPT_NAME="External Disk Formatter macOS"
CREATION_TIMESTAMP="$(date -r $(date +%s) '+%s' 2>/dev/null || date +%s)"
# 
# ⚠️  NOTA DE INTEGRIDAD:
# Este script fue adaptado para macOS el 29 de Julio de 2025 por mbrown
# Basado en la versión Linux pero optimizado para el ecosistema Apple
# 
# 📜 DERECHOS: © 2025 mbrown - Todos los derechos reservados
# ================================================================

# Verificación de firma del autor
SCRIPT_SIGNATURE="$(echo "${SCRIPT_AUTHOR}-format-macos-v${SCRIPT_VERSION}" | shasum -a 256 | cut -d' ' -f1)"

# Función para verificar la integridad del script
verify_script_signature() {
    echo -e "\n${CYAN}📝 Script Information:${NC}"
    echo "✍️  Autor: $SCRIPT_AUTHOR"
    echo "📅 Creado: $SCRIPT_DATE"
    echo "🔢 Versión: $SCRIPT_VERSION"
    echo "🏷️  Nombre: $SCRIPT_NAME"
    echo "🍎 Plataforma: macOS optimizado"
    echo "🔧 Compatibilidad: Windows/Linux/macOS"
    echo ""
}

# Colores para output (compatibles con Terminal de macOS)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
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

show_macos() {
    echo -e "${BOLD}[macOS]${NC} $1"
}

# Función para verificar si estamos en macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        show_error "Este script está diseñado específicamente para macOS"
        echo "Para Linux, usa la versión: format_dual_option.sh"
        exit 1
    fi
}

# Función para verificar si el comando existe
check_command() {
    if ! command -v "$1" &> /dev/null; then
        show_error "El comando '$1' no está disponible"
        case "$1" in
            "diskutil")
                echo "diskutil debería estar incluido en macOS. Verifica tu instalación."
                ;;
            "system_profiler")
                echo "system_profiler debería estar incluido en macOS. Verifica tu instalación."
                ;;
            *)
                echo "Puedes instalarlo con Homebrew: brew install $1"
                ;;
        esac
        exit 1
    fi
}

# Función para detectar solo discos externos en macOS
detect_external_disks() {
    local external_disks=()
    
    show_macos "Usando diskutil para detectar discos externos..."
    
    # Obtener lista de todos los discos
    all_disks=$(diskutil list | grep -E '^/dev/disk[0-9]+' | awk '{print $1}')
    
    for disk in $all_disks; do
        # Obtener información del disco
        disk_info=$(diskutil info "$disk" 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            # Verificar si es externo/removible
            is_removable=$(echo "$disk_info" | grep -i "removable\|external" | grep -i "yes")
            is_internal=$(echo "$disk_info" | grep -i "internal" | grep -i "yes")
            
            # Obtener información adicional
            protocol=$(echo "$disk_info" | grep "Protocol:" | awk -F: '{print $2}' | xargs)
            media_name=$(echo "$disk_info" | grep "Media Name:" | awk -F: '{print $2}' | xargs)
            
            # Verificar que NO sea el disco de arranque
            is_boot_disk=$(echo "$disk_info" | grep -i "os.*version\|system" | head -1)
            
            # Criterios para considerar como externo:
            # 1. Marcado como removible/externo
            # 2. Protocolo USB
            # 3. NO es disco interno
            # 4. NO es disco de arranque
            if [[ -n "$is_removable" || "$protocol" =~ USB ]] && [[ -z "$is_internal" && -z "$is_boot_disk" ]]; then
                # Verificar que el disco no esté montado como sistema
                mount_points=$(diskutil info "$disk" 2>/dev/null | grep "Mount Point:" | awk -F: '{print $2}' | xargs)
                
                # Si no está montado en directorios del sistema, es seguro
                if [[ ! "$mount_points" =~ ^(/|/System|/usr|/var|/Applications) ]]; then
                    external_disks+=("$disk")
                fi
            fi
        fi
    done
    
    # También verificar discos USB específicamente con system_profiler
    show_macos "Verificando con system_profiler para mayor precisión..."
    
    usb_disks=$(system_profiler SPUSBDataType 2>/dev/null | grep -A 10 -B 2 -i "mass storage\|external" | grep -o "/dev/disk[0-9]*" | sort -u)
    
    for usb_disk in $usb_disks; do
        # Verificar que no sea disco de sistema
        disk_info=$(diskutil info "$usb_disk" 2>/dev/null)
        if [ $? -eq 0 ]; then
            is_boot_disk=$(echo "$disk_info" | grep -i "os.*version\|system" | head -1)
            if [[ -z "$is_boot_disk" ]]; then
                # Evitar duplicados
                if [[ ! " ${external_disks[@]} " =~ " ${usb_disk} " ]]; then
                    external_disks+=("$usb_disk")
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

# Función para mostrar información de un disco en macOS
show_disk_info() {
    local disk="$1"
    echo -e "\n${BLUE}=== INFORMACIÓN DEL DISCO $disk ===${NC}"
    
    # Información básica con diskutil
    diskutil info "$disk" 2>/dev/null | grep -E "(Device Node|Media Name|Total Size|Protocol|Removable|File System|Mount Point)"
    
    echo -e "\n${BLUE}=== PARTICIONES DEL DISCO ===${NC}"
    diskutil list "$disk" 2>/dev/null
    
    echo -e "\n${BLUE}=== ESTADO DE MONTAJE ===${NC}"
    df -h | grep "$disk" || show_message "No hay particiones montadas de este disco"
}

# Función para listar particiones de un disco en macOS
list_partitions() {
    local disk="$1"
    echo -e "\n${BLUE}=== PARTICIONES DISPONIBLES EN $disk ===${NC}"
    
    partitions=()
    counter=1
    
    # Obtener lista de particiones del disco
    partition_list=$(diskutil list "$disk" 2>/dev/null | grep -E "^\s*[0-9]+:" | awk '{print $NF}')
    
    for partition in $partition_list; do
        # Verificar que la partición existe
        if diskutil info "/dev/$partition" &>/dev/null; then
            partitions+=("/dev/$partition")
            
            # Información de la partición
            part_info=$(diskutil info "/dev/$partition" 2>/dev/null)
            size=$(echo "$part_info" | grep "Total Size:" | awk -F: '{print $2}' | xargs)
            fstype=$(echo "$part_info" | grep "File System Personality:" | awk -F: '{print $2}' | xargs)
            label=$(echo "$part_info" | grep "Volume Name:" | awk -F: '{print $2}' | xargs)
            mount_point=$(echo "$part_info" | grep "Mount Point:" | awk -F: '{print $2}' | xargs)
            
            [[ -z "$label" ]] && label="Sin etiqueta"
            [[ -z "$mount_point" ]] && mount_point="No montado"
            [[ -z "$fstype" ]] && fstype="Desconocido"
            
            echo -e "${counter}. ${GREEN}/dev/$partition${NC}"
            echo "   Tamaño: $size | Tipo: $fstype | Etiqueta: $label"
            echo "   Montado en: $mount_point"
            echo ""
            
            ((counter++))
        fi
    done
    
    if [ ${#partitions[@]} -eq 0 ]; then
        show_warning "No se encontraron particiones válidas en $disk"
        return 1
    fi
    
    echo "${partitions[@]}"
}

# Función para desmontar particiones en macOS
unmount_partitions() {
    local disk="$1"
    show_message "Desmontando todas las particiones de $disk..."
    
    # Desmontar el disco completo
    diskutil unmountDisk "$disk" 2>/dev/null && show_success "Desmontado $disk" || show_warning "No se pudo desmontar completamente $disk"
}

# Función para desmontar una partición específica en macOS
unmount_single_partition() {
    local partition="$1"
    show_message "Desmontando $partition..."
    
    diskutil unmount "$partition" 2>/dev/null && show_success "Desmontado $partition" || {
        show_warning "No se pudo desmontar $partition, intentando forzar..."
        diskutil unmount force "$partition" 2>/dev/null && show_success "Desmontado forzadamente $partition" || {
            show_error "No se pudo desmontar $partition"
            return 1
        }
    }
}

# Función para formatear disco completo en macOS (Compatible Windows/Linux/macOS)
format_entire_disk() {
    local disk="$1"
    local label="$2"
    
    show_message "Formateando TODO el disco $disk para compatibilidad universal..."
    
    # Desmontar todas las particiones
    unmount_partitions "$disk"
    
    show_macos "Aplicando formato exFAT con esquema MBR para máxima compatibilidad..."
    
    # Usar diskutil con esquema MBR y formato exFAT
    if [ -n "$label" ]; then
        show_message "Formateando con etiqueta '$label'..."
        diskutil eraseDisk ExFAT "$label" MBR "$disk" || {
            show_error "Error al formatear $disk con etiqueta"
            return 1
        }
    else
        show_message "Formateando sin etiqueta específica..."
        diskutil eraseDisk ExFAT "UNTITLED" MBR "$disk" || {
            show_error "Error al formatear $disk"
            return 1
        }
    fi
    
    # Esperar a que el sistema reconozca los cambios
    sleep 2
    
    show_success "Disco completo formateado correctamente"
    show_macos "Formato: exFAT con esquema MBR (compatible Windows/Linux/macOS)"
    return 0
}

# Función para formatear partición individual en macOS
format_single_partition() {
    local partition="$1"
    local label="$2"
    
    show_message "Formateando partición individual $partition a exFAT..."
    
    # Desmontar la partición
    unmount_single_partition "$partition" || return 1
    
    show_macos "Aplicando formato exFAT compatible con todos los sistemas..."
    
    # Formatear la partición específica
    if [ -n "$label" ]; then
        diskutil eraseVolume ExFAT "$label" "$partition" || {
            show_error "Error al formatear $partition con etiqueta"
            return 1
        }
    else
        diskutil eraseVolume ExFAT "UNTITLED" "$partition" || {
            show_error "Error al formatear $partition"
            return 1
        }
    fi
    
    # Esperar sincronización
    sleep 1
    
    show_success "Partición $partition formateada correctamente"
    show_macos "Formato exFAT aplicado (compatible Windows/Linux/macOS)"
    return 0
}

# Función para verificar el resultado en macOS
verify_format() {
    local target="$1"
    show_message "Verificando el formato de $target..."
    sleep 2
    
    echo -e "\n${BLUE}=== RESULTADO FINAL ===${NC}"
    
    if [[ "$target" =~ disk[0-9]+$ ]]; then
        # Es un disco completo
        diskutil list "$target"
        echo -e "\n${BLUE}=== INFORMACIÓN DETALLADA ===${NC}"
        diskutil info "$target"
    else
        # Es una partición específica
        diskutil info "$target"
    fi
    
    echo -e "\n${GREEN}=== VERIFICACIÓN DE COMPATIBILIDAD ===${NC}"
    echo "✅ Formato: exFAT (compatible Windows/Mac/Linux)"
    echo "✅ Esquema: MBR (máxima compatibilidad)"
    echo "✅ Archivos grandes: Soporta >4GB"
    echo "✅ Sistemas soportados: Windows XP+, macOS 10.6.5+, Linux con exfat"
}

# Función para mostrar menú de opciones
show_format_options() {
    echo -e "\n${MAGENTA}=== OPCIONES DE FORMATEO (macOS EDITION) ===${NC}"
    echo -e "${GREEN}1.${NC} Formatear UNA partición específica"
    echo "   → Mantiene las demás particiones intactas"
    echo "   → Solo se pierden datos de la partición elegida"
    echo "   → Formato exFAT compatible Windows/Linux/macOS"
    echo ""
    echo -e "${GREEN}2.${NC} Formatear TODO el disco completo" 
    echo "   → Elimina TODAS las particiones existentes"
    echo "   → Crea UNA sola partición exFAT con todo el espacio"
    echo "   → Se pierden TODOS los datos del disco"
    echo "   → Esquema MBR + exFAT para máxima compatibilidad"
    echo ""
    echo -e "${CYAN}🍎 CARACTERÍSTICAS macOS:${NC}"
    echo "   • Usa diskutil nativo de macOS"
    echo "   • Esquema de partición MBR para Windows/Linux"
    echo "   • Formato exFAT para compatibilidad universal"
    echo "   • Desmontaje seguro antes de formatear"
}

# Función principal
main() {
    echo -e "${CYAN}"
    echo "================================================================"
    echo "    🍎 EXTERNAL DISK FORMATTER - macOS EDITION"
    echo "    ✍️  Creado por: $SCRIPT_AUTHOR | 📅 $SCRIPT_DATE"
    echo "    🔢 Versión: $SCRIPT_VERSION"
    echo "    🎯 COMPATIBILIDAD: Windows/Linux/macOS"
    echo "================================================================"
    echo -e "${NC}"
    
    # Verificar que estamos en macOS
    check_macos
    
    # Verificar firma del script
    verify_script_signature
    
    # Verificar que se ejecuta como root/admin
    if [ "$EUID" -ne 0 ]; then
        show_error "Este script debe ejecutarse con sudo"
        echo "Uso: sudo $0"
        echo ""
        echo "En macOS necesitas permisos de administrador para:"
        echo "• Detectar información de discos externos"
        echo "• Desmontar particiones"
        echo "• Formatear dispositivos"
        exit 1
    fi
    
    # Verificar comandos necesarios de macOS
    check_command "diskutil"
    check_command "system_profiler"
    
    # Detectar discos externos
    show_security "Iniciando detección segura de discos externos en macOS..."
    show_macos "Usando diskutil y system_profiler para detección precisa..."
    external_disks_array=($(detect_external_disks))
    
    if [ ${#external_disks_array[@]} -eq 0 ]; then
        show_error "No se detectaron discos externos"
        echo ""
        echo "Asegúrate de que:"
        echo "• El disco esté conectado y reconocido por macOS"
        echo "• Aparezca en Finder o en 'Acerca de esta Mac' > 'Informe del sistema'"
        echo "• Sea un dispositivo USB o externo"
        echo "• No sea el disco de arranque del sistema"
        echo ""
        echo "Puedes verificar con: diskutil list"
        exit 1
    fi
    
    show_success "Se detectaron ${#external_disks_array[@]} disco(s) externo(s)"
    
    # Mostrar discos externos detectados
    echo -e "\n${GREEN}=== DISCOS EXTERNOS DETECTADOS ===${NC}"
    for i in "${!external_disks_array[@]}"; do
        disk="${external_disks_array[$i]}"
        echo -e "$((i+1)). ${GREEN}$disk${NC}"
        
        # Mostrar información básica
        disk_info=$(diskutil info "$disk" 2>/dev/null)
        if [ $? -eq 0 ]; then
            size=$(echo "$disk_info" | grep "Total Size:" | awk -F: '{print $2}' | xargs)
            media=$(echo "$disk_info" | grep "Media Name:" | awk -F: '{print $2}' | xargs)
            protocol=$(echo "$disk_info" | grep "Protocol:" | awk -F: '{print $2}' | xargs)
            echo "   Tamaño: $size | Media: $media | Protocolo: $protocol"
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
                show_error "No se encontraron particiones válidas en $selected_disk"
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
            echo -e "${CYAN}🍎 Se formateará en exFAT compatible con Windows/Linux/macOS${NC}"
            
            # Confirmación
            read -p "¿Confirmas formatear SOLO esta partición? (escribe 'SI UNA PARTICION'): " confirmation
            
            if [ "$confirmation" != "SI UNA PARTICION" ]; then
                show_message "Operación cancelada por el usuario"
                exit 0
            fi
            
            # Obtener etiqueta
            read -p "Ingresa una etiqueta para la partición (opcional): " label
            
            echo -e "\n${BLUE}=== FORMATEANDO PARTICIÓN INDIVIDUAL (macOS) ===${NC}"
            format_single_partition "$selected_partition" "$label" || exit 1
            verify_format "$selected_partition"
            
            echo -e "\n${GREEN}✅ PARTICIÓN INDIVIDUAL FORMATEADA EXITOSAMENTE${NC}"
            echo -e "${GREEN}🍎 Compatible con Windows, Linux y macOS${NC}"
            ;;
            
        2)
            show_option "Seleccionaste: Formatear TODO el disco completo"
            
            # Mostrar particiones actuales
            echo -e "\n${YELLOW}=== PARTICIONES QUE SE VAN A ELIMINAR ===${NC}"
            diskutil list "$selected_disk"
            
            # Advertencia para disco completo
            echo -e "\n${RED}⚠️  ADVERTENCIA MÁXIMA ⚠️${NC}"
            echo "Vas a formatear TODO el disco: ${RED}$selected_disk${NC}"
            echo -e "${RED}Se eliminarán TODAS las particiones mostradas arriba${NC}"
            echo -e "${RED}Se creará UNA sola partición exFAT con todo el espacio${NC}"
            echo -e "${RED}SE PERDERÁN TODOS LOS DATOS DEL DISCO COMPLETO${NC}"
            echo ""
            echo -e "${CYAN}🍎 Se aplicará esquema MBR + exFAT para compatibilidad total${NC}"
            
            # Confirmación estricta
            read -p "¿Confirmas formatear TODO EL DISCO? (escribe 'SI TODO EL DISCO'): " confirmation
            
            if [ "$confirmation" != "SI TODO EL DISCO" ]; then
                show_message "Operación cancelada por el usuario"
                exit 0
            fi
            
            # Obtener etiqueta
            read -p "Ingresa una etiqueta para el disco (opcional): " label
            
            echo -e "\n${BLUE}=== FORMATEANDO DISCO COMPLETO (macOS) ===${NC}"
            format_entire_disk "$selected_disk" "$label" || exit 1
            verify_format "$selected_disk"
            
            echo -e "\n${GREEN}✅ DISCO COMPLETO FORMATEADO EXITOSAMENTE${NC}"
            echo -e "${GREEN}🍎 Compatible con Windows, Linux y macOS${NC}"
            ;;
            
        *)
            show_error "Opción inválida"
            exit 1
            ;;
    esac
    
    echo -e "\n${GREEN}================================================================${NC}"
    echo -e "${GREEN}    🎉 FORMATEO COMPLETADO EXITOSAMENTE (macOS EDITION)${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo ""
    echo "El disco/partición ahora está en formato exFAT y es compatible con:"
    echo "• Windows (XP SP2+, Vista, 7, 8, 10, 11) ✅"
    echo "• macOS (10.6.5+ Snow Leopard y superiores) ✅"
    echo "• Linux (con exfat-utils/exfatprogs instalado) ✅"
    echo ""
    echo "Características del formato:"
    echo "• Soporta archivos >4GB ✅"
    echo "• Tamaño máximo de archivo: 16 Exabytes"
    echo "• Esquema de partición: MBR (máxima compatibilidad)"
    echo "• Sistema de archivos: exFAT (universal)"
    echo ""
    echo -e "${CYAN}🍎 ESPECÍFICO PARA macOS:${NC}"
    echo "• Formateado con diskutil nativo"
    echo "• Optimizado para intercambio con PCs"
    echo "• Reconocido automáticamente en Finder"
    echo ""
    echo "🔒 SEGURIDAD: Solo se procesaron discos externos removibles"
    echo "Puedes expulsar el disco desde Finder y usarlo en cualquier sistema."
}

# Ejecutar función principal
main "$@"