@echo off

setlocal

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

rem script flags
set "FLAG_CONEMU_ROOT="
set "FLAG_NPP_EDITOR="
set "FLAG_WINMERGE_ROOT="
set FLAG_ARAXIS_COMPARE_ENABLE=0
set "FLAG_ARAXIS_MERGE_ROOT="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-conemu_root" (
    set "FLAG_CONEMU_ROOT=%~2"
    shift
  ) else if "%FLAG%" == "-npp_editor" (
    set "FLAG_NPP_EDITOR=%~2"
    shift
  ) else if "%FLAG%" == "-winmerge_root" (
    set "FLAG_WINMERGE_ROOT=%~2"
    shift
  ) else if "%FLAG%" == "-enable_araxis_compare" (
    set "FLAG_ARAXIS_COMPARE_ENABLE=%~2"
    shift
  ) else if "%FLAG%" == "-araxis_merge_root" (
    set "FLAG_ARAXIS_MERGE_ROOT=%~2"
    shift
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "CONFIG_IN_DIR=%~1"
set "CONFIG_OUT_DIR=%~2"
set "CONFIG_FILE=%~3"

for /F "eol= tokens=* delims=" %%i in ("%CONFIG_IN_DIR%\.") do set "CONFIG_IN_DIR=%%~fi"
for /F "eol= tokens=* delims=" %%i in ("%CONFIG_OUT_DIR%\.") do set "CONFIG_OUT_DIR=%%~fi"

if exist "%CONFIG_OUT_DIR%\%CONFIG_FILE%" exit /b 0

(
  endlocal
  call "%%CONTOOLS_ROOT%%/build/gen_config.bat" ^
    -r "{{CONEMU_ROOT}}" "%FLAG_CONEMU_ROOT%" ^
    -r "{{NPP_EDITOR}}" "%FLAG_NPP_EDITOR%" ^
    -r "{{WINMERGE_ROOT}}" "%FLAG_WINMERGE_ROOT%" ^
    -r "{{ARAXIS_COMPARE_ENABLE}}" "%FLAG_ARAXIS_COMPARE_ENABLE%" ^
    -r "{{ARAXIS_MERGE_ROOT}}" "%FLAG_ARAXIS_MERGE_ROOT%" ^
    "%CONFIG_IN_DIR%" "%CONFIG_OUT_DIR%" "%CONFIG_FILE%"
)
