@echo off

setlocal

if %IMPL_MODE%0 NEQ 0 goto IMPL

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%* || exit /b

for %%i in (CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

call "%%CONTOOLS_ROOT%%/build/init_project_log.bat" "%%?~n0%%" || exit /b

call "%%CONTOOLS_ROOT%%/exec/exec_terminal_prefix.bat" -- %%* || exit /b
exit /b 0

:IMPL
rem CAUTION: We must to reinit the builtin variables in case if `IMPL_MODE` was already setup outside.
call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

rem script flags
set RESTORE_LOCALE=0

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
set FLAG_USE_ONLY_UNIQUE_PATHS=0
set FLAG_USE_SHELL_MSYS=0
set FLAG_USE_SHELL_CYGWIN=0
set FLAG_USE_GIT=0
set FLAG_USE_SVN=0

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
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

for /F "eol= tokens=* delims=" %%i in ("%CD%") do echo CD=`%%i`& echo.

if %FLAG_USE_SHELL_MSYS% EQU 0 goto SKIP_USE_SHELL_MSYS

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/init_msys.bat" || exit /b 255

if defined MSYS_ROOT if exist "%MSYS_ROOT%\bin\*" goto MSYS_OK
(
  echo.%?~nx0%: error: `MSYS_ROOT` variable is not defined or not valid: "%MSYS_ROOT%".
  exit /b 255
) >&2

:SKIP_USE_SHELL_MSYS
:MSYS_OK

if %FLAG_USE_SHELL_CYGWIN% EQU 0 goto SKIP_USE_SHELL_CYGWIN

call "%%TACKLEBAR_PROJECT_ROOT%%/tools/init_cygwin.bat" || exit /b 255

if defined CYGWIN_ROOT if exist "%CYGWIN_ROOT%\bin\*" goto CYGWIN_OK
(
  echo.%?~nx0%: error: `CYGWIN_ROOT` variable is not defined or not valid: "%CYGWIN_ROOT%".
  exit /b 255
) >&2

:SKIP_USE_SHELL_CYGWIN
:CYGWIN_OK

set "LIST_FILE_PATH=%~1"
rem set "OPTIONAL_DEST_DIR=%~2"

if not defined LIST_FILE_PATH (
  echo.%?~nx0%: error: list file path is not defined.
  exit /b 255
) >&2

set "RENAME_FROM_LIST_FILE_NAME_TMP=rename_from_file_list.lst"
set "RENAME_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%RENAME_FROM_LIST_FILE_NAME_TMP%"

rem reversed to skip parent path rename for already a being renamed child
set "REVERSED_INPUT_LIST_FILE_NAME_TMP=reversed_input_file_list.lst"
set "REVERSED_INPUT_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%REVERSED_INPUT_LIST_FILE_NAME_TMP%"

set "REVERSED_UNIQUE_LIST_FILE_NAME_TMP=reversed_unique_file_list.lst"
set "REVERSED_UNIQUE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%REVERSED_UNIQUE_LIST_FILE_NAME_TMP%"

set "UNIQUE_LIST_FILE_NAME_TMP=unique_file_list.lst"
set "UNIQUE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%UNIQUE_LIST_FILE_NAME_TMP%"

set "RENAME_TO_LIST_FILE_NAME_TMP=rename_to_file_list.lst"
set "RENAME_TO_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%RENAME_TO_LIST_FILE_NAME_TMP%"

for /F "eol= tokens=* delims=" %%i in ("%SCRIPT_TEMP_CURRENT_DIR%\mwrtmp") do set "MOVE_WITH_RENAME_DIR_TMP=%%~fi"
set "EMPTY_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\emptydir"

mkdir "%EMPTY_DIR_TMP%" || (
  echo.%?~nx0%: error: could not create a directory: "%EMPTY_DIR_TMP%".
  exit /b 255
) >&2

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
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%RENAME_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FROM_UTF16LE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16LE UTF-8 "%%LIST_FILE_PATH%%" > "%RENAME_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FROM_UTF16BE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16BE UTF-8 "%%LIST_FILE_PATH%%" > "%RENAME_FROM_LIST_FILE_TMP%"
) else (
  set "RENAME_FROM_LIST_FILE_TMP=%LIST_FILE_PATH%"
)

call "%%?~dp0%%.shell/shell_copy_file_log.bat" "%%RENAME_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%RENAME_FROM_LIST_FILE_NAME_TMP%%"

if %FLAG_USE_ONLY_UNIQUE_PATHS% EQU 0 goto IGNORE_FILTER_UNIQUE_PATHS

sort /R "%RENAME_FROM_LIST_FILE_TMP%" /O "%REVERSED_INPUT_LIST_FILE_TMP%"

call "%%?~dp0%%.shell/shell_copy_file_log.bat" "%%REVERSED_INPUT_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%REVERSED_INPUT_LIST_FILE_NAME_TMP%%"

rem recreate empty list
type nul > "%REVERSED_UNIQUE_LIST_FILE_TMP%"

set "PREV_FILE_PATH="
for /F "usebackq tokens=* delims= eol=#" %%i in ("%REVERSED_INPUT_LIST_FILE_TMP%") do (
  set "FILE_PATH=%%i"
  call :FILTER_UNIQUE_PATHS
  set "PREV_FILE_PATH=%%i"
)

call "%%?~dp0%%.shell/shell_copy_file_log.bat" "%%REVERSED_UNIQUE_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%REVERSED_UNIQUE_LIST_FILE_NAME_TMP%%"

goto FILTER_UNIQUE_PATHS_END

:FILTER_UNIQUE_PATHS
if defined PREV_FILE_PATH goto CONTINUE_FILTER_UNIQUE_PATHS_1

if /i "%FILE_PATH%" == "%PREV_FILE_PATH%" exit /b 0

setlocal ENABLEDELAYEDEXPANSION & for /F "eol= tokens=* delims=" %%i in ("!FILE_PATH!") do ( endlocal & (echo.%%i) >> "%REVERSED_UNIQUE_LIST_FILE_TMP%" )
exit /b 0

:CONTINUE_FILTER_UNIQUE_PATHS_1

rem calculate file path string length
setlocal ENABLEDELAYEDEXPANSION
set "FILE_PATH_TMP=%FILE_PATH%"
set FILE_PATH_LEN=0
for %%i in (65536 32768 16384 8192 4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do if not "!FILE_PATH_TMP:~%%i,1!" == "" ( set /A "FILE_PATH_LEN+=%%i" & set "FILE_PATH_TMP=!FILE_PATH_TMP:~%%i!" )
set /A FILE_PATH_LEN+=1

for %%i in (%FILE_PATH_LEN%) do if not "!PREV_FILE_PATH:~%%i,1!" == "" goto CONTINUE_FILTER_UNIQUE_PATHS_2

for /F "eol= tokens=* delims=" %%i in ("!FILE_PATH!") do ( endlocal & (echo.%%i) >> "%REVERSED_UNIQUE_LIST_FILE_TMP%" )
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

rem the previous path is a parent path to the current path, skipping
if /i "%PREV_FILE_PATH_PREFIX%" == "%FILE_PATH_SUFFIX%" exit /b 0

setlocal ENABLEDELAYEDEXPANSION & for /F "eol= tokens=* delims=" %%i in ("!FILE_PATH!") do ( endlocal & (echo.%%i) >> "%REVERSED_UNIQUE_LIST_FILE_TMP%" )

exit /b 0

:FILTER_UNIQUE_PATHS_END

sort /R "%REVERSED_UNIQUE_LIST_FILE_TMP%" /O "%UNIQUE_LIST_FILE_TMP%"

call "%%?~dp0%%.shell/shell_copy_file_log.bat" "%%UNIQUE_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%UNIQUE_LIST_FILE_NAME_TMP%%"

set "RENAME_FROM_LIST_FILE_TMP=%UNIQUE_LIST_FILE_TMP%"

:IGNORE_FILTER_UNIQUE_PATHS

call "%%?~dp0%%.shell/shell_copy_file_log.bat" "%%RENAME_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%RENAME_TO_LIST_FILE_NAME_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar "" "%%PROJECT_LOG_DIR%%/%%RENAME_TO_LIST_FILE_NAME_TMP%%"

"%SystemRoot%\System32\fc.exe" "%PROJECT_LOG_DIR:/=\%\%RENAME_TO_LIST_FILE_NAME_TMP:/=\%" "%PROJECT_LOG_DIR:/=\%/%RENAME_FROM_LIST_FILE_NAME_TMP%" > nul && exit /b 0

call "%%?~dp0%%.shell/shell_copy_file_log.bat" "%%PROJECT_LOG_DIR%%/%%RENAME_TO_LIST_FILE_NAME_TMP%%" "%%RENAME_TO_LIST_FILE_TMP%%"

echo.* Renaming...
echo.

rem trick with simultaneous iteration over 2 list in the same time
(
  for /F "usebackq eol=# tokens=* delims=" %%i in ("%RENAME_TO_LIST_FILE_TMP%") do (
    set /P "FROM_FILE_PATH="
    set "TO_FILE_PATH=%%i"
    call :PROCESS_RENAME
  )
) < "%RENAME_FROM_LIST_FILE_TMP%"

exit /b 0

:PROCESS_RENAME
if not defined FROM_FILE_PATH exit /b 1
if not defined TO_FILE_PATH exit /b 1

set "FROM_FILE_PATH=%FROM_FILE_PATH:/=\%"
set "TO_FILE_PATH=%TO_FILE_PATH:/=\%"

rem check on invalid characters in path
if not "%FROM_FILE_PATH%" == "%FROM_FILE_PATH:**=%" goto FROM_PATH_ERROR
if not "%FROM_FILE_PATH%" == "%FROM_FILE_PATH:?=%" goto FROM_PATH_ERROR
if not "%TO_FILE_PATH%" == "%TO_FILE_PATH:**=%" goto TO_PATH_ERROR
if not "%TO_FILE_PATH%" == "%TO_FILE_PATH:?=%" goto TO_PATH_ERROR

goto PATH_OK

:FROM_PATH_ERROR
(
  echo.%?~nx0%: error: FROM_FILE_PATH is invalid path:
  echo.  FROM_FILE_PATH="%FROM_FILE_PATH%"
  echo.  TO_FILE_PATH  ="%TO_FILE_PATH%"
  exit /b 2
) >&2

goto PATH_OK

:TO_PATH_ERROR
(
  echo.%?~nx0%: error: TO_FILE_PATH is invalid path:
  echo.  FROM_FILE_PATH="%FROM_FILE_PATH%"
  echo.  TO_FILE_PATH  ="%TO_FILE_PATH%"
  exit /b 2
) >&2

:PATH_OK

rem CAUTION:
rem   The `%%~fi` or `%%~nxi` expansions here goes change a path characters case to the case of the existed file path.
rem
rem WORKAROUND:
rem   We must encode a path to a nonexistent path and after conversion to an absolute path, decode it back and so bypass case change in a path characters.
rem
set "FILE_NAME_TEMP_SUFFIX=~%RANDOM%%RANDOM%"

if "%FROM_FILE_PATH:~-1%" == "\" set "FROM_FILE_PATH=%FROM_FILE_PATH:~0,-1%"
if "%TO_FILE_PATH:~-1%" == "\" set "TO_FILE_PATH=%TO_FILE_PATH:~0,-1%"

for /F "eol= tokens=* delims=" %%i in ("%FROM_FILE_PATH%%FILE_NAME_TEMP_SUFFIX%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi\.") do ( set "FROM_FILE_PATH=%%~fi" & set "FROM_FILE_DIR=%%~fj" & set "FROM_FILE_NAME=%%~nxi" )
for /F "eol= tokens=* delims=" %%i in ("%TO_FILE_PATH%%FILE_NAME_TEMP_SUFFIX%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi\.") do ( set "TO_FILE_PATH=%%~fi" & set "TO_FILE_DIR=%%~fj" & set "TO_FILE_NAME=%%~nxi" )

rem decode paths back
call set "FROM_FILE_PATH=%%FROM_FILE_PATH:%FILE_NAME_TEMP_SUFFIX%=%%"
call set "FROM_FILE_NAME=%%FROM_FILE_NAME:%FILE_NAME_TEMP_SUFFIX%=%%"
call set "TO_FILE_PATH=%%TO_FILE_PATH:%FILE_NAME_TEMP_SUFFIX%=%%"
call set "TO_FILE_NAME=%%TO_FILE_NAME:%FILE_NAME_TEMP_SUFFIX%=%%"

rem can not rename an empty name

if not defined FROM_FILE_NAME (
  echo.%?~nx0%: error: FROM_FILE_NAME is empty:
  echo.  FROM_FILE_PATH="%FROM_FILE_PATH%"
  echo.  TO_FILE_PATH  ="%TO_FILE_PATH%"
  exit /b 3
) >&2

if not defined TO_FILE_NAME (
  echo.%?~nx0%: error: TO_FILE_NAME is empty:
  echo.  FROM_FILE_PATH="%FROM_FILE_PATH%"
  echo.  TO_FILE_PATH  ="%TO_FILE_PATH%"
  exit /b 3
) >&2

rem Is the file name case sensitively renamed?
if "%FROM_FILE_NAME%" == "%TO_FILE_NAME%" exit /b 0

echo."%FROM_FILE_PATH%" -^> "%TO_FILE_PATH%"

set TO_FILE_PATH_EXISTS=0
if exist "\\?\%TO_FILE_PATH%" set TO_FILE_PATH_EXISTS=1

if not exist "\\?\%FROM_FILE_PATH%" (
  echo.%?~nx0%: error: FROM_FILE_PATH is not found:
  echo.  FROM_FILE_PATH="%FROM_FILE_PATH%"
  exit /b 4
) >&2

if /i not "%FROM_FILE_DIR%" == "%TO_FILE_DIR%" (
  echo.%?~nx0%: error: parent directory path must stay the same:
  echo.  FROM_FILE_PATH="%FROM_FILE_PATH%"
  echo.  TO_FILE_PATH  ="%TO_FILE_PATH%"
  exit /b 5
) >&2 else if /i not "%FROM_FILE_NAME%" == "%TO_FILE_NAME%" if %TO_FILE_PATH_EXISTS%0 NEQ 0 (
  echo.%?~nx0%: error: TO_FILE_PATH already exists:
  echo.  TO_FILE_PATH  ="%TO_FILE_PATH%"
  exit /b 5
) >&2

if %FLAG_USE_SVN%0 EQU 0 goto SKIP_USE_SVN

rem check if path is under SVN version control

svn info "%FROM_FILE_PATH%" --non-interactive >nul 2>nul || goto SKIP_USE_SVN

:SVN_RENAME
call :CMD svn rename "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" --non-interactive || exit /b 10
echo.
goto SVN_RENAME_END

:SKIP_USE_SVN
:SVN_RENAME_END

if %FLAG_USE_GIT%0 EQU 0 goto SKIP_USE_GIT

rem WORKAROUND:
rem  To rename file in the Git together within SVN we must shell rename file back.
rem

if %FLAG_USE_SVN%0 NEQ 0 (
  call :CMD rename "%%TO_FILE_PATH%%" "%%FROM_FILE_NAME%%" || exit /b 30
  echo.
)

rem check if path is under GIT version control

rem WORKAROUND:
rem  Git ignores absolute path as an command argument and anyway searches current working directory for the repository.
rem  Git checks if the current path is inside the same `.git` directory tree.
rem  Use `pushd` to set the current directory to parent directory of being processed item.
rem

call :CMD pushd "%%FROM_FILE_DIR%%" && (
  git ls-files --error-unmatch "%FROM_FILE_PATH%" >nul 2>nul || ( call :CMD popd & echo.& goto INTERRUPT_USE_GIT )
  call :CMD git mv "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || ( call :CMD popd & echo.& goto INTERRUPT_USE_GIT )
  call :CMD popd
  echo.
  goto USE_GIT_END
)

echo.

:INTERRUPT_USE_GIT
rem restore it back
if %FLAG_USE_SVN%0 NEQ 0 (
  call :CMD rename "%%FROM_FILE_PATH%%" "%%TO_FILE_NAME%%" || exit /b 35
  echo.
)
exit /b 0

:SKIP_USE_GIT
if %FLAG_USE_SVN%0 EQU 0 goto SHELL_RENAME

:USE_GIT_END
exit /b 0

:CMD
echo.^>%*
(%*)
exit /b

:SHELL_RENAME
set FROM_FILE_PATH_AS_DIR=0
if exist "\\?\%FROM_FILE_PATH%\*" set FROM_FILE_PATH_AS_DIR=1

if %FROM_FILE_PATH_AS_DIR% NEQ 0 goto XMOVE_FROM_FILE_PATH_AS_DIR

if %FLAG_USE_SHELL_MSYS% NEQ 0 (
  call :CMD "%%MSYS_ROOT%%/bin/mv.exe" "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || exit /b 40
  echo.
  exit /b 0
)
if %FLAG_USE_SHELL_CYGWIN% NEQ 0 (
  call :CMD "%%CYGWIN_ROOT%%/bin/mv.exe" "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || exit /b 41
  echo.
  exit /b 0
)

call "%%?~dp0%%.shell_move_by_list/shell_move_by_list.xmove_file_with_rename.bat" || exit /b 42
exit /b 0

:CMD
echo.^>%*
(%*)
exit /b

:XMOVE_FROM_FILE_PATH_AS_DIR
if %FLAG_USE_SHELL_MSYS% NEQ 0 (
  call :CMD "%%MSYS_ROOT%%/bin/mv.exe" "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%/" || exit /b 60
  echo.
  exit /b 0
)
if %FLAG_USE_SHELL_CYGWIN% NEQ 0 (
  call :CMD "%%CYGWIN_ROOT%%/bin/mv.exe" "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%/" || exit /b 65
  echo.
  exit /b 0
)

set "XMOVE_DIR_CMD_BARE_FLAGS="
if defined OEMCP set XMOVE_DIR_CMD_BARE_FLAGS=%XMOVE_DIR_CMD_BARE_FLAGS% -chcp "%OEMCP%"

call "%%CONTOOLS_ROOT%%/std/xmove_dir.bat"%%XMOVE_DIR_CMD_BARE_FLAGS%% "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" /E || exit /b 70
echo.
exit /b 0

:CMD
echo.^>%*
(%*)
exit /b
