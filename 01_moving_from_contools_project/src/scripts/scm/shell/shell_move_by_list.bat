@echo off

setlocal

set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

call "%%?~dp0%%__init__.bat" || exit /b

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
set "OPTIONAL_DEST_DIR=%~2"

if not defined LIST_FILE_PATH exit /b 0

set "INPUT_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\input_file_list_utf_8.lst"

set "MOVE_FROM_LIST_FILE_NAME_TMP=move_from_file_list.lst"

set "MOVE_TO_LIST_FILE_NAME_TMP=move_to_file_list.lst"
set "MOVE_TO_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%MOVE_TO_LIST_FILE_NAME_TMP%"

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
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%INPUT_LIST_FILE_TMP%"
) else (
  set "INPUT_LIST_FILE_TMP=%LIST_FILE_PATH%"
)

rem recreate empty list
type nul > "%MOVE_TO_LIST_FILE_TMP%"

if defined OPTIONAL_DEST_DIR (echo.# dest: "%OPTIONAL_DEST_DIR%") >> "%MOVE_TO_LIST_FILE_TMP%"

rem read selected file paths from file
for /F "usebackq tokens=* delims= eol=#" %%i in ("%INPUT_LIST_FILE_TMP%") do (
  set "FILE_PATH=%%i"
  call :FILL_TO_LIST_FILE_TMP
)

goto FILL_TO_LIST_FILE_TMP_END

:FILL_TO_LIST_FILE_TMP

rem avoid any quote characters
set "FILE_PATH=%FILE_PATH:"=%"

rem always remove trailing slash character
if "%FILE_PATH:~-1%" == "\" set "FILE_PATH=%FILE_PATH:~0,-1%"

call :GET_FILE_PATH_COMPONENTS PARENT_DIR FILE_NAME "%%FILE_PATH%%"

for /F "eol= tokens=* delims=" %%i in ("%PARENT_DIR%|%FILE_NAME%") do (
  (echo.%%i) >> "%MOVE_TO_LIST_FILE_TMP%"
)

exit /b 0

:FILL_TO_LIST_FILE_TMP_END

mkdir "%COMMANDER_SCRIPTS_SAVELOAD_LAST_EDITED_DIR%/%SCRIPT_TEMP_DIR_NAME%"

call :COPY_FILE "%%MOVE_TO_LIST_FILE_TMP%%" "%%COMMANDER_SCRIPTS_SAVELOAD_LAST_EDITED_DIR%%/%%SCRIPT_TEMP_DIR_NAME%%/%%MOVE_FROM_LIST_FILE_NAME_TMP%%"
call :COPY_FILE "%%MOVE_TO_LIST_FILE_TMP%%" "%%COMMANDER_SCRIPTS_SAVELOAD_LAST_EDITED_DIR%%/%%SCRIPT_TEMP_DIR_NAME%%/%%MOVE_TO_LIST_FILE_NAME_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar "" "%%COMMANDER_SCRIPTS_SAVELOAD_LAST_EDITED_DIR%%/%%SCRIPT_TEMP_DIR_NAME%%/%%MOVE_TO_LIST_FILE_NAME_TMP%%"

call :COPY_FILE "%%COMMANDER_SCRIPTS_SAVELOAD_LAST_EDITED_DIR%%/%%SCRIPT_TEMP_DIR_NAME%%/%%MOVE_TO_LIST_FILE_NAME_TMP%%" "%%MOVE_TO_LIST_FILE_TMP%%"

rem trick with simultaneous iteration over 2 list in the same time
(
  for /F "usebackq eol= tokens=* delims=" %%i in ("%COPY_TO_LIST_FILE_TMP%") do (
    set IS_LINE_EMPTY=1
    for /F "eol=# tokens=1,* delims=|" %%k in ("%%i") do set "IS_LINE_EMPTY="
    if defined IS_LINE_EMPTY (
      for /F "eol=# tokens=1,* delims=|" %%k in ("%%i") do if not "%%k" == "" if not "%%l" == "" set /P "FROM_FILE_PATH="
    ) else (
      set /P "FROM_FILE_PATH="
      set "TO_FILE_PATH=%%i"
      call :PROCESS_MOVE
    )
  )
) < "%INPUT_LIST_FILE_TMP%"

exit /b

:PROCESS_MOVE
if not defined FROM_FILE_PATH exit /b 1
if not defined TO_FILE_PATH exit /b 2

rem always remove trailing slash character
if "%FROM_FILE_PATH:~-1%" == "\" set "FROM_FILE_PATH=%FROM_FILE_PATH:~0,-1%"
if "%TO_FILE_PATH:~-1%" == "\" set "TO_FILE_PATH=%TO_FILE_PATH:~0,-1%"

rem extract destination path components
for /F "eol= tokens=1,* delims=|" %%i in ("%TO_FILE_PATH%") do (
  set "TO_FILE_DIR=%%i"
  set "TO_FILE_NAME=%%j"
)

rem concatenate
set "TO_FILE_PATH=%TO_FILE_PATH:|=%"

rem file is not moved
if /i "%FROM_FILE_PATH%" == "%TO_FILE_PATH%" exit /b 0

if not exist "%FROM_FILE_PATH%" (
  echo.%?~n0%: error: FROM_FILE_PATH is not found: "%FROM_FILE_PATH%".
  exit /b 4
) >&2

rem check recursion only if FROM_FILE_PATH is a directory
if not exist "%FROM_FILE_PATH%\" goto IGNORE_TO_FILE_PATH_CHECK

call "%%CONTOOLS_ROOT%%/filesys/subtract_path.bat" "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%"
if %ERRORLEVEL% EQU 0 (
  echo.%?~n0%: error: TO_FILE_PATH file path must not contain FROM_FILE_PATH file path: FROM_FILE_PATH="%FROM_FILE_PATH%" TO_FILE_PATH="%TO_FILE_PATH%".
  exit /b 5
) >&2

:IGNORE_TO_FILE_PATH_CHECK

rem check if destination name is changed and print warning
call :GET_FILE_PATH_COMPONENTS FROM_FILE_DIR FROM_FILE_NAME "%%FROM_FILE_PATH%%"

if not "%FROM_FILE_NAME%" == "%TO_FILE_NAME%" (
  echo.%?~n0%: warning: move does not imply rename, destination file name should not change ^(rename ignored^): FROM_FILE_PATH=%FROM_FILE_PATH%" TO_FILE_PATH="%TO_FILE_PATH%".
  exit /b 6
)

if "%FROM_FILE_PATH:~-1%" == "\" set "FROM_FILE_PATH=%FROM_FILE_PATH:~0,-1%"
if "%TO_FILE_DIR:~-1%" == "\" set "TO_FILE_DIR=%TO_FILE_DIR:~0,-1%"

rem move through the shell
rem :MOVE_FILE SHELL

call "%%CONTOOLS_ROOT%%/filesys/get_shared_path.bat" "%%FROM_FILE_PATH%%" "%%TO_FILE_DIR%%"
if %ERRORLEVEL% NEQ 0 (
  echo.%?~n0%: error: source file path and destination file directory must share a common root path: FROM_FILE_PATH=%FROM_FILE_PATH%" TO_FILE_DIR="%TO_FILE_DIR%".
  exit /b -253
) >&2

set "SHARED_ROOT=%RETURN_VALUE%"

call "%%CONTOOLS_ROOT%%/filesys/subtract_path.bat" "%%SHARED_ROOT%%" "%%TO_FILE_DIR%%"
if %ERRORLEVEL% NEQ 0 (
  echo.%?~n0%: error: shared path root is not a prefix to TO_FILE_DIR path: SHARED_ROOT="%SHARED_ROOT%" TO_FILE_DIR="%TO_FILE_DIR%".
  exit /b -252
) >&2

set "TO_FILE_DIR_SUFFIX=%RETURN_VALUE%"

if not defined TO_FILE_DIR_SUFFIX goto SHELL_MOVE_FILE_CMD

call :CMD pushd "%%SHARED_ROOT%%" && (
  call :CMD mkdir "%%TO_FILE_DIR_SUFFIX%%"
  call :CMD popd
)

:SHELL_MOVE_FILE_CMD
set "TO_FILE_PATH=%SHARED_ROOT%\%TO_FILE_DIR_SUFFIX%"

rem always remove trailing slash character
if "%TO_FILE_PATH:~-1%" == "\" set "TO_FILE_PATH=%TO_FILE_PATH:~0,-1%"

call :CMD move "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || exit /b

exit /b 0

:COPY_FILE
echo."%~1" -^> "%~2"
copy "%~f1" "%~f2" /B /Y || exit /b
exit /b 0

:CMD
echo.^>%*
(%*)
exit /b

:GET_FILE_PATH_COMPONENTS
set "%~1=%~dp3"
set "%~2=%~nx3"
exit /b 0
