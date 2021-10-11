@echo off

if /i "%TACKLEBAR_PROJECT_ROOT_INIT0_DIR%" == "%~dp0" exit /b 0

set "TACKLEBAR_PROJECT_ROOT_INIT0_DIR=%~dp0"

if not defined NEST_LVL set NEST_LVL=0

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

if not defined TACKLEBAR_PROJECT_ROOT               call :CANONICAL_PATH TACKLEBAR_PROJECT_ROOT                 "%%~dp0.."
if not defined TACKLEBAR_PROJECT_EXTERNALS_ROOT     call :CANONICAL_PATH TACKLEBAR_PROJECT_EXTERNALS_ROOT       "%%TACKLEBAR_PROJECT_ROOT%%/_externals"

if not defined PROJECT_OUTPUT_ROOT                  call :CANONICAL_PATH PROJECT_OUTPUT_ROOT                    "%%TACKLEBAR_PROJECT_ROOT%%/_out"
if not defined PROJECT_LOG_ROOT                     call :CANONICAL_PATH PROJECT_LOG_ROOT                       "%%TACKLEBAR_PROJECT_ROOT%%/.log"

if not defined TACKLEBAR_PROJECT_INPUT_CONFIG_ROOT  call :CANONICAL_PATH TACKLEBAR_PROJECT_INPUT_CONFIG_ROOT    "%%TACKLEBAR_PROJECT_ROOT%%/_config"
if not defined TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT call :CANONICAL_PATH TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT   "%%PROJECT_OUTPUT_ROOT%%/config/tacklebar"

rem init immediate external projects

if exist "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/contools/__init__/__init__.bat" (
  call "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%/contools/__init__/__init__.bat" || exit /b
)

call "%%CONTOOLS_ROOT%%/std/get_windows_version.bat" || exit /b

rem Windows XP is minimal
call "%%CONTOOLS_ROOT%%/std/check_windows_version.bat" 5 1 || exit /b

if not exist "%TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT%\" ( mkdir "%TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT%" || exit /b 10 )

if not defined LOAD_CONFIG_VERBOSE if %INIT_VERBOSE%0 NEQ 0 set LOAD_CONFIG_VERBOSE=1

rem ignore generation of user config on install and use, because user config must be already generated before first use
call "%%TACKLEBAR_PROJECT_ROOT%%/tools/load_config_dir.bat" -gen_system_config -load_user_output_config "%%TACKLEBAR_PROJECT_INPUT_CONFIG_ROOT%%" "%%TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b

rem init external projects

if exist "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/__init__/__init__.bat" (
  call "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%/tacklelib/__init__/__init__.bat" || exit /b
)

if exist "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/svncmd/__init__/__init__.bat" (
  call "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%/svncmd/__init__/__init__.bat" || exit /b
)

rem initialize dynamic variables
if %COMSPEC_X64_VER%0 NEQ 0 goto CONEMU_CMDLINE_X64
goto CONEMU_CMDLINE_X86

:CONEMU_CMDLINE_X64
set CONEMU_CMDLINE_ATTACH_PREFIX=%CONEMU_CMD64_CMDLINE_ATTACH_PREFIX%
set CONEMU_CMDLINE_RUN_PREFIX=%CONEMU_CMD64_CMDLINE_RUN_PREFIX%

goto CONEMU_CMDLINE_END

:CONEMU_CMDLINE_X86
set CONEMU_CMDLINE_ATTACH_PREFIX=%CONEMU_CMD32_CMDLINE_ATTACH_PREFIX%
set CONEMU_CMDLINE_RUN_PREFIX=%CONEMU_CMD32_CMDLINE_RUN_PREFIX%

:CONEMU_CMDLINE_END

if not exist "%PROJECT_OUTPUT_ROOT%\" ( mkdir "%PROJECT_OUTPUT_ROOT%" || exit /b 11 )
if not exist "%PROJECT_LOG_ROOT%\" ( mkdir "%PROJECT_LOG_ROOT%" || exit /b 12 )

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
