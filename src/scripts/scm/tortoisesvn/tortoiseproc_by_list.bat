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

call "%%CONTOOLS_ROOT%%/exec/exec_terminal_prefix.bat" -- %%* || exit /b
exit /b 0

:IMPL
rem script flags
set FLAG_FROM_URL=0
set RESTORE_LOCALE=0
set "BARE_FLAGS="

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || (
  echo.%?~nx0%: error: could not allocate temporary directory: "%SCRIPT_TEMP_CURRENT_DIR%"
  exit /b 255
) >&2

call "%%CONTOOLS_ROOT%%/std/get_cmdline.bat" %%?0%% %%*
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" RETURN_VALUE ">"
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
rem builtin defaults
if not defined TORTOISEPROC_MAX_SPAWN_CALLS set TORTOISEPROC_MAX_SPAWN_CALLS=10

rem script flags
set "FLAG_CHCP="
set FLAG_CONVERT_FROM_UTF16=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-from_utf16" (
    set FLAG_CONVERT_FROM_UTF16=1
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

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

set "TORTOISEPROC_FROM_LIST_FILE_NAME_TMP=tortoiseproc_from_file_list.lst"
set "TORTOISEPROC_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%TORTOISEPROC_FROM_LIST_FILE_NAME_TMP%"

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
  rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
  rem
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%~1" > "%TORTOISEPROC_FROM_LIST_FILE_TMP%"
) else (
  set "TORTOISEPROC_FROM_LIST_FILE_TMP=%~1"
)

rem build filtered paths list
set "LOCAL_PATH_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\local_path_list.lst"

set "URL_LIST_FILE_NAME_TMP=url_path_list.lst"
set "URL_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%URL_LIST_FILE_NAME_TMP%"

rem calculate maximum busy tasks to wait after, open only TORTOISEPROC_MAX_SPAWN_CALLS windows at the same time
set MAX_SPAWN_TASKS=0

rem create empty file
type nul > "%LOCAL_PATH_LIST_FILE_TMP%"

rem read selected file paths from file
for /F "usebackq eol= tokens=* delims=" %%i in ("%TORTOISEPROC_FROM_LIST_FILE_TMP%") do (
  set "FILE_PATH=%%i"
  call :PROCESS_FILE_PATH
)

if %MAX_SPAWN_TASKS% GTR 0 goto PROCESS_TASKS

(
  echo.%?~nx0%: error: nothing left to process.
  exit /b 254
) >&2

:PROCESS_FILE_PATH
rem run COMMAND over selected files/directories in the CWD directory
if not defined FILE_PATH exit /b 1

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
exit /b 0

:PROCESS_TASKS
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
