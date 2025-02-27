@echo off

setlocal DISABLEDELAYEDEXPANSION

if "%~1" == "" (
  echo.%~nx0: error: variable's name is not defined.
  exit /b 255
) >&2

if "%~2" == "" (
  echo.%~nx0: error: variable's value is not defined: "%~1".
  exit /b 255
) >&2

for /F "tokens=* delims="eol^= %%i in ("%~2\.") do set "RETURN_VALUE=%%~fi"
rem set "RETURN_VALUE=%RETURN_VALUE:\=/%"
endlocal & set "%~1=%RETURN_VALUE%"

exit /b 0
