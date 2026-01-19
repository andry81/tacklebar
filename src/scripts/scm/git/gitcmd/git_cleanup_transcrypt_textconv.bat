@echo off

setlocal

call "%%~dp0../../../__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem script flags
set RESTORE_LOCALE=0

rem call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

rem rem cleanup temporary files
rem call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LAST_ERROR%

:MAIN
rem script flags
set FLAG_FLAGS_SCOPE=0
set FLAG_SHIFT=0
set "FLAG_CHCP="

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
    shift
    set /A FLAG_SHIFT+=1
  ) else if not "%FLAG%" == "-+" if not "%FLAG%" == "--" (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift
  set /A FLAG_SHIFT+=1

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP

  if %FLAG_FLAGS_SCOPE% GTR 0 goto FLAGS_LOOP
)

if %FLAG_FLAGS_SCOPE% GTR 0 (
  echo;%?~%: error: not ended flags scope: %FLAG_FLAGS_SCOPE%
  exit /b -255
) >&2

set "CWD=%~1"
shift
set /A FLAG_SHIFT+=1

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "tokens=* delims="eol^= %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

for /F "tokens=* delims="eol^= %%i in ("%CD%") do echo CD=`%%i`& echo;

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CONTOOLS_ROOT%%/std/callshift.bat" -skip 1 %%FLAG_SHIFT%% "%%GIT_SHELL_ROOT%%\bin\bash.exe" "%%CONTOOLS_PROJECT_EXTERNALS_ROOT:\=/%%/gitcmd/scripts/transcrypt/git_cleanup_transcrypt_textconv.sh" %%*
exit /b
