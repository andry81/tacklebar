@echo off

setlocal

call "%%CONTOOLS_ROOT%%/std/get_cmdline.bat" %%*
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" RETURN_VALUE ">"
echo.

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
)

if defined CYGWIN_ROOT for /F "eol= tokens=* delims=" %%i in ("%CYGWIN_ROOT%\.") do set "CYGWIN_ROOT=%%~fi"
if defined CYGWIN32_ROOT for /F "eol= tokens=* delims=" %%i in ("%CYGWIN32_ROOT%\.") do set "CYGWIN32_ROOT=%%~fi"
if defined CYGWIN64_ROOT for /F "eol= tokens=* delims=" %%i in ("%CYGWIN64_ROOT%\.") do set "CYGWIN64_ROOT=%%~fi"

rem override CYGWIN_ROOT
if %FLAG_USE_ONLY_CYGWIN32_ROOT%0 NEQ 0 (
  set "CYGWIN_ROOT=%CYGWIN32_ROOT%"
  set "CYGWIN_TERMINAL_PREFIX=%CYGWIN32_TERMINAL_PREFIX%"
  goto END_SELECT_CYGWIN_ROOT
)
if %FLAG_USE_ONLY_CYGWIN64_ROOT%0 NEQ 0 (
  set "CYGWIN_ROOT=%CYGWIN64_ROOT%"
  set "CYGWIN_TERMINAL_PREFIX=%CYGWIN64_TERMINAL_PREFIX%"
  goto END_SELECT_CYGWIN_ROOT
)

if %COMSPEC_X64_VER%0 NEQ 0 (
  if defined CYGWIN64_ROOT if exist "\\?\%CYGWIN64_ROOT%\" (
    set "CYGWIN_ROOT=%CYGWIN64_ROOT%"
    set "CYGWIN_TERMINAL_PREFIX=%CYGWIN64_TERMINAL_PREFIX%"
  )
) else if defined CYGWIN32_ROOT if exist "\\?\%CYGWIN32_ROOT%\" (
  set "CYGWIN_ROOT=%CYGWIN32_ROOT%"
  set "CYGWIN_TERMINAL_PREFIX=%CYGWIN32_TERMINAL_PREFIX%"
)

:END_SELECT_CYGWIN_ROOT

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

if defined CYGWIN_ROOT if exist "%CYGWIN_ROOT%\bin\" goto CYGWIN_OK
(
  echo.%?~nx0%: error: `CYGWIN_ROOT` variable is not defined or not valid: "%CYGWIN_ROOT%"
  exit /b 255
) >&2

:CYGWIN_OK

rem register overriden CYGWIN_ROOT
for /F "eol= tokens=* delims=" %%i in ("%CYGWIN_ROOT%") do (echo.%%i) > "%PROJECT_LOG_DIR%\cygwin_root.var"

for /F "eol= tokens=* delims=" %%i in ("%COMSPEC%") do echo.^>%%i
echo.

for /F "eol= tokens=* delims=" %%i in ("%CYGWIN_ROOT:\=/%/bin/bash.exe") do echo.^>%%i

exit /b 0
