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
set RESTORE_LOCALE=0

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

for /F "usebackq eol= tokens=* delims=" %%i in ("%SCRIPT_TEMP_CURRENT_DIR%\cmdline.txt") do ( set "CMDLINE_STR=%%i" )
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

if defined CWD ( for /F "eol= tokens=* delims=" %%i in ("%CWD%\.") do set "CWD=%%~fi" ) else goto NOCWD
if exist "\\?\%CWD%" if exist "%CWD%" ( cd /d "%CWD%" || exit /b 1 )

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %CD%") do title %%i

:NOCWD
set "LIST_FILE_PATH=%~1"

if not defined LIST_FILE_PATH exit /b 0

set "CREATE_DIRS_IN_LIST_FILE_NAME_TMP=create_dirs_in_path_list.lst"
set "CREATE_DIRS_IN_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%CREATE_DIRS_IN_LIST_FILE_NAME_TMP%"

set "INPUT_LIST_FILE_UTF8_TMP=%SCRIPT_TEMP_CURRENT_DIR%\input_file_list_utf_8.lst"

set "EMPTY_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\emptydir"

mkdir "%EMPTY_DIR_TMP%" || (
  echo.%?~n0%: error: could not create a directory: "%EMPTY_DIR_TMP%".
  exit /b 255
) >&2

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

call :COPY_FILE_LOG "%%INPUT_LIST_FILE_UTF8_TMP%%" "%%PROJECT_LOG_DIR%%/%%CREATE_DIRS_IN_LIST_FILE_NAME_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar "" "%%PROJECT_LOG_DIR%%/%%CREATE_DIRS_IN_LIST_FILE_NAME_TMP%%"

call :COPY_FILE_LOG "%%PROJECT_LOG_DIR%%/%%CREATE_DIRS_IN_LIST_FILE_NAME_TMP%%" "%%CREATE_DIRS_IN_LIST_FILE_TMP%%"

set "CREATE_DIRS_IN_DIR_PATH="
if defined CWD if exist "\\?\%CWD%" if not exist "%CWD%" set "CREATE_DIRS_IN_DIR_PATH=%CWD%"

set LINE_INDEX=0
for /f "usebackq tokens=* delims= eol=#" %%i in ("%CREATE_DIRS_IN_LIST_FILE_TMP%") do (
  set "CREATE_DIR_PATH=%%i"
  call :PROCESS_CREATE_DIRS
)

exit /b

:COPY_FILE_LOG
set "COPY_FROM_FILE_PATH=%~f1"
set "COPY_TO_FILE_PATH=%~f2"
echo."%COPY_FROM_FILE_PATH%" -^> "%COPY_TO_FILE_PATH%"

type nul >> "\\?\%COPY_TO_FILE_PATH%"

if not exist "%COPY_FROM_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL
if not exist "%COPY_TO_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL

copy "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" /B /Y
exit /b

:XCOPY_FILE_LOG_IMPL
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
exit /b

:PROCESS_CREATE_DIRS
set /A LINE_INDEX+=1

if not defined CREATE_DIR_PATH exit /b 20

if not defined CREATE_DIRS_IN_DIR_PATH goto IGNORE_CREATE_DIRS_IN_DIR_PATH
if "%CREATE_DIR_PATH:~1,1%" == ":" goto IGNORE_CREATE_DIRS_IN_DIR_PATH

for /F "eol= tokens=* delims=" %%i in ("%CREATE_DIRS_IN_DIR_PATH%\%CREATE_DIR_PATH%\.") do set "CREATE_DIR_PATH=%%~fi"

goto CREATE_DIRS_IN_DIR_PATH

:IGNORE_CREATE_DIRS_IN_DIR_PATH
for /F "eol= tokens=* delims=" %%i in ("%CREATE_DIR_PATH%\.") do set "CREATE_DIR_PATH=%%~fi"

:CREATE_DIRS_IN_DIR_PATH
if exist "\\?\%CREATE_DIR_PATH%\" (
  echo.%?~nx0%: warning: directory path is already exist: "%CREATE_DIR_PATH%"
  exit /b 21
) >&2

echo.^>mkdir "%CREATE_DIR_PATH%"
mkdir "%CREATE_DIR_PATH%" 2>nul || "%WINDIR%/System32/robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%CREATE_DIR_PATH%" >nul || (
  echo.%?~nx0%: error: could not create directory: "%CREATE_DIR_PATH%".
  exit /b 22
) >&2

exit /b 0
