@echo off

setlocal

set "?~0=%~0"
set "?~f0=%~f0"
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

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%\wmi\get_wmic_local_datetime.bat"
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

if %CONEMU_ENABLE%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "attach" %CONEMU_CMDLINE_ATTACH_PREFIX%
if %CONEMU_ENABLE%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "run" (
  %CONEMU_CMDLINE_RUN_PREFIX% "%COMSPEC%" /C @"%?~f0%" %* -cur_console:n 2^>^&1 ^| "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
  exit /b
)
"%COMSPEC%" /C @"%?~f0%" %* 2>&1 | "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
exit /b

:IMPL
rem script flags
set FLAG_PAUSE_ON_EXIT=0
set FLAG_PAUSE_ON_ERROR=0
set FLAG_PAUSE_TIMEOUT_SEC=0
set RESTORE_LOCALE=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || (
  echo.%?~nx0%: error: could not allocate temporary directory: "%SCRIPT_TEMP_CURRENT_DIR%"
  exit /b 255
) >&2

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
  ) else if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/pause.bat" -chcp "%%OEMCP%%" ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"
) else if %LASTERROR% NEQ 0 if %FLAG_PAUSE_ON_ERROR% NEQ 0 (
  if %FLAG_PAUSE_TIMEOUT_SEC% NEQ 0 (
    timeout /T %FLAG_PAUSE_TIMEOUT_SEC%
  ) else if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/pause.bat" -chcp "%%OEMCP%%" ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"
)

exit /b %LASTERROR%

:MAIN
rem script flags
set "FLAG_CHCP="
set FLAG_CONVERT_FROM_UTF16=0
set FLAG_CONVERT_FROM_UTF16LE=0
set FLAG_CONVERT_FROM_UTF16BE=0

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
  ) else if "%FLAG%" == "-from_utf16le" (
    set FLAG_CONVERT_FROM_UTF16LE=1
  ) else if "%FLAG%" == "-from_utf16be" (
    set FLAG_CONVERT_FROM_UTF16BE=1
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

rem if not defined LIST_FILE_PATH exit /b 0

set "CREATE_FILES_IN_DIRS_FROM_LIST_FILE_NAME_TMP=create_files_in_dirs_from_file_list.lst"
set "CREATE_FILES_IN_DIRS_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%CREATE_FILES_IN_DIRS_FROM_LIST_FILE_NAME_TMP%"

set "CREATE_FILES_IN_DIRS_TO_LIST_FILE_NAME_TMP=create_files_in_dirs_to_file_list.lst"
set "CREATE_FILES_IN_DIRS_TO_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%CREATE_FILES_IN_DIRS_TO_LIST_FILE_NAME_TMP%"

set "CREATE_FILES_LIST_FILE_NAME_TMP=create_files_list.lst"
set "CREATE_FILES_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%CREATE_FILES_LIST_FILE_NAME_TMP%"

set "EMPTY_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\emptydir"

mkdir "%EMPTY_DIR_TMP%" || (
  echo.%?~n0%: error: could not create a directory: "%EMPTY_DIR_TMP%".
  exit /b 255
) >&2

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

if defined LIST_FILE_PATH (
  if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
    rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
    rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
    rem
    call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%CREATE_FILES_IN_DIRS_FROM_LIST_FILE_TMP%"
  ) else if %FLAG_CONVERT_FROM_UTF16LE% NEQ 0 (
    call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16LE UTF-8 "%%LIST_FILE_PATH%%" > "%CREATE_FILES_IN_DIRS_FROM_LIST_FILE_TMP%"
  ) else if %FLAG_CONVERT_FROM_UTF16BE% NEQ 0 (
    call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16BE UTF-8 "%%LIST_FILE_PATH%%" > "%CREATE_FILES_IN_DIRS_FROM_LIST_FILE_TMP%"
  ) else (
    set "CREATE_FILES_IN_DIRS_FROM_LIST_FILE_TMP=%LIST_FILE_PATH%"
  )
)

rem create empty list
if "%CURRENT_CP%" == "65001" (
  type "%CONTOOLS_ROOT:/=\%\encoding\boms\efbbbf.bin" > "%CREATE_FILES_LIST_FILE_TMP%"
) else type nul > "%CREATE_FILES_LIST_FILE_TMP%"

if defined LIST_FILE_PATH (
  rem recreate files
  call :COPY_FILE "%%CREATE_FILES_IN_DIRS_FROM_LIST_FILE_TMP%%" "%%CREATE_FILES_IN_DIRS_TO_LIST_FILE_TMP%%" > nul
) else if defined CWD (
  rem use working directory path as base directory path
  for /F "eol= tokens=* delims=" %%i in ("%CWD%") do (echo.%%i) > "\\?\%CREATE_FILES_IN_DIRS_TO_LIST_FILE_TMP%"
) else exit /b 255

call :COPY_FILE_LOG "%%CREATE_FILES_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%CREATE_FILES_LIST_FILE_NAME_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar "" "%%PROJECT_LOG_DIR%%/%%CREATE_FILES_LIST_FILE_NAME_TMP%%"

call :COPY_FILE_LOG "%%PROJECT_LOG_DIR%%/%%CREATE_FILES_LIST_FILE_NAME_TMP%%" "%%CREATE_FILES_LIST_FILE_TMP%%"

for /f "usebackq tokens=* delims= eol=#" %%i in ("%CREATE_FILES_IN_DIRS_TO_LIST_FILE_TMP%") do (
  set "CREATE_FILES_IN_DIR_PATH=%%i"
  call :PROCESS_CREATE_FILES_IN_DIR
)

exit /b

:COPY_FILE
:COPY_FILE_LOG
set "COPY_FROM_FILE_PATH=%~f1"
set "COPY_TO_FILE_PATH=%~f2"
echo."%COPY_FROM_FILE_PATH%" -^> "%COPY_TO_FILE_PATH%"

type nul >> "\\?\%COPY_TO_FILE_PATH%"

if not exist "%COPY_FROM_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL
if not exist "%COPY_TO_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%
copy "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" /B /Y
set LASTERROR=%ERRORLEVEL%
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"
exit /b %LASTERROR%

:XCOPY_FILE_LOG_IMPL
if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" -chcp "%%OEMCP%%" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
) else call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
exit /b

:PROCESS_CREATE_FILES_IN_DIR
if not defined CREATE_FILES_IN_DIR_PATH exit /b 10

for /F "eol= tokens=* delims=" %%i in ("%CREATE_FILES_IN_DIR_PATH%\.") do set "CREATE_FILES_IN_DIR_PATH=%%~fi"

if not exist "\\?\%CREATE_FILES_IN_DIR_PATH%" (
  echo.%?~n0%: error: CREATE_FILES_IN_DIR_PATH does not exist to create empty files in it: CREATE_FILES_IN_DIR_PATH="%CREATE_FILES_IN_DIR_PATH%".
  exit /b 20
) >&2

set LINE_INDEX=0
for /f "usebackq tokens=* delims= eol=#" %%j in ("%CREATE_FILES_LIST_FILE_TMP%") do (
  set "CREATE_FILE_PATH=%%j"
  call :PROCESS_CREATE_FILES
)
exit /b

:PROCESS_CREATE_FILES
set /A LINE_INDEX+=1

if not defined CREATE_FILE_PATH exit /b 30

if %FLAG_CONVERT_FROM_UTF16% EQU 0 goto IGNORE_CONVERT_FROM_UTF16

rem trick to remove BOM in the first line
if %LINE_INDEX% EQU 1 set "CREATE_FILE_PATH=%CREATE_FILE_PATH:~1%"

:IGNORE_CONVERT_FROM_UTF16
if not defined CREATE_FILE_PATH exit /b 0

for /F "eol= tokens=* delims=" %%i in ("%CREATE_FILES_IN_DIR_PATH%\%CREATE_FILE_PATH%\.") do ( set "CREATE_FILE_PATH=%%~fi" & set "CREATE_FILE_PATH_IN_DIR=%%~dpi" )

set "CREATE_FILE_PATH_IN_DIR=%CREATE_FILE_PATH_IN_DIR:~0,-1%"

if exist "\\?\%CREATE_FILE_PATH%" (
  echo.%?~nx0%: warning: file/directory path is already exist: "%CREATE_FILE_PATH%"
  exit /b 40
) >&2

if not exist "\\?\%CREATE_FILE_PATH_IN_DIR%\" (
  echo.%?~nx0%: error: file directory path does not exist: "%CREATE_FILE_PATH_IN_DIR%"
  exit /b 41
)

echo."%CREATE_FILE_PATH%"
type nul > "\\?\%CREATE_FILE_PATH%" || (
  echo.%?~nx0%: error: could not create file: "%CREATE_FILE_PATH%".
  exit /b 42
) >&2

exit /b 0
