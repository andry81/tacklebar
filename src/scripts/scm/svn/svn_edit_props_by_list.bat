@echo off

setlocal

call "%%~dp0../../__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

rem builtin defaults
if not defined NOTEPAD_WINDOW_PER_PROP_CLASS_MAX_CALLS set NOTEPAD_WINDOW_PER_PROP_CLASS_MAX_CALLS=10

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
rem script flags
set "FLAG_CHCP="
set FLAG_CONVERT_FROM_UTF16=0
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
  if "%FLAG%" == "-from_utf16" (
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
for /F "tokens=* delims="eol^= %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

for /F "tokens=* delims="eol^= %%i in ("%CD%") do echo CD=`%%i`& echo;

set "LIST_FILE_PATH=%~1"

if not defined LIST_FILE_PATH (
  echo;%?~%: error: list file path is not defined.
  exit /b 255
) >&2

rem properties saved into files to compare with
set "PROPS_INOUT_FILES_DIR_NAME=inout"
set "PROPS_INOUT_FILES_DIR=%SCRIPT_TEMP_CURRENT_DIR%\%PROPS_INOUT_FILES_DIR_NAME%"

set "SVN_EDIT_PROPS_FROM_LIST_FILE_NAME_TMP=svn_edit_props_from_file_list.lst"
set "SVN_EDIT_PROPS_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%SVN_EDIT_PROPS_FROM_LIST_FILE_NAME_TMP%"

set "EDIT_LIST_FILE_NAME_TMP=edit_file_list.lst"
set "EDIT_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%EDIT_LIST_FILE_NAME_TMP%"

set "EDIT_LIST_FILE_NAME_EDITED_TMP=edit_file_list.edited.lst"
set "EDIT_LIST_FILE_EDITED_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%EDIT_LIST_FILE_NAME_EDITED_TMP%"

set "CHANGESET_LIST_FILE_NAME_TMP=changeset_file_list.lst"
set "CHANGESET_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%CHANGESET_LIST_FILE_NAME_TMP%"

set "XCOPY_FILE_CMD_BARE_FLAGS="
set "XCOPY_DIR_CMD_BARE_FLAGS="
if defined OEMCP (
  set XCOPY_FILE_CMD_BARE_FLAGS=%XCOPY_FILE_CMD_BARE_FLAGS% -chcp "%OEMCP%"
  set XCOPY_DIR_CMD_BARE_FLAGS=%XCOPY_DIR_CMD_BARE_FLAGS% -chcp "%OEMCP%"
)

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
call "%%CONTOOLS_ROOT%%/std/copy.bat" "%%PROPS_FILTER_FILE_IN%%" "%%PROPS_FILTER_FILE%%" || exit /b 10

rem props class edit
call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar . "%%PROPS_FILTER_FILE%%"

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%PROPS_FILTER_FILE%%" "%%PROJECT_LOG_DIR%%/%%PROPS_FILTER_FILE_NAME%%"

:LOAD_PROPS_FILTER
set PROPS_FILTER_DIR_INDEX=0
set PROPS_FILTER_FILE_INDEX=0
for /F "usebackq eol=# tokens=1,2 delims=|" %%i in ("%PROPS_FILTER_FILE%") do (
  set "FILTER_PROP_CLASS=%%i"
  set "FILTER_PROP_NAME=%%j"
  call :PROCESS_LOAD_PROPS_FILTER
)

if %PROPS_FILTER_DIR_INDEX% EQU 0 if %PROPS_FILTER_FILE_INDEX% EQU 0 (
  echo;%?~%: error: no properties is selected, nothing to extract.
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
  echo;%?~%: warning: ignored unsupported property class: "%FILTER_PROP_CLASS%|%FILTER_PROP_NAME%"
  exit /b 30
) >&2

exit /b 0

:PROCESS_LOAD_PROPS_FILTER_END

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir.bat" "%%SCRIPT_TEMP_CURRENT_DIR%%\tmp" >nul || exit /b 40

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
  rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
  rem
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%SVN_EDIT_PROPS_FROM_LIST_FILE_TMP%"
) else (
  set "SVN_EDIT_PROPS_FROM_LIST_FILE_TMP=%LIST_FILE_PATH%"
)

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%SVN_EDIT_PROPS_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%SVN_EDIT_PROPS_FROM_LIST_FILE_NAME_TMP%%"

rem recreate empty list
type nul > "%EDIT_LIST_FILE_TMP%"

rem read selected file paths from file
set PATH_INDEX=0
set NUM_PATHS_TO_EDIT=0
for /F "usebackq tokens=* delims="eol^= %%i in ("%SVN_EDIT_PROPS_FROM_LIST_FILE_TMP%") do (
  set "FILE_PATH=%%i"
  call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.read_props.bat"
  set /A PATH_INDEX+=1
)

rem use CWD if list is empty
if %PATH_INDEX%0 EQU 0 for /F "tokens=* delims="eol^= %%i in ("%CWD%") do (
  set "FILE_PATH=%%i"
  call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.read_props.bat"
  set /A PATH_INDEX+=1
)

if %NUM_PATHS_TO_EDIT% EQU 0 (
  echo;%?~%: warning: no properties is left to process, nothing to edit.
  exit /b 50
) >&2

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%CHANGESET_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%CHANGESET_LIST_FILE_NAME_TMP%%"
call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%EDIT_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%EDIT_LIST_FILE_NAME_TMP%%"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%PROPS_INOUT_FILES_DIR%%" "%%PROJECT_LOG_DIR%%/%%PROPS_INOUT_FILES_DIR_NAME%%" /E /Y

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%EDIT_LIST_FILE_TMP%%" "%%EDIT_LIST_FILE_EDITED_TMP%%"

rem props values edit
call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files_by_list.bat"%%BARE_FLAGS%% -wait . "%%EDIT_LIST_FILE_EDITED_TMP%%"

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%EDIT_LIST_FILE_EDITED_TMP%%" "%%PROJECT_LOG_DIR%%/%%EDIT_LIST_FILE_NAME_EDITED_TMP%%"

call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.write_props.bat"
exit /b
