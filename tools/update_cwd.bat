@echo off

rem CAUTION:
rem   `CWD` must be not empty after this line.
rem
if not defined CWD set "CWD=."

if "%CWD:~0,1%" == "\" set "CWD=."

if not "%CWD:~-1%" == "." set "CWD=%CWD%\."

rem just in case, if `%P` in `%P\.` will expand to `.`
if "%CWD%" == ".\." set "CWD=."

if "%CWD%" == "." exit /b 0

for /F "eol= tokens=* delims=" %%i in ("%CWD%") do set "CWD=%%~fi"

if /i not "%CD%" == "%CWD%" (
  cd /d "%CWD%" 2>nul || (
    echo.%?~nx0%: error: invalid current working directory: CWD="%CWD%"
    exit /b 255
  ) >&2
)
