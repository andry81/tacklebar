@echo off

if defined MINTTY32_ROOT for /F "eol= tokens=* delims=" %%i in ("%MINTTY32_ROOT%\.") do set "MINTTY32_ROOT=%%~fi"
if defined MINTTY64_ROOT for /F "eol= tokens=* delims=" %%i in ("%MINTTY64_ROOT%\.") do set "MINTTY64_ROOT=%%~fi"

if %COMSPEC_X64_VER%0 NEQ 0 (
  if defined MINTTY64_ROOT if exist "\\?\%MINTTY64_ROOT%\*" (
    set "MINTTY_ROOT=%MINTTY64_ROOT%"
    set MINTTY_TERMINAL_PREFIX=%MINTTY64_TERMINAL_PREFIX%
  )
) else (
  if defined MINTTY32_ROOT if exist "\\?\%MINTTY32_ROOT%\*" (
    set "MINTTY_ROOT=%MINTTY32_ROOT%"
    set MINTTY_TERMINAL_PREFIX=%MINTTY32_TERMINAL_PREFIX%
  )
)

exit /b 0
