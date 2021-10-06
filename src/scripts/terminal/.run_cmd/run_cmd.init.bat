@echo off

call "%%CONTOOLS_ROOT%%/std/get_cmdline.bat" %%*
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" RETURN_VALUE ">"
echo.

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
)

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

for /F "eol= tokens=* delims=" %%i in ("%COMSPEC%") do echo.^>%%i

exit /b 0
