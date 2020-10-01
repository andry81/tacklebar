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
set "FLAG_FILE_NAME_TO_SAVE=default.lst"
set FLAG_SAVE_FILE_NAMES_ONLY=0

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
  ) else if "%FLAG%" == "-to_file_name" (
    set "FLAG_FILE_NAME_TO_SAVE=%~2"
    shift
  ) else if "%FLAG%" == "-save_file_names_only" (
    set FLAG_SAVE_FILE_NAMES_ONLY=1
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

:NOCWD
set "LIST_FILE_PATH=%~1"

if not defined LIST_FILE_PATH exit /b 0

call :CANONICAL_PATH FLAG_FILE_NAME_TO_SAVE "%%FLAG_FILE_NAME_TO_SAVE%%"

rem recreate output file
type nul > "%FLAG_FILE_NAME_TO_SAVE%"

set "READ_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\input_file_list_utf_8.lst"

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
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%READ_FROM_LIST_FILE_TMP%"
) else (
  set "READ_FROM_LIST_FILE_TMP=%LIST_FILE_PATH%"
)

rem read selected file paths from file
for /F "usebackq eol= tokens=* delims=" %%i in ("%READ_FROM_LIST_FILE_TMP%") do (
  set "FILE_PATH=%%i"
  call :READ_LIST_FILE
)

exit /b 0

:READ_LIST_FILE
if not exist "%FILE_PATH%" exit /b 0

call :CANONICAL_PATH FILE_PATH "%%FILE_PATH%%"

if %FLAG_SAVE_FILE_NAMES_ONLY% NEQ 0 goto SAVE_FILE_NAMES_ONLY

if not exist "%FILE_PATH%\" (
  for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH:/=\%") do (echo.%%i) >> "%FLAG_FILE_NAME_TO_SAVE%"
  exit /b 0
)

rem read directory file without recursion
for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH:/=\%") do ^
for /F "usebackq eol= tokens=* delims=" %%j in (`@dir "%%i" /A:-D /B /O:N`) do (echo.%%i\%%j) >> "%FLAG_FILE_NAME_TO_SAVE%"

exit /b

:SAVE_FILE_NAMES_ONLY

call :FILE_NAME FILE_NAME "%%FILE_PATH%%"

if not exist "%FILE_PATH%\" (
  for /F "eol= tokens=* delims=" %%i in ("%FILE_NAME%") do (echo.%%i) >> "%FLAG_FILE_NAME_TO_SAVE%"
  exit /b 0
)

rem read directory file without recursion
for /F "usebackq eol= tokens=* delims=" %%i in (`@dir "%FILE_PATH:/=\%" /A:-D /B /O:N`) do (echo.%%i) >> "%FLAG_FILE_NAME_TO_SAVE%"

exit /b

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
set "RETURN_VALUE=%~dpf2"
set "RETURN_VALUE=%RETURN_VALUE:\=/%"
if "%RETURN_VALUE:~-1%" == "/" set "RETURN_VALUE=%RETURN_VALUE:~0,-1%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0

:FILE_NAME
set "%~1=%~nx2"
exit /b 0
