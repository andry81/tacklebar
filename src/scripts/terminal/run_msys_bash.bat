@echo off

setlocal

if %IMPL_MODE%0 NEQ 0 goto IMPL

rem WORKAROUND: Use `call exit` otherwise for some reason can return 0 on not zero return code
call "%%~dp0__init__.bat" || call exit /b %%ERRORLEVEL%%

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

for %%i in (CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

call "%%?~dp0%%.run_msys_bash/run_msys_bash.read_flags.bat" %%* || exit /b

if FLAG_SHIFT GTR 0 for /L %%i in (1,1,%FLAG_SHIFT%) do shift

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

if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"

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

rem register all environment variables
set 2>nul > "%INIT_VARS_FILE%"

rem CAUTION:
rem  No stdout/stderr logging here because of `tee` which can handle VT100 codes (terminal colors and etc)
rem
call "%%TACKLEBAR_SCRIPTS_ROOT%%/.common/exec_terminal_prefix.bat" -msys %%* || exit /b
exit /b 0

:IMPL
rem load initialization environment variables
for /F "usebackq eol=# tokens=1,* delims==" %%i in ("%INIT_VARS_FILE%") do set "%%i=%%j"

for /F "eol= tokens=* delims=" %%i in ("%COMSPEC%") do echo.^>%%i
echo.

for /F "eol= tokens=* delims=" %%i in ("%MSYS_ROOT:\=/%/bin/bash.exe") do echo.^>^>%%i
echo.

if FLAG_SHIFT GTR 0 for /L %%i in (1,1,%FLAG_SHIFT%) do shift

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

rem register environment variables
set > "%PROJECT_LOG_DIR%\env.0.vars"

"%CONTOOLS_UTILITIES_BIN_ROOT%/contools/callf.exe"%CALLF_BARE_FLAGS% ^
  /load-parent-proc-init-env-vars ^
  /attach-parent-console /ret-child-exit ^
  /no-expand-env /S1 ^
  "" "\"{4}\bin\bash.exe\" -c \"\{ cd \"\"{0}\"\"; \"\"{1}/bin/env.exe\"\" {5} \"\"{1}/bin/sort.exe\"\" {6} \"\"{2}/env.1.vars\"\"; CHERE_INVOKING=. exec \"\"{1}/bin/bash.exe\"\" -l -i; } 2{6}{7}1 {5} \"\"{1}/bin/tee.exe\"\" -a \"\"{3}\"\"; exit ${PIPESTATUS[0]}\"" ^
  "%CWD:\=/%" "%MSYS_ROOT:\=/%" "%PROJECT_LOG_DIR:\=/%" "%PROJECT_LOG_FILE:\=/%" "%MSYS_ROOT:/=\%" "|" ">" "&"
set LASTERROR=%ERRORLEVEL%

rem restore locale
if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

if %FLAG_QUIT_ON_EXIT% EQU 0 exit /b %LASTERROR%

exit %LASTERROR%
