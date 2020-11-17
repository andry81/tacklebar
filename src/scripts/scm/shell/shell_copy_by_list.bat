@echo off

setlocal

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

rem no local logging if nested call
set WITH_LOGGING=0
if %NEST_LVL%0 EQU 0 set WITH_LOGGING=1

if %WITH_LOGGING% EQU 0 goto IMPL

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
"%COMSPEC%" /C call %0 %* 2>&1 | "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
exit /b

:IMPL
rem script flags
set FLAG_PAUSE_ON_EXIT=0
set FLAG_PAUSE_ON_ERROR=0
set FLAG_PAUSE_TIMEOUT_SEC=0
set RESTORE_LOCALE=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%"

rem redirect command line into temporary file to print it correcly
setlocal
for %%i in (1) do (
    set "PROMPT=$_"
    echo on
    for %%b in (1) do rem * #%*#
    @echo off
) > "%SCRIPT_TEMP_CURRENT_DIR%\cmdline.txt"
endlocal

for /F "usebackq eol= tokens=* delims=" %%i in ("%SCRIPT_TEMP_CURRENT_DIR%\cmdline.txt") do ( set "CMDLINE_STR=%%i" )
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
rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

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
set FLAG_CONVERT_FROM_UTF16=0
set FLAG_USE_ONLY_UNIQUE_PATHS=0
set FLAG_USE_SHELL_BATCMD_COPY=0
set FLAG_USE_SHELL_MSYS_COPY=0
set FLAG_USE_SHELL_CYGWIN_COPY=0
set "FLAG_CHCP="

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
  ) else if "%FLAG%" == "-from_utf16" (
    set FLAG_CONVERT_FROM_UTF16=1
  ) else if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else if "%FLAG%" == "-use_only_unique_paths" (
    set FLAG_USE_ONLY_UNIQUE_PATHS=1
  ) else if "%FLAG%" == "-use_shell_batcmd_copy" (
    set FLAG_USE_SHELL_BATCMD_COPY=1
  ) else if "%FLAG%" == "-use_shell_msys_copy" (
    set FLAG_USE_SHELL_MSYS_COPY=1
  ) else if "%FLAG%" == "-use_shell_cygwin_copy" (
    set FLAG_USE_SHELL_CYGWIN_COPY=1
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

if not defined CWD goto NOCWD
cd /d "%CWD%" || exit /b 1

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %CD%") do title %%i

:NOCWD
if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 if defined MSYS_ROOT if exist "%MSYS_ROOT%\" goto MSYS_OK

(
  echo.%?~nx0%: error: `MSYS_ROOT` variable is not defined or not exist: "%MSYS_ROOT%".
  exit /b 255
) >&2

if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 if defined CYGWIN_ROOT if exist "%CYGWIN_ROOT%\" goto CYGWIN_OK

(
  echo.%?~nx0%: error: `CYGWIN_ROOT` variable is not defined or not exist: "%CYGWIN_ROOT%".
  exit /b 255
) >&2

:MSYS_OK
:CYGWIN_OK
set "LIST_FILE_PATH=%~1"
set "OPTIONAL_DEST_DIR=%~2"

if not defined LIST_FILE_PATH exit /b 0

set "INPUT_LIST_FILE_NAME_TMP=input_file_list_utf_8.lst"
set "INPUT_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%INPUT_LIST_FILE_NAME_TMP%"

set "REVERSED_INPUT_LIST_FILE_NAME_TMP=reveresed_input_file_list_utf_8.lst"
set "REVERSED_INPUT_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%REVERSED_INPUT_LIST_FILE_NAME_TMP%"

set "REVERESED_UNIQUE_LIST_FILE_NAME_TMP=reversed_unique_file_list_utf_8.lst"
set "REVERESED_UNIQUE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%REVERESED_UNIQUE_LIST_FILE_NAME_TMP%"

set "UNIQUE_LIST_FILE_NAME_TMP=unique_file_list_utf_8.lst"
set "UNIQUE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%UNIQUE_LIST_FILE_NAME_TMP%"

set "COPY_FROM_LIST_FILE_NAME_TMP=copy_from_file_list.lst"

set "COPY_TO_LIST_FILE_NAME_TMP=copy_to_file_list.lst"
set "COPY_TO_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%COPY_TO_LIST_FILE_NAME_TMP%"

set "LOCAL_LIST_FILE_NAME_TMP=local_file_list.lst"
set "LOCAL_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%LOCAL_LIST_FILE_NAME_TMP%"

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem to convert from unicode
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" 65001
  set RESTORE_LOCALE=1
) else if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
)

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
  rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
  rem
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%INPUT_LIST_FILE_TMP%"
) else (
  set "INPUT_LIST_FILE_TMP=%LIST_FILE_PATH%"
)

call :COPY_FILE "%%INPUT_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%INPUT_LIST_FILE_NAME_TMP%%"

if %FLAG_USE_ONLY_UNIQUE_PATHS% EQU 0 goto IGNORE_FILTER_UNIQUE_PATHS

sort /R "%INPUT_LIST_FILE_TMP%" /O "%REVERSED_INPUT_LIST_FILE_TMP%"

call :COPY_FILE "%%REVERSED_INPUT_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%REVERSED_INPUT_LIST_FILE_NAME_TMP%%"

rem recreate empty list
type nul > "%REVERESED_UNIQUE_LIST_FILE_TMP%"

set "PREV_FILE_PATH="
for /F "usebackq tokens=* delims= eol=#" %%i in ("%REVERSED_INPUT_LIST_FILE_TMP%") do (
  set "FILE_PATH=%%i"
  call :FILTER_UNIQUE_PATHS
  set "PREV_FILE_PATH=%%i"
)

call :COPY_FILE "%%REVERESED_UNIQUE_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%REVERESED_UNIQUE_LIST_FILE_NAME_TMP%%"

goto FILTER_UNIQUE_PATHS_END

:COPY_FILE
echo."%~1" -^> "%~2"
if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 (
  "%MSYS_ROOT%/bin/cp.exe" "%~f1" "%~f2" || exit /b
) else if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 (
  "%CYGWIN_ROOT%/bin/cp.exe" "%~f1" "%~f2" || exit /b
) else copy "%~f1" "%~f2" /B /Y || exit /b
exit /b 0

:FILTER_UNIQUE_PATHS
if defined PREV_FILE_PATH goto CONTINUE_FILTER_UNIQUE_PATHS_1

if /i "%FILE_PATH%" == "%PREV_FILE_PATH%" exit /b 0

setlocal ENABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("!FILE_PATH!") do for /F "tokens=* delims=" %%j in ("%%i") do ( endlocal & (echo.%%j) >> "%REVERESED_UNIQUE_LIST_FILE_TMP%" )
exit /b 0

:CONTINUE_FILTER_UNIQUE_PATHS_1

rem calculate file path string length
setlocal ENABLEDELAYEDEXPANSION
set "FILE_PATH_TMP=%FILE_PATH%"
set FILE_PATH_LEN=0
for %%i in (65536 32768 16384 8192 4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do if not "!FILE_PATH_TMP:~%%i,1!" == "" ( set /A "FILE_PATH_LEN+=%%i" & set "FILE_PATH_TMP=!FILE_PATH_TMP:~%%i!" )
set /A FILE_PATH_LEN+=1

for %%i in (%FILE_PATH_LEN%) do if not "!PREV_FILE_PATH:~%%i,1!" == "" goto CONTINUE_FILTER_UNIQUE_PATHS_2

for /F "eol= tokens=* delims=" %%i in ("!FILE_PATH!") do for /F "tokens=* delims=" %%j in ("%%i") do ( endlocal & (echo.%%j) >> "%REVERESED_UNIQUE_LIST_FILE_TMP%" )
exit /b 0

:CONTINUE_FILTER_UNIQUE_PATHS_2
(
  endlocal
  set "FILE_PATH_LEN=%FILE_PATH_LEN%"
)

if not "%FILE_PATH:~-1%" == "\" (
  set "FILE_PATH_SUFFIX=%FILE_PATH%\"
  set /A FILE_PATH_LEN+=1
) else set "FILE_PATH_SUFFIX=%FILE_PATH%"

call set "PREV_FILE_PATH_PREFIX=%%PREV_FILE_PATH:~0,%FILE_PATH_LEN%%%"

if /i "%PREV_FILE_PATH_PREFIX%" == "%FILE_PATH_SUFFIX%" exit /b 0

setlocal ENABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("!FILE_PATH!") do for /F "tokens=* delims=" %%j in ("%%i") do ( endlocal & (echo.%%j) >> "%REVERESED_UNIQUE_LIST_FILE_TMP%" )

exit /b 0

:FILTER_UNIQUE_PATHS_END

sort /R "%REVERESED_UNIQUE_LIST_FILE_TMP%" /O "%UNIQUE_LIST_FILE_TMP%"

call :COPY_FILE "%%UNIQUE_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%UNIQUE_LIST_FILE_NAME_TMP%%"

set "INPUT_LIST_FILE_TMP=%UNIQUE_LIST_FILE_TMP%"

:IGNORE_FILTER_UNIQUE_PATHS

echo.* Generating editable copy list...

rem recreate empty list
type nul > "%COPY_TO_LIST_FILE_TMP%"

if defined OPTIONAL_DEST_DIR (echo.# dest: "%OPTIONAL_DEST_DIR%") >> "%COPY_TO_LIST_FILE_TMP%"

rem read selected file paths from file
for /F "usebackq tokens=* delims= eol=#" %%i in ("%INPUT_LIST_FILE_TMP%") do ( set "FILE_PATH=%%i" & call :FILL_TO_LIST_FILE_TMP )
goto FILL_TO_LIST_FILE_TMP_END

:COPY_FILE
echo."%~1" -^> "%~2"
if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 (
  "%MSYS_ROOT%/bin/cp.exe" "%~f1" "%~f2" || exit /b
) else if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 (
  "%CYGWIN_ROOT%/bin/cp.exe" "%~f1" "%~f2" || exit /b
) else copy "%~f1" "%~f2" /B /Y || exit /b
exit /b 0

:FILL_TO_LIST_FILE_TMP
rem avoid any quote characters
set "FILE_PATH=%FILE_PATH:"=%"

rem always remove trailing slash character
if "%FILE_PATH:~-1%" == "\" set "FILE_PATH=%FILE_PATH:~0,-1%"

call :GET_FILE_PATH_COMPONENTS PARENT_DIR FILE_NAME "%%FILE_PATH%%"

for /F "eol= tokens=* delims=" %%i in ("%PARENT_DIR%|%FILE_NAME%") do ( (echo.%%i) >> "%COPY_TO_LIST_FILE_TMP%" )
exit /b 0

:FILL_TO_LIST_FILE_TMP_END
call :COPY_FILE "%%COPY_TO_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%COPY_FROM_LIST_FILE_NAME_TMP%%"
call :COPY_FILE "%%COPY_TO_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%COPY_TO_LIST_FILE_NAME_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar "" "%%PROJECT_LOG_DIR%%/%%COPY_TO_LIST_FILE_NAME_TMP%%"

call :COPY_FILE "%%PROJECT_LOG_DIR%%/%%COPY_TO_LIST_FILE_NAME_TMP%%" "%%COPY_TO_LIST_FILE_TMP%%"

rem trick with simultaneous iteration over 2 list in the same time
(
  for /F "usebackq eol= tokens=* delims=" %%i in ("%COPY_TO_LIST_FILE_TMP%") do (
    set IS_LINE_EMPTY=1
    for /F "eol=# tokens=1,* delims=|" %%k in ("%%i") do set "IS_LINE_EMPTY="
    if defined IS_LINE_EMPTY (
      for /F "eol=# tokens=1,* delims=|" %%k in ("%%i") do if not "%%k" == "" if not "%%l" == "" set /P "FROM_FILE_PATH="
    ) else (
      set /P "FROM_FILE_PATH="
      set "TO_FILE_PATH=%%i"
      call :PROCESS_COPY
    )
  )
) < "%INPUT_LIST_FILE_TMP%"

exit /b

:COPY_FILE
echo."%~1" -^> "%~2"
if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 (
  "%MSYS_ROOT%/bin/cp.exe" "%~f1" "%~f2" || exit /b
) else if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 (
  "%CYGWIN_ROOT%/bin/cp.exe" "%~f1" "%~f2" || exit /b
) else copy "%~f1" "%~f2" /B /Y || exit /b
exit /b 0

:PROCESS_COPY
if not defined FROM_FILE_PATH exit /b 2
if not defined TO_FILE_PATH exit /b 3

set "FROM_FILE_PATH=%FROM_FILE_PATH:/=\%"
set "TO_FILE_PATH=%TO_FILE_PATH:/=\%"

rem always remove trailing slash character
if "%FROM_FILE_PATH:~-1%" == "\" set "FROM_FILE_PATH=%FROM_FILE_PATH:~0,-1%"
if "%TO_FILE_PATH:~-1%" == "\" set "TO_FILE_PATH=%TO_FILE_PATH:~0,-1%"

for /F "eol= tokens=* delims=" %%i in ("%FROM_FILE_PATH%") do set "FROM_FILE_PATH=%%~fi"

rem extract destination path components
for /F "eol= tokens=1,* delims=|" %%i in ("%TO_FILE_PATH%") do ( set "TO_FILE_DIR=%%i" &  set "TO_FILE_NAME=%%j" )

rem concatenate
set "TO_FILE_PATH=%TO_FILE_PATH:|=%"

for /F "eol= tokens=* delims=" %%i in ("%TO_FILE_PATH%") do set "TO_FILE_PATH=%%~fi"

rem file being copied to itself
if /i "%FROM_FILE_PATH%" == "%TO_FILE_PATH%" exit /b 0

if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 goto PROCESS_SHELL_MSYS_COPY
if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 goto PROCESS_SHELL_CYGWIN_COPY

if not exist "\\?\%FROM_FILE_PATH%" (
  echo.%?~n0%: error: FROM_FILE_PATH is not found: "%FROM_FILE_PATH%".
  exit /b 4
) >&2

rem check recursion only if FROM_FILE_PATH is a directory
set FROM_FILE_PATH_AS_DIR=0
if not exist "\\?\%FROM_FILE_PATH%\" goto IGNORE_TO_FILE_PATH_CHECK
set FROM_FILE_PATH_AS_DIR=1

call "%%CONTOOLS_ROOT%%/filesys/subtract_path.bat" "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%"
if %ERRORLEVEL% EQU 0 (
  echo.%?~n0%: error: TO_FILE_PATH file path must not contain FROM_FILE_PATH file path: FROM_FILE_PATH="%FROM_FILE_PATH%" TO_FILE_PATH="%TO_FILE_PATH%".
  exit /b 5
) >&2

:IGNORE_TO_FILE_PATH_CHECK

call :GET_FILE_PATH_COMPONENTS FROM_FILE_DIR FROM_FILE_NAME "%%FROM_FILE_PATH%%"

if "%FROM_FILE_PATH:~-1%" == "\" set "FROM_FILE_PATH=%FROM_FILE_PATH:~0,-1%"
if "%FROM_FILE_DIR:~-1%" == "\" set "FROM_FILE_DIR=%FROM_FILE_DIR:~0,-1%"

if "%TO_FILE_DIR:~-1%" == "\" set "TO_FILE_DIR=%TO_FILE_DIR:~0,-1%"

if %FLAG_USE_SHELL_BATCMD_COPY% NEQ 0 goto PROCESS_SHELL_BATCMD_COPY

:PROCESS_XCOPY
if %FROM_FILE_PATH_AS_DIR% EQU 0 (
  call :XCOPY_FILE "%%FROM_FILE_DIR%%" "%%FROM_FILE_NAME%%" "%%TO_FILE_DIR%%" /Y /D /H || exit /b
) else (
  call :XCOPY_DIR "%%FROM_FILE_PATH%%" "%%TO_FILE_DIR%%\%%TO_FILE_NAME%%" /E /Y /D || exit /b
)
exit /b 0

:PROCESS_SHELL_BATCMD_COPY
if %FROM_FILE_PATH_AS_DIR% NEQ 0 goto PROCESS_SHELL_BATCMD_COPY_DIR
call :SHELL_BATCMD_COPY_FILE_W_MKDIR "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || exit /b
exit /b 0

:PROCESS_SHELL_BATCMD_COPY_DIR
if not exist "\\?\%TO_FILE_PATH%" ( (echo.^>mkdir "%TO_FILE_PATH%") & mkdir "%TO_FILE_PATH%" )
dir "%FROM_FILE_PATH%" /A:D /B /O:N 2>nul > "%LOCAL_LIST_FILE_TMP%"
for /F "usebackq eol= tokens=* delims=" %%i in ("%LOCAL_LIST_FILE_TMP%") do if not exist "\\?\%TO_FILE_PATH%\%%i" ( (echo.^>mkdir "%TO_FILE_PATH%\%%i") & mkdir "%TO_FILE_PATH%\%%i" )

dir "%FROM_FILE_PATH%" /A:-D /B /O:N 2>nul > "%LOCAL_LIST_FILE_TMP%"
for /F "usebackq eol= tokens=* delims=" %%i in ("%LOCAL_LIST_FILE_TMP%") do ( set "FILE_NAME=%%i" & call :SHELL_BATCMD_COPY_FILE_W_MKDIR "%%FROM_FILE_PATH%%\%%FILE_NAME%%" "%%TO_FILE_PATH%%\%%FILE_NAME%%" )
exit /b 0

:PROCESS_XCOPY
if %FROM_FILE_PATH_AS_DIR% EQU 0 (
  call :XCOPY_FILE "%%FROM_FILE_DIR%%" "%%FROM_FILE_NAME%%" "%%TO_FILE_DIR%%" /Y /D /H || exit /b
) else (
  call :XCOPY_DIR "%%FROM_FILE_PATH%%" "%%TO_FILE_DIR%%\%%TO_FILE_NAME%%" /E /Y /D || exit /b
)
exit /b 0

:PROCESS_SHELL_MSYS_COPY
:PROCESS_SHELL_CYGWIN_COPY
call :COPY_FILE "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || exit /b
exit /b 0

:SHELL_BATCMD_COPY_FILE_W_MKDIR
echo."%~1" -^> "%~2"
if not exist "\\?\%~dp2" mkdir "%~dp2"
copy "%~f1" "%~f2" /B /Y || exit /b
exit /b 0

:COPY_FILE
echo."%~1" -^> "%~2"
if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 (
  if not exist "\\?\%~dp2" "%MSYS_ROOT%/bin/mkdir.exe" "%~2"
  "%MSYS_ROOT%/bin/cp.exe" "%~f1" "%~f2" || exit /b
) else if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 (
  if not exist "\\?\%~dp2" "%CYGWIN_ROOT%/bin/mkdir.exe" "%~2"
  "%CYGWIN_ROOT%/bin/cp.exe" "%~f1" "%~f2" || exit /b
) else (
  if not exist "\\?\%~dp2" mkdir "%~2"
  copy "%~f1" "%~f2" /B /Y || exit /b
)
exit /b 0

:XCOPY_FILE
if not exist "\\?\%~3" mkdir "%~3"
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" %%* || exit /b
exit /b 0

:XCOPY_DIR
if not exist "\\?\%~2" mkdir "%~2"
call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat" %%* || exit /b
exit /b 0

:GET_FILE_PATH_COMPONENTS
set "%~1=%~dp3"
set "%~2=%~nx3"
exit /b 0
