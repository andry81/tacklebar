@echo off

if /i "%TACKLEBAR_PROJECT_ROOT_INIT0_DIR%" == "%~dp0" exit /b 0

set "TACKLEBAR_PROJECT_ROOT_INIT0_DIR=%~dp0"

rem CAUTION:
rem   Here is declared ONLY a basic set of system variables required immediately in this file.
rem   All the rest system variables will be loaded from the `config.*.vars` files.
rem

call :MAIN %%*
set "LASTERROR=%ERRORLEVEL%"

(
  set "MUST_LOAD_CONFIG="
  set "CONFIG_INDEX="
  set "LASTERROR="
  exit /b %LASTERROR%
)

:MAIN
if %TACKLEBAR_SCRIPTS_INSTALL%0 NEQ 0 goto IGNORE_COMMANDER_SCRIPTS_ROOT

if not defined COMMANDER_SCRIPTS_ROOT (
  echo.%~nx0: error: COMMANDER_SCRIPTS_ROOT environment variable is not defined.
  exit /b 1
) >&2

if not exist "%COMMANDER_SCRIPTS_ROOT%\" (
  echo.%~nx0: error: COMMANDER_SCRIPTS_ROOT directory does not exist: "%COMMANDER_SCRIPTS_ROOT%".
  exit /b 2
) >&2

if not defined PROJECT_LOG_ROOT call :CANONICAL_PATH PROJECT_LOG_ROOT "%%COMMANDER_SCRIPTS_ROOT%%/.log"

:IGNORE_COMMANDER_SCRIPTS_ROOT
set "MUST_LOAD_CONFIG=%~1"
if not defined MUST_LOAD_CONFIG set "MUST_LOAD_CONFIG=1"

rem basic set of system variables
call :CANONICAL_PATH TACKLEBAR_PROJECT_ROOT                 "%%~dp0.."

call :CANONICAL_PATH TACKLEBAR_PROJECT_CONFIG_ROOT          "%%TACKLEBAR_PROJECT_ROOT%%/_config"

if not defined PROJECT_OUTPUT_ROOT call :CANONICAL_PATH PROJECT_OUTPUT_ROOT "%%TACKLEBAR_PROJECT_ROOT%%/_out"

call :CANONICAL_PATH TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT   "%%PROJECT_OUTPUT_ROOT%%/config/tacklebar"

call :CANONICAL_PATH TACKLEBAR_PROJECT_EXTERNALS_ROOT       "%%TACKLEBAR_PROJECT_ROOT%%/_externals"

call :CANONICAL_PATH CONTOOLS_ROOT                          "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%/contools/Scripts/Tools"

if not exist "%TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT%\" ( mkdir "%TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT%" || exit /b 10 )

if not exist "%TACKLEBAR_PROJECT_CONFIG_ROOT%/config.system.vars.in" (
  echo.%~nx0: error: `%TACKLEBAR_PROJECT_CONFIG_ROOT%/config.system.vars.in` must exist.
  exit /b 255
) >&2

rem explicitly generate `config.system.vars`
call "%%TACKLEBAR_PROJECT_ROOT%%/tools/gen_system_config.bat" "%%TACKLEBAR_PROJECT_CONFIG_ROOT%%" "%%TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT%%" "config.system.vars" || exit /b 11

set CONFIG_INDEX=system
call :LOAD_CONFIG || exit /b

if exist "%SystemRoot%\System64\" goto IGNORE_MKLINK_SYSTEM64

call "%%CONTOOLS_ROOT%%/ToolAdaptors/lnk/install_system64_link.bat"

if not exist "%SystemRoot%\System64\" (
  echo.%?~nx0%: error: could not create directory link: "%SystemRoot%\System64" -^> "%SystemRoot%\System32"
  exit /b 255
) >&2

echo.

:IGNORE_MKLINK_SYSTEM64

if defined CHCP if exist "%SystemRoot%\System32\chcp.com" (
  "%SystemRoot%\System32\chcp.com" %CHCP%
) else if exist "%SystemRoot%\System64\chcp.com" (
  "%SystemRoot%\System64\chcp.com" %CHCP%
) else (
  echo.%~nx0: warning: `chcp.com` is not found, but the `CHCP` variable is defined: "%CHCP%".
) >&2

for %%i in (PROJECT_ROOT ^
  PROJECT_LOG_ROOT PROJECT_CONFIG_ROOT PROJECT_OUTPUT_ROOT ^
  CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

if not exist "%PROJECT_LOG_ROOT%\" mkdir "%PROJECT_LOG_ROOT%"

rem ignore load user config on install
if %TACKLEBAR_SCRIPTS_INSTALL%0 NEQ 0 goto LOAD_CONFIG_END

set CONFIG_INDEX=0

:LOAD_CONFIG_LOOP
if not exist "%TACKLEBAR_PROJECT_CONFIG_ROOT%/config.%CONFIG_INDEX%.vars.in" goto LOAD_CONFIG_END
call :LOAD_CONFIG -gen_config || exit /b
set /A CONFIG_INDEX+=1
goto LOAD_CONFIG_LOOP

:LOAD_CONFIG
call "%%TACKLEBAR_PROJECT_ROOT%%/tools/load_config.bat" %%* "%%TACKLEBAR_PROJECT_CONFIG_ROOT%%" "%%TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT%%" "config.%%CONFIG_INDEX%%.vars"
exit /b

if %MUST_LOAD_CONFIG% NEQ 0 (
  echo.%~nx0: error: `%TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT%/config.%CONFIG_INDEX%.vars` is not loaded.
  exit /b 255
)

exit /b 0

:LOAD_CONFIG_END

rem initialize externals
call "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%/contools/__init__/__init__.bat" || exit /b

rem CAUTION:
rem   Specific case for Windows XP x64 SP2, where both PROCESSOR_ARCHITECTURE and PROCESSOR_ARCHITEW6432 are equal to AMD64 for 32-bit cmd.exe process!
rem

rem initialize dynamic variables
if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" if not defined PROCESSOR_ARCHITEW6432 goto CONEMU_CMDLINE_X64
goto CONEMU_CMDLINE_X86

:CONEMU_CMDLINE_X64
set CONEMU_CMDLINE_ATTACH_PREFIX=%CONEMU_CMD64_CMDLINE_ATTACH_PREFIX%
set CONEMU_CMDLINE_RUN_PREFIX=%CONEMU_CMD64_CMDLINE_RUN_PREFIX%

goto CONEMU_CMDLINE_END

:CONEMU_CMDLINE_X86
set CONEMU_CMDLINE_ATTACH_PREFIX=%CONEMU_CMD32_CMDLINE_ATTACH_PREFIX%
set CONEMU_CMDLINE_RUN_PREFIX=%CONEMU_CMD32_CMDLINE_RUN_PREFIX%

:CONEMU_CMDLINE_END

exit /b 0

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "RETURN_VALUE=%%~fi"
rem set "RETURN_VALUE=%RETURN_VALUE:\=/%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
