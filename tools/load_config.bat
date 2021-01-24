@echo off

setlocal

for /F "usebackq tokens=* delims=" %%i in (`ver`) do set "VER_STR=%%i"

rem CAUTION:
rem   Usage of the `ver` is not reliable because rely on the `XP` suffix, which in Windows XP x64 SP1 MAY DOES NOT EXIST!
rem
call "%%CONTOOLS_ROOT%%/std/get_wmic_os_version.bat"
set "WINDOWS_VER_STR=%RETURN_VALUE%"

set WINDOWS_MAJOR_VER=0
set WINDOWS_MINOR_VER=0
for /F "eol= tokens=1,2,* delims=." %%i in ("%WINDOWS_VER_STR%") do ( set "WINDOWS_MAJOR_VER=%%i" & set "WINDOWS_MINOR_VER=%%j" )

set "EXPAND_PARAM0="

if %WINDOWS_MAJOR_VER% GTR 5 goto WINDOWS_VER_OK
if %WINDOWS_MAJOR_VER% EQU 5 if %WINDOWS_MINOR_VER% GEQ 1 goto WINDOWS_VER_OK

(
  echo.%~nx0: error: unsupported version of Windows: "%WINDOWS_VER_STR%"
  exit /b 255
) >&2

:WINDOWS_VER_OK

if %WINDOWS_MAJOR_VER% EQU 5 set "EXPAND_PARAM0=OSWINXP"

set "EXPAND_PARAM1="
if /i "%PROCESSOR_ARCHITECTURE%" == "x86" if not defined PROCESSOR_ARCHITEW6432 set "EXPAND_PARAM1=OS32"

(
  endlocal
  call "%%CONTOOLS_ROOT%%/std/load_config.bat" -lite_parse %%* "%EXPAND_PARAM0%" "%EXPAND_PARAM1%"
)
