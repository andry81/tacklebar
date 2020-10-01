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

if "%~1" == "" exit /b 0

set "RENAME_FROM_LIST_FILE_NAME_TMP=rename_from_file_list.lst"
set "RENAME_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%RENAME_FROM_LIST_FILE_NAME_TMP%"

set "RENAME_TO_LIST_FILE_NAME_TMP=rename_to_file_list.lst"
set "RENAME_TO_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%RENAME_TO_LIST_FILE_NAME_TMP%"

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
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%~1" > "%RENAME_FROM_LIST_FILE_TMP%"
) else (
  set "RENAME_FROM_LIST_FILE_TMP=%~1"
)

mkdir "%COMMANDER_SCRIPTS_SAVELOAD_LAST_EDITED_DIR%/%SCRIPT_TEMP_DIR_NAME%"

call :COPY_FILE "%%RENAME_FROM_LIST_FILE_TMP%%" "%%COMMANDER_SCRIPTS_SAVELOAD_LAST_EDITED_DIR%%/%%SCRIPT_TEMP_DIR_NAME%%/%%RENAME_FROM_LIST_FILE_NAME_TMP%%"
call :COPY_FILE "%%RENAME_FROM_LIST_FILE_TMP%%" "%%COMMANDER_SCRIPTS_SAVELOAD_LAST_EDITED_DIR%%/%%SCRIPT_TEMP_DIR_NAME%%/%%RENAME_TO_LIST_FILE_NAME_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar "" "%%COMMANDER_SCRIPTS_SAVELOAD_LAST_EDITED_DIR%%/%%SCRIPT_TEMP_DIR_NAME%%/%%RENAME_TO_LIST_FILE_NAME_TMP%%"

call :COPY_FILE "%%COMMANDER_SCRIPTS_SAVELOAD_LAST_EDITED_DIR%%/%%SCRIPT_TEMP_DIR_NAME%%/%%RENAME_TO_LIST_FILE_NAME_TMP%%" "%%RENAME_TO_LIST_FILE_TMP%%"

rem trick with simultaneous iteration over 2 list in the same time
(
  for /f "usebackq tokens=* delims= eol=#" %%i in ("%RENAME_TO_LIST_FILE_TMP%") do (
    set /P "FROM_FILE_PATH="
    set "TO_FILE_PATH=%%i"
    call :PROCESS_RENAME
  )
) < "%RENAME_FROM_LIST_FILE_TMP%"

exit /b

:PROCESS_RENAME
if not defined FROM_FILE_PATH exit /b 1
if not defined TO_FILE_PATH exit /b 2

rem avoid any quote characters
set "FROM_FILE_PATH=%FROM_FILE_PATH:"=%"
set "TO_FILE_PATH=%TO_FILE_PATH:"=%"

if /i "%FROM_FILE_PATH%" == "%TO_FILE_PATH%" exit /b 0

if exist "%TO_FILE_PATH%" (
  echo.%?~n0%: error: TO_FILE_PATH already exists: "%TO_FILE_PATH%".
  exit /b 3
) >&2

if not exist "%FROM_FILE_PATH%" (
  echo.%?~n0%: error: FROM_FILE_PATH is not found: "%FROM_FILE_PATH%".
  exit /b 4
) >&2

if "%FROM_FILE_PATH:~-1%" == "\" set "FROM_FILE_PATH=%FROM_FILE_PATH:~0,-1%"
if "%TO_FILE_PATH:~-1%" == "\" set "TO_FILE_PATH=%TO_FILE_PATH:~0,-1%"

call :PARENT_DIR FROM_FILE_DIR "%%FROM_FILE_PATH%%"

rem check if file is under GIT version control

rem WORKAROUND:
rem  Git checks if the current path is inside the same .git directories tree.
rem  Use `pushd` to set the current directory to parent directory of being processed item.
rem

set PUSHD=0
call :CMD pushd "%%FROM_FILE_DIR%%" && (
  set PUSHD=1
  rem check if file is under GIT version control
  git ls-files --error-unmatch "%FROM_FILE_PATH%" >nul 2>nul && (
    call :RENAME_FILE GIT
    rem to avoid trigger the shell rename block on not zero return code from above command
    goto RENAME_END
  ) || (
    rem rename through the shell
    call :RENAME_FILE SHELL
  )
)

:RENAME_END
set LASTERROR=%ERRORLEVEL%

if %PUSHD% NEQ 0 call :CMD popd

exit /b %LASTERROR%

:RENAME_FILE
set "MODE=%~1"

call :PARENT_DIR FROM_FILE_DIR "%%FROM_FILE_PATH%%"
call :PARENT_DIR TO_FILE_DIR "%%TO_FILE_PATH%%"

if /i not "%FROM_FILE_DIR%" == "%TO_FILE_DIR%" (
  echo.%?~n0%: error: parent directory path must stay the same: FROM_FILE_PATH="%FROM_FILE_PATH%" TO_FILE_PATH="%TO_FILE_PATH%".
  exit /b -254
) >&2

goto %MODE%_RENAME_FILE

:GIT_RENAME_FILE
call :CMD git mv "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || exit /b

exit /b 0

:SHELL_RENAME_FILE
call :FILE_NAME TO_FILE_NAME "%%TO_FILE_PATH%%"
call :CMD rename "%%FROM_FILE_PATH%%" "%%TO_FILE_NAME%%" || exit /b

exit /b 0

:COPY_FILE
echo."%~1" -^> "%~2"
copy "%~f1" "%~f2" /B /Y || exit /b
exit /b 0

:CMD
echo.^>%*
(%*)
exit /b

:PARENT_DIR
set "%~1=%~dp2"
exit /b 0

:FILE_NAME
set "%~1=%~nx2"
exit /b 0
