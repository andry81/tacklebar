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
rem script flags
set "FLAG_CHCP="
set FLAG_CONVERT_FROM_UTF16=0
set FLAG_CONVERT_FROM_UTF16LE=0
set FLAG_CONVERT_FROM_UTF16BE=0
set FLAG_USE_ONLY_UNIQUE_PATHS=0
set FLAG_USE_SHELL_MSYS=0
set FLAG_USE_SHELL_CYGWIN=0
set FLAG_USE_SHORTCUT_TARGET=0
set FLAG_USE_EXTENDED_PROPERTY=0
set FLAG_USE_GETLINK=0
set FLAG_RETRY_EXTENDED_PROPERTY=0
set FLAG_USE_GIT=0
set FLAG_USE_SVN=0
set "READ_SHORTCUT_BARE_FLAGS="

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
  ) else if "%FLAG%" == "-use_only_unique_paths" (
    set FLAG_USE_ONLY_UNIQUE_PATHS=1
  ) else if "%FLAG%" == "-use_shell_msys" (
    set FLAG_USE_SHELL_MSYS=1
  ) else if "%FLAG%" == "-use_shell_cygwin" (
    set FLAG_USE_SHELL_CYGWIN=1
  ) else if "%FLAG%" == "-use_shortcut_target" (
    set FLAG_USE_SHORTCUT_TARGET=1
  ) else if "%FLAG%" == "-use_extended_property" (
    set FLAG_USE_EXTENDED_PROPERTY=1
    set READ_SHORTCUT_BARE_FLAGS=%READ_SHORTCUT_BARE_FLAGS% -use_extprop
  ) else if "%FLAG%" == "-use_getlink" (
    set FLAG_USE_GETLINK=1
    set READ_SHORTCUT_BARE_FLAGS=%READ_SHORTCUT_BARE_FLAGS% -use_getlink
  ) else if "%FLAG%" == "-retry_extended_property" (
    set FLAG_RETRY_EXTENDED_PROPERTY=1
    set READ_SHORTCUT_BARE_FLAGS=%READ_SHORTCUT_BARE_FLAGS% -retry_extended_property
  ) else if "%FLAG%" == "-use_git" (
    set FLAG_USE_GIT=1
  ) else if "%FLAG%" == "-use_svn" (
    set FLAG_USE_SVN=1
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
for /F "tokens=* delims="eol^= %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

for /F "tokens=* delims="eol^= %%i in ("%CD%") do echo CD=`%%i`& echo.

if %FLAG_USE_SHELL_MSYS% EQU 0 goto SKIP_USE_SHELL_MSYS

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/init_msys.bat" || exit /b 255

if defined MSYS_ROOT if exist "%MSYS_ROOT%\usr\bin\*" goto MSYS_OK
(
  echo.%?~nx0%: error: `MSYS_ROOT` variable is not defined or path is not valid: "%MSYS_ROOT%\usr\bin".
  exit /b 255
) >&2

:SKIP_USE_SHELL_MSYS
:MSYS_OK

if %FLAG_USE_SHELL_CYGWIN% EQU 0 goto SKIP_USE_SHELL_CYGWIN

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/init_cygwin.bat" || exit /b 255

if defined CYGWIN_ROOT if exist "%CYGWIN_ROOT%\bin\*" goto CYGWIN_OK
(
  echo.%?~nx0%: error: `CYGWIN_ROOT` variable is not defined or path is not valid: "%CYGWIN_ROOT%\bin".
  exit /b 255
) >&2

:SKIP_USE_SHELL_CYGWIN
:CYGWIN_OK

set "LIST_FILE_PATH=%~1"
set "OPTIONAL_DEST_DIR=%~2"

if not defined LIST_FILE_PATH (
  echo.%?~nx0%: error: list file path is not defined.
  exit /b 255
) >&2

set "CONFIG_FILE_NAME_TMP0=config.0.vars"
set "CONFIG_FILE_TMP0=%SCRIPT_TEMP_CURRENT_DIR%\%CONFIG_FILE_NAME_TMP0%"

for /F "tokens=* delims="eol^= %%i in ("%LIST_FILE_PATH%") do set "LIST_FILE_PATH=%%~fi"

if not exist "\\?\%LIST_FILE_PATH%" (
  echo.%?~nx0%: error: list file path does not exists: "%LIST_FILE_PATH%".
  exit /b 255
) >&2

if exist "\\?\%LIST_FILE_PATH%\*" (
  echo.%?~nx0%: error: list file path is not a file path: "%LIST_FILE_PATH%".
  exit /b 255
) >&2

set "COPY_FROM_LIST_FILE_NAME_TMP=copy_from_file_list.lst"
set "COPY_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%COPY_FROM_LIST_FILE_NAME_TMP%"

rem ex: for shortcut target paths; format: `<link>|<link-target>`
set "COPY_FROM_TRANSLATED_LIST_FILE_NAME_TMP=copy_from_translated_file_list.lst"
set "COPY_FROM_TRANSLATED_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%COPY_FROM_TRANSLATED_LIST_FILE_NAME_TMP%"

rem reversed to skip parent path copy for already a being copied child
set "REVERSED_INPUT_LIST_FILE_NAME_TMP=reversed_input_file_list.lst"
set "REVERSED_INPUT_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%REVERSED_INPUT_LIST_FILE_NAME_TMP%"

set "REVERSED_UNIQUE_LIST_FILE_NAME_TMP=reversed_unique_file_list.lst"
set "REVERSED_UNIQUE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%REVERSED_UNIQUE_LIST_FILE_NAME_TMP%"

set "UNIQUE_LIST_FILE_NAME_TMP=unique_file_list.lst"
set "UNIQUE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%UNIQUE_LIST_FILE_NAME_TMP%"

set "COPY_TO_LIST_FILE_NAME_TMP=copy_to_file_list.lst"
set "COPY_TO_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%COPY_TO_LIST_FILE_NAME_TMP%"

set "COPY_TO_LIST_FILE_NAME_EDITED_TMP=copy_to_file_list.edited.lst"
set "COPY_TO_LIST_FILE_EDITED_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%COPY_TO_LIST_FILE_NAME_EDITED_TMP%"

for /F "tokens=* delims="eol^= %%i in ("%SCRIPT_TEMP_CURRENT_DIR%\copy-with-rename.tmp") do set "COPY_WITH_RENAME_DIR_TMP=%%~fi"

rem intermediate input variables for `read_shortcut_target_path.bat` script to avoid excessive files creation/deletion
set "TARGET_PATH_STDOUT_FILE=%SCRIPT_TEMP_CURRENT_DIR%\read_shortcut_target_path.stdout.txt"
set "TARGET_PATH_STDERR_FILE=%SCRIPT_TEMP_CURRENT_DIR%\read_shortcut_target_path.stderr.txt"

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
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%COPY_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FROM_UTF16LE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16LE UTF-8 "%%LIST_FILE_PATH%%" > "%COPY_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FROM_UTF16BE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16BE UTF-8 "%%LIST_FILE_PATH%%" > "%COPY_FROM_LIST_FILE_TMP%"
) else (
  set "COPY_FROM_LIST_FILE_TMP=%LIST_FILE_PATH%"
)

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%COPY_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%COPY_FROM_LIST_FILE_NAME_TMP%%"

if %FLAG_USE_ONLY_UNIQUE_PATHS% EQU 0 goto IGNORE_FILTER_UNIQUE_PATHS

sort /R "%COPY_FROM_LIST_FILE_TMP%" /O "%REVERSED_INPUT_LIST_FILE_TMP%"

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%REVERSED_INPUT_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%REVERSED_INPUT_LIST_FILE_NAME_TMP%%"

rem recreate empty list
type nul > "%REVERSED_UNIQUE_LIST_FILE_TMP%"

set "PREV_FILE_PATH="
for /F "usebackq tokens=* delims= eol=#" %%i in ("%REVERSED_INPUT_LIST_FILE_TMP%") do (
  set "FILE_PATH=%%i"
  call :FILTER_UNIQUE_PATHS
  call set "PREV_FILE_PATH=%%FILE_PATH%%"
)

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%REVERSED_UNIQUE_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%REVERSED_UNIQUE_LIST_FILE_NAME_TMP%%"

goto FILTER_UNIQUE_PATHS_END

:FILTER_UNIQUE_PATHS
if not defined FILE_PATH exit /b 1

rem avoid any quote characters
set "FILE_PATH=%FILE_PATH:"=%"

for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%\.") do set "FILE_PATH=%%~fi"

if defined PREV_FILE_PATH goto CONTINUE_FILTER_UNIQUE_PATHS_1

if /i "%FILE_PATH%" == "%PREV_FILE_PATH%" exit /b 0

setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!FILE_PATH!") do ( endlocal & (echo.%%i) >> "%REVERSED_UNIQUE_LIST_FILE_TMP%" )
exit /b 0

:CONTINUE_FILTER_UNIQUE_PATHS_1

rem calculate file path string length
call "%%CONTOOLS_ROOT%%/std/strlen.bat" /v FILE_PATH
set FILE_PATH_LEN=%ERRORLEVEL%

call "%%CONTOOLS_ROOT%%/std/if_.bat" not "%%PREV_FILE_PATH:~%FILE_PATH_LEN%,1%%" == "" && goto CONTINUE_FILTER_UNIQUE_PATHS_2

setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!FILE_PATH!") do endlocal & (echo.%%i) >> "%REVERSED_UNIQUE_LIST_FILE_TMP%"
exit /b 0

:CONTINUE_FILTER_UNIQUE_PATHS_2

if not "%FILE_PATH:~-1%" == "\" (
  set "FILE_PATH_SUFFIX=%FILE_PATH%\"
  set /A FILE_PATH_LEN+=1
) else set "FILE_PATH_SUFFIX=%FILE_PATH%"

call set "PREV_FILE_PATH_PREFIX=%%PREV_FILE_PATH:~0,%FILE_PATH_LEN%%%"

rem the previous path is a parent path to the current path, skipping
if /i "%PREV_FILE_PATH_PREFIX%" == "%FILE_PATH_SUFFIX%" exit /b 0

setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!FILE_PATH!") do ( endlocal & (echo.%%i) >> "%REVERSED_UNIQUE_LIST_FILE_TMP%" )

exit /b 0

:FILTER_UNIQUE_PATHS_END

sort /R "%REVERSED_UNIQUE_LIST_FILE_TMP%" /O "%UNIQUE_LIST_FILE_TMP%"

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%UNIQUE_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%UNIQUE_LIST_FILE_NAME_TMP%%"

set "COPY_FROM_LIST_FILE_TMP=%UNIQUE_LIST_FILE_TMP%"

:IGNORE_FILTER_UNIQUE_PATHS

echo.* Generate default config file...
echo.

(
  echo.# `%?~nx0%` environment variables
  echo.
  echo.# Allows target directory existence before copy content of source directory into it as a directory path change.
  echo.# Otherwise interrupts the coping with an error (default^).
  echo.# Has no effect if target directory does not exist.
  echo.#
  echo.ALLOW_TARGET_DIRECTORY_EXISTENCE_ON_DIRECTORY_COPY=0
  echo.
  echo.# Allows target directory files overwrite before copy content of source directory into it as a directory path change.
  echo.# Otherwise skips the files coping with a warning (default^).
  echo.# Has no effect if ALLOW_TARGET_DIRECTORY_EXISTENCE_ON_DIRECTORY_COPY=0
  echo.#
  echo.ALLOW_TARGET_FILES_OVERWRITE_ON_DIRECTORY_COPY=0
  echo.
  echo.# Allows target files overwrite in case of a file copy.
  echo.# Otherwise skips the coping with an error (default^).
  echo.# Has no effect if ALLOW_DESTINATION_FILE_AUTO_RENAME=1
  echo.#
  echo.ALLOW_TARGET_FILE_OVERWRITE=0
  echo.
  echo.# Allows destination file auto rename in case of an exited one.
  echo.# Has effect if a destination file is conflicted with a source file and has a different content.
  echo.# Has no effect if a source file and a destination file has the same content.
  echo.# If a destination file is equal, then skips the coping with a warning.
  echo.#
  echo.# Default pattern to rename:
  echo.#    `^<name^>[.^<ext^>]` -^> `^<name^> (^<index^>^)[.^<ext^>]`
  echo.#
  echo.ALLOW_DESTINATION_FILE_AUTO_RENAME=0
) > "%CONFIG_FILE_TMP0%"

echo.* Generating editable copy list...
echo.

rem recreate empty list
type nul > "%COPY_FROM_TRANSLATED_LIST_FILE_TMP%"
type nul > "%COPY_TO_LIST_FILE_TMP%"

if defined OPTIONAL_DEST_DIR (echo.# dest: "%OPTIONAL_DEST_DIR%") >> "%COPY_TO_LIST_FILE_TMP%"

rem COPY_TO_LIST_FILE_TMP format:
rem   #> <shortcut-file-path>
rem   <directory-to-copy>|<file-to-copy>|<exclude-dirs-list>|<exclude-files-list>
rem
rem   , where `<shortcut-file-path>` line is optional and has meaning for shortcut files.

rem <exclude-dirs-list>
rem   .   - no exclusion
rem   *   - exclude all subdirectories
rem   **  - exclude all subdirectories and files

rem <exclude-files-list>
rem   *     - exclude all directory files
rem   .ext  - exclude all files with `ext` extension

rem COPY_FROM_TRANSLATED_LIST_FILE_TMP format:
rem   <shortcut-file-path>|<target-file-path>

rem read selected file paths from file
for /F "usebackq eol=# tokens=* delims=" %%i in ("%COPY_FROM_LIST_FILE_TMP%") do set "FILE_PATH=%%i" & call :FILL_TO_LIST_FILE_TMP

goto FILL_TO_LIST_FILE_TMP_END

:FILL_TO_LIST_FILE_TMP
rem avoid any quote characters
set "FILE_PATH=%FILE_PATH:"=%"

for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%\.") do set "FILE_PATH=%%~fi"

if %FLAG_USE_SHORTCUT_TARGET% EQU 0 goto SKIP_SHORTCUT_RESOLVE

for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%") do (
  if /i "%%~xi" == ".lnk" (
    call "%%CONTOOLS_ROOT%%/filesys/read_shortcut_target_path.bat"%%READ_SHORTCUT_BARE_FLAGS%% "%%FILE_PATH%%"
  ) else goto SKIP_SHORTCUT_RESOLVE
)

if defined RETURN_VALUE (
  for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%") do (
    (echo.#^> %%i) >> "%COPY_TO_LIST_FILE_TMP%"
    for /F "tokens=* delims="eol^= %%j in ("%RETURN_VALUE%\.") do for /F "tokens=* delims="eol^= %%k in ("%%i|%%~fj") do (
      (echo.%%~dpj^|%%~nxj) >> "%COPY_TO_LIST_FILE_TMP%"
      (echo.%%k) >> "%COPY_FROM_TRANSLATED_LIST_FILE_TMP%"
    )
  )
) else for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%") do (
  rem format: `	*NOTRESOLVED*|?` to produce an error on copy attempt
  (
    echo.#^> %%i
    echo.^*NOTRESOLVED^*^|?
  ) >> "%COPY_TO_LIST_FILE_TMP%"
  (echo.%%i^|^*NOTRESOLVED^*) >> "%COPY_FROM_TRANSLATED_LIST_FILE_TMP%"
  exit /b 1
)

exit /b 0

:SKIP_SHORTCUT_RESOLVE
for /F "tokens=* delims="eol^= %%i in ("%FILE_PATH%") do for /F "tokens=* delims="eol^= %%j in ("%%~dpi|%%~nxi") do (
  (echo.%%j) >> "%COPY_TO_LIST_FILE_TMP%"
  (echo..^|%%i) >> "%COPY_FROM_TRANSLATED_LIST_FILE_TMP%"
)

exit /b 1

:FILL_TO_LIST_FILE_TMP_END
call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%COPY_TO_LIST_FILE_TMP%%"               "%%PROJECT_LOG_DIR%%/%%COPY_FROM_LIST_FILE_NAME_TMP%%"
call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%COPY_FROM_TRANSLATED_LIST_FILE_TMP%%"  "%%PROJECT_LOG_DIR%%/%%COPY_FROM_TRANSLATED_LIST_FILE_NAME_TMP%%"

call :COPY_FILE /B /Y "%%COPY_TO_LIST_FILE_TMP%%" "%%COPY_TO_LIST_FILE_EDITED_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst . "%%CONFIG_FILE_TMP0%%" "%%COPY_TO_LIST_FILE_EDITED_TMP%%"

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%CONFIG_FILE_TMP0%%"                    "%%PROJECT_LOG_DIR%%/%%CONFIG_FILE_NAME_TMP0%%"
call "%%TACKLEBAR_PROJECT_ROOT%%/tools/shell_copy_file_log.bat" "%%COPY_TO_LIST_FILE_EDITED_TMP%%"        "%%PROJECT_LOG_DIR%%/%%COPY_TO_LIST_FILE_NAME_EDITED_TMP%%"

"%SystemRoot%\System32\fc.exe" "%CONFIG_FILE_TMP0:/=\%" "%COPY_TO_LIST_FILE_EDITED_TMP:/=\%" >nul && exit /b 0

echo.* Reading config...
echo.

set "XCOPY_CMD_BARE_FLAGS="
set "SVN_COPY_BARE_FLAGS="
set "GIT_COPY_BARE_FLAGS="

rem ignore load of system config
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/load_config_dir.bat" -no_load_system_config -load_user_output_config "%%PROJECT_LOG_DIR%%" "%%PROJECT_LOG_DIR%%" || exit /b 255

rem cast all loaded variables
set /A ALLOW_TARGET_DIRECTORY_EXISTENCE_ON_DIRECTORY_COPY+=0
set /A ALLOW_TARGET_FILES_OVERWRITE_ON_DIRECTORY_COPY+=0
set /A ALLOW_TARGET_FILE_OVERWRITE+=0
set /A ALLOW_DESTINATION_FILE_AUTO_RENAME+=0

if %ALLOW_DESTINATION_FILE_AUTO_RENAME% NEQ 0 (
  if %FLAG_USE_GIT% NEQ 0 (
    echo.%?~nx0%: error: `-use_git` flag is not compatible with `ALLOW_DESTINATION_FILE_AUTO_RENAME` configuration variable.
    exit /b 255
  ) >&2
  if %FLAG_USE_SVN% NEQ 0 (
    echo.%?~nx0%: error: `-use_svn` flag is not compatible with `ALLOW_DESTINATION_FILE_AUTO_RENAME` configuration variable.
    exit /b 255
  ) >&2
)

if %ALLOW_DESTINATION_FILE_AUTO_RENAME% EQU 0 if %ALLOW_TARGET_FILE_OVERWRITE% NEQ 0 (
  if %FLAG_USE_SHELL_MSYS% NEQ 0 (
    set XCOPY_CMD_BARE_FLAGS=%XCOPY_CMD_BARE_FLAGS% -f
  ) else if %FLAG_USE_SHELL_CYGWIN% NEQ 0 (
    set XCOPY_CMD_BARE_FLAGS=%XCOPY_CMD_BARE_FLAGS% -f
  ) else set XCOPY_CMD_BARE_FLAGS=%XCOPY_CMD_BARE_FLAGS% /Y
  if %FLAG_USE_SVN% NEQ 0 set SVN_COPY_BARE_FLAGS=%SVN_COPY_BARE_FLAGS% --force
  if %FLAG_USE_GIT% NEQ 0 set GIT_COPY_BARE_FLAGS=%GIT_COPY_BARE_FLAGS% --force
)

echo.* Coping...
echo.

rem suppress last blank line
set NO_PRINT_LAST_BLANK_LINE=1

set READ_FROM_FILE_PATHS=1
set SHORTCUT_CHECK_NEXT_TO_FILE_PATH=0
set "TO_SHORTCUT_FILE_PATH="
set SKIP_NEXT_TO_FILE_PATH=0

rem trick with simultaneous iteration over 2 list in the same time
(
  for /F "usebackq tokens=* delims="eol^= %%i in ("%COPY_TO_LIST_FILE_EDITED_TMP%") do (
    if defined READ_FROM_FILE_PATHS set /P "FROM_FILE_PATHS=" & set "READ_FROM_FILE_PATHS="
    set "TO_FILE_PATH=%%i"
    call :PROCESS_COPY
    echo.---
  )
) < "%COPY_FROM_TRANSLATED_LIST_FILE_TMP%"

exit /b 0

:PROCESS_COPY
if not defined FROM_FILE_PATHS (
  echo.%?~nx0%: error: FROM_FILE_PATHS is empty:
  echo.  FROM_FILE_PATHS="%FROM_FILE_PATHS%"
  echo.  TO_FILE_PATH   ="%TO_FILE_PATH%"
  set READ_FROM_FILE_PATHS=1
  set SKIP_NEXT_TO_FILE_PATH=1
  exit /b 1
) >&2

if not defined TO_FILE_PATH exit /b 1

if %SKIP_NEXT_TO_FILE_PATH% NEQ 0 set "SKIP_NEXT_TO_FILE_PATH=0" & exit /b 1

if %SHORTCUT_CHECK_NEXT_TO_FILE_PATH% EQU 0 goto PROCESS_NOT_SHORTCUT_COPY_TO_FILE_PATH

set SHORTCUT_CHECK_NEXT_TO_FILE_PATH=0
set READ_FROM_FILE_PATHS=1

for /F "tokens=1 delims=|"eol^= %%i in ("%FROM_FILE_PATHS%") do set "FROM_SHORTCUT_FILE_PATH=%%i"

if "%FROM_SHORTCUT_FILE_PATH%" == "." set "FROM_SHORTCUT_FILE_PATH="

if not defined FROM_SHORTCUT_FILE_PATH (
  echo.%?~nx0%: error: FROM_FILE_PATHS is not shortcut target:
  echo.  FROM_FILE_PATHS="%FROM_FILE_PATHS%"
  echo.  TO_FILE_PATH   ="%TO_FILE_PATH%"
  exit /b 1
) >&2

if not "%TO_SHORTCUT_FILE_PATH%" == "%FROM_SHORTCUT_FILE_PATH%" (
  echo.%?~nx0%: error: shortcut paths is not equal, skipped:
  echo.  FROM_SHORTCUT_FILE_PATH="%FROM_SHORTCUT_FILE_PATH%"
  echo.  TO_SHORTCUT_FILE_PATH  ="%TO_SHORTCUT_FILE_PATH%"
  exit /b 1
) >&2

goto PROCESS_COPY_IMPL

:PROCESS_NOT_SHORTCUT_COPY_TO_FILE_PATH
if not "%TO_FILE_PATH:~0,3%" == "#> " goto SHORTCUT_PREFIX_LINE_PARSE_END

set "TO_SHORTCUT_FILE_PATH="
for /F "tokens=1 delims=|"eol^= %%i in ("%TO_FILE_PATH:~3%") do set "TO_SHORTCUT_FILE_PATH=%%i"

set SHORTCUT_CHECK_NEXT_TO_FILE_PATH=1

exit /b -1

:SHORTCUT_PREFIX_LINE_PARSE_END
if "%TO_FILE_PATH:~0,2%" == "# " exit /b 1

set READ_FROM_FILE_PATHS=1

:PROCESS_COPY_IMPL
if "%TO_FILE_PATH:~0,1%" == "#" (
  echo.%?~nx0%: warning: TO_FILE_PATH is skipped:
  echo.  FROM_FILE_PATHS="%FROM_FILE_PATHS%"
  echo.  TO_FILE_PATH   ="%TO_FILE_PATH%"
  exit /b 1
) >&2

set "FROM_FILE_PATHS=%FROM_FILE_PATHS:/=\%"
set "TO_FILE_PATH=%TO_FILE_PATH:/=\%"

rem check on invalid characters in path
if not "%FROM_FILE_PATHS%" == "%FROM_FILE_PATHS:**=%" goto FROM_PATH_ERROR
if not "%FROM_FILE_PATHS%" == "%FROM_FILE_PATHS:?=%" goto FROM_PATH_ERROR
if not "%TO_FILE_PATH%" == "%TO_FILE_PATH:**=%" goto TO_PATH_ERROR
if not "%TO_FILE_PATH%" == "%TO_FILE_PATH:?=%" goto TO_PATH_ERROR

goto PATH_OK

:FROM_PATH_ERROR
(
  echo.%?~nx0%: error: FROM_FILE_PATHS is invalid path:
  echo.  FROM_FILE_PATHS="%FROM_FILE_PATHS%"
  echo.  TO_FILE_PATH   ="%TO_FILE_PATH%"
  exit /b 2
) >&2

goto PATH_OK

:TO_PATH_ERROR
(
  echo.%?~nx0%: error: TO_FILE_PATH is invalid path:
  echo.  FROM_FILE_PATHS="%FROM_FILE_PATHS%"
  echo.  TO_FILE_PATH   ="%TO_FILE_PATH%"
  exit /b 2
) >&2

:PATH_OK

for /F "tokens=1,* delims=|"eol^= %%i in ("%FROM_FILE_PATHS%") do set "FROM_SHORTCUT_FILE_PATH=%%i" & set "FROM_FILE_PATH=%%j"

if "%FROM_SHORTCUT_FILE_PATH%" == "." set "FROM_SHORTCUT_FILE_PATH="

rem CAUTION:
rem   The `%%~fi` or `%%~nxi` expansions here goes change a path characters case to the case of the existed file path.
rem
rem WORKAROUND:
rem   We must encode a path to a nonexistent path and after conversion to an absolute path, decode it back and so bypass case change in a path characters.
rem
set "FILE_NAME_TEMP_SUFFIX=~%RANDOM%-%RANDOM%"

for /F "tokens=* delims="eol^= %%i in ("%FROM_FILE_PATH%%FILE_NAME_TEMP_SUFFIX%\.") do ^
for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "FROM_FILE_PATH=%%~fi" & set "FROM_FILE_DIR=%%~fj" & set "FROM_FILE_NAME=%%~nxi"

rem decode paths back
call set "FROM_FILE_PATH=%%FROM_FILE_PATH:%FILE_NAME_TEMP_SUFFIX%=%%"
call set "FROM_FILE_NAME=%%FROM_FILE_NAME:%FILE_NAME_TEMP_SUFFIX%=%%"

rem extract destination path components
set "XCOPY_EXCLUDE_DIRS_LIST="
set "XCOPY_EXCLUDE_FILES_LIST="
for /F "tokens=1,2,3,4 delims=|"eol^= %%i in ("%TO_FILE_PATH%") do set "TO_FILE_DIR=%%i" & set "TO_FILE_NAME=%%j" & set "XCOPY_EXCLUDE_DIRS_LIST=%%k" & set "XCOPY_EXCLUDE_FILES_LIST=%%l"

rem can not copy an empty name

if not defined TO_FILE_NAME (
  echo.%?~nx0%: error: TO_FILE_NAME is empty:
  echo.  FROM_FILE_PATH="%FROM_FILE_PATH%"
  echo.  TO_FILE_PATH  ="%TO_FILE_PATH%"
  exit /b 3
) >&2

rem file name must contain a single component

if not "%TO_FILE_NAME:\=%" == "%TO_FILE_NAME%" (
  echo.%?~nx0%: error: TO_FILE_NAME has path components separator:
  echo.  FROM_FILE_PATH="%FROM_FILE_PATH%"
  echo.  TO_FILE_PATH  ="%TO_FILE_PATH%"
  exit /b 4
) >&2

set EXCLUDE_COPY_DIR_SUBDIRS=0
set EXCLUDE_COPY_DIR_FILES=0
set EXCLUDE_COPY_DIR_CONTENT=0

if "%XCOPY_EXCLUDE_DIRS_LIST%" == "." set "XCOPY_EXCLUDE_DIRS_LIST="
if not defined XCOPY_EXCLUDE_DIRS_LIST goto END_XCOPY_EXCLUDE_DIRS_LIST

set "XCOPY_EXCLUDE_DIRS_LIST=|%XCOPY_EXCLUDE_DIRS_LIST::=|%|"

if not "%XCOPY_EXCLUDE_DIRS_LIST:|*|=%" == "%XCOPY_EXCLUDE_DIRS_LIST%" ( set "EXCLUDE_COPY_DIR_SUBDIRS=1" & goto END_XCOPY_EXCLUDE_DIRS_LIST )
if not "%XCOPY_EXCLUDE_DIRS_LIST:|**|=%" == "%XCOPY_EXCLUDE_DIRS_LIST%" (
  set EXCLUDE_COPY_DIR_SUBDIRS=1
  set EXCLUDE_COPY_DIR_FILES=1
  set "XCOPY_EXCLUDE_DIRS_LIST=|*|"
  set "XCOPY_EXCLUDE_FILES_LIST=|*|"
  goto END_XCOPY_EXCLUDE_FILES_LIST
)

:END_XCOPY_EXCLUDE_DIRS_LIST
if "%XCOPY_EXCLUDE_FILES_LIST%" == "." set "XCOPY_EXCLUDE_FILES_LIST="
if not defined XCOPY_EXCLUDE_FILES_LIST goto END_XCOPY_EXCLUDE_FILES_LIST

set "XCOPY_EXCLUDE_FILES_LIST=|%XCOPY_EXCLUDE_FILES_LIST::=|%|"

if not "%XCOPY_EXCLUDE_FILES_LIST:|*|=%" == "%XCOPY_EXCLUDE_FILES_LIST%" ( set "EXCLUDE_COPY_DIR_FILES=1" & goto END_XCOPY_EXCLUDE_FILES_LIST )

:END_XCOPY_EXCLUDE_FILES_LIST
if defined XCOPY_EXCLUDE_DIRS_LIST set "XCOPY_EXCLUDE_DIRS_LIST=%XCOPY_EXCLUDE_DIRS_LIST:~1,-1%"
if defined XCOPY_EXCLUDE_FILES_LIST set "XCOPY_EXCLUDE_FILES_LIST=%XCOPY_EXCLUDE_FILES_LIST:~1,-1%"

if %EXCLUDE_COPY_DIR_SUBDIRS%%EXCLUDE_COPY_DIR_FILES% EQU 11 set EXCLUDE_COPY_DIR_CONTENT=1

rem concatenate and renormalize
set "TO_FILE_PATH=%TO_FILE_DIR%\%TO_FILE_NAME%"

for /F "tokens=* delims="eol^= %%i in ("%TO_FILE_PATH%%FILE_NAME_TEMP_SUFFIX%\.") do ^
for /F "tokens=* delims="eol^= %%j in ("%%~dpi.") do set "TO_FILE_PATH=%%~fi" & set "TO_FILE_DIR=%%~fj" & set "TO_FILE_NAME=%%~nxi"

rem decode paths back
call set "TO_FILE_PATH=%%TO_FILE_PATH:%FILE_NAME_TEMP_SUFFIX%=%%"
call set "TO_FILE_NAME=%%TO_FILE_NAME:%FILE_NAME_TEMP_SUFFIX%=%%"

if not defined FROM_SHORTCUT_FILE_PATH (
  echo."%FROM_FILE_PATH%" -^> "%TO_FILE_PATH%"
) else (
  echo."%FROM_SHORTCUT_FILE_PATH%":
  echo.  "%FROM_FILE_PATH%" -^> "%TO_FILE_PATH%"
)

rem file being copied to itself
if /i "%FROM_FILE_PATH%" == "%TO_FILE_PATH%" exit /b 0

if not exist "\\?\%FROM_FILE_PATH%" (
  echo.%?~nx0%: error: FROM_FILE_PATH is not found:
  echo.  FROM_FILE_PATH="%FROM_FILE_PATH%"
  echo.  TO_FILE_PATH  ="%TO_FILE_PATH%"
  exit /b 10
) >&2

set FROM_FILE_PATH_IS_DIR=0
if exist "\\?\%FROM_FILE_PATH%\*" set FROM_FILE_PATH_IS_DIR=1

set TO_FILE_PATH_EXISTS=0
set TO_FILE_PATH_IS_DIR=0
if exist "\\?\%TO_FILE_PATH%" (
  set TO_FILE_PATH_EXISTS=1
  if exist "\\?\%TO_FILE_PATH%\*" set TO_FILE_PATH_IS_DIR=1
)

rem dir-to-dir, file-to-file
if %TO_FILE_PATH_EXISTS% NEQ 0 if %FROM_FILE_PATH_IS_DIR%%TO_FILE_PATH_IS_DIR% NEQ 00 if %FROM_FILE_PATH_IS_DIR%%TO_FILE_PATH_IS_DIR% NEQ 11 (
  echo.%?~nx0%: error: incompatible path types.
  echo.  FROM_FILE_PATH="%FROM_FILE_PATH%"
  echo.  TO_FILE_PATH  ="%TO_FILE_PATH%"
  exit /b 11
) >&2

if %TO_FILE_PATH_IS_DIR% NEQ 0 (
  if %ALLOW_TARGET_DIRECTORY_EXISTENCE_ON_DIRECTORY_COPY% EQU 0 (
    echo.%?~nx0%: error: target existen directory overwrite is not allowed:
    echo.  FROM_FILE_PATH="%FROM_FILE_PATH%"
    echo.  TO_FILE_PATH  ="%TO_FILE_PATH%"
    exit /b 15
  ) >&2
) else if %TO_FILE_PATH_EXISTS% NEQ 0 (
  if %ALLOW_DESTINATION_FILE_AUTO_RENAME% EQU 0 if %ALLOW_TARGET_FILE_OVERWRITE% EQU 0 (
    echo.%?~nx0%: error: target existen file overwrite is not allowed:
    echo.  FROM_FILE_PATH="%FROM_FILE_PATH%"
    echo.  TO_FILE_PATH  ="%TO_FILE_PATH%"
    exit /b 15
  ) >&2
)

rem check recursion only if FROM_FILE_PATH is a directory
if %FROM_FILE_PATH_IS_DIR% NEQ 0 call "%%CONTOOLS_ROOT%%/filesys/subtract_path.bat" "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" && (
  echo.%?~nx0%: error: TO_FILE_PATH file path must not contain FROM_FILE_PATH file path:
  echo.  FROM_FILE_PATH="%FROM_FILE_PATH%"
  echo.  TO_FILE_PATH  ="%TO_FILE_PATH%"
  exit /b 16
) >&2

set TO_FILE_MKDIR=0

if not exist "\\?\%TO_FILE_DIR%\*" (
  set TO_FILE_MKDIR=1
  if %FLAG_USE_SHELL_MSYS%%FLAG_USE_SHELL_CYGWIN% EQU 0 (
    echo.
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir.bat" "%%TO_FILE_DIR%%" || exit /b
  ) else if %FLAG_USE_SHELL_MSYS% NEQ 0 (
    echo.
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%MSYS_ROOT%%/usr/bin/mkdir.exe" -p "%%TO_FILE_DIR%%"
  ) else (
    echo.
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CYGWIN_ROOT%%/bin/mkdir.exe" -p "%%TO_FILE_DIR%%"
  )
)

if %FLAG_USE_SVN% EQU 0 goto SKIP_USE_SVN

rem check if path is under SVN version control
svn info "%FROM_FILE_PATH%" --non-interactive >nul 2>nul || goto SKIP_USE_SVN

:SVN_COPY
call "%%CONTOOLS_ROOT%%/filesys/get_shared_path.bat" "%%FROM_FILE_PATH%%" "%%TO_FILE_DIR%%" || (
  echo.%?~nx0%: error: source file path and destination file directory must share a common root path:
  echo.  FROM_FILE_PATH="%FROM_FILE_PATH%"
  echo.  TO_FILE_DIR   ="%TO_FILE_DIR%"
  exit /b 20
) >&2

set "SHARED_ROOT=%RETURN_VALUE%"

call "%%CONTOOLS_ROOT%%/filesys/subtract_path.bat" "%%SHARED_ROOT%%" "%%TO_FILE_DIR%%" || (
  echo.%?~nx0%: error: shared path root is not a prefix to TO_FILE_DIR path:
  echo.  SHARED_ROOT="%SHARED_ROOT%"
  echo.  TO_FILE_DIR="%TO_FILE_DIR%"
  exit /b 21
) >&2

set "TO_FILE_DIR_SUFFIX=%RETURN_VALUE%"

if not defined TO_FILE_DIR_SUFFIX goto IGNORE_TO_FILE_DIR_SUFFIX_INDEX

call "%%CONTOOLS_ROOT%%/filesys/index_pathstr.bat" TO_FILE_DIR_SUFFIX \ "%%TO_FILE_DIR_SUFFIX%%"
set TO_FILE_DIR_SUFFIX_ARR_SIZE=%RETURN_VALUE%

:IGNORE_TO_FILE_DIR_SUFFIX_INDEX

rem add to version control
if %TO_FILE_DIR_SUFFIX_ARR_SIZE%0 EQU 0 goto SVN_ADD_LOOP_END

set TO_FILE_DIR_SUFFIX_INDEX=1

:SVN_ADD_LOOP
call set "TO_FILE_DIR_SUFFIX_STR=%%TO_FILE_DIR_SUFFIX%TO_FILE_DIR_SUFFIX_INDEX%%%"

echo.
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" svn add --depth immediates --non-interactive "%%SHARED_ROOT%%\%%TO_FILE_DIR_SUFFIX_STR%%"

set /A TO_FILE_DIR_SUFFIX_INDEX+=1

if %TO_FILE_DIR_SUFFIX_INDEX% GTR %TO_FILE_DIR_SUFFIX_ARR_SIZE% goto SVN_ADD_LOOP_END

goto SVN_ADD_LOOP

:SVN_ADD_LOOP_END
echo.
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" svn copy%%SVN_COPY_BARE_FLAGS%% "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || exit /b 25
goto SCM_ADD_COPY

:SKIP_USE_SVN
:SHELL_COPY
if %FROM_FILE_PATH_IS_DIR% NEQ 0 goto XCOPY_FROM_FILE_PATH_AS_DIR

if %TO_FILE_PATH_EXISTS% NEQ 0 if %TO_FILE_PATH_IS_DIR% EQU 0 if %ALLOW_DESTINATION_FILE_AUTO_RENAME% NEQ 0 call "%%?~dp0%%.impl/shell_file_auto_rename.bat" || exit /b 0

if %FLAG_USE_SHELL_MSYS% NEQ 0 (
  if %TO_FILE_MKDIR% EQU 0 echo.
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%MSYS_ROOT%%/usr/bin/cp.exe"%%XCOPY_CMD_BARE_FLAGS%% --preserve "%%FROM_FILE_PATH%%" "%%TO_FILE_DIR%%" || exit /b 40
  goto SCM_ADD_COPY
) else if %FLAG_USE_SHELL_CYGWIN% NEQ 0 (
  if %TO_FILE_MKDIR% EQU 0 echo.
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CYGWIN_ROOT%%/bin/cp.exe"%%XCOPY_CMD_BARE_FLAGS%% --preserve "%%FROM_FILE_PATH%%" "%%TO_FILE_DIR%" || exit /b 41
  goto SCM_ADD_COPY
)

rem file being copied with exactly same name
if "%FROM_FILE_NAME%" == "%TO_FILE_NAME%" goto XCOPY_FILE_WO_RENAME

call "%%?~dp0%%.shell_copy_by_list/shell_copy_by_list.xcopy_file_with_rename.bat" || exit /b 42
goto SCM_ADD_COPY

:XCOPY_FILE_WO_RENAME
rem create an empty destination file if not exist yet to check a path limitation issue
if %TO_FILE_PATH_EXISTS% EQU 0 ( type nul >> "\\?\%TO_FILE_PATH%" ) 2>nul

if exist "%FROM_FILE_PATH%" if exist "%TO_FILE_PATH%" (
  call :COPY_FILE /B%%XCOPY_CMD_BARE_FLAGS%% "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || (
    if %TO_FILE_PATH_EXISTS% EQU 0 "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/shell/delete_file.vbs" "\\?\%TO_FILE_PATH%" 2>nul
    exit /b 50
  )
  goto SCM_ADD_COPY
)

echo.
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%FROM_FILE_DIR%%" "%%TO_FILE_NAME%%" "%%TO_FILE_DIR%%"%%XCOPY_CMD_BARE_FLAGS%% /H || exit /b 51
goto SCM_ADD_COPY

:COPY_FILE
echo.^>copy %*

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%

copy %*
set LAST_ERROR=%ERRORLEVEL%

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

echo.

exit /b %LAST_ERROR%

:XCOPY_FROM_FILE_PATH_AS_DIR
if %FLAG_USE_SHELL_MSYS% NEQ 0 (
  if %TO_FILE_MKDIR% EQU 0 echo.
  if %EXCLUDE_COPY_DIR_CONTENT% EQU 0 (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%MSYS_ROOT%%/usr/bin/cp.exe"%%XCOPY_CMD_BARE_FLAGS%% -R --preserve "%%FROM_FILE_PATH%%/." "%%TO_FILE_PATH%%/" || exit /b 60
  ) else (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%MSYS_ROOT%%/usr/bin/mkdir.exe" "%%TO_FILE_PATH%%" || exit /b 61
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%MSYS_ROOT%%/usr/bin/touch.exe" -r "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%"
  )
  goto SCM_ADD_COPY
) else if %FLAG_USE_SHELL_CYGWIN% NEQ 0 (
  if %TO_FILE_MKDIR% EQU 0 echo.
  if %EXCLUDE_COPY_DIR_CONTENT% EQU 0 (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CYGWIN_ROOT%%/bin/cp.exe"%%XCOPY_CMD_BARE_FLAGS%% -R --preserve "%%FROM_FILE_PATH%%/." "%%TO_FILE_PATH%%/" || exit /b 65
  ) else (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CYGWIN_ROOT%%/bin/mkdir.exe" "%%TO_FILE_PATH%%" || exit /b 66
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CYGWIN_ROOT%%/bin/touch.exe" -r "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%"
  )
  goto SCM_ADD_COPY
)

set "XCOPY_DIR_CMD_BARE_FLAGS="
if defined OEMCP set XCOPY_DIR_CMD_BARE_FLAGS=%XCOPY_DIR_CMD_BARE_FLAGS% -chcp "%OEMCP%"

rem enable copy-to-merge mode
set XCOPY_DIR_CMD_BARE_FLAGS=%XCOPY_DIR_CMD_BARE_FLAGS% -ignore_unexist

rem reenable files overwrite for a directory copy
if defined XCOPY_CMD_BARE_FLAGS set XCOPY_CMD_BARE_FLAGS=%XCOPY_CMD_BARE_FLAGS: /Y=%

if %ALLOW_TARGET_FILES_OVERWRITE_ON_DIRECTORY_COPY% NEQ 0 set XCOPY_CMD_BARE_FLAGS=%XCOPY_CMD_BARE_FLAGS% /Y

echo.
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" /E%%XCOPY_CMD_BARE_FLAGS%% || exit /b 70
goto SCM_ADD_COPY

:SCM_ADD_COPY

if %FLAG_USE_GIT% EQU 0 goto SKIP_USE_GIT

rem WORKAROUND:
rem  Git ignores absolute path as an command argument and anyway searches current working directory for the repository.
rem  Use `pushd` to set the current directory to parent directory of being processed item.
rem

echo.

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" pushd "%%FROM_FILE_DIR%%" && (
  rem check if path is under GIT version control
  git ls-files --error-unmatch "%FROM_FILE_PATH%" >nul 2>nul || ( call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" popd & goto SKIP_USE_GIT )
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" git add "%%TO_FILE_PATH%%" || ( call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" popd & exit /b 100 )
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" popd
  goto USE_GIT_END
)

exit /b 101

:SKIP_USE_GIT
:USE_GIT_END

exit /b 0
