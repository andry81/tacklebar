@echo off

setlocal

call "%%CONTOOLS_ROOT%%/std/get_cmdline.bat" %%*
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" RETURN_VALUE ">"
echo.

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
)

if defined MSYS_ROOT for /F "eol= tokens=* delims=" %%i in ("%MSYS_ROOT%\.") do set "MSYS_ROOT=%%~fi"
if defined MSYS32_ROOT for /F "eol= tokens=* delims=" %%i in ("%MSYS32_ROOT%\.") do set "MSYS32_ROOT=%%~fi"
if defined MSYS64_ROOT for /F "eol= tokens=* delims=" %%i in ("%MSYS64_ROOT%\.") do set "MSYS64_ROOT=%%~fi"

rem override MSYS_ROOT
if %FLAG_USE_ONLY_MSYS32_ROOT%0 NEQ 0 (
  set "MSYS_ROOT=%MSYS32_ROOT%"
  set "MSYS_TERMINAL_PREFIX=%MSYS32_TERMINAL_PREFIX%"
  goto END_SELECT_MSYS_ROOT
)
if %FLAG_USE_ONLY_MSYS64_ROOT%0 NEQ 0 (
  set "MSYS_ROOT=%MSYS64_ROOT%"
  set "MSYS_TERMINAL_PREFIX=%MSYS64_TERMINAL_PREFIX%"
  goto END_SELECT_MSYS_ROOT
)

if %COMSPEC_X64_VER%0 NEQ 0 (
  if defined MSYS64_ROOT if exist "\\?\%MSYS64_ROOT%\" (
    set "MSYS_ROOT=%MSYS64_ROOT%"
    set "MSYS_TERMINAL_PREFIX=%MSYS64_TERMINAL_PREFIX%"
  )
) else if defined MSYS32_ROOT if exist "\\?\%MSYS32_ROOT%\" (
  set "MSYS_ROOT=%MSYS32_ROOT%"
  set "MSYS_TERMINAL_PREFIX=%MSYS32_TERMINAL_PREFIX%"
)

:END_SELECT_MSYS_ROOT

if %USE_MINTTY%0 EQU 0 goto USE_MINTTY_END

if %COMSPEC_X64_VER%0 NEQ 0 (
  if defined MINTTY64_ROOT if exist "\\?\%MINTTY64_ROOT%\" (
    set "MINTTY_ROOT=%MINTTY64_ROOT%"
  )
  set "MINTTY_TERMINAL_PREFIX=%MINTTY64_TERMINAL_PREFIX%"
) else (
  if defined MINTTY32_ROOT if exist "\\?\%MINTTY32_ROOT%\" (
    set "MINTTY_ROOT=%MINTTY32_ROOT%"
  )
  set "MINTTY_TERMINAL_PREFIX=%MINTTY32_TERMINAL_PREFIX%"
)

:USE_MINTTY_END

if defined MSYS_ROOT if exist "%MSYS_ROOT%\bin\" goto MSYS_OK
(
  echo.%?~nx0%: error: `MSYS_ROOT` variable is not defined or not valid: "%MSYS_ROOT%"
  exit /b 255
) >&2

:MSYS_OK

rem register overriden MSYS_ROOT
for /F "eol= tokens=* delims=" %%i in ("%MSYS_ROOT%") do (echo.%%i) > "%PROJECT_LOG_DIR%\msys_root.var"

for /F "eol= tokens=* delims=" %%i in ("%COMSPEC%") do echo.^>%%i
echo.

for /F "eol= tokens=* delims=" %%i in ("%MSYS_ROOT:\=/%/bin/bash.exe") do echo.^>%%i

exit /b 0
