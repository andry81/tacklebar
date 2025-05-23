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
set FLAG_WAIT_EXIT=0
set FLAG_NOTEPADPLUSPLUS=0
set FLAG_USE_NPP_EXTRA_CMDLINE=0
set FLAG_APPEND=0
set FLAG_COVERT_PATHS_TO_UNICODE_CODE_POINTS=0
set FLAG_COVERT_PATHS_TO_UTF8=0

rem Has meaning ONLY if FLAG_USE_NPP_EXTRA_CMDLINE is set
set FLAG_FILE_LIST_IN_UTF8=0
set FLAG_FILE_LIST_IN_UTF16=0
set FLAG_FILE_LIST_IN_UTF16LE=0
set FLAG_FILE_LIST_IN_UTF16BE=0

set "BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else if "%FLAG%" == "-wait" (
    set FLAG_WAIT_EXIT=1
  ) else if "%FLAG%" == "-npp" (
    set FLAG_NOTEPADPLUSPLUS=1
  ) else if "%FLAG%" == "-use_npp_extra_cmdline" (
    set FLAG_USE_NPP_EXTRA_CMDLINE=1
  ) else if "%FLAG%" == "-append" (
    set FLAG_APPEND=1
  ) else if "%FLAG%" == "-paths_to_u16cp" (
    set FLAG_COVERT_PATHS_TO_UNICODE_CODE_POINTS=1
  ) else if "%FLAG%" == "-paths_to_utf8" (
    set FLAG_COVERT_PATHS_TO_UTF8=1
  ) else if "%FLAG%" == "-from_utf8" (
    set FLAG_FILE_LIST_IN_UTF8=1
  ) else if "%FLAG%" == "-from_utf16" (
    set FLAG_FILE_LIST_IN_UTF16=1
  ) else if "%FLAG%" == "-from_utf16le" (
    set FLAG_FILE_LIST_IN_UTF16LE=1
  ) else if "%FLAG%" == "-from_utf16be" (
    set FLAG_FILE_LIST_IN_UTF16BE=1
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

if not defined LIST_FILE_PATH (
  echo;%?~%: error: list file path is not defined.
  exit /b 255
) >&2

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

set "LIST_FILE_PATH=%LIST_FILE_PATH:\=/%"

if %FLAG_NOTEPADPLUSPLUS% EQU 0 goto USE_BASIC_NOTEPAD

set "EDIT_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\edit_from_file_list.xml"
set "EDIT_FROM_LIST_FILE_HEX_TMP=%SCRIPT_TEMP_CURRENT_DIR%\edit_from_file_list.hex.bin"
set "EDIT_FROM_LIST_FILE_U16CP_TMP=%SCRIPT_TEMP_CURRENT_DIR%\edit_from_file_list.u16cp.lst"
set "EDIT_FROM_LIST_FILE_UTF8_TMP=%SCRIPT_TEMP_CURRENT_DIR%\edit_from_file_list.utf8.lst"

set "EDIT_FROM_LIST_FILE_HEX_TMP=%EDIT_FROM_LIST_FILE_HEX_TMP:\=/%"

set "TRANSLATED_LIST_FILE_PATH=%LIST_FILE_PATH%"

set "NPP_START_BARE_FLAGS="

if %FLAG_USE_NPP_EXTRA_CMDLINE% NEQ 0 goto USE_NPP_EXTRA_CMDLINE

rem recreate empty list
type nul > "%EDIT_FROM_LIST_FILE_TMP%"

if %FLAG_COVERT_PATHS_TO_UNICODE_CODE_POINTS% EQU 0 goto IGNORE_CONVERT_TO_U16CP

set "TRANSLATED_LIST_FILE_PATH=%EDIT_FROM_LIST_FILE_U16CP_TMP%"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" certutil -encodehex "%%LIST_FILE_PATH%%" "%%EDIT_FROM_LIST_FILE_HEX_TMP%%"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CONTOOLS_ROOT%%/encoding/convert_hextbl_utf16le_to_u16cp.bat" "%%EDIT_FROM_LIST_FILE_HEX_TMP%%" "%%TRANSLATED_LIST_FILE_PATH%%"

:IGNORE_CONVERT_TO_U16CP

if %FLAG_COVERT_PATHS_TO_UTF8% EQU 0 goto IGNORE_CONVERT_TO_UTF8

set "TRANSLATED_LIST_FILE_PATH=%EDIT_FROM_LIST_FILE_UTF8_TMP%"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CONTOOLS_ROOT%%/encoding/convert_utf16le_to_utf8.bat" "%%LIST_FILE_PATH%%" "%%TRANSLATED_LIST_FILE_PATH%%"

:IGNORE_CONVERT_TO_UTF8

rem create Notepad++ only session file
(
  rem rem make UTF-8-BOM xml to enable open non english character files
  rem type "%CONTOOLS_ROOT%/encoding/boms\efbbbf.bin"
  echo;^<?xml version="1.0" encoding="utf-8"?^>
  echo;^<NotepadPlus^>
  echo;    ^<Session^>
  echo;        ^<mainView^>

  rem read selected file paths from file
  if %FLAG_COVERT_PATHS_TO_UNICODE_CODE_POINTS% EQU 0 (
    for /F "usebackq tokens=* delims="eol^= %%i in ("%TRANSLATED_LIST_FILE_PATH%") do (
      for /F "tokens=* delims="eol^= %%j in ("%%i\.") do echo;            ^<File filename="%%~fj" /^>
    )
  ) else for /F "usebackq tokens=* delims="eol^= %%i in ("%TRANSLATED_LIST_FILE_PATH%") do echo;            ^<File filename="%%~i" /^>

  echo;        ^</mainView^>
  echo;    ^</Session^>
  echo;^</NotepadPlus^>
) >> "%EDIT_FROM_LIST_FILE_TMP%"

set NPP_START_BARE_FLAGS=%NPP_START_BARE_FLAGS% /B

if %FLAG_WAIT_EXIT% NEQ 0 set NPP_START_BARE_FLAGS=%NPP_START_BARE_FLAGS% /WAIT

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start%%NPP_START_BARE_FLAGS%% "" "%%NPP_EDITOR%%"%%BARE_FLAGS%% -openSession "%%EDIT_FROM_LIST_FILE_TMP%%"

exit /b 0

:USE_NPP_EXTRA_CMDLINE

set "NPP_EXTRA_FLAGS="

if %FLAG_FILE_LIST_IN_UTF8% NEQ 0 (
  set NPP_EXTRA_FLAGS=%NPP_EXTRA_FLAGS% -z -from_utf8
) else if %FLAG_FILE_LIST_IN_UTF16% NEQ 0 (
  set NPP_EXTRA_FLAGS=%NPP_EXTRA_FLAGS% -z -from_utf16
) else if %FLAG_FILE_LIST_IN_UTF16LE% NEQ 0 (
  set NPP_EXTRA_FLAGS=%NPP_EXTRA_FLAGS% -z -from_utf16le
) else if %FLAG_FILE_LIST_IN_UTF16BE% NEQ 0 (
  set NPP_EXTRA_FLAGS=%NPP_EXTRA_FLAGS% -z -from_utf16be
)

if %FLAG_APPEND% NEQ 0 (
  set NPP_START_BARE_FLAGS=%NPP_START_BARE_FLAGS% /MIN
  rem `-z --child_cmdline_len_limit -z <limit>` exists for debug purposes
  rem use `-z -no_activate_after_append` to avoid window activation after append by default method
  rem use `-z -append_by_child_instance` for alternative method of append
  rem use `-z -no_exit_after_append` to leave the launcher instance
  set NPP_EXTRA_FLAGS=%NPP_EXTRA_FLAGS% -z -append -z -restore_if_open_inplace
)

set NPP_START_BARE_FLAGS=%NPP_START_BARE_FLAGS% /B

if %FLAG_WAIT_EXIT% NEQ 0 set NPP_START_BARE_FLAGS=%NPP_START_BARE_FLAGS% /WAIT

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start%%NPP_START_BARE_FLAGS%% "" "%%NPP_EDITOR%%"%%BARE_FLAGS%%%%NPP_EXTRA_FLAGS%% -z --open_from_file_list -z "%%TRANSLATED_LIST_FILE_PATH%%" -z --open_short_path_if_gt_limit -z 258

exit /b 0

:USE_BASIC_NOTEPAD

rem CAUTION: no limit to open files!
for /F "usebackq tokens=* delims="eol^= %%i in ("%LIST_FILE_PATH%") do (
  set "FILE_TO_EDIT=%%i"
  call :OPEN_BASIC_EDITOR
)

exit /b 0

:OPEN_BASIC_EDITOR
if not defined FILE_TO_EDIT exit /b 0

for /F "tokens=* delims="eol^= %%i in ("%FILE_TO_EDIT%\.") do set "FILE_TO_EDIT=%%~fi"

rem ignore a sub directory open, files in a sub directory must be selected explicitly in a panel!
if exist "\\?\%FILE_TO_EDIT%\*" exit /b

if %FLAG_WAIT_EXIT% NEQ 0 (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B /WAIT "" "%%BASIC_TEXT_EDITOR%%"%%BARE_FLAGS%% "%%FILE_TO_EDIT%%"
) else (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" start /B "" "%%BASIC_TEXT_EDITOR%%"%%BARE_FLAGS%% "%%FILE_TO_EDIT%%"
)

exit /b
