@echo off

setlocal

call "%%~dp0../__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem script flags
set FLAG_SORT_FILE_LINES=0
set RESTORE_LOCALE=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || (
  echo.%?~nx0%: error: could not allocate temporary directory: "%SCRIPT_TEMP_CURRENT_DIR%"
  exit /b 255
) >&2

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

exit /b %LASTERROR%

:MAIN
rem script flags
set "FLAG_CHCP="
set FLAG_AUTO_SELECT_COMPARE_TOOL=0
set FLAG_ARAXIS=0
set FLAG_WINMERGE=0
set "BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else if "%FLAG%" == "-sort_file_lines" (
    set FLAG_SORT_FILE_LINES=1
  ) else if "%FLAG%" == "-auto_select_compare_tool" (
    set FLAG_AUTO_SELECT_COMPARE_TOOL=1
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

if %FLAG_AUTO_SELECT_COMPARE_TOOL% NEQ 0 (
  if %ARAXIS_COMPARE_ENABLE%0 NEQ 0 if defined ARAXIS_CONSOLE_COMPARE_TOOL if exist "%ARAXIS_CONSOLE_COMPARE_TOOL%" ( set "FLAG_ARAXIS=1" & goto NOT_CONFIGURED_END )
  if defined WINMERGE_COMPARE_TOOL if exist "%WINMERGE_COMPARE_TOOL%" ( set "FLAG_WINMERGE=1" & goto NOT_CONFIGURED_END )
)

if %FLAG_ARAXIS% NEQ 0 (
  if defined ARAXIS_CONSOLE_COMPARE_TOOL if exist "%ARAXIS_CONSOLE_COMPARE_TOOL%" goto NOT_CONFIGURED_END
  goto NOT_CONFIGURED
)

if %FLAG_WINMERGE% NEQ 0 (
  if defined WINMERGE_COMPARE_TOOL if exist "%WINMERGE_COMPARE_TOOL%" goto NOT_CONFIGURED_END
  goto NOT_CONFIGURED
)

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
call;

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
if exist "%FILE_PATH%\*" goto SORT_FILE_LINES_END

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
if not exist "%FILE_PATH%\*" (
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
echo.
(
  %*
) < "%COMPARE_OUTPUT_LIST_FILE_TMP%"
