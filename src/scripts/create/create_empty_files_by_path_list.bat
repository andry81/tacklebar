@echo off

setlocal

call "%%~dp0../__init__/script_init.bat" %%0 %%* || exit /b
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
rem script flags
set "FLAG_CHCP="
set FLAG_CONVERT_FROM_UTF16=0
set FLAG_CONVERT_FROM_UTF16LE=0
set FLAG_CONVERT_FROM_UTF16BE=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-from_utf16" (
    set FLAG_CONVERT_FROM_UTF16=1
  ) else if "%FLAG%" == "-from_utf16le" (
    set FLAG_CONVERT_FROM_UTF16LE=1
  ) else if "%FLAG%" == "-from_utf16be" (
    set FLAG_CONVERT_FROM_UTF16BE=1
  ) else if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else (
    echo.%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "CWD=%~1"
shift

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "tokens=* delims="eol^= %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

set "LIST_FILE_PATH=%~1"

if not defined LIST_FILE_PATH (
  echo.%?~%: error: list file path is not defined.
  exit /b 255
) >&2

set "CREATE_FILES_FROM_LIST_FILE_NAME_TMP=create_files_from_file_list.lst"
set "CREATE_FILES_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%CREATE_FILES_FROM_LIST_FILE_NAME_TMP%"

set "CREATE_FILES_BY_LIST_FILE_NAME_TMP=create_files_by_path_list.lst"
set "CREATE_FILES_BY_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%CREATE_FILES_BY_LIST_FILE_NAME_TMP%"

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

set "XCOPY_FILE_CMD_BARE_FLAGS="
if defined OEMCP set XCOPY_FILE_CMD_BARE_FLAGS=%XCOPY_FILE_CMD_BARE_FLAGS% -chcp "%OEMCP%"

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
  rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
  rem
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%CREATE_FILES_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FROM_UTF16LE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16LE UTF-8 "%%LIST_FILE_PATH%%" > "%CREATE_FILES_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FROM_UTF16BE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16BE UTF-8 "%%LIST_FILE_PATH%%" > "%CREATE_FILES_FROM_LIST_FILE_TMP%"
) else (
  set "CREATE_FILES_FROM_LIST_FILE_TMP=%LIST_FILE_PATH%"
)

call :COPY_FILE /B /Y "%%CREATE_FILES_FROM_LIST_FILE_TMP%%" "%%CREATE_FILES_BY_LIST_FILE_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar . "%%CREATE_FILES_BY_LIST_FILE_TMP%%"

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%CREATE_FILES_BY_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%CREATE_FILES_BY_LIST_FILE_NAME_TMP%%"

set "CREATE_FILES_IN_DIR_PATH="
if defined CWD if exist "\\?\%CWD%" if not exist "%CWD%" set "CREATE_FILES_IN_DIR_PATH=%CWD%"

set LINE_INDEX=0
for /f "usebackq tokens=* delims= eol=#" %%i in ("%CREATE_FILES_BY_LIST_FILE_TMP%") do (
  set "CREATE_FILE_PATH=%%i"
  call :PROCESS_CREATE_FILES
)

exit /b

:PROCESS_CREATE_FILES
set /A LINE_INDEX+=1

if not defined CREATE_FILE_PATH exit /b 30

if not defined CREATE_FILES_IN_DIR_PATH goto IGNORE_CREATE_FILES_IN_DIR_PATH
if "%CREATE_FILE_PATH:~1,1%" == ":" goto IGNORE_CREATE_FILES_IN_DIR_PATH

for /F "tokens=* delims="eol^= %%i in ("%CREATE_FILES_IN_DIR_PATH%\%CREATE_FILE_PATH%\.") do set "CREATE_FILE_PATH=%%~fi" & set "CREATE_FILE_PATH_IN_DIR=%%~dpi"

set "CREATE_FILE_PATH_IN_DIR=%CREATE_FILE_PATH_IN_DIR:~0,-1%"

goto CREATE_FILES_IN_DIR_PATH

:IGNORE_CREATE_FILES_IN_DIR_PATH
for /F "tokens=* delims="eol^= %%i in ("%CREATE_FILE_PATH%\.") do set "CREATE_FILE_PATH=%%~fi" & set "CREATE_FILE_PATH_IN_DIR=%%~dpi"

set "CREATE_FILE_PATH_IN_DIR=%CREATE_FILE_PATH_IN_DIR:~0,-1%"

:CREATE_FILES_IN_DIR_PATH
if exist "\\?\%CREATE_FILE_PATH%" (
  echo.%?~%: warning: file/directory path is already exist: "%CREATE_FILE_PATH%"
  exit /b 40
) >&2

if not exist "\\?\%CREATE_FILE_PATH_IN_DIR%\*" (
  echo.%?~%: error: file directory path does not exist: "%CREATE_FILE_PATH_IN_DIR%"
  exit /b 41
) >&2

echo."%CREATE_FILE_PATH%"
type nul > "\\?\%CREATE_FILE_PATH%" || (
  echo.%?~%: error: could not create file: "%CREATE_FILE_PATH%".
  exit /b 42
) >&2

exit /b

:COPY_FILE
echo.^>copy %*

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%

copy %*
set LAST_ERROR=%ERRORLEVEL%

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

echo.

exit /b %LAST_ERROR%
