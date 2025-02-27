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

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/update_cwd.bat" || exit /b

rem safe title call
for /F "tokens=* delims="eol^= %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

set "LIST_FILE_PATH=%~1"
set "TARGET_PATH=%~2"

if not defined LIST_FILE_PATH (
  echo.%?~nx0%: error: list file path is not defined.
  exit /b 255
) >&2

if not defined TARGET_PATH (
  echo.%?~nx0%: error: target path is not defined.
  exit /b 255
) >&2

set "LIST_FILE_PATH=%LIST_FILE_PATH:\=/%"
set "TARGET_PATH=%TARGET_PATH:\=/%"

set "FFMPEG_CONCAT_FROM_LIST_FILE_NAME_TMP=ffmpeg_concat_from_file_list.lst"
set "FFMPEG_CONCAT_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%FFMPEG_CONCAT_FROM_LIST_FILE_NAME_TMP%"

set "FFMPEG_CONCAT_TO_LIST_FILE_NAME_TMP=ffmpeg_concat_to_file_list.lst"
set "FFMPEG_CONCAT_TO_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%FFMPEG_CONCAT_TO_LIST_FILE_NAME_TMP%"

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

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

call "%%CONTOOLS_ROOT%%/std/copy.bat" "%%FFMPEG_CONCAT_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%FFMPEG_CONCAT_FROM_LIST_FILE_NAME_TMP%%" /B /Y
call "%%CONTOOLS_ROOT%%/std/copy.bat" "%%FFMPEG_CONCAT_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%FFMPEG_CONCAT_TO_LIST_FILE_NAME_TMP%%" /B /Y

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar . "%%PROJECT_LOG_DIR%%/%%FFMPEG_CONCAT_TO_LIST_FILE_NAME_TMP%%"

call "%%CONTOOLS_ROOT%%/std/copy.bat" "%%PROJECT_LOG_DIR%%/%%FFMPEG_CONCAT_TO_LIST_FILE_NAME_TMP%%" "%%FFMPEG_CONCAT_TO_LIST_FILE_TMP%%" /B /Y

rem select file
set "FFMPEG_CONCAT_TO_FILE_PATH="
for /F "usebackq tokens=* delims="eol^= %%i in (`@"%CONTOOLS_UTILS_BIN_ROOT%/contools/wxFileDialog.exe" "MP4 Video files (*.mp4)|*.mp4|All files|*.*" "%TARGET_PATH%" "Convert to a file" -sp`) do (
  set "FFMPEG_CONCAT_TO_FILE_PATH=%%i"
)
if %ERRORLEVEL% NEQ 0 exit /b 0
if not defined FFMPEG_CONCAT_TO_FILE_PATH (
  echo.%?~nx0%: error: file path is not selected.
  exit /b 0
) >&2

if %FLAG_WAIT_EXIT% NEQ 0 (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%COMSPEC%%" /C @"%%CONTOOLS_ROOT%%/ToolAdaptors/ffmpeg/ffmpeg_concat_copy_by_list.bat"%%BARE_FLAGS%% "%%FFMPEG_CONCAT_TO_LIST_FILE_TMP%%" "%%FFMPEG_CONCAT_TO_FILE_PATH%%"
) else (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B "" "%%COMSPEC%%" /C @"%%CONTOOLS_ROOT%%/ToolAdaptors/ffmpeg/ffmpeg_concat_copy_by_list.bat"%%BARE_FLAGS%% "%%FFMPEG_CONCAT_TO_LIST_FILE_TMP%%" "%%FFMPEG_CONCAT_TO_FILE_PATH%%"
)

exit /b

