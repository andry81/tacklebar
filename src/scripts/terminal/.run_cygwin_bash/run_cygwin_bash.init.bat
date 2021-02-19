@echo off

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || (
  echo.%~nx0: error: could not allocate temporary directory: "%SCRIPT_TEMP_CURRENT_DIR%"
  exit /b 255
) >&2

rem redirect command line into temporary file to print it correcly
setlocal
for %%i in (1) do (
    set "PROMPT=$_"
    echo on
    for %%b in (1) do rem * #%*#
    @echo off
) > "%SCRIPT_TEMP_CURRENT_DIR%\cmdline.txt"
endlocal

for /F "usebackq eol= tokens=* delims=" %%i in ("%SCRIPT_TEMP_CURRENT_DIR%\cmdline.txt") do set "CMDLINE_STR=%%i"
setlocal ENABLEDELAYEDEXPANSION
set "CMDLINE_STR=!CMDLINE_STR:*#=!"
set "CMDLINE_STR=!CMDLINE_STR:~0,-2!"
set CMDLINE_STR=^>"!?~f0!" !CMDLINE_STR!
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" CMDLINE_STR
echo.
endlocal

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
)

if defined CYGWIN_ROOT for /F "eol= tokens=* delims=" %%i in ("%CYGWIN_ROOT%\.") do set "CYGWIN_ROOT=%%~fi"
if defined CYGWIN32_ROOT for /F "eol= tokens=* delims=" %%i in ("%CYGWIN32_ROOT%\.") do set "CYGWIN32_ROOT=%%~fi"
if defined CYGWIN64_ROOT for /F "eol= tokens=* delims=" %%i in ("%CYGWIN64_ROOT%\.") do set "CYGWIN64_ROOT=%%~fi"

rem override CYGWIN_ROOT
if %FLAG_USE_ONLY_CYGWIN32_ROOT%0 NEQ 0 ( set "CYGWIN_ROOT=%CYGWIN32_ROOT%" & goto END_SELECT_CYGWIN_ROOT )
if %FLAG_USE_ONLY_CYGWIN64_ROOT%0 NEQ 0 ( set "CYGWIN_ROOT=%CYGWIN64_ROOT%" & goto END_SELECT_CYGWIN_ROOT )

if %PROC_X64_VER%0 NEQ 0 (
  if defined CYGWIN64_ROOT if exist "\\?\%CYGWIN64_ROOT%\" set "CYGWIN_ROOT=%CYGWIN64_ROOT%"
) else if defined CYGWIN32_ROOT if exist "\\?\%CYGWIN32_ROOT%\" set "CYGWIN_ROOT=%CYGWIN32_ROOT%"

:END_SELECT_CYGWIN_ROOT

rem register overriden CYGWIN_ROOT
for /F "eol= tokens=* delims=" %%i in ("%CYGWIN_ROOT%") do (echo.%%i) > "%PROJECT_LOG_DIR%\cygwin_root.var"

for /F "eol= tokens=* delims=" %%i in ("%COMSPEC%") do echo.^>%%i
echo.

for /F "eol= tokens=* delims=" %%i in ("%CYGWIN_ROOT:\=/%/bin/bash.exe") do echo.^>%%i

exit /b 0
