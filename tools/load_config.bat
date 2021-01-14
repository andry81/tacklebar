@echo off

setlocal

for /F "usebackq tokens=* delims=" %%i in (`ver`) do set "VER_STR=%%i"

set "EXPAND_PARAM0="
if not "%VER_STR:Windows XP=%" == "%VER_STR%" set "EXPAND_PARAM0=OSWINXP"

set "EXPAND_PARAM1="
if /i "%PROCESSOR_ARCHITECTURE%" == "x86" if not defined PROCESSOR_ARCHITEW6432 set "EXPAND_PARAM1=OS32"

(
  endlocal
  call "%%CONTOOLS_ROOT%%/std/load_config.bat" -lite_parse %%* "%EXPAND_PARAM0%" "%EXPAND_PARAM1%"
)
