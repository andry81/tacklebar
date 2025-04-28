@echo off

setlocal

call "%%~dp0../__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem script flags
set RESTORE_LOCALE=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LAST_ERROR%

:MAIN
rem script flags
set "FLAG_CHCP="
set FLAG_CONVERT_FROM_UTF16=0
set FLAG_CONVERT_TO_UTF16LE=0
set FLAG_CONVERT_TO_UTF16BE=0
set "FLAG_FILE_NAME_TO_SAVE=default.lst"
set FLAG_SAVE_FILE_NAMES_ONLY=0
rem includes all directories including subdirectories
set FLAG_INCLUDE_DIRS=0
rem include only empty directories (empty directory by input path, but not an empty subdirectory)
set FLAG_INCLUDE_EMPTY_DIRS=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-from_utf16" (
    set FLAG_CONVERT_FROM_UTF16=1
  ) else if "%FLAG%" == "-to_utf16le" (
    set FLAG_CONVERT_TO_UTF16LE=1
  ) else if "%FLAG%" == "-to_utf16be" (
    set FLAG_CONVERT_TO_UTF16BE=1
  ) else if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else if "%FLAG%" == "-to_file_name" (
    set "FLAG_FILE_NAME_TO_SAVE=%~2"
    shift
  ) else if "%FLAG%" == "-save_file_names_only" (
    set FLAG_SAVE_FILE_NAMES_ONLY=1
  ) else if "%FLAG%" == "-include_dirs" (
    set FLAG_INCLUDE_DIRS=1
  ) else if "%FLAG%" == "-include_empty_dirs" (
    set FLAG_INCLUDE_EMPTY_DIRS=1
  ) else (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "CWD=%~1"
shift

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "tokens=* delims="eol^= %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

set "LIST_FILE_PATH=%~1"

if not defined LIST_FILE_PATH (
  echo;%?~%: error: list file path is not defined.
  exit /b 255
) >&2

set "READ_FROM_LIST_FILE_NAME_TMP=input_file_list.lst"
set "READ_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%READ_FROM_LIST_FILE_NAME_TMP%"

set "SAVE_FROM_LIST_FILE_NAME_TMP=output_file_list.lst"
set "SAVE_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%SAVE_FROM_LIST_FILE_NAME_TMP%"

set "LOCAL_LIST_FILE_NAME_TMP=local_file_list.lst"
set "LOCAL_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%LOCAL_LIST_FILE_NAME_TMP%"

call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" FLAG_FILE_NAME_TO_SAVE "%%FLAG_FILE_NAME_TO_SAVE%%"

rem recreate output file
type nul > "%SAVE_FROM_LIST_FILE_TMP%"
type nul > "%FLAG_FILE_NAME_TO_SAVE%"

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
  rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
  rem
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%READ_FROM_LIST_FILE_TMP%"
) else (
  set "READ_FROM_LIST_FILE_TMP=%LIST_FILE_PATH%"
)

call "%%CONTOOLS_ROOT%%/std/copy.bat" "%%READ_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%READ_FROM_LIST_FILE_NAME_TMP%%" /B /Y

rem read selected file paths from file
for /F "usebackq tokens=* delims="eol^= %%i in ("%READ_FROM_LIST_FILE_TMP%") do (
  set "FILE_PATH=%%i"
  call :READ_LIST_FILE
)

call "%%CONTOOLS_ROOT%%/std/copy.bat" "%%SAVE_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%SAVE_FROM_LIST_FILE_NAME_TMP%%" /B /Y

echo;"%SAVE_FROM_LIST_FILE_TMP%" -^> "%FLAG_FILE_NAME_TO_SAVE%"

if %FLAG_CONVERT_TO_UTF16LE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-8 UTF-16LE "%%SAVE_FROM_LIST_FILE_TMP%%" > "%FLAG_FILE_NAME_TO_SAVE%"
) else if %FLAG_CONVERT_TO_UTF16BE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-8 UTF-16BE "%%SAVE_FROM_LIST_FILE_TMP%%" > "%FLAG_FILE_NAME_TO_SAVE%"
) else (
  if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%
  copy "%SAVE_FROM_LIST_FILE_TMP%" "%FLAG_FILE_NAME_TO_SAVE%" /B /Y
  if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"
)

exit /b 0

:READ_LIST_FILE
if not exist "%FILE_PATH%" exit /b 0

call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" FILE_PATH "%%FILE_PATH%%"

set "FILE_PATH=%FILE_PATH:/=\%"

setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!FILE_PATH!") do endlocal & echo;* %%i

if %FLAG_SAVE_FILE_NAMES_ONLY% NEQ 0 goto SAVE_FILE_NAMES_ONLY

if not exist "%FILE_PATH%\*" (
  for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%") do (echo;%%i) >> "%SAVE_FROM_LIST_FILE_TMP%"
  exit /b 0
)

if %FLAG_INCLUDE_DIRS% NEQ 0 goto SAVE_FILE_PATHS_INCLUDING_DIRS

rem read directory file without recursion
set IS_EMPTY_DIR=1
dir "%FILE_PATH%" /A:-D /B /O:N 2>nul > "%LOCAL_LIST_FILE_TMP%"
for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%") do for /F "usebackq tokens=* delims="eol^= %%j in ("%LOCAL_LIST_FILE_TMP%") do set "IS_EMPTY_DIR=0" & (echo;%%i\%%j) >> "%SAVE_FROM_LIST_FILE_TMP%"

if %FLAG_INCLUDE_EMPTY_DIRS% NEQ 0 if %IS_EMPTY_DIR% NEQ 0 for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%") do (echo;%%i\) >> "%SAVE_FROM_LIST_FILE_TMP%"

exit /b

:SAVE_FILE_PATHS_INCLUDING_DIRS

rem read directory file or subdirectory without recursion
set IS_EMPTY_DIR=1
dir "%FILE_PATH%" /B /O:N 2>nul > "%LOCAL_LIST_FILE_TMP%"
for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%") do for /F "usebackq tokens=* delims="eol^= %%j in ("%LOCAL_LIST_FILE_TMP%") do set "IS_EMPTY_DIR=0" & (echo;%%i\%%j) >> "%SAVE_FROM_LIST_FILE_TMP%"

if %IS_EMPTY_DIR% NEQ 0 for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%") do (echo;%%i\) >> "%SAVE_FROM_LIST_FILE_TMP%"

exit /b

:SAVE_FILE_NAMES_ONLY

for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%") do set "FILE_NAME=%%~nxi"

if not exist "%FILE_PATH%\*" (
  for /F "tokens=* delims="eol^= %%i in ("%FILE_NAME%") do (echo;%%i) >> "%SAVE_FROM_LIST_FILE_TMP%"
  exit /b 0
)

if %FLAG_INCLUDE_DIRS% NEQ 0 goto SAVE_FILE_NAMES_INCLUDING_DIRS

rem read directory file without recursion
set IS_EMPTY_DIR=1
dir "%FILE_PATH%" /A:-D /B /O:N 2>nul > "%LOCAL_LIST_FILE_TMP%"
for /F "usebackq tokens=* delims="eol^= %%i in ("%LOCAL_LIST_FILE_TMP%") do set "IS_EMPTY_DIR=0" & (echo;%%~nxi) >> "%SAVE_FROM_LIST_FILE_TMP%"

if %FLAG_INCLUDE_EMPTY_DIRS% NEQ 0 if %IS_EMPTY_DIR% NEQ 0 for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%") do (echo;%%~nxi\) >> "%SAVE_FROM_LIST_FILE_TMP%"

exit /b

:SAVE_FILE_NAMES_INCLUDING_DIRS

rem read directory file or subdirectory without recursion
set IS_EMPTY_DIR=1
dir "%FILE_PATH%" /B /O:N 2>nul > "%LOCAL_LIST_FILE_TMP%"
for /F "usebackq tokens=* delims="eol^= %%i in ("%LOCAL_LIST_FILE_TMP%") do set "IS_EMPTY_DIR=0" & (echo;%%~nxi) >> "%SAVE_FROM_LIST_FILE_TMP%"

if %IS_EMPTY_DIR% NEQ 0 for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%") do (echo;%%~nxi\) >> "%SAVE_FROM_LIST_FILE_TMP%"

exit /b
