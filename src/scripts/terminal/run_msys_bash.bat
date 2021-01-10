@echo off

setlocal

set "?~0=%~0"
set "?~f0=%~f0"
set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

call "%%?~dp0%%__init__.bat" || exit /b

for %%i in (PROJECT_ROOT PROJECT_LOG_ROOT PROJECT_CONFIG_ROOT CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

if %IMPL_MODE%0 NEQ 0 goto IMPL

rem script flags
set "FLAG_CHCP="
set FLAG_QUIT_ON_EXIT=0
set FLAG_PAUSE_ON_ERROR=0
set FLAG_USE_CMD=0
set FLAG_USE_CONEMU=0
set FLAG_USE_X64=0
set FLAG_USE_X32=0

:FLAGS_OUTTER_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else if "%FLAG%" == "-quit_on_exit" (
    set FLAG_QUIT_ON_EXIT=1
  ) else if "%FLAG%" == "-pause_on_error" (
    set FLAG_PAUSE_ON_ERROR=1
  ) else if "%FLAG%" == "-use_cmd" (
    set FLAG_USE_CMD=1
  ) else if "%FLAG%" == "-use_conemu" (
    set FLAG_USE_CONEMU=1
  ) else if "%FLAG%" == "-comspec" (
    set "COMSPEC=%~2"
    shift
  ) else if "%FLAG%" == "-comspec64" (
    if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" set "COMSPEC=%~2"
    shift
  ) else if "%FLAG%" == "-comspec32" (
    if /i "%PROCESSOR_ARCHITECTURE%" == "x86" set "COMSPEC=%~2"
    shift
  ) else if "%FLAG%" == "-comspeclnk" (
    set "COMSPECLNK=%~2"
    shift
  ) else if "%FLAG%" == "-comspeclnk64" (
    if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" set "COMSPECLNK=%~2"
    shift
  ) else if "%FLAG%" == "-comspeclnk32" (
    if /i "%PROCESSOR_ARCHITECTURE%" == "x86" set "COMSPECLNK=%~2"
    shift
  ) else if "%FLAG%" == "-x64" (
    set FLAG_USE_X64=1
  ) else if "%FLAG%" == "-x32" (
    set FLAG_USE_X32=1
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_OUTTER_LOOP
)

if %FLAG_USE_CMD% NEQ 0 set CONEMU_ENABLE=0
if %FLAG_USE_CONEMU% NEQ 0 set CONEMU_ENABLE=1

if not defined COMSPECLNK set "COMSPECLNK=%COMSPEC%"

if %FLAG_USE_X64% NEQ 0 set "COMSPECLNK=%SystemRoot%\System64\cmd.exe"
if %FLAG_USE_X32% NEQ 0 if defined PROCESSOR_ARCHITEW6432 (
  set "COMSPECLNK=%SystemRoot%\SysWOW64\cmd.exe"
) else set "COMSPECLNK=%SystemRoot%\System32\cmd.exe"

rem CAUTION:
rem   We should avoid use handles 3 and 4 while the redirection has take a place because handles does reuse
rem   internally from left to right when being redirected externally.
rem   Example: if `1` is redirected, then `3` is internally reused, then if `2` redirected, then `4` is internally reused and so on.
rem   The discussion of the logic:
rem   https://stackoverflow.com/questions/9878007/why-doesnt-my-stderr-redirection-end-after-command-finishes-and-how-do-i-fix-i/9880156#9880156
rem   A partial analisis:
rem   https://www.dostips.com/forum/viewtopic.php?p=14612#p14612
rem

(
  endlocal
  set IMPL_MODE=1

  if %CONEMU_ENABLE%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "attach" %CONEMU_CMDLINE_ATTACH_PREFIX%
  if %CONEMU_ENABLE%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "run" (
    %CONEMU_CMDLINE_RUN_PREFIX% "%COMSPECLNK%" /C call "%?~0%" %* -cur_console:n
    set "CONTOOLS_ROOT=%CONTOOLS_ROOT%"
    set "FLAG_PAUSE_ON_ERROR=%FLAG_PAUSE_ON_ERROR%"
    goto IMPL_EXIT
  )
  "%COMSPECLNK%" /C call "%?~0%" %*
  set "CONTOOLS_ROOT=%CONTOOLS_ROOT%"
  set "FLAG_PAUSE_ON_ERROR=%FLAG_PAUSE_ON_ERROR%"
  goto IMPL_EXIT
)

:IMPL_EXIT
set LASTERROR=%ERRORLEVEL%

if %LASTERROR% NEQ 0 if %FLAG_PAUSE_ON_ERROR%0 NEQ 0 call "%%CONTOOLS_ROOT%%/std/pause.bat"

(
  set "LASTERROR="
  set "CONTOOLS_ROOT="
  set "FLAG_PAUSE_ON_ERROR="
  exit /b %LASTERROR%
)

:IMPL
set "?~0=%~0"
set "?~f0=%~f0"
set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

rem script flags
set "FLAG_CHCP="
set FLAG_QUIT_ON_EXIT=0
set FLAG_PAUSE_ON_ERROR=0
set FLAG_USE_X64=0
set FLAG_USE_X32=0

:FLAGS_INNER_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else if "%FLAG%" == "-quit_on_exit" (
    set FLAG_QUIT_ON_EXIT=1
  ) else if "%FLAG%" == "-pause_on_error" (
    set FLAG_PAUSE_ON_ERROR=1
  ) else if "%FLAG%" == "-use_cmd" (
    rem
  ) else if "%FLAG%" == "-use_conemu" (
    rem
  ) else if "%FLAG%" == "-comspec" (
    set "COMSPEC=%~2"
    shift
  ) else if "%FLAG%" == "-comspec64" (
    if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" set "COMSPEC=%~2"
    shift
  ) else if "%FLAG%" == "-comspec32" (
    if /i "%PROCESSOR_ARCHITECTURE%" == "x86" set "COMSPEC=%~2"
    shift
  ) else if "%FLAG%" == "-comspeclnk" (
    set "COMSPECLNK=%~2"
    shift
  ) else if "%FLAG%" == "-comspeclnk64" (
    if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" set "COMSPECLNK=%~2"
    shift
  ) else if "%FLAG%" == "-comspeclnk32" (
    if /i "%PROCESSOR_ARCHITECTURE%" == "x86" set "COMSPECLNK=%~2"
    shift
  ) else if "%FLAG%" == "-x64" (
    set FLAG_USE_X64=1
  ) else if "%FLAG%" == "-x32" (
    set FLAG_USE_X32=1
  )

  shift

  rem read until no flags
  goto FLAGS_INNER_LOOP
)

:FLAGS_INNER_LOOP_END

if not defined COMSPECLNK set "COMSPECLNK=%COMSPEC%"

if %FLAG_USE_X64% NEQ 0 set "COMSPECLNK=%SystemRoot%\System64\cmd.exe"
if %FLAG_USE_X32% NEQ 0 if defined PROCESSOR_ARCHITEW6432 (
  set "COMSPECLNK=%SystemRoot%\SysWOW64\cmd.exe"
) else set "COMSPECLNK=%SystemRoot%\System32\cmd.exe"

title %COMSPEC%

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%/std/get_wmic_local_datetime.bat"
set "LOG_FILE_NAME_SUFFIX=%RETURN_VALUE:~0,4%'%RETURN_VALUE:~4,2%'%RETURN_VALUE:~6,2%_%RETURN_VALUE:~8,2%'%RETURN_VALUE:~10,2%'%RETURN_VALUE:~12,2%''%RETURN_VALUE:~15,3%"

set "PROJECT_LOG_DIR=%PROJECT_LOG_ROOT%/%LOG_FILE_NAME_SUFFIX%.%?~n0%"
set "PROJECT_LOG_FILE=%PROJECT_LOG_DIR%/%LOG_FILE_NAME_SUFFIX%.%?~n0%.log"

if not exist "%PROJECT_LOG_DIR%" ( mkdir "%PROJECT_LOG_DIR%" || exit /b )

if defined MSYS_ROOT if exist "%MSYS_ROOT%\bin\" goto MSYS_OK
(echo.%?~nx0%: error: `MSYS_ROOT` variable is not defined or not valid: "%MSYS_ROOT%".) | "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E /+ "%PROJECT_LOG_FILE:/=\%"
exit /b 255

:MSYS_OK
set "PWD=%~1"

call "%%?~dp0%%.%%?~n0%%\%%?~n0%%.init.bat" %* | "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"

(
  endlocal
  set "IMPL_MODE="

  rem stdout+stderr redirection into the same log file without handles restore
  "%MSYS_ROOT%\bin\bash.exe" -c "{ cd ""%PWD:\=/%""; CHERE_INVOKING=. exec ""%MSYS_ROOT:\=/%/bin/bash.exe"" -l -i; } 2>&1 | ""%MSYS_ROOT:\=/%/bin/tee.exe"" -a ""%PROJECT_LOG_FILE:\=/%"""

  set "CONTOOLS_ROOT=%CONTOOLS_ROOT%"
  set "FLAG_CHCP=%FLAG_CHCP%"
  set "CURRENT_CP=%CURRENT_CP%"
  set "CP_HISTORY_LIST=%CP_HISTORY_LIST%"
  set "FLAG_QUIT_ON_EXIT=%FLAG_QUIT_ON_EXIT%"
)

set LASTERROR=%ERRORLEVEL%

rem restore locale
if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

(
  set "LASTERROR="
  set "CONTOOLS_ROOT="
  set "FLAG_CHCP="
  set "CURRENT_CP="
  set "CP_HISTORY_LIST="
  set "FLAG_QUIT_ON_EXIT="

  if %FLAG_QUIT_ON_EXIT% EQU 0 exit /b %LASTERROR%

  exit %LASTERROR%
)
