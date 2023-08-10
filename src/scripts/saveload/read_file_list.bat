@echo off

setlocal

if %IMPL_MODE%0 NEQ 0 goto IMPL

rem WORKAROUND: Use `call exit` otherwise for some reason can return 0 on not zero return code
call "%%~dp0__init__.bat" || call exit /b %%ERRORLEVEL%%

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

for %%i in (CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

call "%%CONTOOLS_ROOT%%/build/init_project_log.bat" "%%?~n0%%" || exit /b

call "%%CONTOOLS_ROOT%%/exec/exec_terminal_prefix.bat" -log-conout %%* || exit /b
exit /b 0

:IMPL
rem script flags
set RESTORE_LOCALE=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || (
  echo.%?~nx0%: error: could not allocate temporary directory: "%SCRIPT_TEMP_CURRENT_DIR%"
  exit /b 255
) >&2

call "%%CONTOOLS_ROOT%%/std/get_cmdline.bat" %%?0%% %%*
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" RETURN_VALUE "%%?00%%>"
echo.

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

:EXIT_MAIN
rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LASTERROR%

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
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "CWD=%~1"
shift

if defined CWD if "%CWD:~0,1%" == "\" set "CWD="
if defined CWD ( for /F "eol= tokens=* delims=" %%i in ("%CWD%\.") do set "CWD=%%~fi" ) else goto NOCWD
if exist "\\?\%CWD%" if exist "%CWD%" ( cd /d "%CWD%" || exit /b 1 )

:NOCWD

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

set "LIST_FILE_PATH=%~1"

if not defined LIST_FILE_PATH exit /b 0

set "READ_FROM_LIST_FILE_NAME_TMP=input_file_list.lst"
set "READ_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%READ_FROM_LIST_FILE_NAME_TMP%"

set "SAVE_FROM_LIST_FILE_NAME_TMP=output_file_list.lst"
set "SAVE_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%SAVE_FROM_LIST_FILE_NAME_TMP%"

set "LOCAL_LIST_FILE_NAME_TMP=local_file_list.lst"
set "LOCAL_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%LOCAL_LIST_FILE_NAME_TMP%"

call :CANONICAL_PATH FLAG_FILE_NAME_TO_SAVE "%%FLAG_FILE_NAME_TO_SAVE%%"

rem recreate output file
type nul > "%SAVE_FROM_LIST_FILE_TMP%"
type nul > "%FLAG_FILE_NAME_TO_SAVE%"

if defined FLAG_CHCP (
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

call :COPY_FILE "%%READ_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%READ_FROM_LIST_FILE_NAME_TMP%%"

rem read selected file paths from file
for /F "usebackq eol= tokens=* delims=" %%i in ("%READ_FROM_LIST_FILE_TMP%") do (
  set "FILE_PATH=%%i"
  call :READ_LIST_FILE
)

call :COPY_FILE "%%SAVE_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%SAVE_FROM_LIST_FILE_NAME_TMP%%"

echo."%SAVE_FROM_LIST_FILE_TMP%" -^> "%FLAG_FILE_NAME_TO_SAVE%"

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

call :CANONICAL_PATH FILE_PATH "%%FILE_PATH%%"

set "FILE_PATH=%FILE_PATH:/=\%"

setlocal ENABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("!FILE_PATH!") do ( endlocal & (echo.* %%i) )

if %FLAG_SAVE_FILE_NAMES_ONLY% NEQ 0 goto SAVE_FILE_NAMES_ONLY

if not exist "%FILE_PATH%\" (
  for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH%") do (echo.%%i) >> "%SAVE_FROM_LIST_FILE_TMP%"
  exit /b 0
)

if %FLAG_INCLUDE_DIRS% NEQ 0 goto SAVE_FILE_PATHS_INCLUDING_DIRS

rem read directory file without recursion
set IS_EMPTY_DIR=1
dir "%FILE_PATH%" /A:-D /B /O:N 2>nul > "%LOCAL_LIST_FILE_TMP%"
for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH%") do for /F "usebackq eol= tokens=* delims=" %%j in ("%LOCAL_LIST_FILE_TMP%") do ( set "IS_EMPTY_DIR=0" & (echo.%%i\%%j) >> "%SAVE_FROM_LIST_FILE_TMP%" )

if %FLAG_INCLUDE_EMPTY_DIRS% NEQ 0 if %IS_EMPTY_DIR% NEQ 0 for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH%") do (echo.%%i\) >> "%SAVE_FROM_LIST_FILE_TMP%"

exit /b

:SAVE_FILE_PATHS_INCLUDING_DIRS

rem read directory file or subdirectory without recursion
set IS_EMPTY_DIR=1
dir "%FILE_PATH%" /B /O:N 2>nul > "%LOCAL_LIST_FILE_TMP%"
for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH%") do for /F "usebackq eol= tokens=* delims=" %%j in ("%LOCAL_LIST_FILE_TMP%") do ( set "IS_EMPTY_DIR=0" & (echo.%%i\%%j) >> "%SAVE_FROM_LIST_FILE_TMP%" )

if %IS_EMPTY_DIR% NEQ 0 for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH%") do (echo.%%i\) >> "%SAVE_FROM_LIST_FILE_TMP%"

exit /b

:SAVE_FILE_NAMES_ONLY

call :FILE_NAME FILE_NAME "%%FILE_PATH%%"

if not exist "%FILE_PATH%\" (
  for /F "eol= tokens=* delims=" %%i in ("%FILE_NAME%") do (echo.%%i) >> "%SAVE_FROM_LIST_FILE_TMP%"
  exit /b 0
)

if %FLAG_INCLUDE_DIRS% NEQ 0 goto SAVE_FILE_NAMES_INCLUDING_DIRS

rem read directory file without recursion
set IS_EMPTY_DIR=1
dir "%FILE_PATH%" /A:-D /B /O:N 2>nul > "%LOCAL_LIST_FILE_TMP%"
for /F "usebackq eol= tokens=* delims=" %%i in ("%LOCAL_LIST_FILE_TMP%") do ( set "IS_EMPTY_DIR=0" & (echo.%%~nxi) >> "%SAVE_FROM_LIST_FILE_TMP%" )

if %FLAG_INCLUDE_EMPTY_DIRS% NEQ 0 if %IS_EMPTY_DIR% NEQ 0 for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH%") do (echo.%%~nxi\) >> "%SAVE_FROM_LIST_FILE_TMP%"

exit /b

:SAVE_FILE_NAMES_INCLUDING_DIRS

rem read directory file or subdirectory without recursion
set IS_EMPTY_DIR=1
dir "%FILE_PATH%" /B /O:N 2>nul > "%LOCAL_LIST_FILE_TMP%"
for /F "usebackq eol= tokens=* delims=" %%i in ("%LOCAL_LIST_FILE_TMP%") do ( set "IS_EMPTY_DIR=0" & (echo.%%~nxi) >> "%SAVE_FROM_LIST_FILE_TMP%" )

if %IS_EMPTY_DIR% NEQ 0 for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH%") do (echo.%%~nxi\) >> "%SAVE_FROM_LIST_FILE_TMP%"

exit /b

:COPY_FILE
echo."%~1" -^> "%~2"
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%
copy "%~f1" "%~f2" /B /Y
set LASTERROR=%ERRORLEVEL%
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"
exit /b %LASTERROR%

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "RETURN_VALUE=%%~fi"
rem set "RETURN_VALUE=%RETURN_VALUE:\=/%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0

:FILE_NAME
set "%~1=%~nx2"
exit /b 0
