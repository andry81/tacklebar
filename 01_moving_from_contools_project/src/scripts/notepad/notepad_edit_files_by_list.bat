@echo off

setlocal

set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

call "%%?~dp0%%__init__.bat" || exit /b

rem script flags
set FLAG_PAUSE_ON_EXIT=0
set FLAG_PAUSE_ON_ERROR=0
set FLAG_PAUSE_TIMEOUT_SEC=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%"

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

:EXIT_MAIN
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

if %FLAG_PAUSE_ON_EXIT% NEQ 0 (
  if %FLAG_PAUSE_TIMEOUT_SEC% NEQ 0 (
    timeout /T %FLAG_PAUSE_TIMEOUT_SEC%
  ) else pause
) else if %LASTERROR% NEQ 0 if %FLAG_PAUSE_ON_ERROR% NEQ 0 (
  if %FLAG_PAUSE_TIMEOUT_SEC% NEQ 0 (
    timeout /T %FLAG_PAUSE_TIMEOUT_SEC%
  ) else pause
)

exit /b %LASTERROR%

:MAIN
rem script flags
set FLAG_WAIT_EXIT=0
set FLAG_NOTEPADPLUSPLUS=0
set FLAG_COVERT_PATHS_TO_UNICODE_CODE_POINTS=0
set FLAG_COVERT_PATHS_TO_UTF8=0
set "BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-pause_on_exit" (
    set FLAG_PAUSE_ON_EXIT=1
  ) else if "%FLAG%" == "-pause_on_error" (
    set FLAG_PAUSE_ON_ERROR=1
  ) else if "%FLAG%" == "-pause_timeout_sec" (
    set "FLAG_PAUSE_TIMEOUT_SEC=%~2"
    shift
  ) else if "%FLAG%" == "-wait" (
    set FLAG_WAIT_EXIT=1
  ) else if "%FLAG%" == "-npp" (
    set FLAG_NOTEPADPLUSPLUS=1
  ) else if "%FLAG%" == "-paths_to_u16cp" (
    set FLAG_COVERT_PATHS_TO_UNICODE_CODE_POINTS=1
  ) else if "%FLAG%" == "-paths_to_utf8" (
    set FLAG_COVERT_PATHS_TO_UTF8=1
  ) else (
    set BARE_FLAGS=%BARE_FLAGS% %1
  )

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "CWD=%~1"
shift

if not defined CWD goto NOCWD
cd /d "%CWD%" || exit /b 1

:NOCWD

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

if %FLAG_COVERT_PATHS_TO_UNICODE_CODE_POINTS% EQU 0 goto IGNORE_CONVERT_TO_U16CP

set "TRANSLATED_LIST_FILE_PATH=%EDIT_FROM_LIST_FILE_U16CP_TMP%"

call :CMD certutil -encodehex "%%LIST_FILE_PATH%%" "%%EDIT_FROM_LIST_FILE_HEX_TMP%%"

call :CMD "%%CONTOOLS_ROOT%%/encoding/convert_hextbl_utf16le_to_u16cp.bat" "%%EDIT_FROM_LIST_FILE_HEX_TMP%%" "%%TRANSLATED_LIST_FILE_PATH%%"

:IGNORE_CONVERT_TO_U16CP

if %FLAG_COVERT_PATHS_TO_UTF8% EQU 0 goto IGNORE_CONVERT_TO_UTF8

set "TRANSLATED_LIST_FILE_PATH=%EDIT_FROM_LIST_FILE_UTF8_TMP%"

call :CMD "%%CONTOOLS_ROOT%%/encoding/convert_utf16le_to_utf8.bat" "%%LIST_FILE_PATH%%" "%%TRANSLATED_LIST_FILE_PATH%%"

:IGNORE_CONVERT_TO_UTF8

rem call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%CHCP%%
rem set RESTORE_LOCALE=1

rem create Notepad++ only session file
(
  rem rem make UTF-8-BOM xml to enable open non english character files
  rem type "%CONTOOLS_ROOT%/encoding/boms\efbbbf.bin"
  echo.^<?xml version="1.0" encoding="utf-8"?^>
  echo.^<NotepadPlus^>
  echo.    ^<Session^>
  echo.        ^<mainView^>

  rem read selected file paths from file
  for /F "usebackq eol= tokens=* delims=" %%i in ("%TRANSLATED_LIST_FILE_PATH%") do (
    rem ignore a sub directory open, files in a sub directory must be selected explicitly in a panel!
    if not exist "%%i\" echo.            ^<File filename="%%i" /^>
  )

  echo.        ^</mainView^>
  echo.    ^</Session^>
  echo.^</NotepadPlus^>
) >> "%EDIT_FROM_LIST_FILE_TMP%"

rem restore locale
rem if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

if %FLAG_WAIT_EXIT% NEQ 0 (
  call :CMD start /B /WAIT "" "%%NPP_EDITOR%%"%%BARE_FLAGS%% -openSession "%%EDIT_FROM_LIST_FILE_TMP%%"
) else (
  call :CMD start /B "" "%%NPP_EDITOR%%"%%BARE_FLAGS%% -openSession "%%EDIT_FROM_LIST_FILE_TMP%%"
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

rem ignore a sub directory open, files in a sub directory must be selected explicitly in a panel!
if exist "%FILE_TO_EDIT%\" exit /b

if %FLAG_WAIT_EXIT% NEQ 0 (
  call :CMD start /B /WAIT "" "%%BASIC_TEXT_EDITOR%%"%%BARE_FLAGS%% "%%FILE_TO_EDIT%%"
) else (
  call :CMD start /B "" "%%BASIC_TEXT_EDITOR%%"%%BARE_FLAGS%% "%%FILE_TO_EDIT%%"
)

exit /b

:CMD
echo.^>%*
(%*)
