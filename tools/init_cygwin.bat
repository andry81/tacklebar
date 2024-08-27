@echo off

if defined CYGWIN32_ROOT for /F "eol= tokens=* delims=" %%i in ("%CYGWIN32_ROOT%\.") do set "CYGWIN32_ROOT=%%~fi"
if defined CYGWIN64_ROOT for /F "eol= tokens=* delims=" %%i in ("%CYGWIN64_ROOT%\.") do set "CYGWIN64_ROOT=%%~fi"

set "CYGWIN_ROOT="
set "MINTTY_TERMINAL_PREFIX="

if %COMSPEC_X64_VER%0 NEQ 0 (
  if defined CYGWIN64_ROOT if exist "\\?\%CYGWIN64_ROOT%\*" (
    set "CYGWIN_ROOT=%CYGWIN64_ROOT%"
    set "MINTTY_TERMINAL_PREFIX=%CYGWIN64_MINTTY_TERMINAL_PREFIX%"
  )
) else (
  if defined CYGWIN32_ROOT if exist "\\?\%CYGWIN32_ROOT%\*" (
    set "CYGWIN_ROOT=%CYGWIN32_ROOT%"
    set "MINTTY_TERMINAL_PREFIX=%CYGWIN32_MINTTY_TERMINAL_PREFIX%"
  )
)

exit /b 0
