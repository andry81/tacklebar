@echo off

setlocal

call "%%~dp0__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem script flags
set RESTORE_LOCALE=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LAST_ERROR%

:MAIN
if %USE_MINTTY%0 NEQ 0 (
  for /F "eol= tokens=* delims=" %%i in ("%MINTTY_TERMINAL_PREFIX%") do echo.^>%%i
  echo.
)

for /F "eol= tokens=* delims=" %%i in ("%COMSPEC%") do echo.^>%%i
echo.

set "CWD=%~1"
shift

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

set CALLF_BARE_FLAGS=/load-parent-proc-init-env-vars /disable-ctrl-signals

if %FLAG_USE_X64% NEQ 0 set CALLF_BARE_FLAGS=%CALLF_BARE_FLAGS% /disable-wow64-fs-redir

set CALLF_BARE_FLAGS=%CALLF_BARE_FLAGS% /print-win-error-string /pipe-inout-child

rem Windows 7 and less check
call "%%CONTOOLS_ROOT%%/std/check_windows_version.bat" 6 2 || (
  rem reattach works on Windows 7 only
  set CALLF_BARE_FLAGS=%CALLF_BARE_FLAGS% /detach-inherited-console-on-wait /wait-child-first-time-timeout 300 
)

set CALLF_BARE_FLAGS=%CALLF_BARE_FLAGS% /no-expand-env /no-subst-vars /no-esc /ret-child-exit

rem register environment variables
set > "%PROJECT_LOG_DIR%\env.0.vars"

"%CONTOOLS_UTILITIES_BIN_ROOT%/contools/callf.exe"%CALLF_BARE_FLAGS% ^
  "%COMSPECLNK%" "/k \"set ^> \"%%PROJECT_LOG_DIR%%\env.1.vars\"\""
set LAST_ERROR=%ERRORLEVEL%

rem restore locale
if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

if %FLAG_QUIT_ON_EXIT% EQU 0 exit /b %LAST_ERROR%

exit %LAST_ERROR%
