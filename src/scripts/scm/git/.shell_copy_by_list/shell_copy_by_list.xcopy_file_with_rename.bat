@echo off

setlocal

rem create an empty destination file if not exist yet to check a path limitation issue
type nul >> "\\?\%TO_FILE_PATH%"

if exist "%FROM_FILE_PATH%" if exist "%TO_FILE_PATH%" (
  copy "%FROM_FILE_PATH%" "%TO_FILE_PATH%" /B /Y || exit /b 31
  exit /b 0
)

rem rename through a temporary file
mkdir "%COPY_WITH_RENAME_DIR_TMP%" 2>nul || robocopy.exe /create "%EMPTY_DIR_TMP%" "%COPY_WITH_RENAME_DIR_TMP%" >nul || (
  echo.%?~nx0%: error: could not create temporary directory: "%COPY_WITH_RENAME_DIR_TMP%".
  exit /b 40
) >&2

call :MAIN %%*
set LASTERRORLEVEL=%ERRORLEVEL%

rmdir /S /Q "\\?\%COPY_WITH_RENAME_DIR_TMP%" >nul 2>nul

exit /b %LASTERRORLEVEL%

:MAIN
type nul >> "\\?\%COPY_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%"

if not exist "%COPY_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%" (
  echo.%?~nx0%: error: temporary directory for a file rename must be a limited length path: "%COPY_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%".
  exit /b 41
) >&2

if not exist "%FROM_FILE_PATH%" goto XCOPY_FILE_TO_TMP_DIR_TO_RENAME

:COPY_FILE_TO_TMP_DIR_TO_RENAME
copy "%FROM_FILE_PATH%" "%COPY_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%" /B /Y || (
  echo.%?~nx0%: error: could not copy into temporary directory: "%FROM_FILE_PATH%" -^> "%COPY_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%".
  exit /b 50
) >&2

if not exist "\\?\%TO_FILE_DIR%\" (
  echo.^>mkdir "%TO_FILE_DIR%"
  mkdir "%TO_FILE_DIR%" 2>nul || robocopy.exe /create "%EMPTY_DIR_TMP%" "%TO_FILE_DIR%" >nul || (
    echo.%?~nx0%: error: could not create a target file directory: "%TO_FILE_DIR%".
    exit /b 51
  ) >&2
)

call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%COPY_WITH_RENAME_DIR_TMP%%" "%%TO_FILE_NAME%%" "%%TO_FILE_DIR%%" /Y /H || exit /b 52
exit /b 0

:XCOPY_FILE_TO_TMP_DIR_TO_RENAME
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%FROM_FILE_DIR%%" "%%FROM_FILE_NAME%%" "%%COPY_WITH_RENAME_DIR_TMP%%" /Y /H || exit /b 53

move "%COPY_WITH_RENAME_DIR_TMP%\%FROM_FILE_NAME%" "%COPY_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%" >nul || (
  echo.%?~nx0%: error: could not rename file in temporary directory: "%COPY_WITH_RENAME_DIR_TMP%\%FROM_FILE_NAME%" -^> "%TO_FILE_NAME%".
  exit /b 60
) >&2

if not exist "%TO_FILE_PATH%" goto XCOPY_FILE_FROM_TMP_DIR

copy "%COPY_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%" "%TO_FILE_PATH%" /B /Y || (
  echo.%?~nx0%: error: could not copy a renamed file from temporary directory: "%FROM_FILE_PATH%" -^> "%COPY_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%".
  exit /b 61
) >&2
exit /b 0

:XCOPY_FILE_FROM_TMP_DIR
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%COPY_WITH_RENAME_DIR_TMP%%" "%%TO_FILE_NAME%%" "%%TO_FILE_DIR%%" /Y /H || exit /b 62
exit /b 0
