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
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" RETURN_VALUE "%%?00%%>"
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
set FLAG_WAIT_EXIT=0
set "BARE_FLAGS="

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
  ) else if "%FLAG%" == "-wait" (
    set FLAG_WAIT_EXIT=1
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

set "LIST_FILE_PATH=%~1"
set "TARGET_PATH=%~2"

if not defined LIST_FILE_PATH exit /b 0
if not defined TARGET_PATH exit /b 0

set "LIST_FILE_PATH=%LIST_FILE_PATH:\=/%"
set "TARGET_PATH=%TARGET_PATH:\=/%"

set "FFMPEG_CONCAT_FROM_LIST_FILE_NAME_TMP=ffmpeg_concat_from_file_list.lst"
set "FFMPEG_CONCAT_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%FFMPEG_CONCAT_FROM_LIST_FILE_NAME_TMP%"

set "FFMPEG_CONCAT_TO_LIST_FILE_NAME_TMP=ffmpeg_concat_to_file_list.lst"
set "FFMPEG_CONCAT_TO_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%FFMPEG_CONCAT_TO_LIST_FILE_NAME_TMP%"

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
)

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
  rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
  rem
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%FFMPEG_CONCAT_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FROM_UTF16LE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16LE UTF-8 "%%LIST_FILE_PATH%%" > "%FFMPEG_CONCAT_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FROM_UTF16BE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16BE UTF-8 "%%LIST_FILE_PATH%%" > "%FFMPEG_CONCAT_FROM_LIST_FILE_TMP%"
) else (
  set "FFMPEG_CONCAT_FROM_LIST_FILE_TMP=%LIST_FILE_PATH%"
)

call :COPY_FILE "%%FFMPEG_CONCAT_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%FFMPEG_CONCAT_FROM_LIST_FILE_NAME_TMP%%"
call :COPY_FILE "%%FFMPEG_CONCAT_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%FFMPEG_CONCAT_TO_LIST_FILE_NAME_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar "" "%%PROJECT_LOG_DIR%%/%%FFMPEG_CONCAT_TO_LIST_FILE_NAME_TMP%%"

call :COPY_FILE "%%PROJECT_LOG_DIR%%/%%FFMPEG_CONCAT_TO_LIST_FILE_NAME_TMP%%" "%%FFMPEG_CONCAT_TO_LIST_FILE_TMP%%"

rem select file
set "FFMPEG_CONCAT_TO_FILE_PATH="
for /F "usebackq eol= tokens=* delims=" %%i in (`@"%CONTOOLS_UTILITIES_BIN_ROOT%/contools/wxFileDialog.exe" "MP4 Video files (*.mp4)|*.mp4|All files|*.*" "%TARGET_PATH%" "Convert to a file" -sp`) do (
  set "FFMPEG_CONCAT_TO_FILE_PATH=%%i"
)
if %ERRORLEVEL% NEQ 0 exit /b 0
if not defined FFMPEG_CONCAT_TO_FILE_PATH (
  echo.%?~nx0%: error: file path is not selected.
  exit /b 0
) >&2

if %FLAG_WAIT_EXIT% NEQ 0 (
  call :CMD start /B /WAIT "" "%%COMSPEC%%" /C @"%%CONTOOLS_ROOT%%/ToolAdaptors/ffmpeg/ffmpeg_concat_copy_by_list.bat"%%BARE_FLAGS%% "%%FFMPEG_CONCAT_TO_LIST_FILE_TMP%%" "%%FFMPEG_CONCAT_TO_FILE_PATH%%"
) else (
  call :CMD start /B "" "%%COMSPEC%%" /C @"%%CONTOOLS_ROOT%%/ToolAdaptors/ffmpeg/ffmpeg_concat_copy_by_list.bat"%%BARE_FLAGS%% "%%FFMPEG_CONCAT_TO_LIST_FILE_TMP%%" "%%FFMPEG_CONCAT_TO_FILE_PATH%%"
)

exit /b

:COPY_FILE
echo."%~1" -^> "%~2"
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%
copy "%~f1" "%~f2" /B /Y
set LASTERROR=%ERRORLEVEL%
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"
exit /b %LASTERROR%

:CMD
echo.^>%*
(%*)
