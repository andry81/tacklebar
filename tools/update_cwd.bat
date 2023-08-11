@echo off

if defined CWD if "%CWD:~0,1%" == "\" set "CWD=."

if not defined CWD set "CWD=."

for /F "eol= tokens=* delims=" %%i in ("%CWD%\.") do set "CWD=%%~fi"

if exist "\\?\%CWD%" if exist "%CWD%" ( cd /d "%CWD%" || exit /b 255 )
