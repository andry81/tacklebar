@echo off

setlocal

rem create an empty destination file if not exist yet to check a path limitation issue
( type nul >> "\\?\%TO_FILE_PATH%" ) 2>nul

if exist "%FROM_FILE_PATH%" if exist "%TO_FILE_PATH%" (
  echo;^>move%XMOVE_CMD_BARE_FLAGS% "%FROM_FILE_PATH%" "%TO_FILE_PATH%"
  move%XMOVE_CMD_BARE_FLAGS% "%FROM_FILE_PATH%" "%TO_FILE_PATH%" || (
    if %TO_FILE_PATH_EXISTS%0 EQU 0 "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/shell/delete_file.vbs" "\\?\%TO_FILE_PATH%" 2>nul
    echo;
    exit /b 31
  )
  exit /b 0
)

rem rename through a temporary file
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir.bat" "%%MOVE_WITH_RENAME_DIR_TMP%%" >nul || exit /b

type nul >> "\\?\%MOVE_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%"

if not exist "%MOVE_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%" (
  echo;%?~%: error: temporary directory for a file rename must be a limited length path: "%MOVE_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%"
  exit /b 41
) >&2

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

del /F /Q /A:-D "%MOVE_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%"

exit /b %LAST_ERROR%

:MAIN
if not exist "%FROM_FILE_PATH%" goto XMOVE_FILE_TO_TMP_DIR_TO_RENAME

:MOVE_FILE_TO_TMP_DIR_TO_RENAME
move "%FROM_FILE_PATH%" "%MOVE_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%" || (
  echo;%?~%: error: could not copy into temporary directory: "%FROM_FILE_PATH%" -^> "%MOVE_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%"
  exit /b 50
) >&2

echo;
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xmove_file.bat" "%%MOVE_WITH_RENAME_DIR_TMP%%" "%%TO_FILE_NAME%%" "%%TO_FILE_DIR%%" /Y || (
  if %TO_FILE_PATH_EXISTS%0 EQU 0 "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/shell/delete_file.vbs" "\\?\%TO_FILE_PATH%" 2>nul
  exit /b 52
)

exit /b 0

:XMOVE_FILE_TO_TMP_DIR_TO_RENAME
echo;
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xmove_file.bat" "%%FROM_FILE_DIR%%" "%%FROM_FILE_NAME%%" "%%MOVE_WITH_RENAME_DIR_TMP%%" /Y || exit /b

rename "%MOVE_WITH_RENAME_DIR_TMP%\%FROM_FILE_NAME%" "%TO_FILE_NAME%" >nul || (
  echo;%?~%: error: could not rename file in temporary directory: "%MOVE_WITH_RENAME_DIR_TMP%\%FROM_FILE_NAME%" -^> "%TO_FILE_NAME%".
  exit /b 60
) >&2

if not exist "%TO_FILE_PATH%" goto XMOVE_FILE_FROM_TMP_DIR

move%XMOVE_CMD_BARE_FLAGS% "%MOVE_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%" "%TO_FILE_PATH%" || (
  echo;%?~%: error: could not copy a renamed file from temporary directory: "%FROM_FILE_PATH%" -^> "%MOVE_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%".
  exit /b 61
) >&2

exit /b 0

:XMOVE_FILE_FROM_TMP_DIR
rem Waits `robocopy` asynchronous write
rem call "%%CONTOOLS_ROOT%%/locks/wait_dir_files_write_access.bat" "%%MOVE_WITH_RENAME_DIR_TMP%%" || exit /b

echo;
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xmove_file.bat" "%%MOVE_WITH_RENAME_DIR_TMP%%" "%%TO_FILE_NAME%%" "%%TO_FILE_DIR%%" /Y || (
  if %TO_FILE_PATH_EXISTS%0 EQU 0 "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/shell/delete_file.vbs" "\\?\%TO_FILE_PATH%" 2>nul
  exit /b 62
)

exit /b 0
