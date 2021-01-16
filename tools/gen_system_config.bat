@echo off

setlocal

set "CONFIG_IN_DIR=%~1"
set "CONFIG_OUT_DIR=%~2"
set "CONFIG_FILE=%~3"

for /F "eol= tokens=* delims=" %%i in ("%CONFIG_IN_DIR%\.") do set "CONFIG_IN_DIR=%%~fi"
for /F "eol= tokens=* delims=" %%i in ("%CONFIG_OUT_DIR%\.") do set "CONFIG_OUT_DIR=%%~fi"

if exist "%CONFIG_OUT_DIR%\%CONFIG_FILE%" exit /b 0

set ACP=1251
call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKLM\SYSTEM\CurrentControlSet\Control\Nls\CodePage" ACP >nul 2>nul
if defined REGQUERY_VALUE set "ACP=%REGQUERY_VALUE%"

set OEMCP=437
call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKLM\SYSTEM\CurrentControlSet\Control\Nls\CodePage" OEMCP >nul 2>nul
if defined REGQUERY_VALUE set "OEMCP=%REGQUERY_VALUE%"

(
  endlocal
  call "%%CONTOOLS_ROOT%%/std/gen_config.bat" -r "{{ACP}}" "%ACP%" -r "{{OEMCP}}" "%OEMCP%" "%CONFIG_IN_DIR%" "%CONFIG_OUT_DIR%" "%CONFIG_FILE%"
)
