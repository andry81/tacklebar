@echo off

setlocal

call "%%~dp0../../__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

:EXIT_MAIN
exit /b %LASTERROR%

:MAIN
svn pe svn:externals %*

echo.Waiting 10 sec or press any key...
timeout /t 10 > nul
