@echo off

setlocal

if %IMPL_MODE%0 NEQ 0 goto IMPL

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

for %%i in (CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

call "%%CONTOOLS_ROOT%%/build/init_project_log.bat" "%%?~n0%%" || exit /b

call "%%CONTOOLS_ROOT%%/exec/exec_terminal_prefix.bat" -- %%* || exit /b
exit /b 0

:IMPL
call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || (
  echo.%?~nx0%: error: could not allocate temporary directory: "%SCRIPT_TEMP_CURRENT_DIR%"
  exit /b 255
) >&2

call "%%CONTOOLS_ROOT%%/std/get_cmdline.bat" %%?0%% %%*
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" RETURN_VALUE ">"
echo.

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

:EXIT_MAIN
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LASTERROR%

:MAIN
rem script flags
set FLAG_WAIT_EXIT=0
set FLAG_NOTEPADPLUSPLUS=0
set "BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-wait" (
    set FLAG_WAIT_EXIT=1
  ) else if "%FLAG%" == "-npp" (
    set FLAG_NOTEPADPLUSPLUS=1
  ) else (
    set BARE_FLAGS=%BARE_FLAGS% %1
  )

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "CWD=%~1"
shift

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

set "LIST_FILE_PATH=%~1"

if not defined LIST_FILE_PATH (
  echo.%?~nx0%: error: LIST_FILE_PATH is not defined.
  exit /b 1
) >&2

if not exist "%LIST_FILE_PATH%" (
  echo.%?~nx0%: error: LIST_FILE_PATH does not exist: "%LIST_FILE_PATH%".
  exit /b 2
) >&2

if exist "%LIST_FILE_PATH%\" (
  echo.%?~nx0%: error: LIST_FILE_PATH must be a file: "%LIST_FILE_PATH%".
  exit /b 3
) >&2

if %FLAG_NOTEPADPLUSPLUS% EQU 0 goto USE_BASIC_EDITOR

if %FLAG_WAIT_EXIT% NEQ 0 (
  call :CMD start /B /WAIT "" "%%NPP_EDITOR%%"%%BARE_FLAGS%% "%%LIST_FILE_PATH%%"
) else (
  call :CMD start /B "" "%%NPP_EDITOR%%"%%BARE_FLAGS%% "%%LIST_FILE_PATH%%"
)

exit /b

:USE_BASIC_NOTEPAD
if %FLAG_WAIT_EXIT% NEQ 0 (
  call :CMD start /B /WAIT "" "%%BASIC_TEXT_EDITOR%%"%%BARE_FLAGS%% "%%LIST_FILE_PATH%%"
) else (
  call :CMD start /B "" "%%BASIC_TEXT_EDITOR%%"%%BARE_FLAGS%% "%%LIST_FILE_PATH%%"
)

exit /b

:CMD
echo.^>%*
(%*)
