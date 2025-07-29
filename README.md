# Scripts Útiles - Colección mBrownC

Esta carpeta contiene una colección de scripts útiles para administración de sistemas, formateo de discos y automatización de tareas comunes.

## Índice de Scripts

### External Disk Formatter (Linux)
**Archivo:** `format_dual_option.sh`  
**Plataforma:** Linux (Ubuntu/Debian)  
**Descripción:** Script seguro para formatear discos externos USB con compatibilidad total Windows/Mac/Linux  
**Características:**
- Solo detecta discos externos (protección del sistema)
- Doble opción: formatear partición individual o disco completo
- Formato exFAT compatible con todos los sistemas operativos
- Soporte para archivos >4GB
- Verificaciones de seguridad múltiples

### External Disk Formatter (macOS)
**Archivo:** `format_dual_option_macos.sh`  
**Plataforma:** macOS (Monterey+ recomendado)  
**Descripción:** Versión nativa para macOS que formatea discos externos USB para uso universal  
**Características:**
- Usa herramientas nativas de macOS (diskutil, system_profiler)
- Solo detecta discos externos/removibles (protección del sistema)
- Formato exFAT con esquema MBR para máxima compatibilidad
- Compatible con Windows, Linux y macOS
- Desmontaje seguro antes de formatear

---

## Instrucciones de Uso

### Para Linux (Ubuntu/Debian)

#### 1. Preparar el Script
```bash
sudo chmod +x format_dual_option.sh
```

#### 2. Ejecutar el Script
```bash
sudo ./format_dual_option.sh
```

### Para macOS

#### 1. Preparar el Script
```bash
sudo chmod +x format_dual_option_macos.sh
```

#### 2. Ejecutar el Script
```bash
sudo ./format_dual_option_macos.sh
```

**Nota:** En macOS no necesitas instalar dependencias adicionales ya que usa herramientas nativas del sistema (diskutil, system_profiler).

### 3. Comandos Rápidos de Referencia

| Acción | Comando |
|--------|---------|
| Dar permisos | `sudo chmod +x script.sh` |
| Ejecutar script | `sudo ./script.sh` |
| Ver permisos | `ls -la script.sh` |
| Hacer ejecutable para usuario | `chmod u+x script.sh` |
| Hacer ejecutable para todos | `chmod +x script.sh` |

---

## Requisitos del Sistema

### Para Linux (External Disk Formatter):
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install exfatprogs exfat-fuse util-linux parted

# Para sistemas más antiguos
sudo apt install exfat-utils exfat-fuse util-linux parted
```

### Para macOS (External Disk Formatter):
**No requiere instalación de dependencias adicionales**

Los comandos necesarios están incluidos de forma nativa en macOS:
- `diskutil` - Herramienta de gestión de discos
- `system_profiler` - Información del sistema
- `shasum` - Verificación de integridad

**Compatibilidad:** macOS 10.12 (Sierra) o superior, recomendado macOS 12+ (Monterey)

### Dependencias Generales: