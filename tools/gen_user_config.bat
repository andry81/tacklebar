@echo off

setlocal

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

call "%%?~dp0%%.gen_user_config/gen_user_config.read_flags.bat" %%* || exit /b

if FLAG_SHIFT GTR 0 for /L %%i in (1,1,%FLAG_SHIFT%) do shift

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
