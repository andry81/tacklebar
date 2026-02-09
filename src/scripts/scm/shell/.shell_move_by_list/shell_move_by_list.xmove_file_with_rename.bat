@echo off

setlocal

rem create an empty destination file if not exist yet to check a path limitation issue
( call;>> "\\?\%TO_FILE_PATH%" ) 2>nul

set FROM_FILE_PATH_LONG=1
if exist "%FROM_FILE_PATH%" call "%%CONTOOLS_ROOT%%/std/is_str_shorter_than.bat" 258 "%%FROM_FILE_PATH%%" set FROM_FILE_PATH_LONG=0

set TO_FILE_PATH_LONG=1
if exist "%TO_FILE_PATH%" call "%%CONTOOLS_ROOT%%/std/is_str_shorter_than.bat" 258 "%%TO_FILE_PATH%%" set TO_FILE_PATH_LONG=0

if %FROM_FILE_PATH_LONG% EQU 0 if %TO_FILE_PATH_LONG% EQU 0 (
  call :MOVE_FILE %%XMOVE_CMD_BARE_FLAGS%% "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || (
    if %TO_FILE_PATH_EXISTS%0 EQU 0 del /F /Q /A:-D "%TO_FILE_PATH%" 2>nul
    echo;
    exit /b 31
  )
  exit /b 0
)

rem rename through a temporary file
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir.bat" "%%MOVE_WITH_RENAME_DIR_TMP%%" >nul || exit /b

call;>> "\\?\%MOVE_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%"

if not exist "%MOVE_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%" (
  echo;%?~%: error: temporary directory for a file rename must be a limited length path: "%MOVE_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%"
  exit /b 41
) >&2

del /F /Q /A:-D "%MOVE_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%"

if %FROM_FILE_PATH_LONG% NEQ 0 goto XMOVE_FILE_TO_TMP_DIR_TO_RENAME

:MOVE_FILE_TO_TMP_DIR_TO_RENAME
call :MOVE_FILE "%%FROM_FILE_PATH%%" "%%MOVE_WITH_RENAME_DIR_TMP%%\%%TO_FILE_NAME%%" || (
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

if %TO_FILE_PATH_LONG% NEQ 0 goto XMOVE_FILE_FROM_TMP_DIR

call :MOVE_FILE %%XMOVE_CMD_BARE_FLAGS%% "%%MOVE_WITH_RENAME_DIR_TMP%%\%%TO_FILE_NAME%%" "%%TO_FILE_PATH%%" || (
  echo;%?~%: error: could not copy a renamed file from temporary directory: "%FROM_FILE_PATH%" -^> "%MOVE_WITH_RENAME_DIR_TMP%\%TO_FILE_NAME%".
  exit /b 61
) >&2

exit /b 0

:XMOVE_FILE_FROM_TMP_DIR
echo;
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xmove_file.bat" "%%MOVE_WITH_RENAME_DIR_TMP%%" "%%TO_FILE_NAME%%" "%%TO_FILE_DIR%%" /Y || (
  if %TO_FILE_PATH_EXISTS%0 EQU 0 "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/shell/delete_file.vbs" "\\?\%TO_FILE_PATH%" 2>nul
  exit /b 62
)

exit /b 0

:MOVE_FILE
echo;^>move %*

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%

move %*
set LAST_ERROR=%ERRORLEVEL%

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

echo;

exit /b %LAST_ERROR%
