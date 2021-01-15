@echo off

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%"

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
set CMDLINE_STR=^>%?~f0% !CMDLINE_STR!
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" CMDLINE_STR
echo.
endlocal

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
) else if exist "%SystemRoot%\System32\chcp.com" for /F "usebackq eol= tokens=1,* delims=:" %%i in (`@"%%SystemRoot%%\System32\chcp.com" 2^>nul`) do set "CURRENT_CP=%%j"
if defined CURRENT_CP set "CURRENT_CP=%CURRENT_CP: =%"

for /F "eol= tokens=* delims=" %%i in ("%COMSPEC%") do echo.^>%%i
echo.

for /F "eol= tokens=* delims=" %%i in ("%CYGWIN_ROOT:\=/%/bin/bash.exe") do echo.^>%%i
