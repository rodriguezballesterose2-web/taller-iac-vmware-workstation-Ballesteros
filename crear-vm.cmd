@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM ============================================================
REM crear-vm.cmd - Crea una VM en VMware Workstation (IaC)
REM Codigos de salida: 0 = correcto, 1 = fallo, 2 = parametros invalidos
REM ============================================================

REM ---- Valores por defecto ----
set "VM_NAME=VM_Taller"
set "VM_DIR=%USERPROFILE%\Documents\Virtual Machines"
set "VM_ISO="
set "VM_CPUS=2"
set "VM_MEM=2048"
set "VM_DISK=20"
set "VM_NET=nat"
set "DO_START=0"
set "DRY_RUN=0"
set "FORCE=0"

REM ---- Lectura de parametros ----
:parse
if "%~1"=="" goto :parsed
if /i "%~1"=="-h" goto :help
if /i "%~1"=="--help" goto :help
if /i "%~1"=="--name"  ( set "VM_NAME=%~2"  & shift & shift & goto :parse )
if /i "%~1"=="--dir"   ( set "VM_DIR=%~2"   & shift & shift & goto :parse )
if /i "%~1"=="--iso"   ( set "VM_ISO=%~2"   & shift & shift & goto :parse )
if /i "%~1"=="--cpus"  ( set "VM_CPUS=%~2"  & shift & shift & goto :parse )
if /i "%~1"=="--mem"   ( set "VM_MEM=%~2"   & shift & shift & goto :parse )
if /i "%~1"=="--disk"  ( set "VM_DISK=%~2"  & shift & shift & goto :parse )
if /i "%~1"=="--net"   ( set "VM_NET=%~2"   & shift & shift & goto :parse )
if /i "%~1"=="--start"   ( set "DO_START=1" & shift & goto :parse )
if /i "%~1"=="--dry-run" ( set "DRY_RUN=1"  & shift & goto :parse )
if /i "%~1"=="--force"   ( set "FORCE=1"    & shift & goto :parse )
echo [ERROR] Parametro desconocido: %~1
echo         Use --help para ver el uso.
exit /b 2
:parsed

REM ---- Validacion de entradas (todo antes de crear nada) ----
echo(!VM_NAME!| findstr /r /x "[A-Za-z0-9._-][A-Za-z0-9._-]*" >nul
if errorlevel 1 (
    echo [ERROR] --name solo admite letras, numeros, punto, guion y guion bajo: "!VM_NAME!"
    exit /b 2
)
call :checknum "--cpus" "!VM_CPUS!" || exit /b 2
call :checknum "--mem"  "!VM_MEM!"  || exit /b 2
call :checknum "--disk" "!VM_DISK!" || exit /b 2
if /i not "!VM_NET!"=="nat" if /i not "!VM_NET!"=="bridged" if /i not "!VM_NET!"=="hostonly" (
    echo [ERROR] --net debe ser nat, bridged o hostonly: "!VM_NET!"
    exit /b 2
)
if defined VM_ISO if not exist "!VM_ISO!" (
    echo [ERROR] La ISO no existe: "!VM_ISO!"
    exit /b 2
)

REM ---- [1/7] Deteccion de VMware Workstation (sin rutas fijas) ----
set "VMW_HOME="
if exist "%ProgramFiles%\VMware\VMware Workstation\vmrun.exe" set "VMW_HOME=%ProgramFiles%\VMware\VMware Workstation"
if not defined VMW_HOME if exist "%ProgramFiles(x86)%\VMware\VMware Workstation\vmrun.exe" set "VMW_HOME=%ProgramFiles(x86)%\VMware\VMware Workstation"
if not defined VMW_HOME (
    echo [ERROR] No se encontro VMware Workstation en este equipo.
    exit /b 1
)
set "VMRUN=!VMW_HOME!\vmrun.exe"
set "VDM=!VMW_HOME!\vmware-vdiskmanager.exe"
if not exist "!VDM!" (
    echo [ERROR] No se encontro vmware-vdiskmanager.exe en !VMW_HOME!
    exit /b 1
)

set "VM_PATH=!VM_DIR!\!VM_NAME!"
set "VMX=!VM_PATH!\!VM_NAME!.vmx"
set "VMDK=!VM_PATH!\!VM_NAME!.vmdk"

echo [1/7] Herramientas verificadas en: !VMW_HOME!
echo [INFO] name=!VM_NAME! cpus=!VM_CPUS! mem=!VM_MEM! disk=!VM_DISK!GB net=!VM_NET!

REM ---- Idempotencia: si la VM ya existe, detenerse salvo --force ----
if exist "!VM_PATH!" (
    if "!FORCE!"=="0" (
        echo [ERROR] La VM ya existe: !VM_PATH!
        echo         Use --force para recrearla.
        exit /b 1
    )
    "!VMRUN!" -T ws list | findstr /i /c:"!VMX!" >nul
    if not errorlevel 1 (
        echo [ERROR] La VM esta encendida. Apaguela antes de usar --force.
        exit /b 1
    )
)

REM ---- Simulacion ----
if "!DRY_RUN!"=="1" (
    echo [DRY-RUN] Se crearia la carpeta: !VM_PATH!
    echo [DRY-RUN] Se crearia el disco dinamico de !VM_DISK!GB: !VMDK!
    echo [DRY-RUN] Se generaria el archivo de configuracion: !VMX!
    if "!DO_START!"=="1" echo [DRY-RUN] Se encenderia la VM.
    echo [DRY-RUN] No se modifico nada en disco.
    exit /b 0
)

REM ---- Si existia y hay --force, se elimina para recrear ----
if exist "!VM_PATH!" (
    echo [INFO] --force: eliminando la VM existente...
    rmdir /s /q "!VM_PATH!"
)

REM ---- [2/7] Crear carpeta de la VM ----
echo [2/7] Creando carpeta: !VM_PATH!
mkdir "!VM_PATH!"
if errorlevel 1 (
    echo [ERROR] No se pudo crear la carpeta.
    exit /b 1
)

REM ---- [3/7] Crear disco virtual dinamico (growable, tipo 0) ----
echo [3/7] Creando disco de !VM_DISK!GB...
"!VDM!" -c -s !VM_DISK!GB -a lsilogic -t 0 "!VMDK!"
if errorlevel 1 (
    echo [ERROR] Fallo la creacion del disco.
    exit /b 1
)

echo [OK] Carpeta y disco creados. Falta generar el .vmx en el siguiente paso.
exit /b 0

REM ---- Ayuda ----
:help
echo.
echo Uso: crear-vm.cmd [opciones]
echo.
echo   --name NOMBRE   Nombre de la VM (letras, numeros, . - _). Defecto: VM_Taller
echo   --dir RUTA      Carpeta base. Defecto: Documents\Virtual Machines
echo   --iso RUTA      Imagen ISO de instalacion (debe existir)
echo   --cpus N        Procesadores virtuales. Defecto: 2
echo   --mem MB        Memoria RAM en MB. Defecto: 2048
echo   --disk GB       Tamano del disco en GB. Defecto: 20
echo   --net MODO      nat, bridged o hostonly. Defecto: nat
echo   --start         Enciende la VM al terminar
echo   --dry-run       Simula sin crear nada
echo   --force         Permite recrear una VM existente
echo   -h, --help      Muestra esta ayuda
echo.
exit /b 0

REM ---- Subrutina: valida entero positivo ----
:checknum
echo(%~2| findstr /r /x "[0-9][0-9]*" >nul
if errorlevel 1 (
    echo [ERROR] %~1 debe ser un entero positivo: %~2
    exit /b 2
)
echo(%~2| findstr /r /x "0*" >nul
if not errorlevel 1 (
    echo [ERROR] %~1 debe ser mayor que cero: %~2
    exit /b 2
)
exit /b 0