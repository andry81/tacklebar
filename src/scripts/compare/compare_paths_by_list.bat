@echo off

setlocal

if %IMPL_MODE%0 NEQ 0 goto IMPL

call "%%~dp0__init__.bat" || exit /b

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
set FLAG_SORT_FILE_LINES=0
set RESTORE_LOCALE=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || (
  echo.%?~nx0%: error: could not allocate temporary directory: "%SCRIPT_TEMP_CURRENT_DIR%"
  exit /b 255
) >&2

call "%%CONTOOLS_ROOT%%/std/get_cmdline.bat" %%?0%% %%*
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" RETURN_VALUE ">"
echo.

rem drop variables related to specific handles
set "COMPARE_OUTPUT_LIST_FILE_TMP="
set "COMPARE_FROM_LIST_FILE_0="

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

:EXIT_MAIN
rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

rem waiting for specific handles release
if not defined COMPARE_OUTPUT_LIST_FILE_TMP ^
if not defined COMPARE_FROM_LIST_FILE_0 goto WAIT_RELEASE_END

:WAIT_RELEASE0
rem check file related to specific handle on writable access which indicates ready to release state
move /Y "%COMPARE_FROM_LIST_FILE_0%" "%COMPARE_FROM_LIST_FILE_0%" >nul 2>nul
if %ERRORLEVEL% EQU 0 goto WAIT_RELEASE1
echo.%?~nx0%: warning: waiting for specific handles to release...
rem improvised sleep for 1000 msec
call "%%CONTOOLS_ROOT%%/std/sleep.bat" 1000
goto WAIT_RELEASE0

:WAIT_RELEASE1
rem check file related to specific handle on writable access which indicates ready to release state
move /Y "%COMPARE_OUTPUT_LIST_FILE_TMP%" "%COMPARE_OUTPUT_LIST_FILE_TMP%" >nul 2>nul
if %ERRORLEVEL% EQU 0 goto WAIT_RELEASE_END
echo.%?~nx0%: warning: waiting for specific handles to release...
rem improvised sleep for 1000 msec
call "%%CONTOOLS_ROOT%%/std/sleep.bat" 1000
goto WAIT_RELEASE1
:WAIT_RELEASE_END

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LASTERROR%

:MAIN
rem script flags
set "FLAG_CHCP="
set FLAG_CONVERT_FILE0_FROM_UTF16=0
set FLAG_CONVERT_FILE0_FROM_UTF16LE=0
set FLAG_CONVERT_FILE0_FROM_UTF16BE=0
set FLAG_CONVERT_FILE1_FROM_UTF16=0
set FLAG_CONVERT_FILE1_FROM_UTF16LE=0
set FLAG_CONVERT_FILE1_FROM_UTF16BE=0
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
  if "%FLAG%" == "-file0_from_utf16" (
    set FLAG_CONVERT_FILE0_FROM_UTF16=1
  ) else if "%FLAG%" == "-file0_from_utf16le" (
    set FLAG_CONVERT_FILE0_FROM_UTF16LE=1
  ) else if "%FLAG%" == "-file0_from_utf16be" (
    set FLAG_CONVERT_FILE0_FROM_UTF16BE=1
  ) else if "%FLAG%" == "-file1_from_utf16" (
    set FLAG_CONVERT_FILE1_FROM_UTF16=1
  ) else if "%FLAG%" == "-file1_from_utf16le" (
    set FLAG_CONVERT_FILE1_FROM_UTF16LE=1
  ) else if "%FLAG%" == "-file1_from_utf16be" (
    set FLAG_CONVERT_FILE1_FROM_UTF16BE=1
  ) else if "%FLAG%" == "-chcp" (
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

set "CWD=%~1"
shift

if defined CWD if "%CWD:~0,1%" == "\" set "CWD="
if defined CWD ( for /F "eol= tokens=* delims=" %%i in ("%CWD%\.") do set "CWD=%%~fi" ) else goto NOCWD
if exist "\\?\%CWD%" if exist "%CWD%" ( cd /d "%CWD%" || exit /b 1 )

:NOCWD

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

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
set "COMPARE_OUTPUT_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\output_file_list.lst"

rem create new file
type nul > "%COMPARE_OUTPUT_LIST_FILE_TMP%"

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
)

rem drop last error
type nul > nul
set LASTERROR=0
set LISTS_PAIR_INDEX=1
set NUM_LISTS=0

:ARGS_APPEND_LOOP
if "%~1" == "" goto ARGS_APPEND_LOOP_END

set "COMPARE_FROM_LIST_FILE=%~1"
shift

if %LISTS_PAIR_INDEX% LSS 10 (
  set "LISTS_PAIR_INDEX_PREFIX_STR=00%LISTS_PAIR_INDEX%"
) else if %LISTS_PAIR_INDEX% LSS 100 (
  set "LISTS_PAIR_INDEX_PREFIX_STR=0%LISTS_PAIR_INDEX%"
) else set "LISTS_PAIR_INDEX_PREFIX_STR=%LISTS_PAIR_INDEX%"

set "LISTS_PAIR_INDEX_DIR=%SCRIPT_TEMP_CURRENT_DIR%\%LISTS_PAIR_INDEX_PREFIX_STR%"
if not exist "%LISTS_PAIR_INDEX_DIR%" mkdir "%LISTS_PAIR_INDEX_DIR%"

set "COMPARE_FROM_LIST_FILE_%NUM_LISTS%_TMP=%LISTS_PAIR_INDEX_DIR%\input_file_list.%NUM_LISTS%.lst"

call set "COMPARE_FROM_LIST_FILE_TMP=%%COMPARE_FROM_LIST_FILE_%NUM_LISTS%_TMP%%"

call set "FLAG_CONVERT_FILE_FROM_UTF16=%%FLAG_CONVERT_FILE%NUM_LISTS%_FROM_UTF16%%"
call set "FLAG_CONVERT_FILE_FROM_UTF16LE=%%FLAG_CONVERT_FILE%NUM_LISTS%_FROM_UTF16LE%%"
call set "FLAG_CONVERT_FILE_FROM_UTF16BE=%%FLAG_CONVERT_FILE%NUM_LISTS%_FROM_UTF16BE%%"

if %FLAG_CONVERT_FILE_FROM_UTF16% NEQ 0 (
  rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
  rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
  rem
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%COMPARE_FROM_LIST_FILE%%" > "%COMPARE_FROM_LIST_FILE_TMP%"
  set "COMPARE_FROM_LIST_FILE_%NUM_LISTS%=%COMPARE_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FILE_FROM_UTF16LE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16LE UTF-8 "%%COMPARE_FROM_LIST_FILE%%" > "%COMPARE_FROM_LIST_FILE_TMP%"
  set "COMPARE_FROM_LIST_FILE_%NUM_LISTS%=%COMPARE_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FILE_FROM_UTF16BE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16BE UTF-8 "%%COMPARE_FROM_LIST_FILE%%" > "%COMPARE_FROM_LIST_FILE_TMP%"
  set "COMPARE_FROM_LIST_FILE_%NUM_LISTS%=%COMPARE_FROM_LIST_FILE_TMP%"
) else (
  set "COMPARE_FROM_LIST_FILE_%NUM_LISTS%=%COMPARE_FROM_LIST_FILE%"
)

set /A NUM_LISTS+=1
set /A NUM_LISTS_REMAINDER=NUM_LISTS%%2
if %NUM_LISTS_REMAINDER% NEQ 0 goto ARGS_APPEND_LOOP

call :PROCESS_LISTS

goto ARGS_APPEND_LOOP

:ARGS_APPEND_LOOP_END

if %NUM_LISTS% GTR 1 call :PROCESS_COMPARE

set /A NUM_LISTS_REMAINDER=NUM_LISTS%%2
if %NUM_LISTS_REMAINDER% NEQ 0 (
  if %LASTERROR% EQU 0 set LASTERROR=254
  echo.%?~nx0%: warning: the last list is ignored:
  echo.  "%COMPARE_OUTPUT_LIST_FILE_TMP%"
)

rem wait all tasks to close
:WAIT_RUNNING_TASKS
call "%%CONTOOLS_ROOT%%/locks/read_file_to_var.bat" RUNNING_TASKS_COUNTER 0 "%%RUNNING_TASKS_COUNTER_LOCK_FILE0%%" "%%RUNNING_TASKS_COUNTER_FILE0%%"
if 0 GEQ %RUNNING_TASKS_COUNTER% exit /b %LASTERROR%
rem improvised sleep for 20 msec
call "%%CONTOOLS_ROOT%%/std/sleep.bat" 1000
goto WAIT_RUNNING_TASKS

exit /b %LASTERROR%

:PROCESS_LISTS
set PATHS_PAIR_INDEX=1

set "FILE_PATH_0="
set "FILE_PATH_1="

rem append to lists an End Of List character
(echo..) >> "%COMPARE_FROM_LIST_FILE_0%"
(echo..) >> "%COMPARE_FROM_LIST_FILE_1%"

rem trick with simultaneous iteration over 2 list in the same time
(
  for /f "usebackq tokens=* delims= eol=#" %%i in ("%COMPARE_FROM_LIST_FILE_1%") do (
    set /P "FILE_PATH_0="
    set "FILE_PATH_1=%%i"
    call :PROCESS_PATHS "%%FILE_PATH_0%%" "%%FILE_PATH_1%%" || goto PROCESS_LISTS_END
  )
) < "%COMPARE_FROM_LIST_FILE_0%"

:PROCESS_LISTS_END
if defined FILE_PATH_0 ^
if not defined FILE_PATH_1 (
  if %LASTERROR% EQU 0 set LASTERROR=254
  echo.%?~nx0%: warning: the rest list paths is ignored:
  echo."%COMPARE_FROM_LIST_FILE_0%":
  echo.  "%FILE_PATH_0%"
)

if defined FILE_PATH_1 ^
if not defined FILE_PATH_0 (
  if %LASTERROR% EQU 0 set LASTERROR=253
  echo.%?~nx0%: warning: the rest list paths is ignored:
  echo."%COMPARE_FROM_LIST_FILE_1%":
  echo.  "%FILE_PATH_1%"
)

exit /b %LASTERROR%

:PROCESS_PATHS
rem drop the End Of List character
if "%FILE_PATH_0%" == "." set "FILE_PATH_0="
if "%FILE_PATH_1%" == "." set "FILE_PATH_1="

if not defined FILE_PATH_0 exit /b 1
if not defined FILE_PATH_1 exit /b 2

if %FLAG_SORT_FILE_LINES% EQU 0 goto SORT_FILE_LINES_END
if exist "%FILE_PATH_0%\" goto SORT_FILE_LINES_END
if exist "%FILE_PATH_1%\" goto SORT_FILE_LINES_END

if %PATHS_PAIR_INDEX% LSS 10 (
  set "PATHS_PAIR_INDEX_PREFIX_STR=00%PATHS_PAIR_INDEX%"
) else if %PATHS_PAIR_INDEX% LSS 100 (
  set "PATHS_PAIR_INDEX_PREFIX_STR=0%PATHS_PAIR_INDEX%"
) else set "PATHS_PAIR_INDEX_PREFIX_STR=%PATHS_PAIR_INDEX%"

set "PATHS_PAIR_INDEX_DIR=%LISTS_PAIR_INDEX_DIR%\%PATHS_PAIR_INDEX_PREFIX_STR%"
if not exist "%PATHS_PAIR_INDEX_DIR%" mkdir "%PATHS_PAIR_INDEX_DIR%"

rem The use of the `type` is required here to recognise the UTF-16 WITH BOM (`sort` can recognise ONLY the UTF-8 input)
rem But in both cases not `sort` nor `type` CAN NOT recognise the UTF-16 WITHOUT BOM!
set "FILE_OUT_0=%PATHS_PAIR_INDEX_DIR%\%~n1.0%~x1"
set "FILE_OUT_1=%PATHS_PAIR_INDEX_DIR%\%~n2.1%~x2"
if exist "%FILE_PATH_0%" ^
if not exist "%FILE_PATH_0%\" (
  type "%FILE_PATH_0%" | sort /O "%FILE_OUT_0%"
  set "FILE_PATH_0=%FILE_OUT_0%"
)
if exist "%FILE_PATH_1%" ^
if not exist "%FILE_PATH_1%\" (
  type "%FILE_PATH_1%" | sort /O "%FILE_OUT_1%"
  set "FILE_PATH_1=%FILE_OUT_1%"
)

:SORT_FILE_LINES_END
rem safe echo call
for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH_0%") do (echo.%%i) >> "%COMPARE_OUTPUT_LIST_FILE_TMP%"
for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH_1%") do (echo.%%i) >> "%COMPARE_OUTPUT_LIST_FILE_TMP%"
set /A PATHS_PAIR_INDEX+=1

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
