# Taller IaC: crear una VM en VMware Workstation con un script .cmd

Script `crear-vm.cmd` que crea (y opcionalmente enciende) una maquina virtual
en VMware Workstation para Windows, usando solo comandos de Windows y las
utilidades de linea de comandos incluidas con Workstation (`vmware-vdiskmanager`
y `vmrun`). El archivo de configuracion `.vmx` lo genera el script.

## Requisitos

- Windows con VMware Workstation instalado (el script detecta la ruta de instalacion).
- Ejecutar desde `cmd.exe` (no PowerShell).
- Espacio en disco suficiente para el disco virtual.

## Uso

```
crear-vm.cmd [opciones]
```

| Parametro | Valor por defecto | Descripcion |
|---|---|---|
| `--name NOMBRE` | `VM_Taller` | Nombre de la VM (letras, numeros, punto, guion y guion bajo) |
| `--dir RUTA` | `Documents\Virtual Machines` | Carpeta base donde se crea la carpeta de la VM |
| `--iso RUTA` | (ninguno) | Imagen ISO de instalacion; si se indica y no existe, falla |
| `--cpus N` | `2` | Procesadores virtuales (entero positivo) |
| `--mem MB` | `2048` | Memoria RAM en MB (entero positivo) |
| `--disk GB` | `20` | Tamano del disco en GB (entero positivo, crecimiento dinamico) |
| `--net MODO` | `nat` | `nat`, `bridged` o `hostonly` |
| `--start` | desactivado | Enciende la VM al terminar |
| `--dry-run` | desactivado | Simula sin crear ni modificar nada en disco |
| `--force` | desactivado | Permite recrear una VM que ya existe (no si esta encendida) |
| `-h`, `--help` | | Muestra la ayuda |

## Ejemplos

```
crear-vm.cmd --help
crear-vm.cmd --name prueba --dry-run
crear-vm.cmd --name taller1 --iso "C:\ruta\ubuntu-server.iso"
crear-vm.cmd --name taller1 --iso "C:\ruta\ubuntu-server.iso" --start
crear-vm.cmd --name taller2 --cpus 4 --mem 4096 --disk 30 --net bridged
crear-vm.cmd --name taller1 --force
```

## Codigos de salida

| Codigo | Significado |
|---|---|
| 0 | Todo correcto |
| 1 | Fallo la ejecucion (por ejemplo, la VM ya existe o esta encendida) |
| 2 | Parametros invalidos |

## Comportamiento

- Valida todas las entradas antes de crear nada.
- Idempotente: si la VM ya existe, se detiene sin modificarla, salvo con `--force`.
- Con `--force` no actua sobre una VM encendida.
- Con `--dry-run` no queda ningun archivo nuevo en disco.
- En Workstation no hay que "registrar" la VM: basta con abrir el archivo `.vmx`.

## Estructura del repositorio

```
crear-vm.cmd     # script
README.md        # este archivo
informe/         # informe en PDF (APA 7)
evidencias/      # capturas de las pruebas T1-T11
.gitignore       # no se suben discos virtuales, ISOs ni logs
.gitattributes   # finales de linea CRLF en los .cmd
```