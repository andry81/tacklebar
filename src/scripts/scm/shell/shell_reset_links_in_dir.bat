@echo off & goto DOC_END

rem USAGE:
rem   shell_reset_links_in_dir.bat [-+] <flags> [--] <current-directory> <links-directory>

rem Description:
rem   Resets list of Windows shortcut files in a directory recursively.
:DOC_END

setlocal

call "%%~dp0../../__init__/script_init.bat" %%0 %%* || exit /b
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
rem script flags
set FLAG_FLAGS_SCOPE=0
set "FLAG_CHCP="
set "RESET_SHORTCUT_BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG if "%FLAG%" == "-+" set /A FLAG_FLAGS_SCOPE+=1
if defined FLAG if "%FLAG%" == "--" set /A FLAG_FLAGS_SCOPE-=1

if defined FLAG (
  if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    set RESET_SHORTCUT_BARE_FLAGS=%RESET_SHORTCUT_BARE_FLAGS% %FLAG% %2
    shift
  ) else if "%FLAG:~0,7%" == "-reset-" (
    set RESET_SHORTCUT_BARE_FLAGS=%RESET_SHORTCUT_BARE_FLAGS% %FLAG%
  ) else if "%FLAG:~0,7%" == "-allow-" (
    set RESET_SHORTCUT_BARE_FLAGS=%RESET_SHORTCUT_BARE_FLAGS% %FLAG%
  ) else if "%FLAG:~0,5%" == "-use-" (
    set RESET_SHORTCUT_BARE_FLAGS=%RESET_SHORTCUT_BARE_FLAGS% %FLAG%
  ) else if "%FLAG:~0,7%" == "-print-" (
    set RESET_SHORTCUT_BARE_FLAGS=%RESET_SHORTCUT_BARE_FLAGS% %FLAG%
  ) else if not "%FLAG%" == "-+" if not "%FLAG%" == "--" (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP

  if %FLAG_FLAGS_SCOPE% GTR 0 goto FLAGS_LOOP
)

if %FLAG_FLAGS_SCOPE% GTR 0 (
  echo;%?~%: error: not ended flags scope: [%FLAG_FLAGS_SCOPE%]: %FLAG%
  exit /b -255
) >&2

set "CWD=%~1"
shift

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "tokens=* delims="eol^= %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

for /F "tokens=* delims="eol^= %%i in ("%CD%") do echo CD=`%%i`& echo;

set "LINKS_DIR=%~1"

call "%%CONTOOLS_TOOL_ADAPTORS_ROOT%%/vbs/reset_shortcut_from_dir.bat"%%RESET_SHORTCUT_BARE_FLAGS%% -- "%%LINKS_DIR%%"
