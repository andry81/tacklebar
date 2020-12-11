@echo off

setlocal

set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

call "%%?~dp0%%__init__.bat" || exit /b

for %%i in (PROJECT_ROOT PROJECT_LOG_ROOT PROJECT_CONFIG_ROOT CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

if %IMPL_MODE%0 NEQ 0 goto IMPL

rem no local logging if nested call
set WITH_LOGGING=0
if %NEST_LVL%0 EQU 0 set WITH_LOGGING=1

if %WITH_LOGGING% EQU 0 goto IMPL

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%/std/get_wmic_local_datetime.bat"
set "LOG_FILE_NAME_SUFFIX=%RETURN_VALUE:~0,4%'%RETURN_VALUE:~4,2%'%RETURN_VALUE:~6,2%_%RETURN_VALUE:~8,2%'%RETURN_VALUE:~10,2%'%RETURN_VALUE:~12,2%''%RETURN_VALUE:~15,3%"

set "PROJECT_LOG_DIR=%PROJECT_LOG_ROOT%/%LOG_FILE_NAME_SUFFIX%.%~n0"
set "PROJECT_LOG_FILE=%PROJECT_LOG_DIR%/%LOG_FILE_NAME_SUFFIX%.%~n0.log"

if not exist "%PROJECT_LOG_DIR%" ( mkdir "%PROJECT_LOG_DIR%" || exit /b )

set IMPL_MODE=1
rem CAUTION:
rem   We should avoid use handles 3 and 4 while the redirection has take a place because handles does reuse
rem   internally from left to right when being redirected externally.
rem   Example: if `1` is redirected, then `3` is internally reused, then if `2` redirected, then `4` is internally reused and so on.
rem   The discussion of the logic:
rem   https://stackoverflow.com/questions/9878007/why-doesnt-my-stderr-redirection-end-after-command-finishes-and-how-do-i-fix-i/9880156#9880156
rem   A partial analisis:
rem   https://www.dostips.com/forum/viewtopic.php?p=14612#p14612
rem
"%COMSPEC%" /C call %0 %* 2>&1 | "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
exit /b

:IMPL
rem script flags
set FLAG_PAUSE_ON_EXIT=0
set FLAG_PAUSE_ON_ERROR=0
set FLAG_PAUSE_TIMEOUT_SEC=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%"

rem redirect command line into temporary file to print it correcly
setlocal
for %%i in (1) do (
    set "PROMPT=$_"
    echo on
    for %%b in (1) do rem * #%*#
    @echo off
) > "%SCRIPT_TEMP_CURRENT_DIR%\cmdline.txt"
endlocal

for /F "usebackq eol= tokens=* delims=" %%i in ("%SCRIPT_TEMP_CURRENT_DIR%\cmdline.txt") do set "CMDLINE_STR=%%i"
setlocal ENABLEDELAYEDEXPANSION
set "CMDLINE_STR=!CMDLINE_STR:*#=!"
set "CMDLINE_STR=!CMDLINE_STR:~0,-2!"
set CMDLINE_STR=^>%0 !CMDLINE_STR!
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" CMDLINE_STR
echo.
endlocal

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
  ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"
) else if %LASTERROR% NEQ 0 if %FLAG_PAUSE_ON_ERROR% NEQ 0 (
  if %FLAG_PAUSE_TIMEOUT_SEC% NEQ 0 (
    timeout /T %FLAG_PAUSE_TIMEOUT_SEC%
  ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"
)

exit /b %LASTERROR%

:MAIN
rem script flags
set FLAG_CONVERT_FROM_UTF16=0
set FLAG_CONVERT_TO_UTF16LE=0
set FLAG_CONVERT_TO_UTF16BE=0
set "FLAG_CHCP="
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
  if "%FLAG%" == "-pause_on_exit" (
    set FLAG_PAUSE_ON_EXIT=1
  ) else if "%FLAG%" == "-pause_on_error" (
    set FLAG_PAUSE_ON_ERROR=1
  ) else if "%FLAG%" == "-pause_timeout_sec" (
    set "FLAG_PAUSE_TIMEOUT_SEC=%~2"
    shift
  ) else if "%FLAG%" == "-from_utf16" (
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

if defined CWD ( for /F "eol= tokens=* delims=" %%i in ("%CWD%\.") do set "CWD=%%~fi" ) else goto NOCWD
if exist "\\?\%CWD%" if exist "%CWD%" ( cd /d "%CWD%" || exit /b 1 )

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %CD%") do title %%i

:NOCWD
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
  copy "%SAVE_FROM_LIST_FILE_TMP:/=\%" "%FLAG_FILE_NAME_TO_SAVE:/=\%" /B /Y
)

exit /b 0

:READ_LIST_FILE
if not exist "%FILE_PATH%" exit /b 0

call :CANONICAL_PATH FILE_PATH "%%FILE_PATH%%"

set "FILE_PATH=%FILE_PATH:/=\%"

setlocal ENABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("!FILE_PATH!") do for /F "tokens=* delims=" %%j in ("%%i") do ( endlocal & (echo.* %%j) )

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
copy "%~f1" "%~f2" /B /Y || exit /b
exit /b 0

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "RETURN_VALUE=%%~fi"
set "RETURN_VALUE=%RETURN_VALUE:\=/%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0

:FILE_NAME
set "%~1=%~nx2"
exit /b 0
