@echo off

if %IMPL_MODE%0 NEQ 0 goto IMPL

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/check_vars.bat" TACKLEBAR_PROJECT_ROOT PROJECT_OUTPUT_ROOT PROJECT_LOG_ROOT CONTOOLS_ROOT CONTOOLS_UTILS_BIN_ROOT || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%* || exit /b

call "%%CONTOOLS_ROOT%%/std/callshift.bat" 1 "%%?~dp0%%.impl/run.read_flags.bat" %%* || exit /b

if FLAG_SHIFT GTR 0 for /L %%i in (1,1,%FLAG_SHIFT%) do shift

if %FLAG_ELEVATED% NEQ 0 (
  rem Check for true elevated environment (required in case of Windows XP)
  call "%%CONTOOLS_ROOT%%/std/is_admin_elevated.bat" || (
    echo;%?~%: error: the script process is not properly elevated up to Administrator privileges.
    exit /b 255
  ) >&2
)

rem CAUTION:
rem   Must not be `NO_LOG`, because `INIT_VARS_FILE` depends on existed `PROJECT_LOG_DIR`.
rem
if %FLAG_NO_LOG% NEQ 0 set NO_LOG_OUTPUT=1

if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"

set USE_MINTTY=0
set USE_CONEMU=0

if %FLAG_USE_MINTTY% NEQ 0 (
  set "USE_MINTTY=1"
) else if %FLAG_USE_CONEMU% NEQ 0 (
  set "USE_CONEMU=1"
)

if not defined COMSPECLNK set "COMSPECLNK=%COMSPEC%"

rem select COMSPEC bitness

if %FLAG_USE_X64% NEQ 0 set "COMSPECLNK=%SystemRoot%\System64\cmd.exe"
if %FLAG_USE_X32% NEQ 0 if defined PROCESSOR_ARCHITEW6432 (
  set "COMSPECLNK=%SystemRoot%\SysWOW64\cmd.exe"
) else set "COMSPECLNK=%SystemRoot%\System32\cmd.exe"

rem select platform by script callee file name and terminal

if not "%?~n0%" == "run_cmd" goto SKIP_MINTTY_INIT

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/init_mintty.bat" || exit /b 255

if %USE_MINTTY% EQU 0 goto SKIP_MINTTY_INIT
if defined MINTTY_ROOT if exist "%MINTTY_ROOT%\*" goto MINTTY_OK
(
  echo;%?~%: error: `MINTTY_ROOT` variable is not defined or path is not a directory: "%MINTTY_ROOT%"
  exit /b 255
) >&2

:MINTTY_OK
:SKIP_MINTTY_INIT

if not "%?~n0%" == "run_cygwin_bash" goto SKIP_CYGWIN_INIT

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/init_cygwin.bat" || exit /b 255

if defined CYGWIN_ROOT if exist "%CYGWIN_ROOT%\bin\*" goto CYGWIN_OK
(
  echo;%?~%: error: `CYGWIN_ROOT` variable is not defined or path is not a directory: "%CYGWIN_ROOT%\bin"
  exit /b 255
) >&2

:CYGWIN_OK
:SKIP_CYGWIN_INIT

if not "%?~n0%" == "run_msys_bash" goto SKIP_MSYS_INIT

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/init_msys.bat" || exit /b 255

if defined MSYS_ROOT if exist "%MSYS_ROOT%\usr\bin\*" goto MSYS_OK
(
  echo;%?~%: error: `MSYS_ROOT` variable is not defined or path is not a directory: "%MSYS_ROOT%\usr\bin"
  exit /b 255
) >&2

:MSYS_OK
:SKIP_MSYS_INIT

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/init_project_log.bat" "%%?~n0%%" || exit /b

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/init_vars_file.bat" || exit /b

set /A FLAG_SKIP+=1

rem CAUTION:
rem  In case of `cygwin` and `msys` here is should not be any stdout/stderr logging because of `tee` which can handle VT100 codes (terminal colors and etc)
rem
call "%%CONTOOLS_ROOT%%/std/callshift.bat" -skip %%FLAG_SKIP%% 1 "%%CONTOOLS_ROOT%%/exec/exec_terminal_prefix.bat"%%EXEC_TERMINAL_PREFIX_BARE_FLAGS%% -- %%* || exit /b

rem The caller must exit after this exit.
exit /b 0

:IMPL
rem CAUTION: We must to reinit the builtin variables in case if `IMPL_MODE` was already setup outside.
call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%* || exit /b

rem load initialization environment variables
if defined INIT_VARS_FILE call "%%CONTOOLS_ROOT%%/std/set_vars_from_file.bat" "%%INIT_VARS_FILE%%"

call "%%CONTOOLS_ROOT%%/std/get_cmdline.bat" %%*
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" RETURN_VALUE ">"
echo;

rem The caller can continue after this exit.
exit /b 0

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
rem   7. Because the console window is owned or attached by the most top parent `callf.exe` process with the `/pause-on-exit*` flag, then
rem      there is no chance to skip the pause or skip a print into the console window if someone of children processes got crash or console detach,
rem      even under elevated environment.
rem
rem CONs:
rem   1. The `callf.exe` still can not redirect stdin/stdout of a child `cmd.exe` process without losing the auto completion feature (in case of interactive input - `cmd.exe /k`).
rem
