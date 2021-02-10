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
set FLAG_FROM_URL=0
set RESTORE_LOCALE=0
set "BARE_FLAGS="

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

rem builtin defaults
if not defined TORTOISEPROC_MAX_SPAWN_CALLS set TORTOISEPROC_MAX_SPAWN_CALLS=10

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
  ) else if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else if "%FLAG%" == "-from_url" (
    set FLAG_FROM_URL=1
  ) else (
    set BARE_FLAGS=%BARE_FLAGS% %1
  )

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

if %FLAG_FROM_URL% EQU 0 (
  if defined BARE_FLAGS (
    echo.%?~nx0%: error: invalid flags: %BARE_FLAGS%
    exit /b -255
  ) >&2
)

set "COMMAND=%~1"
set "CWD=%~2"
shift
shift

if defined CWD ( for /F "eol= tokens=* delims=" %%i in ("%CWD%\.") do set "CWD=%%~fi" ) else goto NOCWD
if exist "\\?\%CWD%" if exist "%CWD%" ( cd /d "%CWD%" || exit /b 1 )

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %CD%") do title %%i

:NOCWD
rem build filtered paths list
set "LOCAL_PATH_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\local_path_list.lst"

set "URL_LIST_FILE_NAME_TMP=url_path_list.lst"
set "URL_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%URL_LIST_FILE_NAME_TMP%"

rem calculate maximum busy tasks to wait after, open only TORTOISEPROC_MAX_SPAWN_CALLS windows at the same time
set MAX_SPAWN_TASKS=0

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
)

rem create empty file
type nul > "%LOCAL_PATH_LIST_FILE_TMP%"

rem run COMMAND over selected files/directories in the CWD directory
:FILE_PATH_LOOP
set "FILE_PATH=%~1"
if not defined FILE_PATH goto PROCESS_TASKS

rem reduce relative path to avoid . and .. characters
call "%%CONTOOLS_ROOT%%/filesys/reduce_relative_path.bat" "%%FILE_PATH%%"
set "FILE_PATH=%RETURN_VALUE%"

set "FILE_PATH_DECORATED=\%FILE_PATH%\"

rem cut off suffix with .svn subdirectory
if "%FILE_PATH_DECORATED:\.svn\=%" == "%FILE_PATH_DECORATED%" goto IGNORE_FILE_PATH_WCROOT_PATH_CUTOFF

set "FILE_PATH_WCROOT_SUFFIX=%FILE_PATH_DECORATED:*.svn\=%"

set "FILE_PATH_WCROOT_PREFIX=%FILE_PATH_DECORATED%"
if not defined FILE_PATH_WCROOT_SUFFIX goto CUTOFF_WCROOT_PREFIX

call set "FILE_PATH_WCROOT_PREFIX=%%FILE_PATH_DECORATED:\%FILE_PATH_WCROOT_SUFFIX%=%%"

:CUTOFF_WCROOT_PREFIX
rem remove bounds character and extract diretory path
if "%FILE_PATH_DECORATED:~-1%" == "\" set "FILE_PATH_DECORATED=%FILE_PATH_DECORATED:~0,-1%"
call "%%CONTOOLS_ROOT%%/filesys/split_pathstr.bat" "%%FILE_PATH_DECORATED:~1%%" \ "" FILE_PATH

rem should not be empty
if not defined FILE_PATH set FILE_PATH=.

:IGNORE_FILE_PATH_WCROOT_PATH_CUTOFF

if "%FILE_PATH:~-1%" == "\" set "FILE_PATH=%FILE_PATH:~0,-1%"

svn info "%FILE_PATH%" --non-interactive >nul 2>nul || (
  echo.%?~nx0%: error: not versioned directory: "%FILE_PATH%".
  exit /b 254
) >&2

rem safe echo call
for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH%") do (echo.%%i) >> "%LOCAL_PATH_LIST_FILE_TMP%"
set /A MAX_SPAWN_TASKS+=1

shift

goto FILE_PATH_LOOP

:PROCESS_TASKS
if %MAX_SPAWN_TASKS% GTR 0 goto PROCESS_TASKS

(
  echo.%?~nx0%: error: nothing left to process.
  exit /b 254
) >&2

if %FLAG_FROM_URL% EQU 0 goto SPAWN_FROM_LOCAL

rem create empty file
type nul > "%URL_LIST_FILE_TMP%"

rem read urls
for /F "usebackq eol= tokens=* delims=" %%i in ("%LOCAL_PATH_LIST_FILE_TMP%") do (
  svn info "%%i" --show-item url
) >> "%URL_LIST_FILE_TMP%"

rem url list edit
call :COPY_FILE "%%URL_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%URL_LIST_FILE_NAME_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat"%%BARE_FLAGS%% -wait -nosession -multiInst "" "%%PROJECT_LOG_DIR%%/%%URL_LIST_FILE_NAME_TMP%%" || exit /b

call :COPY_FILE "%%PROJECT_LOG_DIR%%/%%URL_LIST_FILE_NAME_TMP%%" "%%URL_LIST_FILE_TMP%%"

echo.

call :SPAWN_TASKS_FROM_URLS "%%CONTOOLS_ROOT%%/tasks/spawn_tasks.bat" "%%MAX_SPAWN_TASKS%%" "%%TORTOISEPROC_MAX_SPAWN_CALLS%%" 0 call "%%TACKLEBAR_SCRIPTS_ROOT%%/scm/tortoisesvn/tortoiseproc_read_path_from_stdin.bat"
exit /b 0

:SPAWN_FROM_LOCAL
call :SPAWN_TASKS "%%CONTOOLS_ROOT%%/tasks/spawn_tasks.bat" "%%MAX_SPAWN_TASKS%%" "%%TORTOISEPROC_MAX_SPAWN_CALLS%%" 0 call "%%TACKLEBAR_SCRIPTS_ROOT%%/scm/tortoisesvn/tortoiseproc_read_path_from_stdin.bat"
exit /b

:COPY_FILE
echo."%~1" -^> "%~2"
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%
copy "%~f1" "%~f2" /B /Y
set LASTERROR=%ERRORLEVEL%
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"
exit /b %LASTERROR%

:SPAWN_TASKS_FROM_URLS
echo.^>%*
echo.
(
  %*
) < "%URL_LIST_FILE_TMP%"
exit /b

:SPAWN_TASKS
echo.^>%*
echo.
(
  %*
) < "%LOCAL_PATH_LIST_FILE_TMP%"
exit /b
