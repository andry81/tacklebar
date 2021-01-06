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

if %CONEMU_ENABLE%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "attach" %CONEMU_CMDLINE_ATTACH_PREFIX%
if %CONEMU_ENABLE%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "run" (
  %CONEMU_CMDLINE_RUN_PREFIX% "%COMSPEC%" /C call "%?~0%" %* -cur_console:n 2^>^&1 ^| "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
  exit /b
)
"%COMSPEC%" /C call "%?~0%" %* 2>&1 | "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
exit /b

:IMPL
rem builtin defaults
if not defined NOTEPAD_WINDOW_PER_PROP_CLASS_MAX_CALLS set NOTEPAD_WINDOW_PER_PROP_CLASS_MAX_CALLS=10

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
  ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"
) else if %LASTERROR% NEQ 0 if %FLAG_PAUSE_ON_ERROR% NEQ 0 (
  if %FLAG_PAUSE_TIMEOUT_SEC% NEQ 0 (
    timeout /T %FLAG_PAUSE_TIMEOUT_SEC%
  ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"
)

exit /b %LASTERROR%

:MAIN
rem script flags
set FLAG_WAIT_EXIT=0
set FLAG_CONVERT_FROM_UTF16=0
set "FLAG_CHCP="
rem open an edit window per property class (`svn:ignore`, `svn.externals` and so on)
set FLAG_WINDOW_PER_PROP_CLASS=0
rem open an edit property classes filter window before open an edit properties window(s)
set FLAG_EDIT_FILTER_BY_PROP_CLASS=0
rem edit all properties selected by property classes filter window
set FLAG_CREATE_PROP_IF_EMPTY=0
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
  ) else if "%FLAG%" == "-wait" (
    set FLAG_WAIT_EXIT=1
  ) else if "%FLAG%" == "-from_utf16" (
    set FLAG_CONVERT_FROM_UTF16=1
  ) else if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else if "%FLAG%" == "-window_per_prop_class" (
    set FLAG_WINDOW_PER_PROP_CLASS=1
  ) else if "%FLAG%" == "-edit_filter_by_prop_class" (
    set FLAG_EDIT_FILTER_BY_PROP_CLASS=1
  ) else if "%FLAG%" == "-create_prop_if_empty" (
    set FLAG_CREATE_PROP_IF_EMPTY=1
  ) else (
    set BARE_FLAGS=%BARE_FLAGS% %1
  )

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

rem properties saved into files to compare with
set "PROPS_INOUT_FILES_DIR_NAME=inout"
set "PROPS_INOUT_FILES_DIR=%SCRIPT_TEMP_CURRENT_DIR%\%PROPS_INOUT_FILES_DIR_NAME%"

set "SVN_EDIT_PROPS_FROM_LIST_FILE_NAME_TMP=svn_edit_props_from_file_list.lst"
set "SVN_EDIT_PROPS_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%SVN_EDIT_PROPS_FROM_LIST_FILE_NAME_TMP%"

set "EDIT_LIST_FILE_NAME_TMP=edit_file_list.lst"
set "EDIT_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%EDIT_LIST_FILE_NAME_TMP%"

set "CHANGESET_LIST_FILE_NAME_TMP=changeset_file_list.lst"
set "CHANGESET_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%CHANGESET_LIST_FILE_NAME_TMP%"

set "EMPTY_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\emptydir"

mkdir "%EMPTY_DIR_TMP%" || (
  echo.%?~n0%: error: could not create a directory: "%EMPTY_DIR_TMP%".
  exit /b 255
) >&2

if %FLAG_CREATE_PROP_IF_EMPTY% NEQ 0 (
  set "PROPS_FILTER_FILE_NAME_IN=svn_props_to_edit_all.lst.in"
) else set "PROPS_FILTER_FILE_NAME_IN=svn_props_to_edit.lst.in"
set "PROPS_FILTER_FILE_IN=%TACKLEBAR_SCRIPTS_CONFIG_ROOT%\svn\%PROPS_FILTER_FILE_NAME_IN%"

if %FLAG_EDIT_FILTER_BY_PROP_CLASS% NEQ 0 goto USE_USER_PROPS_FILTER
set "PROPS_FILTER_FILE_NAME=%PROPS_FILTER_FILE_NAME_IN%"
set "PROPS_FILTER_FILE=%PROPS_FILTER_FILE_IN%"
goto LOAD_PROPS_FILTER

:USE_USER_PROPS_FILTER
set "PROPS_FILTER_FILE_NAME=svn_props_to_edit.lst"
set "PROPS_FILTER_FILE=%SCRIPT_TEMP_CURRENT_DIR%\%PROPS_FILTER_FILE_NAME%"
call :COPY_FILE "%%PROPS_FILTER_FILE_IN%%" "%%PROPS_FILTER_FILE%%" || exit /b 10

rem props class edit
call :COPY_FILE_LOG "%%PROPS_FILTER_FILE%%" "%%PROJECT_LOG_DIR%%/%%PROPS_FILTER_FILE_NAME%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar "" "%%PROJECT_LOG_DIR%%/%%PROPS_FILTER_FILE_NAME%%"

call :COPY_FILE_LOG "%%PROJECT_LOG_DIR%%/%%PROPS_FILTER_FILE_NAME%%" "%%PROPS_FILTER_FILE%%"

:LOAD_PROPS_FILTER
set PROPS_FILTER_DIR_INDEX=0
set PROPS_FILTER_FILE_INDEX=0
for /F "usebackq eol=# tokens=1,2 delims=|" %%i in ("%PROPS_FILTER_FILE%") do (
  set "FILTER_PROP_CLASS=%%i"
  set "FILTER_PROP_NAME=%%j"
  call :PROCESS_LOAD_PROPS_FILTER
)

if %PROPS_FILTER_DIR_INDEX% EQU 0 if %PROPS_FILTER_FILE_INDEX% EQU 0 (
  echo.%?~nx0%: error: no properties is selected, nothing to extract.
  exit /b 20
) >&2

goto PROCESS_LOAD_PROPS_FILTER_END

:PROCESS_LOAD_PROPS_FILTER
if "%FILTER_PROP_CLASS%" == "dir" (
  set "PROPS_FILTER[dir][%PROPS_FILTER_DIR_INDEX%]=%FILTER_PROP_NAME%"
  set /A PROPS_FILTER_DIR_INDEX+=1
) else if "%FILTER_PROP_CLASS%" == "file" (
  set "PROPS_FILTER[file][%PROPS_FILTER_FILE_INDEX%]=%FILTER_PROP_NAME%"
  set /A PROPS_FILTER_FILE_INDEX+=1
) else (
  echo.%?~nx0%: warning: ignored unsupported property class: "%FILTER_PROP_CLASS%|%FILTER_PROP_NAME%"
  exit /b 30
) >&2

exit /b 0

:COPY_FILE
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

:PROCESS_LOAD_PROPS_FILTER_END

mkdir "%SCRIPT_TEMP_CURRENT_DIR%\tmp" 2>nul || "%WINDIR%/System32/robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%SCRIPT_TEMP_CURRENT_DIR%\tmp" >nul || (
  echo.%?~nx0%: error: could not create a file directory: "%SCRIPT_TEMP_CURRENT_DIR%".
  exit /b 40
) >&2

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem to convert from unicode
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" 65001
  set RESTORE_LOCALE=1
)

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
  rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
  rem
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%SVN_EDIT_PROPS_FROM_LIST_FILE_TMP%"
) else (
  set "SVN_EDIT_PROPS_FROM_LIST_FILE_TMP=%LIST_FILE_PATH%"
)

call :COPY_FILE_LOG "%%SVN_EDIT_PROPS_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%SVN_EDIT_PROPS_FROM_LIST_FILE_NAME_TMP%%"

echo.

rem recreate empty list
type nul > "%EDIT_LIST_FILE_TMP%"

rem read selected file paths from file
set PATH_INDEX=0
set NUM_PATHS_TO_EDIT=0
for /F "usebackq eol= tokens=* delims=" %%i in ("%SVN_EDIT_PROPS_FROM_LIST_FILE_TMP%") do (
  set "FILE_PATH=%%i"
  call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.read_props.bat"
  set /A PATH_INDEX+=1
)

if %NUM_PATHS_TO_EDIT% EQU 0 (
  echo.%?~nx0%: warning: no properties is left to process, nothing to edit.
  exit /b 50
) >&2

call :COPY_FILE_LOG "%%CHANGESET_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%CHANGESET_LIST_FILE_NAME_TMP%%"
call :COPY_FILE_LOG "%%EDIT_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%EDIT_LIST_FILE_NAME_TMP%%"

rem props values edit
call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files_by_list.bat"%%BARE_FLAGS%% -wait -nosession -multiInst "" "%%PROJECT_LOG_DIR%%/%%EDIT_LIST_FILE_NAME_TMP%%"

call :COPY_FILE_LOG "%%PROJECT_LOG_DIR%%/%%EDIT_LIST_FILE_NAME_TMP%%" "%%EDIT_LIST_FILE_TMP%%"

echo.

( mkdir "%PROJECT_LOG_DIR%\%PROPS_INOUT_FILES_DIR_NAME%" 2>nul || "%WINDIR%/System32/robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%PROJECT_LOG_DIR%\%PROPS_INOUT_FILES_DIR_NAME%" >nul ) && ^
call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat" "%%PROPS_INOUT_FILES_DIR%%" "%%PROJECT_LOG_DIR%%/%%PROPS_INOUT_FILES_DIR_NAME%%" /E /Y

echo.

call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.write_props.bat"
exit /b

:COPY_FILE
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
