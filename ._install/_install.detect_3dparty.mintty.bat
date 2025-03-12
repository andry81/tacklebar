@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_MINTTY32_ROOT="
set "DETECTED_MINTTY32_TERMINAL_PREFIX="
set "DETECTED_MINTTY64_ROOT="
set "DETECTED_MINTTY64_TERMINAL_PREFIX="

echo.Searching `MinTTY` installation...
echo.

call :DETECT %%*

echo. * MINTTY32_ROOT="%DETECTED_MINTTY32_ROOT%"
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!DETECTED_MINTTY32_TERMINAL_PREFIX!") do endlocal & echo. * MINTTY32_TERMINAL_PREFIX="%%i"
echo. * MINTTY64_ROOT="%DETECTED_MINTTY64_ROOT%"
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!DETECTED_MINTTY64_TERMINAL_PREFIX!") do endlocal & echo. * MINTTY64_TERMINAL_PREFIX="%%i"

echo.

if not defined DETECTED_MINTTY32_ROOT (
  echo.%?~%: warning: `MinTTY` 32-bit is not detected.
  echo.
) >&2

if not defined DETECTED_MINTTY64_ROOT (
  echo.%?~%: warning: `MinTTY` 64-bit is not detected.
  echo.
) >&2

rem return variable
setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=1,2 delims=|"eol^= %%i in ("!DETECTED_MINTTY32_TERMINAL_PREFIX!|!DETECTED_MINTTY64_TERMINAL_PREFIX!") do endlocal & (
  endlocal
  set "DETECTED_MINTTY32_ROOT=%DETECTED_MINTTY32_ROOT%"
  set "DETECTED_MINTTY32_TERMINAL_PREFIX=%%i"
  set "DETECTED_MINTTY64_ROOT=%DETECTED_MINTTY64_ROOT%"
  set "DETECTED_MINTTY64_TERMINAL_PREFIX=%%j"
  exit /b 0
)

:DETECT
rem drop last error level
call;

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

for %%i in (DETECTED_MSYS32_ROOT DETECTED_MSYS64_ROOT) do (
  set "MSYS_ROOT=%%i"
  call :FIND_INSTALL_DIR
)

goto END_SEARCH

:FIND_INSTALL_DIR

call set "MSYS_ROOT=%%%MSYS_ROOT%%%"

if not exist "%MSYS_ROOT%\usr\bin\mintty.exe" exit /b 0

call "%%CONTOOLS_ROOT%%/filesys/read_pe_header_bitness.bat" "%%MSYS_ROOT%%\usr\bin\mintty.exe"

rem find first
if "%RETURN_VALUE%" == "64" (
  if not defined DETECTED_MINTTY64_ROOT (
    set "DETECTED_MINTTY64_ROOT=%MSYS_ROOT%"
    set "DETECTED_MINTTY64_TERMINAL_PREFIX=$/\x22%%MINTTY64_ROOT%%\usr\bin\mintty.exe$/\x22"
  )
) else (
  if not defined DETECTED_MINTTY32_ROOT (
    set "DETECTED_MINTTY32_ROOT=%MSYS_ROOT%"
    set "DETECTED_MINTTY32_TERMINAL_PREFIX=$/\x22%%MINTTY32_ROOT%%\usr\bin\mintty.exe$/\x22"
  )
)

:END_SEARCH

for %%i in (DETECTED_CYGWIN32_ROOT DETECTED_CYGWIN64_ROOT) do (
  set "CYGWIN_ROOT=%%i"
  call :FIND_INSTALL_DIR
)

goto END_SEARCH

:FIND_INSTALL_DIR

call set "CYGWIN_ROOT=%%%CYGWIN_ROOT%%%"

if not exist "%CYGWIN_ROOT%\bin\mintty.exe" exit /b 0

call "%%CONTOOLS_ROOT%%/filesys/read_pe_header_bitness.bat" "%%CYGWIN_ROOT%%\bin\mintty.exe"

rem find first
if "%RETURN_VALUE%" == "64" (
  if not defined DETECTED_MINTTY64_ROOT (
    set "DETECTED_MINTTY64_ROOT=%CYGWIN_ROOT%"
    set "DETECTED_MINTTY64_TERMINAL_PREFIX=$/\x22%%MINTTY64_ROOT%%\bin\mintty.exe$/\x22 -i $/\x22%%MINTTY64_ROOT%%\Cygwin-Terminal.ico$/\x22"
  )
) else (
  if not defined DETECTED_MINTTY32_ROOT (
    set "DETECTED_MINTTY32_ROOT=%CYGWIN_ROOT%"
    set "DETECTED_MINTTY32_TERMINAL_PREFIX=$/\x22%%MINTTY32_ROOT%%\bin\mintty.exe$/\x22 -i $/\x22%%MINTTY32_ROOT%%\Cygwin-Terminal.ico$/\x22"
  )
)

:END_SEARCH

exit /b 0
