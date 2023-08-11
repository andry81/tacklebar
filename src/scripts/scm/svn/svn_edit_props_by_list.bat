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
rem builtin defaults
if not defined NOTEPAD_WINDOW_PER_PROP_CLASS_MAX_CALLS set NOTEPAD_WINDOW_PER_PROP_CLASS_MAX_CALLS=10

rem script flags
set RESTORE_LOCALE=0

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
rem script flags
set "FLAG_CHCP="
set FLAG_CONVERT_FROM_UTF16=0
rem open an edit window per property class (`svn:ignore`, `svn.externals` and so on)
set FLAG_WINDOW_PER_PROP_CLASS=0
rem open an edit property classes filter window before open an edit properties window(s)
set FLAG_EDIT_FILTER_BY_PROP_CLASS=0
rem edit all properties selected by property classes filter window
set FLAG_CREATE_PROP_IF_EMPTY=0
set FLAG_WAIT_EXIT=0
set "BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-wait" (
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

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

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

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%
copy "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" /B /Y
set LASTERROR=%ERRORLEVEL%
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"
exit /b %LASTERROR%

:XCOPY_FILE_LOG_IMPL
if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" -chcp "%%OEMCP%%" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
) else call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
exit /b

:PROCESS_LOAD_PROPS_FILTER_END

mkdir "%SCRIPT_TEMP_CURRENT_DIR%\tmp" 2>nul || if exist "%SystemRoot%\System32\robocopy.exe" ( "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%SCRIPT_TEMP_CURRENT_DIR%\tmp" >nul ) else type 2>nul || (
  echo.%?~nx0%: error: could not create a file directory: "%SCRIPT_TEMP_CURRENT_DIR%".
  exit /b 40
) >&2

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
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

( mkdir "%PROJECT_LOG_DIR%\%PROPS_INOUT_FILES_DIR_NAME%" 2>nul || if exist "%SystemRoot%\System32\robocopy.exe" ( "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%PROJECT_LOG_DIR%\%PROPS_INOUT_FILES_DIR_NAME%" >nul ) else type 2>nul ) && ^
if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat" -chcp "%%OEMCP%%" "%%PROPS_INOUT_FILES_DIR%%" "%%PROJECT_LOG_DIR%%/%%PROPS_INOUT_FILES_DIR_NAME%%" /E /Y
) else call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat" "%%PROPS_INOUT_FILES_DIR%%" "%%PROJECT_LOG_DIR%%/%%PROPS_INOUT_FILES_DIR_NAME%%" /E /Y

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

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%
copy "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" /B /Y
set LASTERROR=%ERRORLEVEL%
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"
exit /b %LASTERROR%

:XCOPY_FILE_LOG_IMPL
if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" -chcp "%%OEMCP%%" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
) else call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
exit /b
