@echo off

setlocal

call "%%~dp0../../__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem script flags
set RESTORE_LOCALE=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LAST_ERROR%

:MAIN
rem builtin defaults
if not defined TORTOISEPROC_MAX_SPAWN_CALLS set TORTOISEPROC_MAX_SPAWN_CALLS=10

rem script flags
set FLAG_FLAGS_SCOPE=0
set "FLAG_CHCP="
set FLAG_CONVERT_FROM_UTF16=0
set FLAG_FROM_URL=0
set "BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG if "%FLAG%" == "-+" set /A FLAG_FLAGS_SCOPE+=1
if defined FLAG if "%FLAG%" == "--" set /A FLAG_FLAGS_SCOPE-=1

if defined FLAG (
  if "%FLAG%" == "-from_utf16" (
    set FLAG_CONVERT_FROM_UTF16=1
  ) else if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else if "%FLAG%" == "-from_url" (
    set FLAG_FROM_URL=1
  ) else if not "%FLAG%" == "-+" if not "%FLAG%" == "--" (
    set BARE_FLAGS=%BARE_FLAGS% %1
  )

  shift

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP

  if %FLAG_FLAGS_SCOPE% GTR 0 goto FLAGS_LOOP
)

if %FLAG_FLAGS_SCOPE% GTR 0 (
  echo;%?~%: error: not ended flags scope: %FLAG_FLAGS_SCOPE%
  exit /b -255
) >&2

if %FLAG_FROM_URL% EQU 0 if defined BARE_FLAGS (
  echo;%?~%: error: invalid flags: %BARE_FLAGS%
  exit /b -255
) >&2

set "COMMAND=%~1"
set "CWD=%~2"
set "LIST_FILE_PATH=%~3"

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "tokens=* delims="eol^= %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

for /F "tokens=* delims="eol^= %%i in ("%CD%") do echo CD=`%%i`& echo;

set "TORTOISEPROC_FROM_LIST_FILE_NAME_TMP=tortoiseproc_from_file_list.lst"
set "TORTOISEPROC_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%TORTOISEPROC_FROM_LIST_FILE_NAME_TMP%"

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

rem cast to integer
set /A CURRENT_CP+=0

if defined LIST_FILE_PATH (
  if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
    rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
    rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
    rem
    call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%TORTOISEPROC_FROM_LIST_FILE_TMP%"
  ) else set "TORTOISEPROC_FROM_LIST_FILE_TMP=%LIST_FILE_PATH%"
) else cd > "%TORTOISEPROC_FROM_LIST_FILE_TMP%

rem build filtered paths list
set "LOCAL_PATH_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\local_path_list.lst"

set "URL_LIST_FILE_NAME_TMP=url_path_list.lst"
set "URL_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%URL_LIST_FILE_NAME_TMP%"

rem calculate maximum busy tasks to wait after, open only TORTOISEPROC_MAX_SPAWN_CALLS windows at the same time
set MAX_SPAWN_TASKS=0

rem rem convert from utf, details: https://learn.microsoft.com/en-us/windows/win32/intl/code-page-identifiers
rem if %CURRENT_CP% EQU 1200 set BARE_FLAGS=%BARE_FLAGS% -from_utf16le
rem if %CURRENT_CP% EQU 1201 set BARE_FLAGS=%BARE_FLAGS% -from_utf16be
rem if %CURRENT_CP% EQU 65001 set BARE_FLAGS=%BARE_FLAGS% -from_utf8

rem create empty file
call;> "%LOCAL_PATH_LIST_FILE_TMP%"

rem read selected file paths from file
set PATH_INDEX=0
for /F "usebackq tokens=* delims="eol^= %%i in ("%TORTOISEPROC_FROM_LIST_FILE_TMP%") do (
  set "FILE_PATH=%%i"
  call :PROCESS_FILE_PATH
  set /A PATH_INDEX+=1
)

rem use CWD if list is empty
if %PATH_INDEX%0 EQU 0 for /F "tokens=* delims="eol^= %%i in ("%CWD%") do (
  set "FILE_PATH=%%i"
  call :PROCESS_FILE_PATH
  set /A PATH_INDEX+=1
)

if %MAX_SPAWN_TASKS% GTR 0 goto PROCESS_TASKS

(
  echo;%?~%: error: nothing left to process.
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
  echo;%?~%: error: not versioned directory: "%FILE_PATH%".
  exit /b 254
) >&2

rem safe echo call
for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%") do (echo;%%i) >> "%LOCAL_PATH_LIST_FILE_TMP%"
set /A MAX_SPAWN_TASKS+=1
exit /b 0

:PROCESS_TASKS
if %FLAG_FROM_URL% EQU 0 goto SPAWN_FROM_LOCAL

rem create empty file
call;> "%URL_LIST_FILE_TMP%"

rem read urls
(for /F "usebackq tokens=* delims="eol^= %%i in ("%LOCAL_PATH_LIST_FILE_TMP%") do svn info "%%i" --show-item url) >> "%URL_LIST_FILE_TMP%"

rem url list edit
call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%URL_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%URL_LIST_FILE_NAME_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat"%%BARE_FLAGS%% -wait . "%%PROJECT_LOG_DIR%%/%%URL_LIST_FILE_NAME_TMP%%" || exit /b

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
