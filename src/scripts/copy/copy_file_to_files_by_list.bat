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
set FLAG_USE_SHELL_MSYS=0
set FLAG_USE_SHELL_CYGWIN=0

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
  ) else if "%FLAG%" == "-use_shell_msys" (
    set FLAG_USE_SHELL_MSYS=1
  ) else if "%FLAG%" == "-use_shell_cygwin" (
    set FLAG_USE_SHELL_CYGWIN=1
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

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

for /F "eol= tokens=* delims=" %%i in ("%CD%") do echo CD=`%%i`& echo.

if %FLAG_USE_SHELL_MSYS% EQU 0 goto SKIP_USE_SHELL_MSYS

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/init_msys.bat" || exit /b 255

if defined MSYS_ROOT if exist "%MSYS_ROOT%\bin\*" goto MSYS_OK
(
  echo.%?~nx0%: error: `MSYS_ROOT` variable is not defined or not valid: "%MSYS_ROOT%".
  exit /b 255
) >&2

:SKIP_USE_SHELL_MSYS
:MSYS_OK

if %FLAG_USE_SHELL_CYGWIN% EQU 0 goto SKIP_USE_SHELL_CYGWIN

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/init_cygwin.bat" || exit /b 255

if defined CYGWIN_ROOT if exist "%CYGWIN_ROOT%\bin\*" goto CYGWIN_OK
(
  echo.%?~nx0%: error: `CYGWIN_ROOT` variable is not defined or not valid: "%CYGWIN_ROOT%".
  exit /b 255
) >&2

:SKIP_USE_SHELL_CYGWIN
:CYGWIN_OK

set "FILE_TO_COPY=%~1"
set "LIST_FILE_PATH=%~2"

if not defined FILE_TO_COPY (
  echo.%?~nx0%: error: file to copy is not defined.
  exit /b 255
) >&2

if not defined LIST_FILE_PATH (
  echo.%?~nx0%: error: list file path is not defined.
  exit /b 255
) >&2

for /F "eol= tokens=* delims=" %%i in ("%FILE_TO_COPY%") do set "FILE_TO_COPY=%%~fi"

if not exist "\\?\%FILE_TO_COPY%" (
  echo.%?~nx0%: error: file to copy does not exists: "%FILE_TO_COPY%".
  exit /b 255
) >&2

if exist "\\?\%FILE_TO_COPY%\*" (
  echo.%?~nx0%: error: file to copy is not a file path: "%FILE_TO_COPY%".
  exit /b 255
) >&2

set "COPY_FILE_TO_FILES_FROM_LIST_FILE_NAME_TMP=copy_file_to_files_from_file_list.lst"
set "COPY_FILE_TO_FILES_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%COPY_FILE_TO_FILES_FROM_LIST_FILE_NAME_TMP%"

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
  rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
  rem
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%COPY_FILE_TO_FILES_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FROM_UTF16LE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16LE UTF-8 "%%LIST_FILE_PATH%%" > "%COPY_FILE_TO_FILES_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FROM_UTF16BE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16BE UTF-8 "%%LIST_FILE_PATH%%" > "%COPY_FILE_TO_FILES_FROM_LIST_FILE_TMP%"
) else (
  set "COPY_FILE_TO_FILES_FROM_LIST_FILE_TMP=%LIST_FILE_PATH%"
)

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%COPY_FILE_TO_FILES_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%COPY_FILE_TO_FILES_FROM_LIST_FILE_NAME_TMP%%"

echo.Coping...
echo.

rem read selected file paths from file
for /F "usebackq eol= tokens=* delims=" %%i in ("%COPY_FILE_TO_FILES_FROM_LIST_FILE_TMP%") do (
  set TO_FILE_PATH=%%i
  call :PROCESS_FILE_PATH
)
exit /b

:PROCESS_FILE_PATH
if not defined TO_FILE_PATH exit /b 0

for /F "eol= tokens=* delims=" %%i in ("%TO_FILE_PATH%") do set "TO_FILE_PATH=%%~fi"

rem must be files, not sub directories
if exist "\\?\%TO_FILE_PATH%\*" (
  echo.%?~nx0%: error: path must be a file path: "%TO_FILE_PATH%"
  exit /b 1
) >&2

call :COPY_FILE "%%FILE_TO_COPY%%" "%%TO_FILE_PATH%%"

exit /b 0

:COPY_FILE
echo."%~1" -^> "%~2"
if %FLAG_USE_SHELL_MSYS% NEQ 0 (
  "%MSYS_ROOT%/bin/cp.exe" --preserve=timestamps "%~f1" "%~f2" || exit /b
) else if %FLAG_USE_SHELL_CYGWIN% NEQ 0 (
  "%CYGWIN_ROOT%/bin/cp.exe" --preserve=timestamps "%~f1" "%~f2" || exit /b
) else call :COPY_FILE_IMPL /B /Y "%%~f1" "%%~f2" || exit /b
exit /b 0

:COPY_FILE_IMPL
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%

copy %*
set LAST_ERROR=%ERRORLEVEL%

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

exit /b %LAST_ERROR%
