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
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LASTERROR%

:MAIN
rem script flags
set "FLAG_CHCP="
set FLAG_WAIT_EXIT=0
set FLAG_NOTEPADPLUSPLUS=0
set FLAG_USE_NPP_EXTRA_CMDLINE=0
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
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

set "LIST_FILE_PATH=%~1"

if not defined LIST_FILE_PATH exit /b 0

set "LIST_FILE_PATH=%LIST_FILE_PATH:\=/%"

if %FLAG_NOTEPADPLUSPLUS% EQU 0 goto USE_BASIC_NOTEPAD

set "EDIT_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\edit_from_file_list.xml"
set "EDIT_FROM_LIST_FILE_HEX_TMP=%SCRIPT_TEMP_CURRENT_DIR%\edit_from_file_list.hex.bin"
set "EDIT_FROM_LIST_FILE_U16CP_TMP=%SCRIPT_TEMP_CURRENT_DIR%\edit_from_file_list.u16cp.lst"
set "EDIT_FROM_LIST_FILE_UTF8_TMP=%SCRIPT_TEMP_CURRENT_DIR%\edit_from_file_list.utf8.lst"

set "EDIT_FROM_LIST_FILE_HEX_TMP=%EDIT_FROM_LIST_FILE_HEX_TMP:\=/%"

rem recreate empty list
type nul > "%EDIT_FROM_LIST_FILE_TMP%"

set "TRANSLATED_LIST_FILE_PATH=%LIST_FILE_PATH%"

if %FLAG_USE_NPP_EXTRA_CMDLINE% NEQ 0 goto USE_NPP_EXTRA_CMDLINE

if %FLAG_COVERT_PATHS_TO_UNICODE_CODE_POINTS% EQU 0 goto IGNORE_CONVERT_TO_U16CP

set "TRANSLATED_LIST_FILE_PATH=%EDIT_FROM_LIST_FILE_U16CP_TMP%"

call :CMD certutil -encodehex "%%LIST_FILE_PATH%%" "%%EDIT_FROM_LIST_FILE_HEX_TMP%%"

call :CMD "%%CONTOOLS_ROOT%%/encoding/convert_hextbl_utf16le_to_u16cp.bat" "%%EDIT_FROM_LIST_FILE_HEX_TMP%%" "%%TRANSLATED_LIST_FILE_PATH%%"

:IGNORE_CONVERT_TO_U16CP

if %FLAG_COVERT_PATHS_TO_UTF8% EQU 0 goto IGNORE_CONVERT_TO_UTF8

set "TRANSLATED_LIST_FILE_PATH=%EDIT_FROM_LIST_FILE_UTF8_TMP%"

call :CMD "%%CONTOOLS_ROOT%%/encoding/convert_utf16le_to_utf8.bat" "%%LIST_FILE_PATH%%" "%%TRANSLATED_LIST_FILE_PATH%%"

:IGNORE_CONVERT_TO_UTF8

if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%FLAG_CHCP%%

rem create Notepad++ only session file
(
  rem rem make UTF-8-BOM xml to enable open non english character files
  rem type "%CONTOOLS_ROOT%/encoding/boms\efbbbf.bin"
  echo.^<?xml version="1.0" encoding="utf-8"?^>
  echo.^<NotepadPlus^>
  echo.    ^<Session^>
  echo.        ^<mainView^>

  rem read selected file paths from file
  if %FLAG_COVERT_PATHS_TO_UNICODE_CODE_POINTS% EQU 0 (
    for /F "usebackq eol= tokens=* delims=" %%i in ("%TRANSLATED_LIST_FILE_PATH%") do (
      for /F "eol= tokens=* delims=" %%j in ("%%i\.") do echo.            ^<File filename="%%~fj" /^>
    )
  ) else for /F "usebackq eol= tokens=* delims=" %%i in ("%TRANSLATED_LIST_FILE_PATH%") do echo.            ^<File filename="%%~i" /^>

  echo.        ^</mainView^>
  echo.    ^</Session^>
  echo.^</NotepadPlus^>
) >> "%EDIT_FROM_LIST_FILE_TMP%"

rem restore locale
if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

if %FLAG_WAIT_EXIT% NEQ 0 (
  call :CMD start /B /WAIT "" "%%NPP_EDITOR%%"%%BARE_FLAGS%% -openSession "%%EDIT_FROM_LIST_FILE_TMP%%"
) else (
  call :CMD start /B "" "%%NPP_EDITOR%%"%%BARE_FLAGS%% -openSession "%%EDIT_FROM_LIST_FILE_TMP%%"
)

exit /b 0

:USE_NPP_EXTRA_CMDLINE

set "NPP_EXTRA_FLAGS="

if %FLAG_FILE_LIST_IN_UTF8% NEQ 0 (
  set "NPP_EXTRA_FLAGS=%NPP_EXTRA_FLAGS% -z -from_utf8"
) else if %FLAG_FILE_LIST_IN_UTF16% NEQ 0 (
  set "NPP_EXTRA_FLAGS=%NPP_EXTRA_FLAGS% -z -from_utf16"
) else if %FLAG_FILE_LIST_IN_UTF16LE% NEQ 0 (
  set "NPP_EXTRA_FLAGS=%NPP_EXTRA_FLAGS% -z -from_utf16le"
) else if %FLAG_FILE_LIST_IN_UTF16BE% NEQ 0 (
  set "NPP_EXTRA_FLAGS=%NPP_EXTRA_FLAGS% -z -from_utf16be"
)

if %FLAG_WAIT_EXIT% NEQ 0 (
  call :CMD start /B /WAIT "" "%%NPP_EDITOR%%"%%BARE_FLAGS%% -openSession%%NPP_EXTRA_FLAGS%% -z --open_from_file_list -z "%%TRANSLATED_LIST_FILE_PATH%%"
) else (
  call :CMD start /B "" "%%NPP_EDITOR%%"%%BARE_FLAGS%% -openSession%%NPP_EXTRA_FLAGS%% -z --open_from_file_list -z "%%TRANSLATED_LIST_FILE_PATH%%"
)

exit /b 0

:USE_BASIC_NOTEPAD

rem CAUTION: no limit to open files!
for /F "usebackq eol= tokens=* delims=" %%i in ("%LIST_FILE_PATH%") do (
  set "FILE_TO_EDIT=%%i"
  call :OPEN_BASIC_EDITOR
)

exit /b 0

:OPEN_BASIC_EDITOR
if not defined FILE_TO_EDIT exit /b 0

for /F "eol= tokens=* delims=" %%i in ("%FILE_TO_EDIT%\.") do set "FILE_TO_EDIT=%%~fi"

rem ignore a sub directory open, files in a sub directory must be selected explicitly in a panel!
if exist "\\?\%FILE_TO_EDIT%\" exit /b

if %FLAG_WAIT_EXIT% NEQ 0 (
  call :CMD start /B /WAIT "" "%%BASIC_TEXT_EDITOR%%"%%BARE_FLAGS%% "%%FILE_TO_EDIT%%"
) else (
  call :CMD start /B "" "%%BASIC_TEXT_EDITOR%%"%%BARE_FLAGS%% "%%FILE_TO_EDIT%%"
)

exit /b

:CMD
echo.^>%*
(%*)
