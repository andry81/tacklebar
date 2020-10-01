@echo off

setlocal

set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

call "%%?~dp0%%__init__.bat" || goto :EOF

rem script flags
set FLAG_PAUSE_ON_EXIT=0
set FLAG_PAUSE_ON_ERROR=0
set FLAG_PAUSE_TIMEOUT_SEC=0
set RESTORE_LOCALE=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%"

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

:EXIT_MAIN
rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

if %FLAG_PAUSE_ON_EXIT% NEQ 0 (
  if %FLAG_PAUSE_TIMEOUT_SEC% NEQ 0 (
    timeout /T %FLAG_PAUSE_TIMEOUT_SEC%
  ) else pause
) else if %LASTERROR% NEQ 0 if %FLAG_PAUSE_ON_ERROR% NEQ 0 (
  if %FLAG_PAUSE_TIMEOUT_SEC% NEQ 0 (
    timeout /T %FLAG_PAUSE_TIMEOUT_SEC%
  ) else pause
)

exit /b %LASTERROR%

:MAIN
rem script flags
set FLAG_CONVERT_FROM_UTF16=0
set "FLAG_CHCP="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-pause_on_exit" (
    set FLAG_PAUSE_ON_EXIT=1
  ) else if "%FLAG%" == "-pause_on_error" (
    set FLAG_PAUSE_ON_ERROR=1
  ) else if "%FLAG%" == "-pause_timeout_sec" (
    set "FLAG_PAUSE_TIMEOUT_SEC=%~2"
    shift
  ) else if "%FLAG%" == "-from_utf16" (
    set FLAG_CONVERT_FROM_UTF16=1
  ) else if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "CWD=%~1"
shift

if not defined CWD goto NOCWD
cd /d "%CWD%" || exit /b 1

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %CD%") do title %%i

:NOCWD

set "LIST_FILE_PATH=%~1"

if not defined LIST_FILE_PATH exit /b 0

set "CREATE_DIRS_IN_LIST_FILE_NAME_TMP=create_dirs_in_path_list.lst"
set "CREATE_DIRS_IN_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%CREATE_DIRS_IN_LIST_FILE_NAME_TMP%"

set "INPUT_LIST_FILE_UTF8_TMP=%SCRIPT_TEMP_CURRENT_DIR%\input_file_list_utf_8.lst"

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem to convert from unicode
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" 65001
  set RESTORE_LOCALE=1
) else if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
)

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
  rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
  rem
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%INPUT_LIST_FILE_UTF8_TMP%"
) else (
  set "INPUT_LIST_FILE_UTF8_TMP=%LIST_FILE_PATH%"
)

mkdir "%COMMANDER_SCRIPTS_SAVELOAD_LAST_EDITED_DIR%/%SCRIPT_TEMP_DIR_NAME%"

call :COPY_FILE "%%INPUT_LIST_FILE_UTF8_TMP%%" "%%COMMANDER_SCRIPTS_SAVELOAD_LAST_EDITED_DIR%%/%%SCRIPT_TEMP_DIR_NAME%%/%%CREATE_DIRS_IN_LIST_FILE_NAME_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar "" "%%COMMANDER_SCRIPTS_SAVELOAD_LAST_EDITED_DIR%%/%%SCRIPT_TEMP_DIR_NAME%%/%%CREATE_DIRS_IN_LIST_FILE_NAME_TMP%%"

call :COPY_FILE "%%COMMANDER_SCRIPTS_SAVELOAD_LAST_EDITED_DIR%%/%%SCRIPT_TEMP_DIR_NAME%%/%%CREATE_DIRS_IN_LIST_FILE_NAME_TMP%%" "%%CREATE_DIRS_IN_LIST_FILE_TMP%%"

set LINE_INDEX=0
for /f "usebackq tokens=* delims= eol=#" %%i in ("%CREATE_DIRS_IN_LIST_FILE_TMP%") do (
  set "CREATE_DIR_PATH=%%i"
  call :PROCESS_CREATE_DIRS
)

exit /b

:PROCESS_CREATE_DIRS
set /A LINE_INDEX+=1

if not defined CREATE_DIR_PATH exit /b 1

if exist "%CREATE_DIR_PATH%\" (
  echo.%?~nx0%: error: directory path is already exist: "%CREATE_DIR_PATH%"
  exit /b 3
) >&2

call :CREATE_DIR

exit /b

:COPY_FILE
echo."%~1" -^> "%~2"
copy "%~f1" "%~f2" /B /Y || exit /b
exit /b 0

:CMD
echo.^>%*
(%*)
exit /b

:CREATE_DIR
echo.+"%CREATE_DIR_PATH%"
mkdir "%CREATE_DIR_PATH%"
exit /b
