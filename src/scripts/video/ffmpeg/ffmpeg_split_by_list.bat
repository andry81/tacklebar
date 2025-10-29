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
  echo;%?~%: error: list file path is not defined.
  exit /b 255
) >&2

if not defined TARGET_PATH (
  echo;%?~%: error: target path is not defined.
  exit /b 255
) >&2

set "CONFIG_FILE_NAME_TMP0=config.0.vars"
set "CONFIG_FILE_TMP0=%SCRIPT_TEMP_CURRENT_DIR%\%CONFIG_FILE_NAME_TMP0%"

for /F "tokens=* delims="eol^= %%i in ("%LIST_FILE_PATH%\.") do set "LIST_FILE_PATH=%%~fi"
for /F "tokens=* delims="eol^= %%i in ("%TARGET_PATH%\.") do set "TARGET_PATH=%%~fi"

if not exist "\\?\%LIST_FILE_PATH%" (
  echo;%?~%: error: list file path does not exists: "%LIST_FILE_PATH%".
  exit /b 255
) >&2

if exist "\\?\%LIST_FILE_PATH%\*" (
  echo;%?~%: error: list file path is not a file path: "%LIST_FILE_PATH%".
  exit /b 255
) >&2

if not exist "\\?\%TARGET_PATH%\*" (
  echo;%?~%: error: target path directory does not exists: "%TARGET_PATH%".
  exit /b 255
) >&2

set "FFMPEG_SPLIT_FROM_LIST_FILE_NAME_TMP=ffmpeg_split_from_file_list.lst"
set "FFMPEG_SPLIT_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%FFMPEG_SPLIT_FROM_LIST_FILE_NAME_TMP%"

set "FFMPEG_SPLIT_FROM_LIST_FILE_NAME_EDITED_TMP=ffmpeg_split_from_file_list.edited.lst"
set "FFMPEG_SPLIT_FROM_LIST_FILE_EDITED_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%FFMPEG_SPLIT_FROM_LIST_FILE_NAME_EDITED_TMP%"

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

rem select directory
set "FFMPEG_SPLIT_TO_DIR_PATH="
for /F "usebackq tokens=* delims="eol^= %%i in (`@"%CONTOOLS_UTILS_BIN_ROOT%/contools/wxFileDialog.exe" "MP4 Video files (*.mp4)|*.mp4|All files|*.*" "%TARGET_PATH%" "Split to files" -od`) do ^
set "FFMPEG_SPLIT_TO_DIR_PATH=%%i"

if %ERRORLEVEL% NEQ 0 exit /b 0
if not defined FFMPEG_SPLIT_TO_DIR_PATH (
  echo;%?~%: error: directory path is not selected.
  exit /b 0
) >&2

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
  rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
  rem
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%FFMPEG_SPLIT_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FROM_UTF16LE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16LE UTF-8 "%%LIST_FILE_PATH%%" > "%FFMPEG_SPLIT_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FROM_UTF16BE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16BE UTF-8 "%%LIST_FILE_PATH%%" > "%FFMPEG_SPLIT_FROM_LIST_FILE_TMP%"
) else set "FFMPEG_SPLIT_FROM_LIST_FILE_TMP=%LIST_FILE_PATH%"

echo;* Generating default config file...
echo;

(
  echo;# `%?~nx0%` environment variables
  echo;
  echo;# Allows target files overwrite.
  echo;# Otherwise skips the splitting with an error (default^).
  echo;#
  echo;# NOTE:
  echo;#  The output file name is suffixed with the index beginning from 1 in format:
  echo;#   ^<file-name^> (^<index^>^).^<ext^>
  echo;#
  echo;ALLOW_TARGET_FILE_OVERWRITE=0
  echo;
  echo;# Split mode:
  echo;#  * by-file-size-limit
  echo;#    Split by a file size maximum value.
  echo;#
  echo;MODE=by-file-size-limit
  echo;
  echo;# File size limit in megabytes
  echo;# (4096 is default^)
  echo;#
  echo;FILE_SIZE_LIMIT_MB=4096
  echo;
  echo;# An input file overhead in kilobytes which must be subtracted before
  echo;# the calculation using a file container time duration
  echo;# (4096KB is default^).
  echo;#
  echo;FILE_IN_OVERHEAD_KB=4096
) > "%CONFIG_FILE_TMP0%"

echo;* Generating editable split list...
echo;

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%FFMPEG_SPLIT_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%FFMPEG_SPLIT_FROM_LIST_FILE_NAME_TMP%%"

call :COPY_FILE /B /Y "%%FFMPEG_SPLIT_FROM_LIST_FILE_TMP%%" "%%FFMPEG_SPLIT_FROM_LIST_FILE_EDITED_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst . "%%CONFIG_FILE_TMP0%%" "%%FFMPEG_SPLIT_FROM_LIST_FILE_EDITED_TMP%%"

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%CONFIG_FILE_TMP0%%"                        "%%PROJECT_LOG_DIR%%/%%CONFIG_FILE_NAME_TMP0%%"
call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%FFMPEG_SPLIT_FROM_LIST_FILE_EDITED_TMP%%"  "%%PROJECT_LOG_DIR%%/%%FFMPEG_SPLIT_FROM_LIST_FILE_NAME_EDITED_TMP%%"

echo;* Reading config...
echo;

rem ignore load of system config
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/load_config_dir.bat" -no_load_system_config -load_user_output_config "%%PROJECT_LOG_DIR%%" "%%PROJECT_LOG_DIR%%" || exit /b 255

rem cast all loaded integer variables
set /A ALLOW_TARGET_FILE_OVERWRITE+=0
set /A FILE_SIZE_LIMIT_MB+=0
set /A FILE_IN_OVERHEAD_KB+=0

set "BARE_FORWARD_FLAGS="

if %ALLOW_TARGET_FILE_OVERWRITE% NEQ 0 set BARE_FORWARD_FLAGS=%BARE_FORWARD_FLAGS% -f
set BARE_FORWARD_FLAGS=%BARE_FORWARD_FLAGS% -mode "%MODE%"
if %FILE_SIZE_LIMIT_MB% NEQ 0 set BARE_FORWARD_FLAGS=%BARE_FORWARD_FLAGS% -file-size-limit-mb "%FILE_SIZE_LIMIT_MB%"
if %FILE_IN_OVERHEAD_KB% NEQ 0 set BARE_FORWARD_FLAGS=%BARE_FORWARD_FLAGS% -file-in-overhead-kb "%FILE_IN_OVERHEAD_KB%"

echo;* Splitting...
echo;

if %FLAG_WAIT_EXIT% NEQ 0 (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/callln.bat" start /B /WAIT "" "%%COMSPEC%%" /C @"%%CONTOOLS_ROOT%%/ToolAdaptors/ffmpeg/ffmpeg_split_copy_by_list.bat"%%BARE_FORWARD_FLAGS%%%%BARE_FLAGS%% "%%FFMPEG_SPLIT_FROM_LIST_FILE_EDITED_TMP%%" "%%FFMPEG_SPLIT_TO_DIR_PATH%%"
) else (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/callln.bat" start /B "" "%%COMSPEC%%" /C @"%%CONTOOLS_ROOT%%/ToolAdaptors/ffmpeg/ffmpeg_split_copy_by_list.bat"%%BARE_FORWARD_FLAGS%%%%BARE_FLAGS%% "%%FFMPEG_SPLIT_FROM_LIST_FILE_EDITED_TMP%%" "%%FFMPEG_SPLIT_TO_DIR_PATH%%"
)

exit /b

:COPY_FILE
echo;^>copy %*

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%

copy %*
set LAST_ERROR=%ERRORLEVEL%

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

echo;

exit /b %LAST_ERROR%
