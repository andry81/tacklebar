@echo off

rem skip copy into the log directory
if %NO_GEN%0 NEQ 0 exit /b 0
if %NO_LOG%0 NEQ 0 exit /b 0

rem CAUTION:
rem   Script must rewrite the output file because can be altered by user edit.

setlocal

set "COPY_FROM_FILE_PATH=%~f1"
set "COPY_TO_FILE_PATH=%~f2"

echo;"%COPY_FROM_FILE_PATH%" -^> "%COPY_TO_FILE_PATH%"

if %FLAG_USE_SHELL_MSYS%0 NEQ 0 "%MSYS_ROOT%/usr/bin/cp.exe" -f --preserve "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b
if %FLAG_USE_SHELL_CYGWIN%0 NEQ 0 "%CYGWIN_ROOT%/bin/cp.exe" -f --preserve "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b

type nul >> "\\?\%COPY_TO_FILE_PATH%"

rem long file path optimization
if not exist "%COPY_FROM_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL
if not exist "%COPY_TO_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%

copy "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" /B /Y
set LAST_ERROR=%ERRORLEVEL%

echo;

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

exit /b %LAST_ERROR%

:XCOPY_FILE_LOG_IMPL
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%~dp1." "%%~nx1" "%%~dp2." /Y /H >nul
exit /b
