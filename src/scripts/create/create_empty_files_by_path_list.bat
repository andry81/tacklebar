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
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

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

set "LIST_FILE_PATH=%~1"

if not defined LIST_FILE_PATH exit /b 0

set "CREATE_FILES_FROM_LIST_FILE_NAME_TMP=create_files_from_file_list.lst"
set "CREATE_FILES_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%CREATE_FILES_FROM_LIST_FILE_NAME_TMP%"

set "CREATE_FILES_BY_LIST_FILE_NAME_TMP=create_files_by_path_list.lst"
set "CREATE_FILES_BY_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%CREATE_FILES_BY_LIST_FILE_NAME_TMP%"

set "EMPTY_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\emptydir"

mkdir "%EMPTY_DIR_TMP%" || (
  echo.%?~n0%: error: could not create a directory: "%EMPTY_DIR_TMP%".
  exit /b 255
) >&2

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
)

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

call :COPY_FILE_LOG "%%CREATE_FILES_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%CREATE_FILES_BY_LIST_FILE_NAME_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar "" "%%PROJECT_LOG_DIR%%/%%CREATE_FILES_BY_LIST_FILE_NAME_TMP%%"

call :COPY_FILE_LOG "%%PROJECT_LOG_DIR%%/%%CREATE_FILES_BY_LIST_FILE_NAME_TMP%%" "%%CREATE_FILES_BY_LIST_FILE_TMP%%"

set "CREATE_FILES_IN_DIR_PATH="
if defined CWD if exist "\\?\%CWD%" if not exist "%CWD%" set "CREATE_FILES_IN_DIR_PATH=%CWD%"

set LINE_INDEX=0
for /f "usebackq tokens=* delims= eol=#" %%i in ("%CREATE_FILES_BY_LIST_FILE_TMP%") do (
  set "CREATE_FILE_PATH=%%i"
  call :PROCESS_CREATE_FILES
)

exit /b

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

:PROCESS_CREATE_FILES
set /A LINE_INDEX+=1

if not defined CREATE_FILE_PATH exit /b 30

if not defined CREATE_FILES_IN_DIR_PATH goto IGNORE_CREATE_FILES_IN_DIR_PATH
if "%CREATE_FILE_PATH:~1,1%" == ":" goto IGNORE_CREATE_FILES_IN_DIR_PATH

for /F "eol= tokens=* delims=" %%i in ("%CREATE_FILES_IN_DIR_PATH%\%CREATE_FILE_PATH%\.") do ( set "CREATE_FILE_PATH=%%~fi" & set "CREATE_FILE_PATH_IN_DIR=%%~dpi" )

set "CREATE_FILE_PATH_IN_DIR=%CREATE_FILE_PATH_IN_DIR:~0,-1%"

goto CREATE_FILES_IN_DIR_PATH

:IGNORE_CREATE_FILES_IN_DIR_PATH
for /F "eol= tokens=* delims=" %%i in ("%CREATE_FILE_PATH%\.") do ( set "CREATE_FILE_PATH=%%~fi" & set "CREATE_FILE_PATH_IN_DIR=%%~dpi" )

set "CREATE_FILE_PATH_IN_DIR=%CREATE_FILE_PATH_IN_DIR:~0,-1%"

:CREATE_FILES_IN_DIR_PATH
if exist "\\?\%CREATE_FILE_PATH%" (
  echo.%?~nx0%: warning: file/directory path is already exist: "%CREATE_FILE_PATH%"
  exit /b 40
) >&2

if not exist "\\?\%CREATE_FILE_PATH_IN_DIR%\" (
  echo.%?~nx0%: error: file directory path does not exist: "%CREATE_FILE_PATH_IN_DIR%"
  exit /b 41
)

echo."%CREATE_FILE_PATH%"
type nul > "\\?\%CREATE_FILE_PATH%" || (
  echo.%?~nx0%: error: could not create file: "%CREATE_FILE_PATH%".
  exit /b 42
)

exit /b
