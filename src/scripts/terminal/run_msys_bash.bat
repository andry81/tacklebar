@echo off

setlocal

set "?~0=%~0"
set "?~f0=%~f0"
set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

call "%%?~dp0%%__init__.bat" || exit /b

for %%i in (PROJECT_LOG_ROOT CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

if %IMPL_MODE%0 NEQ 0 goto IMPL

rem script flags
set FLAG_ELEVATED=0
set "FLAG_CHCP="
set FLAG_QUIT_ON_EXIT=0
set FLAG_PAUSE_ON_ERROR=0
set FLAG_USE_CMD=0
set FLAG_USE_CONEMU=0
set FLAG_USE_X64=0
set FLAG_USE_X32=0
set FLAG_USE_ONLY_MSYS32_ROOT=0
set FLAG_USE_ONLY_MSYS64_ROOT=0

:FLAGS_OUTTER_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

rem CAUTION:
rem   Below is a specific case for Windows XP x64 SP2, where both PROCESSOR_ARCHITECTURE and PROCESSOR_ARCHITEW6432 are equal to AMD64 for 32-bit cmd.exe process!
rem

if defined FLAG (
  if "%FLAG%" == "-elevated" (
    set FLAG_ELEVATED=1
  ) else if "%FLAG%" == "-chcp" (
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
    if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" if not defined PROCESSOR_ARCHITEW6432 set "COMSPEC=%~2"
    shift
  ) else if "%FLAG%" == "-comspec32" (
    if /i "%PROCESSOR_ARCHITECTURE%" == "x86" ( set "COMSPEC=%~2" ) else if defined PROCESSOR_ARCHITEW6432 set "COMSPEC=%~2"
    shift
  ) else if "%FLAG%" == "-comspeclnk" (
    set "COMSPECLNK=%~2"
    shift
  ) else if "%FLAG%" == "-comspeclnk64" (
    if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" if not defined PROCESSOR_ARCHITEW6432 set "COMSPECLNK=%~2"
    shift
  ) else if "%FLAG%" == "-comspeclnk32" (
    if /i "%PROCESSOR_ARCHITECTURE%" == "x86" ( set "COMSPECLNK=%~2" ) else if defined PROCESSOR_ARCHITEW6432 set "COMSPECLNK=%~2"
    shift
  ) else if "%FLAG%" == "-x64" (
    set FLAG_USE_X64=1
  ) else if "%FLAG%" == "-x32" (
    set FLAG_USE_X32=1
  ) else if "%FLAG%" == "-use_only_msys32_root" (
    set FLAG_USE_ONLY_MSYS32_ROOT=1
  ) else if "%FLAG%" == "-use_only_msys64_root" (
    set FLAG_USE_ONLY_MSYS64_ROOT=1
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_OUTTER_LOOP
)

if %FLAG_ELEVATED% NEQ 0 (
  rem Check for true elevated environment (required in case of Windows XP)
  "%SystemRoot%\System32\net.exe" session >nul 2>nul || (
    echo.%?~nx0%: error: the script process is not properly elevated up to Administrator privileges.
    goto IMPL_EXIT
  ) >&2
)

if %FLAG_USE_CMD% NEQ 0 set CONEMU_ENABLE=0
if %FLAG_USE_CONEMU% NEQ 0 set CONEMU_ENABLE=1

if not defined COMSPECLNK set "COMSPECLNK=%COMSPEC%"

if %FLAG_USE_X64% NEQ 0 set "COMSPECLNK=%SystemRoot%\System64\cmd.exe"
if %FLAG_USE_X32% NEQ 0 if defined PROCESSOR_ARCHITEW6432 (
  set "COMSPECLNK=%SystemRoot%\SysWOW64\cmd.exe"
) else set "COMSPECLNK=%SystemRoot%\System32\cmd.exe"

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%\wmi\get_wmic_local_datetime.bat"
set "LOG_FILE_NAME_SUFFIX=%RETURN_VALUE:~0,4%'%RETURN_VALUE:~4,2%'%RETURN_VALUE:~6,2%_%RETURN_VALUE:~8,2%'%RETURN_VALUE:~10,2%'%RETURN_VALUE:~12,2%''%RETURN_VALUE:~15,3%"

set "PROJECT_LOG_DIR=%PROJECT_LOG_ROOT%\%LOG_FILE_NAME_SUFFIX%.%?~n0%"
set "PROJECT_LOG_FILE=%PROJECT_LOG_DIR%\%LOG_FILE_NAME_SUFFIX%.%?~n0%.log"

if not exist "%PROJECT_LOG_DIR%" ( mkdir "%PROJECT_LOG_DIR%" || exit /b )

rem CAUTION:
rem   In Windowx XP an elevated call under data protection flag will block the wmic tool, so we have to use `ver` command instead!
rem
for /F "usebackq tokens=1,2,* delims=[]" %%i in (`ver`) do for /F "tokens=1,2,* delims= " %%l in ("%%j") do set "WINDOWS_VER_STR=%%m"

set WINDOWS_MAJOR_VER=0
set WINDOWS_MINOR_VER=0
for /F "eol= tokens=1,2,* delims=." %%i in ("%WINDOWS_VER_STR%") do ( set "WINDOWS_MAJOR_VER=%%i" & set "WINDOWS_MINOR_VER=%%j" )

if %WINDOWS_MAJOR_VER% GTR 5 goto WINDOWS_VER_OK
if %WINDOWS_MAJOR_VER% EQU 5 if %WINDOWS_MINOR_VER% GEQ 1 goto WINDOWS_VER_OK

(
  echo.%~nx0: error: unsupported version of Windows: "%WINDOWS_VER_STR%"
  set LASTERROR=255
  goto EXIT
) >&2

:WINDOWS_VER_OK

set WINDOWS_X64_VER=0
if defined PROCESSOR_ARCHITEW6432 ( set "WINDOWS_X64_VER=1" ) else if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" set WINDOWS_X64_VER=1

rem CAUTION:
rem   Specific case for Windows XP x64 SP2, where both PROCESSOR_ARCHITECTURE and PROCESSOR_ARCHITEW6432 are equal to AMD64 for 32-bit cmd.exe process!
rem
set PROC_X64_VER=0
if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" if not defined PROCESSOR_ARCHITEW6432 set PROC_X64_VER=1

rem register initialization environment variables
(
for %%i in (FLAG_ELEVATED LOG_FILE_NAME_SUFFIX PROJECT_LOG_DIR PROJECT_LOG_FILE COMMANDER_SCRIPTS_ROOT COMMANDER_INI ^
            WINDOWS_VER_STR WINDOWS_MAJOR_VER WINDOWS_MINOR_VER WINDOWS_X64_VER PROC_X64_VER COMSPEC COMSPECLNK MSYS_ROOT MSYS32_ROOT MSYS64_ROOT ^
            TERMINAL_SCREEN_WIDTH TERMINAL_SCREEN_HEIGHT TERMINAL_SCREEN_BUFFER_HEIGHT ^
            CONEMU_ENABLE CONEMU_INTERACT_MODE OEMCP TEE_PIPEOUT_WAIT_SYNC_TIMEOUT_MS) do ^
if defined %%i ( for /F "usebackq eol= tokens=1,* delims==" %%j in (`set %%i 2^>nul`) do if /i "%%i" == "%%j" echo.%%j=%%k) else echo.#%%i=
) > "%PROJECT_LOG_DIR%\init.vars"

rem List of issues discovered in Windows 7/XP:
rem 1. Run from shortcut file (`.lnk`) in the Windows XP (but not in the Windows 7) brings truncated command line down to ~260 characters.
rem 2. Run from shortcut file (`.lnk`) loads console windows parameters (font, windows size, buffer size, etc) from the shortcut at first and from the registry
rem    (HKCU\Console) at second. If try to change and save parameters, then saves ONLY into the shortcut, which brings the shortcut file overwrite.
rem 3. Run under UAC promotion in the Windows 7+ blocks environment inheritance, blocks stdout redirection into a pipe from non-elevated process into elevated one and
rem    blocks console screen buffer change (piping locks process (stdout) screen buffer sizes).
rem    To bypass that, for example, need to:
rem     a. Save environment variables to a file from non-elevated process and load them back in an elevated process.
rem     b. Use redirection only from an elevated process.
rem     c. Change console screen buffer sizes before stdout redirection into a pipe.
rem

rem To resolve all the issues we DO NOT USE shortcut files (.lnk) for UAC promotion. Instead we use as a replacement `winshell_call.vbs` + `call.vbs` scripts.
rem
rem The PROs:
rem   1. No need to change console windows parameters (font, windows sizes, buffer sizes, etc) each time the project is installed. The parameters loads/saves from/to the registry and so
rem      is shared between installations.
rem   2. Implementation is the same and portable between all the Windows versions like Windows XP/7. No need now to use different implementation for each Windows version.
rem   3. Process inheritance tree is retained between non-elevated process and elevated process because parent non-elevated process (`winchell_call.vbs`) awaits current directory
rem      release in the child elevated process (`call.vbs`) instead of awaits a child process exit and so independent to security permission from the Windows
rem      (in the Windows all elevated processes isolated from non-elevated processes and so can not be enumerated or can not be watched for exit by non-elevated processes).
rem
rem The CONs:
rem   1. To preserve the process inheritance tree between a non-elevated process and an elevated process, there is another process in the inheritance chain,
rem      compared to running a shortcut from a file with the UAC promotion flag raised.
rem   2. Implementation of the `winshell_call.vbs` script has race condition timeout because of the inner `ShellExecute` API call which does not support return code and
rem      does not have builtin child process exit await logic. So there is a chance that the parent non-elevated process will close before close the child elevated process.
rem

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
  set "INIT_VARS_FILE=%PROJECT_LOG_DIR%\init.vars"
  set ?__CMDLINE__="%?~f0%" %*

  if %CONEMU_ENABLE%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "attach" %CONEMU_CMDLINE_ATTACH_PREFIX%
  if %CONEMU_ENABLE%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "run" (
    %CONEMU_CMDLINE_RUN_PREFIX% "%COMSPECLNK%" /C @%%?__CMDLINE__%% -cur_console:n
    call set LASTERROR=%%ERRORLEVEL%%
    set "CONTOOLS_ROOT=%CONTOOLS_ROOT%"
    set "FLAG_PAUSE_ON_ERROR=%FLAG_PAUSE_ON_ERROR%"
    goto IMPL_EXIT
  )
  "%COMSPECLNK%" /C @%%?__CMDLINE__%%
  call set LASTERROR=%%ERRORLEVEL%%
  set "CONTOOLS_ROOT=%CONTOOLS_ROOT%"
  set "FLAG_PAUSE_ON_ERROR=%FLAG_PAUSE_ON_ERROR%"
  goto IMPL_EXIT
)

:IMPL_EXIT
if %LASTERROR%0 NEQ 0 if %FLAG_PAUSE_ON_ERROR%0 NEQ 0 if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/pause.bat" -chcp "%%OEMCP%%" ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"

(
  set "LASTERROR="
  set "CONTOOLS_ROOT="
  set "FLAG_PAUSE_ON_ERROR="
  exit /b %LASTERROR%
)

:IMPL
rem load initialization environment variables
for /F "usebackq eol=# tokens=* delims=" %%i in ("%INIT_VARS_FILE%") do set "%%i"

set "?~0=%~0"
set "?~f0=%~f0"
set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

rem script flags
set FLAG_ELEVATED=0
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

rem CAUTION:
rem   Below is a specific case for Windows XP x64 SP2, where both PROCESSOR_ARCHITECTURE and PROCESSOR_ARCHITEW6432 are equal to AMD64 for 32-bit cmd.exe process!
rem

if defined FLAG (
  if "%FLAG%" == "-elevated" (
    set FLAG_ELEVATED=1
  ) else if "%FLAG%" == "-chcp" (
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
    if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" if not defined PROCESSOR_ARCHITEW6432 set "COMSPEC=%~2"
    shift
  ) else if "%FLAG%" == "-comspec32" (
    if /i "%PROCESSOR_ARCHITECTURE%" == "x86" ( set "COMSPEC=%~2" ) else if defined PROCESSOR_ARCHITEW6432 set "COMSPEC=%~2"
    shift
  ) else if "%FLAG%" == "-comspeclnk" (
    set "COMSPECLNK=%~2"
    shift
  ) else if "%FLAG%" == "-comspeclnk64" (
    if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" if not defined PROCESSOR_ARCHITEW6432 set "COMSPECLNK=%~2"
    shift
  ) else if "%FLAG%" == "-comspeclnk32" (
    if /i "%PROCESSOR_ARCHITECTURE%" == "x86" ( set "COMSPECLNK=%~2" ) else if defined PROCESSOR_ARCHITEW6432 set "COMSPECLNK=%~2"
    shift
  ) else if "%FLAG%" == "-x64" (
    set FLAG_USE_X64=1
  ) else if "%FLAG%" == "-x32" (
    set FLAG_USE_X32=1
  ) else if "%FLAG%" == "-use_only_msys32_root" (
    set FLAG_USE_ONLY_MSYS32_ROOT=1
  ) else if "%FLAG%" == "-use_only_msys64_root" (
    set FLAG_USE_ONLY_MSYS64_ROOT=1
  )

  shift

  rem read until no flags
  goto FLAGS_INNER_LOOP
)

:FLAGS_INNER_LOOP_END

title %COMSPEC%

set "PWD=%~1"

rem CAUTION: Avoid use `call` under piping to avoid `^` character duplication on expand of the `%*` sequence (`%%*` sequence does not escape `%*` in piping)
set ?__CMDLINE__=%*
"%COMSPEC%" /C @"%?~dp0%.%?~n0%\%?~n0%.init.bat" %%?__CMDLINE__%% | "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
set LASTERROR=%ERRORLEVEL%

if %LASTERROR% NEQ 0 (
  if %CONEMU_ENABLE%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "run" (
    if %LASTERROR%0 NEQ 0 if %FLAG_PAUSE_ON_ERROR%0 NEQ 0 if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/pause.bat" -chcp "%%OEMCP%%" ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"
  )
  exit /b %LASTERROR%
)

rem reload overriden MSYS_ROOT
set /P MSYS_ROOT=< "%PROJECT_LOG_DIR%\msys_root.var"

rem escape characters for the Bash shell expressions
set "PWD=%PWD:\=/%"
set "PWD=%PWD:'='\''%"

(
  endlocal
  set "IMPL_MODE="
  set "INIT_VARS_FILE="
  set "?__CMDLINE__="

  rem register environment variables
  set | "%MSYS_ROOT%\bin\sort.exe" > "%PROJECT_LOG_DIR%\env.0.vars"

  rem stdout+stderr redirection into the same log file without handles restore
  "%MSYS_ROOT%\bin\bash.exe" -c "{ cd '%PWD%'; ""%MSYS_ROOT:\=/%/bin/env.exe"" | ""%MSYS_ROOT:\=/%/bin/sort.exe"" > ""%PROJECT_LOG_DIR:\=/%/env.1.vars""; CHERE_INVOKING=. exec ""%MSYS_ROOT:\=/%/bin/bash.exe"" -l -i; } 2>&1 | ""%MSYS_ROOT:\=/%/bin/tee.exe"" -a ""%PROJECT_LOG_FILE:\=/%"""
  call set LASTERROR=%%ERRORLEVEL%%

  set "CONTOOLS_ROOT=%CONTOOLS_ROOT%"
  set "FLAG_CHCP=%FLAG_CHCP%"
  set "OEMCP=%OEMCP%"
  set "CURRENT_CP=%CURRENT_CP%"
  set "CP_HISTORY_LIST=%CP_HISTORY_LIST%"
  set "FLAG_PAUSE_ON_ERROR=%FLAG_PAUSE_ON_ERROR%"
  set "FLAG_QUIT_ON_EXIT=%FLAG_QUIT_ON_EXIT%"

  set "CONEMU_ENABLE=%CONEMU_ENABLE%"
  set "CONEMU_INTERACT_MODE=%CONEMU_INTERACT_MODE%"
)

rem restore locale
if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

if %CONEMU_ENABLE%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "run" (
  if %LASTERROR%0 NEQ 0 if %FLAG_PAUSE_ON_ERROR%0 NEQ 0 if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/pause.bat" -chcp "%%OEMCP%%" ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"
)

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
