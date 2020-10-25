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
set FLAG_SORT_FILE_LINES=0
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
(
  endlocal
  echo.^>%0 %CMDLINE_STR%
  echo.
)

rem drop variables related to specific handles
set "COMPARE_OUTPUT_LIST_FILE_TMP="

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

:EXIT_MAIN
rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

rem waiting for specific handles release
if not defined COMPARE_OUTPUT_LIST_FILE_TMP goto WAIT_RELEASE_END

:WAIT_RELEASE
rem check file related to specific handle on writable access which indicates ready to release state
move /Y "%COMPARE_OUTPUT_LIST_FILE_TMP%" "%COMPARE_OUTPUT_LIST_FILE_TMP%" >nul 2>nul
if %ERRORLEVEL% EQU 0 goto WAIT_RELEASE_END
echo.%?~nx0%: warning: waiting for specific handles to release...
rem improvised sleep for 1000 msec
call "%%CONTOOLS_ROOT%%/std/sleep.bat" 1000
goto WAIT_RELEASE
:WAIT_RELEASE_END

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
set "FLAG_CHCP="
set FLAG_ARAXIS=0
set FLAG_WINMERGE=0
set "BARE_FLAGS="

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
  ) else if "%FLAG%" == "-sort_file_lines" (
    set FLAG_SORT_FILE_LINES=1
  ) else if "%FLAG%" == "-araxis" (
    set FLAG_ARAXIS=1
  ) else if "%FLAG%" == "-winmerge" (
    set FLAG_WINMERGE=1
  ) else (
    set BARE_FLAGS=%BARE_FLAGS% %1
  )

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

if %FLAG_ARAXIS% NEQ 0 (
  if not defined ARAXIS_CONSOLE_COMPARE_TOOL goto NOT_CONFIGURED
  goto NOT_CONFIGURED_END
)

if %FLAG_WINMERGE% NEQ 0 (
  if not defined WINMERGE_COMPARE_TOOL goto NOT_CONFIGURED
  goto NOT_CONFIGURED_END
)

goto NOT_CONFIGURED_END
:NOT_CONFIGURED
(
  echo.%?~nx0%: error: the comparison tool is not configured properly.
  exit /b 255
) >&2
:NOT_CONFIGURED_END

set "RUNNING_TASKS_COUNTER_LOCK_FILE0=%SCRIPT_TEMP_CURRENT_DIR%\running_tasks_counter_lock0.txt"
set "RUNNING_TASKS_COUNTER_FILE0=%SCRIPT_TEMP_CURRENT_DIR%\running_tasks_counter0.txt"
set "COMPARE_INPUT_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\input_file_list.lst"
set "COMPARE_OUTPUT_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\output_file_list.lst"

rem create new file
type nul > "%COMPARE_INPUT_LIST_FILE_TMP%"
type nul > "%COMPARE_OUTPUT_LIST_FILE_TMP%"

if defined FLAG_CHCP (
  rem to convert from unicode
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%FLAG_CHCP%%
  set RESTORE_LOCALE=1
)

:ARGS_APPEND_LOOP
if "%~1" == "" goto ARGS_APPEND_LOOP_END

rem safe echo call
for /F "eol= tokens=* delims=" %%i in ("%~1") do (echo.%%i) >> "%COMPARE_INPUT_LIST_FILE_TMP%"
shift
goto ARGS_APPEND_LOOP

:ARGS_APPEND_LOOP_END

rem drop last error
type nul > nul
set LASTERROR=0
set PATHS_PAIR_INDEX=1
set NUM_PATHS=0

rem append to lists an End Of List character
(echo..) >> "%COMPARE_INPUT_LIST_FILE_TMP%"

rem read selected file paths from list
for /F "usebackq eol= tokens=* delims=" %%i in ("%COMPARE_INPUT_LIST_FILE_TMP%") do (
  set "FILE_PATH=%%i"
  call :PROCESS_PATH "%%FILE_PATH%%" || goto PROCESS_PATH_END
)

:PROCESS_PATH_END
if %PATHS_PAIR_INDEX% GTR 1 call :PROCESS_COMPARE

set /A NUM_PATHS_REMAINDER=NUM_PATHS%%2
if %NUM_PATHS_REMAINDER% NEQ 0 (
  if %LASTERROR% EQU 0 set LASTERROR=254
  echo.%?~nx0%: warning: the rest list paths is ignored:
  echo.  "%COMPARE_OUTPUT_LIST_FILE_TMP%":
  echo.    "%PREV_FILE_PATH%"
)

rem wait all tasks to close
:WAIT_RUNNING_TASKS
call "%%CONTOOLS_ROOT%%/locks/read_file_to_var.bat" RUNNING_TASKS_COUNTER 0 "%%RUNNING_TASKS_COUNTER_LOCK_FILE0%%" "%%RUNNING_TASKS_COUNTER_FILE0%%"
if 0 GEQ %RUNNING_TASKS_COUNTER% exit /b %LASTERROR%
rem improvised sleep for 20 msec
call "%%CONTOOLS_ROOT%%/std/sleep.bat" 1000
goto WAIT_RUNNING_TASKS

exit /b %LASTERROR%

:PROCESS_PATH
rem drop the End Of List character
if "%FILE_PATH%" == "." set "FILE_PATH="

if not defined FILE_PATH exit /b 1

if %FLAG_SORT_FILE_LINES% EQU 0 goto SORT_FILE_LINES_END
if exist "%FILE_PATH%\" goto SORT_FILE_LINES_END

if %PATHS_PAIR_INDEX% LSS 10 (
  set "PATHS_PAIR_INDEX_PREFIX_STR=00%PATHS_PAIR_INDEX%"
) else if %PATHS_PAIR_INDEX% LSS 100 (
  set "PATHS_PAIR_INDEX_PREFIX_STR=0%PATHS_PAIR_INDEX%"
) else set "PATHS_PAIR_INDEX_PREFIX_STR=%PATHS_PAIR_INDEX%"

set "PATHS_PAIR_INDEX_DIR=%SCRIPT_TEMP_CURRENT_DIR%\%PATHS_PAIR_INDEX_PREFIX_STR%"
if not exist "%PATHS_PAIR_INDEX_DIR%" mkdir "%PATHS_PAIR_INDEX_DIR%"

rem The use of the `type` is required here to recognise the UTF-16 WITH BOM (`sort` can recognise ONLY the UTF-8 input)
rem But in both cases not `sort` nor `type` CAN NOT recognise the UTF-16 WITHOUT BOM!
set "FILE_OUT=%PATHS_PAIR_INDEX_DIR%\%~n1.%NUM_PATHS%%~x1"
if exist "%FILE_PATH%" ^
if not exist "%FILE_PATH%\" (
  type "%FILE_PATH%" | sort /O "%FILE_OUT%"
  set "FILE_PATH=%FILE_OUT%"
)

:SORT_FILE_LINES_END
set /A NUM_PATHS+=1
set /A NUM_PATHS_REMAINDER=NUM_PATHS%%2

if %NUM_PATHS_REMAINDER% EQU 0 (
  rem safe echo call
  for /F "eol= tokens=* delims=" %%i in ("%PREV_FILE_PATH%") do (echo.%%i) >> "%COMPARE_OUTPUT_LIST_FILE_TMP%"
  for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH%") do (echo.%%i) >> "%COMPARE_OUTPUT_LIST_FILE_TMP%"
  set /A PATHS_PAIR_INDEX+=1
)

set "PREV_FILE_PATH=%FILE_PATH%"

exit /b 0

:PROCESS_COMPARE
set /A MAX_SPAWN_TASKS=PATHS_PAIR_INDEX-1
call :SPAWN_TASKS "%%CONTOOLS_ROOT%%/tasks/spawn_tasks.bat" "%%MAX_SPAWN_TASKS%%" "%%COMPARE_TOOL_MAX_SPAWN_CALLS%%" 0 call "%%TACKLEBAR_SCRIPTS_ROOT%%/compare/compare_paths_from_stdin.bat" "%%RUNNING_TASKS_COUNTER_LOCK_FILE0%%" "%%RUNNING_TASKS_COUNTER_FILE0%%"
exit /b

:SPAWN_TASKS
call "%%CONTOOLS_ROOT%%/locks/write_file_from_var.bat" MAX_SPAWN_TASKS "%%RUNNING_TASKS_COUNTER_LOCK_FILE0%%" "%%RUNNING_TASKS_COUNTER_FILE0%%"

echo.^>%*
(
  %*
) < "%COMPARE_OUTPUT_LIST_FILE_TMP%"
