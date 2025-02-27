@echo off

setlocal

rem create an empty destination file if not exist yet to check a path limitation issue
( type nul >> "\\?\%TO_FILE_PATH%" ) 2>nul

if exist "%FROM_FILE_PATH%" if exist "%TO_FILE_PATH%" (
  call :COPY_FILE /B /Y "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || (
    if %TO_FILE_PATH_EXISTS% EQU 0 "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/shell/delete_file.vbs" "\\?\%TO_FILE_PATH%" 2>nul
    exit /b 31
  )
  exit /b 0
)

rem rename through a temporary file
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir.bat" "%%COPY_WITH_RENAME_DIR_TMP%%" >nul || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

exit /b %LAST_ERROR%

:MAIN
type nul >> "\\?\%COPY_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%"

if not exist "%COPY_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%" (
  echo.%?~nx0%: error: temporary directory for a file rename must be a limited length path: "%COPY_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%".
  exit /b 41
) >&2

del /F /Q /A:-D "%COPY_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%"

if not exist "%FROM_FILE_PATH%" goto XCOPY_FILE_TO_TMP_DIR_TO_RENAME

:COPY_FILE_TO_TMP_DIR_TO_RENAME
call :COPY_FILE /B /Y "%%FROM_FILE_PATH%%" "%%COPY_WITH_RENAME_DIR_TMP%%\%%TO_FILE_NAME%%" || (
  echo.%?~nx0%: error: could not copy into temporary directory: "%FROM_FILE_PATH%" -^> "%COPY_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%".
  exit /b 50
) >&2

echo.

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%COPY_WITH_RENAME_DIR_TMP%%" "%%TO_FILE_NAME%%" "%%TO_FILE_DIR%%" /Y /H || (
  if %TO_FILE_PATH_EXISTS% EQU 0 "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/shell/delete_file.vbs" "\\?\%TO_FILE_PATH%" 2>nul
  exit /b 52
)

exit /b 0

:XCOPY_FILE_TO_TMP_DIR_TO_RENAME
echo.
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%FROM_FILE_DIR%%" "%%FROM_FILE_NAME%%" "%%COPY_WITH_RENAME_DIR_TMP%%" /Y /H || exit /b

rename "%COPY_WITH_RENAME_DIR_TMP%\%FROM_FILE_NAME%" "%TO_FILE_NAME%" >nul || (
  echo.%?~nx0%: error: could not rename file in temporary directory: "%COPY_WITH_RENAME_DIR_TMP%\%FROM_FILE_NAME%" -^> "%TO_FILE_NAME%".
  exit /b 60
) >&2

if not exist "%TO_FILE_PATH%" goto XCOPY_FILE_FROM_TMP_DIR

call :COPY_FILE /B /Y "%%COPY_WITH_RENAME_DIR_TMP%%\%%TO_FILE_NAME%%" "%%TO_FILE_PATH%%" || (
  echo.%?~nx0%: error: could not copy a renamed file from temporary directory: "%FROM_FILE_PATH%" -^> "%COPY_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%".
  exit /b 61
) >&2

exit /b 0

:XCOPY_FILE_FROM_TMP_DIR
echo.
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%COPY_WITH_RENAME_DIR_TMP%%" "%%TO_FILE_NAME%%" "%%TO_FILE_DIR%%" /Y /H || (
  if %TO_FILE_PATH_EXISTS% EQU 0 "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/shell/delete_file.vbs" "\\?\%TO_FILE_PATH%" 2>nul
  exit /b 62
)

exit /b 0

:COPY_FILE
echo.^>copy %*

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%

copy %*
set LAST_ERROR=%ERRORLEVEL%

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

echo.

exit /b %LAST_ERROR%
