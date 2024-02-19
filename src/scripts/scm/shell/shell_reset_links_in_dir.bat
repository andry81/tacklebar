@echo off

setlocal

call "%%~dp0../../__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem script flags
set RESTORE_LOCALE=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || (
  echo.%?~nx0%: error: could not allocate temporary directory: "%SCRIPT_TEMP_CURRENT_DIR%"
  exit /b 255
) >&2

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

:EXIT_MAIN
rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LASTERROR%

:MAIN
rem script flags
set "FLAG_CHCP="
set FLAG_PRINT_ASSIGN=0
set "BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-pause_on_exit" (
    set FLAG_PAUSE_ON_EXIT=1
  ) else if "%FLAG%" == "-pause_on_error" (
    set FLAG_PAUSE_ON_ERROR=1
  ) else if "%FLAG%" == "-pause_timeout_sec" (
    set "FLAG_PAUSE_TIMEOUT_SEC=%~2"
    shift
  ) else if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    set BARE_FLAGS=%BARE_FLAGS% -chcp "%~2"
    shift
  ) else if "%FLAG:~0,7%" == "-reset-" (
    set BARE_FLAGS=%BARE_FLAGS% %1
  ) else if "%FLAG:~0,7%" == "-allow-" (
    set BARE_FLAGS=%BARE_FLAGS% %1
  ) else if "%FLAG%" == "-print-assign" (
    if %FLAG_PRINT_ASSIGN% EQU 0 set BARE_FLAGS=%BARE_FLAGS% -p
    set FLAG_PRINT_ASSIGN=1
  ) else if "%FLAG%" == "-p" (
    if %FLAG_PRINT_ASSIGN% EQU 0 set BARE_FLAGS=%BARE_FLAGS% -p
    set FLAG_PRINT_ASSIGN=1
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "CWD=%~1"
shift

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

for /F "eol= tokens=* delims=" %%i in ("%CD%") do echo CD=`%%i`& echo.

set "LINKS_DIR=%~1"

call "%%CONTOOLS_TOOL_ADAPTORS_ROOT%%/vbs/reset_shortcut_from_dir.bat"%%BARE_FLAGS%% "%%LINKS_DIR%%"
