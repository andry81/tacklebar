@echo off

setlocal

call "%%~dp0../../__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem script flags
set FLAG_FROM_URL=0
set RESTORE_LOCALE=0
set "BARE_FLAGS="

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LAST_ERROR%

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
  if "%FLAG%" == "-chcp" (
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
    echo;%?~%: error: invalid flags: %BARE_FLAGS%
    exit /b -255
  ) >&2
)

set "COMMAND=%~1"
set "CWD=%~2"
shift
shift

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "tokens=* delims="eol^= %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

for /F "tokens=* delims="eol^= %%i in ("%CD%") do echo CD=`%%i`& echo;

rem build filtered paths list
set "LOCAL_PATH_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\local_path_list.lst"

set "URL_LIST_FILE_NAME_TMP=url_path_list.lst"
set "URL_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%URL_LIST_FILE_NAME_TMP%"

rem calculate maximum busy tasks to wait after, open only TORTOISEPROC_MAX_SPAWN_CALLS windows at the same time
set MAX_SPAWN_TASKS=0

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

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
  echo;%?~%: error: not versioned directory: "%FILE_PATH%".
  exit /b 254
) >&2

rem safe echo call
for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%") do (echo;%%i) >> "%LOCAL_PATH_LIST_FILE_TMP%"
set /A MAX_SPAWN_TASKS+=1

shift

goto FILE_PATH_LOOP

:PROCESS_TASKS
if %MAX_SPAWN_TASKS% GTR 0 goto PROCESS_TASKS

(
  echo;%?~%: error: nothing left to process.
  exit /b 254
) >&2

if %FLAG_FROM_URL% EQU 0 goto SPAWN_FROM_LOCAL

rem create empty file
type nul > "%URL_LIST_FILE_TMP%"

rem read urls
(for /F "usebackq tokens=* delims="eol^= %%i in ("%LOCAL_PATH_LIST_FILE_TMP%") do svn info "%%i" --show-item url) >> "%URL_LIST_FILE_TMP%"

rem url list edit
call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%URL_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%URL_LIST_FILE_NAME_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat"%%BARE_FLAGS%% -wait -nosession -multiInst . "%%PROJECT_LOG_DIR%%/%%URL_LIST_FILE_NAME_TMP%%" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%PROJECT_LOG_DIR%%/%%URL_LIST_FILE_NAME_TMP%%" "%%URL_LIST_FILE_TMP%%"

echo;

call :SPAWN_TASKS_FROM_URLS "%%CONTOOLS_ROOT%%/tasks/spawn_tasks.bat" "%%MAX_SPAWN_TASKS%%" "%%TORTOISEPROC_MAX_SPAWN_CALLS%%" 0 call "%%TACKLEBAR_SCRIPTS_ROOT%%/scm/tortoisesvn/tortoiseproc_read_path_from_stdin.bat"
exit /b 0

:SPAWN_FROM_LOCAL
call :SPAWN_TASKS "%%CONTOOLS_ROOT%%/tasks/spawn_tasks.bat" "%%MAX_SPAWN_TASKS%%" "%%TORTOISEPROC_MAX_SPAWN_CALLS%%" 0 call "%%TACKLEBAR_SCRIPTS_ROOT%%/scm/tortoisesvn/tortoiseproc_read_path_from_stdin.bat"
exit /b

:SPAWN_TASKS_FROM_URLS
echo;^>%*
echo;
(
  %*
) < "%URL_LIST_FILE_TMP%"
exit /b

:SPAWN_TASKS
echo;^>%*
echo;
(
  %*
) < "%LOCAL_PATH_LIST_FILE_TMP%"
exit /b
