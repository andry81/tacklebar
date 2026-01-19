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
set FLAG_FLAGS_SCOPE=0
set "FLAG_CHCP="
set FLAG_CONVERT_FROM_UTF16=0
set FLAG_CONVERT_TO_UTF16LE=0
set FLAG_CONVERT_TO_UTF16BE=0
set "FLAG_FILE_NAME_TO_SAVE=default.lst"

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG if "%FLAG%" == "-+" set /A FLAG_FLAGS_SCOPE+=1
if defined FLAG if "%FLAG%" == "--" set /A FLAG_FLAGS_SCOPE-=1

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
  ) else if not "%FLAG%" == "-+" if not "%FLAG%" == "--" (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP

  if %FLAG_FLAGS_SCOPE% GTR 0 goto FLAGS_LOOP
)

if %FLAG_FLAGS_SCOPE% GTR 0 (
  echo;%?~%: error: not ended flags scope: %FLAG_FLAGS_SCOPE%
  exit /b -255
) >&2

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

set "SAVE_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\input_file_list.lst"

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
  rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
  rem
  if %FLAG_CONVERT_TO_UTF16LE% NEQ 0 (
    call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-16LE "%%LIST_FILE_PATH%%" > "%SAVE_FROM_LIST_FILE_TMP%"
  ) else if %FLAG_CONVERT_TO_UTF16BE% NEQ 0 (
    call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-16BE "%%LIST_FILE_PATH%%" > "%SAVE_FROM_LIST_FILE_TMP%"
  ) else call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%SAVE_FROM_LIST_FILE_TMP%"
) else set "SAVE_FROM_LIST_FILE_TMP=%LIST_FILE_PATH%"

call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" SAVE_FROM_LIST_FILE_TMP         "%%SAVE_FROM_LIST_FILE_TMP%%"
call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" FLAG_FILE_NAME_TO_SAVE          "%%FLAG_FILE_NAME_TO_SAVE%%"

echo;"%SAVE_FROM_LIST_FILE_TMP%" -^> "%FLAG_FILE_NAME_TO_SAVE%"

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%

copy "%SAVE_FROM_LIST_FILE_TMP%" "%FLAG_FILE_NAME_TO_SAVE%" /B /Y
set LAST_ERROR=%ERRORLEVEL%

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

exit /b %LAST_ERROR%
