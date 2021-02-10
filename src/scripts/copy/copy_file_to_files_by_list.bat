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
set FLAG_USE_SHELL_MSYS_COPY=0
set FLAG_USE_SHELL_CYGWIN_COPY=0

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
  ) else if "%FLAG%" == "-from_file" (
    set "FLAG_FILE_TO_COPY=%~2"
    shift
  ) else if "%FLAG%" == "-from_utf16" (
    set FLAG_CONVERT_FROM_UTF16=1
  ) else if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else if "%FLAG%" == "-use_shell_msys_copy" (
    set FLAG_USE_SHELL_MSYS_COPY=1
  ) else if "%FLAG%" == "-use_shell_cygwin_copy" (
    set FLAG_USE_SHELL_CYGWIN_COPY=1
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 if defined MSYS_ROOT if exist "%MSYS_ROOT%\bin\" goto MSYS_OK
if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 (
  echo.%?~nx0%: error: `MSYS_ROOT` variable is not defined or not valid: "%MSYS_ROOT%".
  exit /b 255
) >&2

if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 if defined CYGWIN_ROOT if exist "%CYGWIN_ROOT%\bin\" goto CYGWIN_OK
if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 (
  echo.%?~nx0%: error: `CYGWIN_ROOT` variable is not defined or not valid: "%CYGWIN_ROOT%".
  exit /b 255
) >&2

:MSYS_OK
:CYGWIN_OK
if not defined FLAG_FILE_TO_COPY (
  echo.%?~nx0%: error: file to copy is not defined.
  exit /b 1
) >&2

for /F "eol= tokens=* delims=" %%i in ("%FLAG_FILE_TO_COPY%") do set "FLAG_FILE_TO_COPY=%%~fi"

if not exist "\\?\%FLAG_FILE_TO_COPY%" (
  echo.%?~nx0%: error: file to copy does not exists: "%FLAG_FILE_TO_COPY%".
  exit /b 2
) >&2

if exist "\\?\%FLAG_FILE_TO_COPY%\" (
  echo.%?~nx0%: error: file to copy is not a file path: "%FLAG_FILE_TO_COPY%".
  exit /b 3
) >&2

set "COPY_FILE_TO_FILES_FROM_LIST_FILE_NAME_TMP=copy_file_to_files_from_file_list.lst"
set "COPY_FILE_TO_FILES_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%COPY_FILE_TO_FILES_FROM_LIST_FILE_NAME_TMP%"

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
)

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
  rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
  rem
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%~1" > "%COPY_FILE_TO_FILES_FROM_LIST_FILE_TMP%"
) else (
  set "COPY_FILE_TO_FILES_FROM_LIST_FILE_TMP=%~1"
)

call :COPY_FILE "%%COPY_FILE_TO_FILES_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%COPY_FILE_TO_FILES_FROM_LIST_FILE_NAME_TMP%%"

rem read selected file paths from file
for /F "usebackq eol= tokens=* delims=" %%i in ("%COPY_FILE_TO_FILES_FROM_LIST_FILE_TMP%") do (
  set TO_FILE_PATH=%%i
  call :PROCESS_FILE_PATH
)
exit /b

:PROCESS_FILE_PATH
if not defined TO_FILE_PATH exit /b 0

for /F "eol= tokens=* delims=" %%i in ("%TO_FILE_PATH%") do set "TO_FILE_PATH=%%~fi"

rem must be files, not sub directories
if exist "\\?\%TO_FILE_PATH%\" (
  echo.%?~nx0%: error: path must be a file path: "%TO_FILE_PATH%"
  exit /b 1
) >&2

call :COPY_FILE "%%FLAG_FILE_TO_COPY%%" "%%TO_FILE_PATH%%"

exit /b 0

:COPY_FILE
echo."%~1" -^> "%~2"
if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 (
  "%MSYS_ROOT%/bin/cp.exe" --preserve=timestamps "%~f1" "%~f2" || exit /b
) else if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 (
  "%CYGWIN_ROOT%/bin/cp.exe" --preserve=timestamps "%~f1" "%~f2" || exit /b
) else ( call :COPY_FILE_IMPL "%%~f1" "%%~f2" /B /Y || exit /b )
exit /b 0

:COPY_FILE_IMPL
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%
copy %*
set LASTERROR=%ERRORLEVEL%
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"
exit /b %LASTERROR%
