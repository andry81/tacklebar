@echo off

setlocal

rem script names call stack
if defined ?~ ( set "?~=%?~%-^>%~nx0" ) else if defined ?~nx0 ( set "?~=%?~nx0%-^>%~nx0" ) else set "?~=%~nx0"

rem CAUTION:
rem   `CWD` must be not empty after this line.
rem
if not defined CWD set "CWD=."

if "%CWD%" == "." goto EXIT

rem avoid current drive directory root
if "%CWD:~0,1%" == "\" set "CWD=." & goto EXIT

if not "%CWD:~-1%" == "." set "CWD=%CWD%\."

rem just in case, if `%P` in `%P\.` will expand to `.`
if "%CWD%" == ".\." set "CWD=." & goto EXIT

for /F "tokens=* delims="eol^= %%i in ("%CWD%") do set "CWD=%%~fi"

(
  endlocal
  set "CWD=%CWD%"
  if /i not "%CD%" == "%CWD%" cd /d "%CWD%" 2>nul || (
    echo;%?~%: error: invalid current working directory: CWD="%CWD%"
    exit /b 255
  ) >&2
  exit /b 0
)

:EXIT
(
  endlocal
  set "CWD=%CWD%"
  exit /b 0
)
