@echo off

setlocal

set "?~0=%~0"
set "?~f0=%~f0"
set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

call "%%?~dp0%%__init__.bat" || exit /b

for %%i in (PROJECT_ROOT PROJECT_LOG_ROOT PROJECT_CONFIG_ROOT CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

if %IMPL_MODE%0 NEQ 0 goto IMPL

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%/std/get_wmic_local_datetime.bat"
set "LOG_FILE_NAME_SUFFIX=%RETURN_VALUE:~0,4%'%RETURN_VALUE:~4,2%'%RETURN_VALUE:~6,2%_%RETURN_VALUE:~8,2%'%RETURN_VALUE:~10,2%'%RETURN_VALUE:~12,2%''%RETURN_VALUE:~15,3%"

set "PROJECT_LOG_DIR=%PROJECT_LOG_ROOT%/%LOG_FILE_NAME_SUFFIX%.%~n0"
set "PROJECT_LOG_FILE=%PROJECT_LOG_DIR%/%LOG_FILE_NAME_SUFFIX%.%~n0.log"

if not exist "%PROJECT_LOG_DIR%" ( mkdir "%PROJECT_LOG_DIR%" || exit /b )

set IMPL_MODE=1

rem CAUTION:
rem   We should avoid use handles 3 and 4 while the redirection has take a place because handles does reuse
rem   internally from left to right when being redirected externally.
rem   Example: if `1` is redirected, then `3` is internally reused, then if `2` redirected, then `4` is internally reused and so on.
rem   The discussion of the logic:
rem   https://stackoverflow.com/questions/9878007/why-doesnt-my-stderr-redirection-end-after-command-finishes-and-how-do-i-fix-i/9880156#9880156
rem   A partial analisis:
rem   https://www.dostips.com/forum/viewtopic.php?p=14612#p14612
rem

if %CONEMU_ENABLE%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "attach" %CONEMU_CMDLINE_ATTACH_PREFIX%
if %CONEMU_ENABLE%0 NEQ 0 if /i "%CONEMU_INTERACT_MODE%" == "run" (
  %CONEMU_CMDLINE_RUN_PREFIX% "%COMSPEC%" /C call "%?~f0%" %* -cur_console:n 2^>^&1 ^| "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
  exit /b
)
"%COMSPEC%" /C call "%?~f0%" %* 2>&1 | "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
exit /b

:IMPL
rem script flags
set FLAG_PAUSE_ON_EXIT=0
set FLAG_PAUSE_ON_ERROR=0
set FLAG_PAUSE_TIMEOUT_SEC=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || (
  echo.%?~nx0%: error: could not allocate temporary directory: "%SCRIPT_TEMP_CURRENT_DIR%"
  exit /b 255
) >&2

rem redirect command line into temporary file to print it correcly
setlocal
for %%i in (1) do (
    set "PROMPT=$_"
    echo on
    for %%b in (1) do rem * #%*#
    @echo off
) > "%SCRIPT_TEMP_CURRENT_DIR%\cmdline.txt"
endlocal

for /F "usebackq eol= tokens=* delims=" %%i in ("%SCRIPT_TEMP_CURRENT_DIR%\cmdline.txt") do set "CMDLINE_STR=%%i"
setlocal ENABLEDELAYEDEXPANSION
set "CMDLINE_STR=!CMDLINE_STR:*#=!"
set "CMDLINE_STR=!CMDLINE_STR:~0,-2!"
set CMDLINE_STR=^>%0 !CMDLINE_STR!
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" CMDLINE_STR
echo.
endlocal

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

:EXIT_MAIN
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

if %FLAG_PAUSE_ON_EXIT% NEQ 0 (
  if %FLAG_PAUSE_TIMEOUT_SEC% NEQ 0 (
    timeout /T %FLAG_PAUSE_TIMEOUT_SEC%
  ) else if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/pause.bat" -chcp "%%OEMCP%%" ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"
) else if %LASTERROR% NEQ 0 if %FLAG_PAUSE_ON_ERROR% NEQ 0 (
  if %FLAG_PAUSE_TIMEOUT_SEC% NEQ 0 (
    timeout /T %FLAG_PAUSE_TIMEOUT_SEC%
  ) else if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/pause.bat" -chcp "%%OEMCP%%" ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"
)

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
  ) else if "%FLAG%" == "-pause_on_exit" (
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

if defined CWD ( for /F "eol= tokens=* delims=" %%i in ("%CWD%\.") do set "CWD=%%~fi" ) else goto NOCWD
if exist "\\?\%CWD%" if exist "%CWD%" ( cd /d "%CWD%" || exit /b 1 )

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %CD%") do title %%i

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
