@echo off

setlocal

rem CAUTION:
rem   In Windowx XP an elevated call under data protection flag will block the wmic tool, so we have to use `ver` command instead!
rem
for /F "usebackq tokens=1,2,* delims=[]" %%i in (`ver`) do for /F "tokens=1,2,* delims= " %%l in ("%%j") do set "WINDOWS_VER_STR=%%m"

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

rem CAUTION:
rem   Specific case for Windows XP x64 SP2, where both PROCESSOR_ARCHITECTURE and PROCESSOR_ARCHITEW6432 are equal to AMD64 for 32-bit cmd.exe process!
rem
set "EXPAND_PARAM1=OS32"
if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" if not defined PROCESSOR_ARCHITEW6432 set "EXPAND_PARAM1="

(
  endlocal
  call "%%CONTOOLS_ROOT%%/std/load_config.bat" -lite_parse %%* "%EXPAND_PARAM0%" "%EXPAND_PARAM1%"
)
