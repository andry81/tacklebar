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
if %CONEMU_ENABLE%0 NEQ 0 %CONEMU_CMDLINE_RUN_PREFIX% "%COMSPEC%" /C call %0 %* -cur_console:n 2^>^&1 ^| "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
if %CONEMU_ENABLE%0 EQU 0 "%COMSPEC%" /C call %0 %* 2>&1 | "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
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
rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

if %FLAG_PAUSE_ON_EXIT% NEQ 0 (
  if %FLAG_PAUSE_TIMEOUT_SEC% NEQ 0 (
    timeout /T %FLAG_PAUSE_TIMEOUT_SEC%
  ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"
) else if %LASTERROR% NEQ 0 if %FLAG_PAUSE_ON_ERROR% NEQ 0 (
  if %FLAG_PAUSE_TIMEOUT_SEC% NEQ 0 (
    timeout /T %FLAG_PAUSE_TIMEOUT_SEC%
  ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"
)

exit /b %LASTERROR%

:MAIN
rem script flags
set FLAG_CONVERT_FROM_UTF16=0
set FLAG_CONVERT_FROM_UTF16LE=0
set FLAG_CONVERT_FROM_UTF16BE=0
set FLAG_USE_ONLY_UNIQUE_PATHS=0
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
  ) else if "%FLAG%" == "-from_utf16le" (
    set FLAG_CONVERT_FROM_UTF16LE=1
  ) else if "%FLAG%" == "-from_utf16be" (
    set FLAG_CONVERT_FROM_UTF16BE=1
  ) else if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else if "%FLAG%" == "-use_only_unique_paths" (
    set FLAG_USE_ONLY_UNIQUE_PATHS=1
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

if defined CWD ( for /F "eol= tokens=* delims=" %%i in ("%CWD%\.") do set "CWD=%%~fi" ) else goto NOCWD
if exist "\\?\%CWD%" if exist "%CWD%" ( cd /d "%CWD%" || exit /b 1 )

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %CD%") do title %%i

:NOCWD
if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 if defined MSYS_ROOT if exist "%MSYS_ROOT%\bin\" goto MSYS_OK
if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 (
  echo.%?~nx0%: error: `MSYS_ROOT` variable is not defined or not valid: "%MSYS_ROOT%".
  exit /b 255
) >&2

if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 if defined CYGWIN_ROOT if exist "%CYGWIN_ROOT%\bin\" goto CYGWIN_OK
if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 (
  echo.%?~nx0%: error: `CYGWIN_ROOT` variable is not defined or not valid: "%CYGWIN_ROOT%".
  exit /b 255
) >&2

:MSYS_OK
:CYGWIN_OK
set "LIST_FILE_PATH=%~1"
set "OPTIONAL_DEST_DIR=%~2"

if not defined LIST_FILE_PATH exit /b 0

set "COPY_FROM_LIST_FILE_NAME_TMP=copy_from_file_list.lst"
set "COPY_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%COPY_FROM_LIST_FILE_NAME_TMP%"

set "REVERSED_INPUT_LIST_FILE_NAME_TMP=reveresed_input_file_list.lst"
set "REVERSED_INPUT_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%REVERSED_INPUT_LIST_FILE_NAME_TMP%"

set "REVERESED_UNIQUE_LIST_FILE_NAME_TMP=reversed_unique_file_list.lst"
set "REVERESED_UNIQUE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%REVERESED_UNIQUE_LIST_FILE_NAME_TMP%"

set "UNIQUE_LIST_FILE_NAME_TMP=unique_file_list.lst"
set "UNIQUE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%UNIQUE_LIST_FILE_NAME_TMP%"

set "COPY_TO_LIST_FILE_NAME_TMP=copy_to_file_list.lst"
set "COPY_TO_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%COPY_TO_LIST_FILE_NAME_TMP%"

for /F "eol= tokens=* delims=" %%i in ("%SCRIPT_TEMP_CURRENT_DIR%\cwrtmp") do set "COPY_WITH_RENAME_DIR_TMP=%%~fi"
set "EMPTY_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\emptydir"

mkdir "%EMPTY_DIR_TMP%" || (
  echo.%?~n0%: error: could not create a directory: "%EMPTY_DIR_TMP%".
  exit /b 255
) >&2

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
) else (
  if %FLAG_CONVERT_FROM_UTF16% NEQ 0 goto CHCP_65001
  if %FLAG_CONVERT_FROM_UTF16LE% NEQ 0 goto CHCP_65001
  if %FLAG_CONVERT_FROM_UTF16BE% NEQ 0 goto CHCP_65001
)

goto END_CHCP_65001

:CHCP_65001
rem to convert from unicode
call "%%CONTOOLS_ROOT%%/std/chcp.bat" 65001
set RESTORE_LOCALE=1

:END_CHCP_65001

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

call :COPY_FILE_LOG "%%COPY_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%COPY_FROM_LIST_FILE_NAME_TMP%%"

if %FLAG_USE_ONLY_UNIQUE_PATHS% EQU 0 goto IGNORE_FILTER_UNIQUE_PATHS

sort /R "%COPY_FROM_LIST_FILE_TMP%" /O "%REVERSED_INPUT_LIST_FILE_TMP%"

call :COPY_FILE_LOG "%%REVERSED_INPUT_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%REVERSED_INPUT_LIST_FILE_NAME_TMP%%"

rem recreate empty list
type nul > "%REVERESED_UNIQUE_LIST_FILE_TMP%"

set "PREV_FILE_PATH="
for /F "usebackq tokens=* delims= eol=#" %%i in ("%REVERSED_INPUT_LIST_FILE_TMP%") do (
  set "FILE_PATH=%%i"
  call :FILTER_UNIQUE_PATHS
  set "PREV_FILE_PATH=%%i"
)

call :COPY_FILE_LOG "%%REVERESED_UNIQUE_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%REVERESED_UNIQUE_LIST_FILE_NAME_TMP%%"

goto FILTER_UNIQUE_PATHS_END

:COPY_FILE_LOG
set "COPY_FROM_FILE_PATH=%~f1"
set "COPY_TO_FILE_PATH=%~f2"
echo."%COPY_FROM_FILE_PATH%" -^> "%COPY_TO_FILE_PATH%"
if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 ( "%MSYS_ROOT%/bin/cp.exe" --preserve=timestamps "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b )
if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 ( "%CYGWIN_ROOT%/bin/cp.exe" --preserve=timestamps "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b )

type nul >> "\\?\%COPY_TO_FILE_PATH%"

if not exist "%COPY_FROM_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL
if not exist "%COPY_TO_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL

copy "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" /B /Y
exit /b

:XCOPY_FILE_LOG_IMPL
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
exit /b

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

call :COPY_FILE_LOG "%%UNIQUE_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%UNIQUE_LIST_FILE_NAME_TMP%%"

set "COPY_FROM_LIST_FILE_TMP=%UNIQUE_LIST_FILE_TMP%"

:IGNORE_FILTER_UNIQUE_PATHS

echo.* Generating editable copy list...

rem recreate empty list
type nul > "%COPY_TO_LIST_FILE_TMP%"

if defined OPTIONAL_DEST_DIR (echo.# dest: "%OPTIONAL_DEST_DIR%") >> "%COPY_TO_LIST_FILE_TMP%"

rem read selected file paths from file
for /F "usebackq tokens=* delims= eol=#" %%i in ("%COPY_FROM_LIST_FILE_TMP%") do ( set "FILE_PATH=%%i" & call :FILL_TO_LIST_FILE_TMP )
goto FILL_TO_LIST_FILE_TMP_END

:COPY_FILE_LOG
set "COPY_FROM_FILE_PATH=%~f1"
set "COPY_TO_FILE_PATH=%~f2"
echo."%COPY_FROM_FILE_PATH%" -^> "%COPY_TO_FILE_PATH%"
if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 ( "%MSYS_ROOT%/bin/cp.exe" --preserve=timestamps "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b )
if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 ( "%CYGWIN_ROOT%/bin/cp.exe" --preserve=timestamps "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b )

type nul >> "\\?\%COPY_TO_FILE_PATH%"

if not exist "%COPY_FROM_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL
if not exist "%COPY_TO_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL

copy "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" /B /Y
exit /b

:XCOPY_FILE_LOG_IMPL
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
exit /b

:FILL_TO_LIST_FILE_TMP
rem avoid any quote characters
set "FILE_PATH=%FILE_PATH:"=%"

for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi|%%~nxi") do ( (echo.%%j) >> "%COPY_TO_LIST_FILE_TMP%" )
exit /b 0

:FILL_TO_LIST_FILE_TMP_END
call :COPY_FILE_LOG "%%COPY_TO_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%COPY_FROM_LIST_FILE_NAME_TMP%%"
call :COPY_FILE_LOG "%%COPY_TO_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%COPY_TO_LIST_FILE_NAME_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar "" "%%PROJECT_LOG_DIR%%/%%COPY_TO_LIST_FILE_NAME_TMP%%"

call :COPY_FILE_LOG "%%PROJECT_LOG_DIR%%/%%COPY_TO_LIST_FILE_NAME_TMP%%" "%%COPY_TO_LIST_FILE_TMP%%"

echo.
echo.Coping...

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
) < "%COPY_FROM_LIST_FILE_TMP%"

exit /b

:COPY_FILE_LOG
set "COPY_FROM_FILE_PATH=%~f1"
set "COPY_TO_FILE_PATH=%~f2"
echo."%COPY_FROM_FILE_PATH%" -^> "%COPY_TO_FILE_PATH%"
if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 ( "%MSYS_ROOT%/bin/cp.exe" --preserve=timestamps "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b )
if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 ( "%CYGWIN_ROOT%/bin/cp.exe" --preserve=timestamps "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b )

type nul >> "\\?\%COPY_TO_FILE_PATH%"

if not exist "%COPY_FROM_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL
if not exist "%COPY_TO_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL

copy "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" /B /Y
exit /b

:XCOPY_FILE_LOG_IMPL
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
exit /b

:PROCESS_COPY
if not defined FROM_FILE_PATH exit /b 2
if not defined TO_FILE_PATH exit /b 3

set "FROM_FILE_PATH=%FROM_FILE_PATH:/=\%"
set "TO_FILE_PATH=%TO_FILE_PATH:/=\%"

for /F "eol= tokens=* delims=" %%i in ("%FROM_FILE_PATH%\.") do ( set "FROM_FILE_PATH=%%~fi" & set "FROM_FILE_DIR=%%~dpi" & set "FROM_FILE_NAME=%%~nxi" )

set "FROM_FILE_DIR=%FROM_FILE_DIR:~0,-1%"

rem extract destination path components
set "XCOPY_EXCLUDE_DIRS_LIST="
set "XCOPY_EXCLUDE_FILES_LIST="
for /F "eol= tokens=1,2,3,4 delims=|" %%i in ("%TO_FILE_PATH%") do ( set "TO_FILE_DIR=%%i" & set "TO_FILE_NAME=%%j" & set "XCOPY_EXCLUDE_DIRS_LIST=%%k" & set "XCOPY_EXCLUDE_FILES_LIST=%%l" )

set EXCLUDE_COPY_DIR_SUBDIRS=0
set EXCLUDE_COPY_DIR_FILES=0
set EXCLUDE_COPY_DIR_CONTENT=0

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
if not defined XCOPY_EXCLUDE_FILES_LIST goto END_XCOPY_EXCLUDE_FILES_LIST

set "XCOPY_EXCLUDE_FILES_LIST=|%XCOPY_EXCLUDE_FILES_LIST::=|%|"

if not "%XCOPY_EXCLUDE_FILES_LIST:|*|=%" == "%XCOPY_EXCLUDE_FILES_LIST%" ( set "EXCLUDE_COPY_DIR_FILES=1" & goto END_XCOPY_EXCLUDE_FILES_LIST )

:END_XCOPY_EXCLUDE_FILES_LIST
if defined XCOPY_EXCLUDE_DIRS_LIST set "XCOPY_EXCLUDE_DIRS_LIST=%XCOPY_EXCLUDE_DIRS_LIST:~1,-1%"
if defined XCOPY_EXCLUDE_FILES_LIST set "XCOPY_EXCLUDE_FILES_LIST=%XCOPY_EXCLUDE_FILES_LIST:~1,-1%"

if %EXCLUDE_COPY_DIR_SUBDIRS%%EXCLUDE_COPY_DIR_FILES% EQU 11 set EXCLUDE_COPY_DIR_CONTENT=1

rem concatenate and renormalize
set "TO_FILE_PATH=%TO_FILE_DIR%\%TO_FILE_NAME%"

for /F "eol= tokens=* delims=" %%i in ("%TO_FILE_PATH%\.") do ( set "TO_FILE_PATH=%%~fi" & set "TO_FILE_DIR=%%~dpi" & set "TO_FILE_NAME=%%~nxi" )

set "TO_FILE_DIR=%TO_FILE_DIR:~0,-1%"

rem file being copied to itself
if /i "%FROM_FILE_PATH%" == "%TO_FILE_PATH%" exit /b 0

echo."%FROM_FILE_PATH%" -^> "%TO_FILE_PATH%"

if not exist "\\?\%FROM_FILE_PATH%" (
  echo.%?~n0%: error: FROM_FILE_PATH is not found: "%FROM_FILE_PATH%".
  exit /b 4
) >&2

rem check recursion only if FROM_FILE_PATH is a directory
set FROM_FILE_PATH_AS_DIR=0
if not exist "\\?\%FROM_FILE_PATH%\" goto IGNORE_TO_FILE_PATH_CHECK
set FROM_FILE_PATH_AS_DIR=1

call "%%CONTOOLS_ROOT%%/filesys/subtract_path.bat" "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" && (
  echo.%?~n0%: error: TO_FILE_PATH file path must not contain FROM_FILE_PATH file path: FROM_FILE_PATH="%FROM_FILE_PATH%" TO_FILE_PATH="%TO_FILE_PATH%".
  exit /b 5
) >&2

:IGNORE_TO_FILE_PATH_CHECK

set TO_FILE_PATH_EXISTS=0
if exist "\\?\%TO_FILE_PATH%" set TO_FILE_PATH_EXISTS=1

if not exist "\\?\%TO_FILE_DIR%\" (
  echo.^>mkdir "%TO_FILE_DIR%"
  if %FLAG_USE_SHELL_MSYS_COPY%%FLAG_USE_SHELL_CYGWIN_COPY% EQU 0 (
    mkdir "%TO_FILE_DIR%" 2>nul || "%WINDIR%/System32/robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%TO_FILE_DIR%" >nul || (
      echo.%?~nx0%: error: could not create a target file directory: "%TO_FILE_DIR%".
      exit /b 10
    ) >&2
  ) else if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 (
    "%MSYS_ROOT%/bin/mkdir.exe" -p "%TO_FILE_DIR%"
  ) else "%CYGWIN_ROOT%/bin/mkdir.exe" -p "%TO_FILE_DIR%"
)

:SHELL_COPY
if %FROM_FILE_PATH_AS_DIR% NEQ 0 goto XCOPY_FROM_FILE_PATH_AS_DIR

if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 (
  call :CMD "%%MSYS_ROOT%%/bin/cp.exe" --preserve=timestamps "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || exit /b 40
  goto GIT_ADD
)
if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 (
  call :CMD "%%CYGWIN_ROOT%%/bin/cp.exe" --preserve=timestamps "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || exit /b 41
  goto GIT_ADD
)

if /i "%FROM_FILE_NAME%" == "%TO_FILE_NAME%" goto XCOPY_FILE_WO_RENAME

call "%%?~dp0%%.shell_copy_by_list/shell_copy_by_list.xcopy_file_with_rename.bat" || exit /b 42
goto GIT_ADD

:CMD
echo.^>%*
(%*)
exit /b

:XCOPY_FILE_WO_RENAME
rem create an empty destination file if not exist yet to check a path limitation issue
( type nul >> "\\?\%TO_FILE_PATH%" ) 2>nul

if exist "%FROM_FILE_PATH%" if exist "%TO_FILE_PATH%" (
  call :CMD copy "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" /B /Y || (
    if %TO_FILE_PATH_EXISTS% EQU 0 "%WINDIR%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/shell/delete_file.vbs" "\\?\%TO_FILE_PATH%" 2>nul
    exit /b 50
  )
  goto GIT_ADD
)

call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%FROM_FILE_DIR%%" "%%TO_FILE_NAME%%" "%%TO_FILE_DIR%%" /Y /H || exit /b 51
goto GIT_ADD

:CMD
echo.^>%*
(%*)
exit /b

:XCOPY_FROM_FILE_PATH_AS_DIR
if %FLAG_USE_SHELL_MSYS_COPY% NEQ 0 (
  if %EXCLUDE_COPY_DIR_CONTENT% EQU 0 (
    call :CMD "%%MSYS_ROOT%%/bin/cp.exe" -R --preserve=timestamps "%%FROM_FILE_PATH%%/." "%%TO_FILE_PATH%%/" || exit /b 60
  ) else (
    call :CMD "%%MSYS_ROOT%%/bin/mkdir.exe" "%%TO_FILE_PATH%%" || exit /b 61
    call :CMD "%%MSYS_ROOT%%/bin/touch.exe" -r "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%"
  )
  goto GIT_ADD
)
if %FLAG_USE_SHELL_CYGWIN_COPY% NEQ 0 (
  if %EXCLUDE_COPY_DIR_CONTENT% EQU 0 (
    call :CMD "%%CYGWIN_ROOT%%/bin/cp.exe" -R --preserve=timestamps "%%FROM_FILE_PATH%%/." "%%TO_FILE_PATH%%/" || exit /b 65
  ) else (
    call :CMD "%%CYGWIN_ROOT%%/bin/mkdir.exe" "%%TO_FILE_PATH%%" || exit /b 66
    call :CMD "%%CYGWIN_ROOT%%/bin/touch.exe" -r "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%"
  )
  goto GIT_ADD
)

call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat" -copy_dir "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" /E /Y /DCOPY:T || exit /b 70
goto GIT_ADD

:CMD
echo.^>%*
(%*)
exit /b

:GIT_ADD
rem WORKAROUND:
rem  Git ignores absolute path as an command argument and anyway searches current working directory for the repository.
rem  Use `pushd` to set the current directory to parent directory of being processed item.
rem

call :CMD pushd "%%FROM_FILE_DIR%%" && (
  rem check if path is under GIT version control
  git ls-files --error-unmatch "%FROM_FILE_PATH%" >nul 2>nul || ( popd & exit /b 0 )
  call :CMD git add "%%TO_FILE_PATH%%" || exit /b 100
  popd
  exit /b 0
)

exit /b 101

:CMD
echo.^>%*
(%*)
exit /b
