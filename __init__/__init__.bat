@echo off

if /i "%TACKLEBAR_PROJECT_ROOT_INIT0_DIR%" == "%~dp0" exit /b 0

set "TACKLEBAR_PROJECT_ROOT_INIT0_DIR=%~dp0"

if not defined NEST_LVL set NEST_LVL=0

rem Do not make a file or a directory
if defined NO_GEN set /A NO_GEN+=0

rem Do not make a log directory or a log file
if defined NO_LOG set /A NO_LOG+=0

rem Do not make a log output or stdio duplication into files
if defined NO_LOG_OUTPUT set /A NO_LOG_OUTPUT+=0

rem Do not change code page
if defined NO_CHCP set /A NO_CHCP+=0

if %TACKLEBAR_SCRIPTS_INSTALL%0 NEQ 0 goto IGNORE_COMMANDER_SCRIPTS_ROOT

if not defined COMMANDER_SCRIPTS_ROOT (
  echo.%~nx0: error: COMMANDER_SCRIPTS_ROOT environment variable is not defined.
  exit /b 1
) >&2

if not exist "%COMMANDER_SCRIPTS_ROOT%\*" (
  echo.%~nx0: error: COMMANDER_SCRIPTS_ROOT directory does not exist: "%COMMANDER_SCRIPTS_ROOT%".
  exit /b 2
) >&2

:IGNORE_COMMANDER_SCRIPTS_ROOT

if not defined TACKLEBAR_PROJECT_ROOT               call "%%~dp0canonical_path.bat" TACKLEBAR_PROJECT_ROOT                 "%%~dp0.."
if not defined TACKLEBAR_PROJECT_EXTERNALS_ROOT     call "%%~dp0canonical_path.bat" TACKLEBAR_PROJECT_EXTERNALS_ROOT       "%%TACKLEBAR_PROJECT_ROOT%%/_externals"

if not exist "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%\*" (
  echo.%~nx0: error: TACKLEBAR_PROJECT_EXTERNALS_ROOT directory does not exist: "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%".
  exit /b 255
) >&2

if not defined PROJECT_OUTPUT_ROOT                  call "%%~dp0canonical_path.bat" PROJECT_OUTPUT_ROOT                    "%%TACKLEBAR_PROJECT_ROOT%%/_out"
if not defined PROJECT_LOG_ROOT                     call "%%~dp0canonical_path.bat" PROJECT_LOG_ROOT                       "%%TACKLEBAR_PROJECT_ROOT%%/.log"

if not defined TACKLEBAR_PROJECT_INPUT_CONFIG_ROOT  call "%%~dp0canonical_path.bat" TACKLEBAR_PROJECT_INPUT_CONFIG_ROOT    "%%TACKLEBAR_PROJECT_ROOT%%/_config"
if not defined TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT call "%%~dp0canonical_path.bat" TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT   "%%PROJECT_OUTPUT_ROOT%%/config/tacklebar"

rem retarget externals of an external project

if not defined CONTOOLS_PROJECT_EXTERNALS_ROOT      call "%%~dp0canonical_path.bat" CONTOOLS_PROJECT_EXTERNALS_ROOT        "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%"
if not defined TACKLELIB_PROJECT_EXTERNALS_ROOT     call "%%~dp0canonical_path.bat" TACKLELIB_PROJECT_EXTERNALS_ROOT       "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%"
if not defined SVNCMD_PROJECT_EXTERNALS_ROOT        call "%%~dp0canonical_path.bat" SVNCMD_PROJECT_EXTERNALS_ROOT          "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%"

rem init immediate external projects

if exist "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/contools/__init__/__init__.bat" (
  rem disable code page change in nested __init__
  set /A NO_CHCP+=1
  call "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%/contools/__init__/__init__.bat" -no_load_user_config || exit /b
  set /A NO_CHCP-=1
)

call "%%CONTOOLS_ROOT%%/std/get_windows_version.bat" || exit /b

rem Windows XP is minimal
call "%%CONTOOLS_ROOT%%/std/check_windows_version.bat" 5 1 || exit /b

if %NO_GEN%0 EQU 0 (
  call "%%CONTOOLS_ROOT%%/std/mkdir_if_notexist.bat" "%%TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b 10
)

if not defined LOAD_CONFIG_VERBOSE if %INIT_VERBOSE%0 NEQ 0 set LOAD_CONFIG_VERBOSE=1

rem ignore generation of user config on install and use, because user config must be already generated before first use
if %NO_GEN%0 EQU 0 (
  call "%%TACKLEBAR_PROJECT_ROOT%%/tools/load_config_dir.bat" -gen_system_config -load_user_output_config -- "%%TACKLEBAR_PROJECT_INPUT_CONFIG_ROOT%%" "%%TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b
) else call "%%TACKLEBAR_PROJECT_ROOT%%/tools/load_config_dir.bat" -load_user_output_config -- "%%TACKLEBAR_PROJECT_INPUT_CONFIG_ROOT%%" "%%TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b

rem init external projects

if exist "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/__init__/__init__.bat" (
  rem disable code page change in nested __init__
  set /A NO_CHCP+=1
  call "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%/tacklelib/__init__/__init__.bat" -no_load_user_config || exit /b
  set /A NO_CHCP-=1
)

if exist "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/svncmd/__init__/__init__.bat" (
  rem disable code page change in nested __init__
  set /A NO_CHCP+=1
  call "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%/svncmd/__init__/__init__.bat" -no_load_user_config || exit /b
  set /A NO_CHCP-=1
)

if %NO_GEN%0 EQU 0 (
  call "%%CONTOOLS_ROOT%%/std/mkdir_if_notexist.bat" "%%PROJECT_OUTPUT_ROOT%%" || exit /b 11
)

if %NO_CHCP%0 EQU 0 (
  if defined CHCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%CHCP%%
)

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/init_conemu.bat" || exit /b 20

exit /b 0
