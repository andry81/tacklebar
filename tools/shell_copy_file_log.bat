@echo off

setlocal

set "COPY_FROM_FILE_PATH=%~f1"
set "COPY_TO_FILE_PATH=%~f2"

echo."%COPY_FROM_FILE_PATH%" -^> "%COPY_TO_FILE_PATH%"

if %FLAG_USE_SHELL_MSYS% NEQ 0 ( "%MSYS_ROOT%/bin/cp.exe" --preserve=timestamps "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b )
if %FLAG_USE_SHELL_CYGWIN% NEQ 0 ( "%CYGWIN_ROOT%/bin/cp.exe" --preserve=timestamps "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b )

type nul >> "\\?\%COPY_TO_FILE_PATH%"

rem long file path optimization
if not exist "%COPY_FROM_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL
if not exist "%COPY_TO_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%

copy "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" /B /Y
set LAST_ERROR=%ERRORLEVEL%

echo.

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

exit /b %LAST_ERROR%

:XCOPY_FILE_LOG_IMPL
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
exit /b