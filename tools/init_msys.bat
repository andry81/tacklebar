@echo off

if defined MSYS32_ROOT for /F "eol= tokens=* delims=" %%i in ("%MSYS32_ROOT%\.") do set "MSYS32_ROOT=%%~fi"
if defined MSYS64_ROOT for /F "eol= tokens=* delims=" %%i in ("%MSYS64_ROOT%\.") do set "MSYS64_ROOT=%%~fi"

if %COMSPEC_X64_VER%0 NEQ 0 (
  if defined MSYS64_ROOT if exist "\\?\%MSYS64_ROOT%\*" (
    set "MSYS_ROOT=%MSYS64_ROOT%"
    set "MINTTY_TERMINAL_PREFIX=%MSYS64_MINTTY_TERMINAL_PREFIX%"
  )
) else if defined MSYS32_ROOT if exist "\\?\%MSYS32_ROOT%\*" (
  set "MSYS_ROOT=%MSYS32_ROOT%"
  set "MINTTY_TERMINAL_PREFIX=%MSYS32_MINTTY_TERMINAL_PREFIX%"
)
