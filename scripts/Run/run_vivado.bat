@echo off
setlocal

echo --- Searching for Vivado Installation ---

REM Check if vivado is already in PATH
where vivado >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Vivado found in PATH.
    vivado -mode batch -source run_vivado.tcl
    pause
    goto :EOF
)

REM Common Install Paths to check (Add more if needed)
set "VIVADO_PATHS=C:\AMDDesignTools\2025.2\Vivado\bin;C:\Xilinx\Vivado\2024.1\bin;C:\Xilinx\Vivado\2023.2\bin;C:\Xilinx\Vivado\2023.1\bin;C:\Xilinx\Vivado\2022.2\bin;C:\Xilinx\Vivado\2022.1\bin;C:\Xilinx\Vivado\2021.2\bin;C:\Xilinx\Vivado\2020.2\bin"

for %%P in ("%VIVADO_PATHS:;=" "%") do (
    if exist "%%~P\vivado.bat" (
        echo [INFO] Found Vivado at: %%~P
        set "PATH=%%~P;%PATH%"
        vivado -mode batch -source run_vivado.tcl
        pause
        goto :EOF
    )
)

echo [ERROR] Vivado not found in PATH or standard locations.
echo Please add Vivado/bin to your PATH or edit this script.
pause
