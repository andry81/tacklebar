@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

for %%i in (CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
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
set FLAG_USE_CMD=0
set FLAG_USE_MINTTY=0
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
  ) else if "%FLAG%" == "-use_mintty" (
    set FLAG_USE_MINTTY=1
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
    exit /b 255
  ) >&2
)

call "%%CONTOOLS_ROOT%%/std/get_cmdline.bat" %%?0%% %%*
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" RETURN_VALUE "%%?00%%>"
echo.

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
)

if defined MSYS_ROOT for /F "eol= tokens=* delims=" %%i in ("%MSYS_ROOT%\.") do set "MSYS_ROOT=%%~fi"
if defined MSYS32_ROOT for /F "eol= tokens=* delims=" %%i in ("%MSYS32_ROOT%\.") do set "MSYS32_ROOT=%%~fi"
if defined MSYS64_ROOT for /F "eol= tokens=* delims=" %%i in ("%MSYS64_ROOT%\.") do set "MSYS64_ROOT=%%~fi"

set USE_MINTTY=0
set USE_CONEMU=0

if %FLAG_USE_MINTTY% NEQ 0 (
  set "USE_MINTTY=1"
) else if %FLAG_USE_CONEMU% NEQ 0 (
  set "USE_CONEMU=1"
)

if not defined COMSPECLNK set "COMSPECLNK=%COMSPEC%"

if %FLAG_USE_X64% NEQ 0 set "COMSPECLNK=%SystemRoot%\System64\cmd.exe"
if %FLAG_USE_X32% NEQ 0 if defined PROCESSOR_ARCHITEW6432 (
  set "COMSPECLNK=%SystemRoot%\SysWOW64\cmd.exe"
) else set "COMSPECLNK=%SystemRoot%\System32\cmd.exe"

rem override MSYS_ROOT
if %FLAG_USE_ONLY_MSYS32_ROOT%0 NEQ 0 (
  set "MSYS_ROOT=%MSYS32_ROOT%"
  set "MSYS_TERMINAL_PREFIX=%MSYS32_MINTTY_TERMINAL_PREFIX%"
  goto END_SELECT_MSYS_ROOT
)
if %FLAG_USE_ONLY_MSYS64_ROOT%0 NEQ 0 (
  set "MSYS_ROOT=%MSYS64_ROOT%"
  set "MSYS_TERMINAL_PREFIX=%MSYS64_MINTTY_TERMINAL_PREFIX%"
  goto END_SELECT_MSYS_ROOT
)

if %COMSPEC_X64_VER%0 NEQ 0 (
  if defined MSYS64_ROOT if exist "\\?\%MSYS64_ROOT%\" (
    set "MSYS_ROOT=%MSYS64_ROOT%"
    set "MSYS_TERMINAL_PREFIX=%MSYS64_MINTTY_TERMINAL_PREFIX%"
  )
) else if defined MSYS32_ROOT if exist "\\?\%MSYS32_ROOT%\" (
  set "MSYS_ROOT=%MSYS32_ROOT%"
  set "MSYS_TERMINAL_PREFIX=%MSYS32_MINTTY_TERMINAL_PREFIX%"
)

:END_SELECT_MSYS_ROOT

if %COMSPEC_X64_VER%0 NEQ 0 (
  if defined MINTTY64_ROOT if exist "\\?\%MINTTY64_ROOT%\" (
    set "MINTTY_ROOT=%MINTTY64_ROOT%"
  )
) else (
  if defined MINTTY32_ROOT if exist "\\?\%MINTTY32_ROOT%\" (
    set "MINTTY_ROOT=%MINTTY32_ROOT%"
  )
)

if defined MSYS_ROOT if exist "%MSYS_ROOT%\bin\" goto MSYS_OK
(
  echo.%?~nx0%: error: `MSYS_ROOT` variable is not defined or not valid: "%MSYS_ROOT%"
  exit /b 255
) >&2

:MSYS_OK

call "%%CONTOOLS_ROOT%%/build/init_project_log.bat" "%%?~n0%%" || exit /b

rem register initialization environment variables
( for %%i in (FLAG_ELEVATED PROJECT_LOG_FILE_NAME_SUFFIX PROJECT_LOG_DIR PROJECT_LOG_FILE COMMANDER_SCRIPTS_ROOT COMMANDER_INI ^
              WINDOWS_VER_STR WINDOWS_MAJOR_VER WINDOWS_MINOR_VER WINDOWS_X64_VER COMSPEC_X64_VER COMSPEC COMSPECLNK ^
              TERMINAL_SCREEN_WIDTH TERMINAL_SCREEN_HEIGHT TERMINAL_SCREEN_BUFFER_HEIGHT ^
              USE_MINTTY USE_CONEMU CONEMU_INTERACT_MODE CONEMU_ROOT CONEMU_CMDLINE_ATTACH_PREFIX CONEMU_CMDLINE_RUN_PREFIX ^
              MSYS_ROOT MSYS_MINTTY_TERMINAL_PREFIX OEMCP) do ^
if defined %%i ( call echo.%%i=%%%%i%%) else ( echo.#%%i=) ) > "%PROJECT_LOG_DIR%\init.vars"

rem List of issues discovered in Windows XP/7:
rem 1. Run from shortcut file (`.lnk`) in the Windows XP (but not in the Windows 7) brings truncated command line down to ~260 characters.
rem 2. Run from shortcut file (`.lnk`) loads console windows parameters (font, windows size, buffer size, etc) from the shortcut at first and from the registry
rem    (HKCU\Console) at second. If try to change and save parameters, then saves ONLY into the shortcut, which brings the shortcut file overwrite.
rem 3. Run under UAC promotion in the Windows 7+ blocks environment inheritance, blocks stdout redirection into a pipe from non-elevated process into elevated one and
rem    blocks console screen buffer change (piping locks process (stdout) screen buffer sizes).
rem    To bypass that, for example, need to:
rem     a. Save environment variables to a file from non-elevated process and load them back in an elevated process.
rem     b. Use redirection only from an elevated process.
rem     c. Change console screen buffer sizes before stdout redirection into a pipe.
rem 4. Windows antivirus software in some cases reports a `.vbs` script as not safe or requests an explicit action on each `.vbs` script execution.
rem

rem To resolve all the issues we DO NOT USE shortcut files (`.lnk`) or Visual Basic scripts (`.vbs`) for UAC promotion. Instead we use as a replacement `callf.exe` utility.
rem
rem PROs:
rem   1. Implementation is the same and portable between all the Windows versions like Windows XP/7/8/10. No need to use different implementation for each Windows version.
rem   2. No need to change console windows parameters (font, windows sizes, buffer sizes, etc) each time the project is installed. The parameters loads/saves from/to the registry and so
rem      is shared between installations.
rem   3. Process inheritance tree is retained between non-elevated process and elevated process because parent non-elevated process (`callf.exe`) awaits child elevated process.
rem   4. A single console can be shared between non-elevated and elevated processes.
rem   5. A single log file can be shared between non-elevated and elevated processes.
rem   6. The `/pause-on-exit*` flags of the `callf.exe` does not block execution on detached console versus the `pause` command of the `cmd.exe` interpreter which does block.
rem
rem CONs:
rem   1. The `callf.exe` still can not redirect stdin/stdout of a child `cmd.exe` process without losing the auto completion feature (in case of interactive input - `cmd.exe /k`).
rem

set "INIT_VARS_FILE=%PROJECT_LOG_DIR%\init.vars"

rem CAUTION:
rem  No stdout/stderr logging here because of `tee` which can handle VT100 codes (terminal colors and etc)
rem
call "%%TACKLEBAR_SCRIPTS_ROOT%%/.common/exec_terminal_prefix.bat" -msys -log-stdin %%* || exit /b
exit /b 0

:IMPL
rem load initialization environment variables
for /F "usebackq eol=# tokens=1,* delims==" %%i in ("%INIT_VARS_FILE%") do if /i not "%%i" == "COMSPEC" set "%%i=%%j"

for /F "eol= tokens=* delims=" %%i in ("%COMSPEC%") do echo.^>%%i
echo.

for /F "eol= tokens=* delims=" %%i in ("%MSYS_ROOT:\=/%/bin/bash.exe") do echo.^>%%i

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

rem script flags
set FLAG_ELEVATED=0
set "FLAG_CHCP="
set FLAG_QUIT_ON_EXIT=0
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
  ) else if "%FLAG%" == "-use_mintty" (
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

set "CWD=%~1"
shift

if defined CWD if "%CWD:~0,1%" == "\" set "CWD="
if defined CWD ( for /F "eol= tokens=* delims=" %%i in ("%CWD%\.") do set "CWD=%%~fi" ) else goto NOCWD
if exist "\\?\%CWD%" if exist "%CWD%" ( cd /d "%CWD%" || exit /b 1 )

:NOCWD

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

set "CALLF_BARE_FLAGS="
if %FLAG_USE_X64% NEQ 0 set "CALLF_BARE_FLAGS= /disable-wow64-fs-redir"

rem escape characters for the Bash shell expressions
set "CWD=%CWD:\=/%"
set "CWD=%CWD:'='\''%"

rem register environment variables
set | "%MSYS_ROOT%\bin\sort.exe" > "%PROJECT_LOG_DIR%\env.0.vars"

rem stdout+stderr redirection into the same log file without handles restore
"%CONTOOLS_UTILITIES_BIN_ROOT%/contools/callf.exe"%CALLF_BARE_FLAGS% ^
  /load-parent-proc-init-env-vars ^
  /attach-parent-console /ret-child-exit /no-expand-env /no-subst-vars ^
  "%MSYS_ROOT%\bin\bash.exe" "-c \"{ cd '%CWD%'; \"\"%MSYS_ROOT:\=/%/bin/env.exe\"\" | \"\"%MSYS_ROOT:\=/%/bin/sort.exe\"\" > \"\"%PROJECT_LOG_DIR:\=/%/env.1.vars\"\"; CHERE_INVOKING=. exec \"\"%MSYS_ROOT:\=/%/bin/bash.exe\"\" -l -i; } 2>&1 | \"\"%MSYS_ROOT:\=/%/bin/tee.exe\"\" -a \"\"%PROJECT_LOG_FILE:\=/%\"\"; exit ${PIPESTATUS[0]}\""
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
