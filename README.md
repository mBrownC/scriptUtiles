# scriptUtiles# Scripts Útiles - Colección mBrownC

Esta carpeta contiene una colección de scripts útiles para administración de sistemas, formateo de discos y automatización de tareas comunes.

## Índice de Scripts

### External Disk Formatter
**Archivo:** `format_dual_option.sh`  
**Descripción:** Script seguro para formatear discos externos USB con compatibilidad total Windows/Mac/Linux  
**Características:**
- Solo detecta discos externos (protección del sistema)
- Doble opción: formatear partición individual o disco completo
- Formato exFAT compatible con todos los sistemas operativos
- Soporte para archivos >4GB
- Verificaciones de seguridad múltiples

---

## Instrucciones de Uso

### 1. Preparar el Script
Antes de ejecutar cualquier script, debes darle permisos de ejecución:

```bash
sudo chmod +x nombre_del_script.sh
```

**Ejemplo para el formateador de discos:**
```bash
sudo chmod +x format_dual_option.sh
```

### 2. Ejecutar el Script
Una vez que el script tenga permisos, ejecútalo con:

```bash
sudo ./nombre_del_script.sh
```

**Ejemplo para el formateador de discos:**
```bash
sudo ./format_dual_option.sh
```

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

### Para External Disk Formatter:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install exfatprogs exfat-fuse util-linux parted

# Para sistemas más antiguos
sudo apt install exfat-utils exfat-fuse util-linux parted
```

### Dependencias Generales: