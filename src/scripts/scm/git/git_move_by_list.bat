@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

for %%i in (CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

if %IMPL_MODE%0 NEQ 0 goto IMPL

call "%%CONTOOLS_ROOT%%/build/init_project_log.bat" "%%?~n0%%" || exit /b

call "%%TACKLEBAR_SCRIPTS_ROOT%%/.common/exec_terminal_prefix.bat" || exit /b
exit /b 0

:IMPL
rem script flags
set RESTORE_LOCALE=0

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || (
  echo.%?~nx0%: error: could not allocate temporary directory: "%SCRIPT_TEMP_CURRENT_DIR%"
  exit /b 255
) >&2

call "%%CONTOOLS_ROOT%%/std/get_cmdline.bat" %%*
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
set FLAG_USE_SHELL_MSYS_MOVE=0
set FLAG_USE_SHELL_CYGWIN_MOVE=0

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
  ) else if "%FLAG%" == "-use_shell_msys_move" (
    set FLAG_USE_SHELL_MSYS_MOVE=1
  ) else if "%FLAG%" == "-use_shell_cygwin_move" (
    set FLAG_USE_SHELL_CYGWIN_MOVE=1
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

if defined CWD if "%CWD:~0,1%" == "\" set "CWD="
if defined CWD ( for /F "eol= tokens=* delims=" %%i in ("%CWD%\.") do set "CWD=%%~fi" ) else goto NOCWD
if exist "\\?\%CWD%" if exist "%CWD%" ( cd /d "%CWD%" || exit /b 1 )

:NOCWD

rem safe title call
for /F "eol= tokens=* delims=" %%i in ("%?~nx0%: %COMSPEC%: %CD%") do title %%i

if %FLAG_USE_SHELL_MSYS_MOVE% NEQ 0 if defined MSYS_ROOT if exist "%MSYS_ROOT%\bin\" goto MSYS_OK
if %FLAG_USE_SHELL_MSYS_MOVE% NEQ 0 (
  echo.%?~nx0%: error: `MSYS_ROOT` variable is not defined or not valid: "%MSYS_ROOT%".
  exit /b 255
) >&2

if %FLAG_USE_SHELL_CYGWIN_MOVE% NEQ 0 if defined CYGWIN_ROOT if exist "%CYGWIN_ROOT%\bin\" goto CYGWIN_OK
if %FLAG_USE_SHELL_CYGWIN_MOVE% NEQ 0 (
  echo.%?~nx0%: error: `CYGWIN_ROOT` variable is not defined or not valid: "%CYGWIN_ROOT%".
  exit /b 255
) >&2

:MSYS_OK
:CYGWIN_OK
set "LIST_FILE_PATH=%~1"
set "OPTIONAL_DEST_DIR=%~2"

if not defined LIST_FILE_PATH exit /b 0

set "MOVE_FROM_LIST_FILE_NAME_TMP=move_from_file_list.lst"
set "MOVE_FROM_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%MOVE_FROM_LIST_FILE_NAME_TMP%"

set "REVERSED_INPUT_LIST_FILE_NAME_TMP=reveresed_input_file_list.lst"
set "REVERSED_INPUT_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%REVERSED_INPUT_LIST_FILE_NAME_TMP%"

set "REVERESED_UNIQUE_LIST_FILE_NAME_TMP=reversed_unique_file_list.lst"
set "REVERESED_UNIQUE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%REVERESED_UNIQUE_LIST_FILE_NAME_TMP%"

set "UNIQUE_LIST_FILE_NAME_TMP=unique_file_list.lst"
set "UNIQUE_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%UNIQUE_LIST_FILE_NAME_TMP%"

set "MOVE_TO_LIST_FILE_NAME_TMP=move_to_file_list.lst"
set "MOVE_TO_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\%MOVE_TO_LIST_FILE_NAME_TMP%"

for /F "eol= tokens=* delims=" %%i in ("%SCRIPT_TEMP_CURRENT_DIR%\mwrtmp") do set "MOVE_WITH_RENAME_DIR_TMP=%%~fi"
set "EMPTY_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\emptydir"

mkdir "%EMPTY_DIR_TMP%" || (
  echo.%?~n0%: error: could not create a directory: "%EMPTY_DIR_TMP%".
  exit /b 255
) >&2

if defined FLAG_CHCP (
  call "%%CONTOOLS_ROOT%%/std/chcp.bat" "%%FLAG_CHCP%%"
  set RESTORE_LOCALE=1
)

if %FLAG_CONVERT_FROM_UTF16% NEQ 0 (
  rem Recreate files and recode files w/o BOM applience (do use UTF-16 instead of UCS-2LE/BE for that!)
  rem See for details: https://stackoverflow.com/questions/11571665/using-iconv-to-convert-from-utf-16be-to-utf-8-without-bom/11571759#11571759
  rem
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16 UTF-8 "%%LIST_FILE_PATH%%" > "%MOVE_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FROM_UTF16LE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16LE UTF-8 "%%LIST_FILE_PATH%%" > "%MOVE_FROM_LIST_FILE_TMP%"
) else if %FLAG_CONVERT_FROM_UTF16BE% NEQ 0 (
  call "%%CONTOOLS_ROOT%%/encoding/ansi2any.bat" UTF-16BE UTF-8 "%%LIST_FILE_PATH%%" > "%MOVE_FROM_LIST_FILE_TMP%"
) else (
  set "MOVE_FROM_LIST_FILE_TMP=%LIST_FILE_PATH%"
)

call :COPY_FILE_LOG "%%MOVE_FROM_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%MOVE_FROM_LIST_FILE_NAME_TMP%%"

if %FLAG_USE_ONLY_UNIQUE_PATHS% EQU 0 goto IGNORE_FILTER_UNIQUE_PATHS

sort /R "%MOVE_FROM_LIST_FILE_TMP%" /O "%REVERSED_INPUT_LIST_FILE_TMP%"

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
if %FLAG_USE_SHELL_MSYS_MOVE% NEQ 0 ( "%MSYS_ROOT%/bin/cp.exe" --preserve=timestamps "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b )
if %FLAG_USE_SHELL_CYGWIN_MOVE% NEQ 0 ( "%CYGWIN_ROOT%/bin/cp.exe" --preserve=timestamps "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b )

type nul >> "\\?\%COPY_TO_FILE_PATH%"

if not exist "%COPY_FROM_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL
if not exist "%COPY_TO_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%
copy "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" /B /Y
set LASTERROR=%ERRORLEVEL%
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"
exit /b %LASTERROR%

:XCOPY_FILE_LOG_IMPL
if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" -chcp "%%OEMCP%%" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
) else call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
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

set "MOVE_FROM_LIST_FILE_TMP=%UNIQUE_LIST_FILE_TMP%"

:IGNORE_FILTER_UNIQUE_PATHS

echo.* Generating editable move list...

rem recreate empty list
type nul > "%MOVE_TO_LIST_FILE_TMP%"

if defined OPTIONAL_DEST_DIR (echo.# dest: "%OPTIONAL_DEST_DIR%") >> "%MOVE_TO_LIST_FILE_TMP%"

rem read selected file paths from file
for /F "usebackq tokens=* delims= eol=#" %%i in ("%MOVE_FROM_LIST_FILE_TMP%") do ( set "FILE_PATH=%%i" & call :FILL_TO_LIST_FILE_TMP )
goto FILL_TO_LIST_FILE_TMP_END

:COPY_FILE_LOG
set "COPY_FROM_FILE_PATH=%~f1"
set "COPY_TO_FILE_PATH=%~f2"
echo."%COPY_FROM_FILE_PATH%" -^> "%COPY_TO_FILE_PATH%"
if %FLAG_USE_SHELL_MSYS_MOVE% NEQ 0 ( "%MSYS_ROOT%/bin/cp.exe" --preserve=timestamps "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b )
if %FLAG_USE_SHELL_CYGWIN_MOVE% NEQ 0 ( "%CYGWIN_ROOT%/bin/cp.exe" --preserve=timestamps "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b )

type nul >> "\\?\%COPY_TO_FILE_PATH%"

if not exist "%COPY_FROM_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL
if not exist "%COPY_TO_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%
copy "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" /B /Y
set LASTERROR=%ERRORLEVEL%
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"
exit /b %LASTERROR%

:XCOPY_FILE_LOG_IMPL
if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" -chcp "%%OEMCP%%" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
) else call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
exit /b

:FILL_TO_LIST_FILE_TMP
rem avoid any quote characters
set "FILE_PATH=%FILE_PATH:"=%"

for /F "eol= tokens=* delims=" %%i in ("%FILE_PATH%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi|%%~nxi") do ( (echo.%%j) >> "%MOVE_TO_LIST_FILE_TMP%" )
exit /b 0

:FILL_TO_LIST_FILE_TMP_END
call :COPY_FILE_LOG "%%MOVE_TO_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%MOVE_FROM_LIST_FILE_NAME_TMP%%"
call :COPY_FILE_LOG "%%MOVE_TO_LIST_FILE_TMP%%" "%%PROJECT_LOG_DIR%%/%%MOVE_TO_LIST_FILE_NAME_TMP%%"

call "%%TACKLEBAR_SCRIPTS_ROOT%%/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst -notabbar "" "%%PROJECT_LOG_DIR%%/%%MOVE_TO_LIST_FILE_NAME_TMP%%"

"%SystemRoot%\System32\fc.exe" "%PROJECT_LOG_DIR:/=\%\%MOVE_TO_LIST_FILE_NAME_TMP:/=\%" "%MOVE_TO_LIST_FILE_TMP%" > nul && exit /b 0

call :COPY_FILE_LOG "%%PROJECT_LOG_DIR%%/%%MOVE_TO_LIST_FILE_NAME_TMP%%" "%%MOVE_TO_LIST_FILE_TMP%%"

echo.
echo.Moving...

rem trick with simultaneous iteration over 2 list in the same time
(
  for /F "usebackq eol= tokens=* delims=" %%i in ("%MOVE_TO_LIST_FILE_TMP%") do (
    set IS_LINE_EMPTY=1
    for /F "eol=# tokens=1,* delims=|" %%k in ("%%i") do set "IS_LINE_EMPTY="
    if defined IS_LINE_EMPTY (
      for /F "eol=# tokens=1,* delims=|" %%k in ("%%i") do if not "%%k" == "" if not "%%l" == "" set /P "FROM_FILE_PATH="
    ) else (
      set /P "FROM_FILE_PATH="
      set "TO_FILE_PATH=%%i"
      call :PROCESS_MOVE
    )
  )
) < "%MOVE_FROM_LIST_FILE_TMP%"

exit /b 0

:COPY_FILE_LOG
set "COPY_FROM_FILE_PATH=%~f1"
set "COPY_TO_FILE_PATH=%~f2"
echo."%COPY_FROM_FILE_PATH%" -^> "%COPY_TO_FILE_PATH%"
if %FLAG_USE_SHELL_MSYS_MOVE% NEQ 0 ( "%MSYS_ROOT%/bin/cp.exe" --preserve=timestamps "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b )
if %FLAG_USE_SHELL_CYGWIN_MOVE% NEQ 0 ( "%CYGWIN_ROOT%/bin/cp.exe" --preserve=timestamps "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" & exit /b )

type nul >> "\\?\%COPY_TO_FILE_PATH%"

if not exist "%COPY_FROM_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL
if not exist "%COPY_TO_FILE_PATH%" goto XCOPY_FILE_LOG_IMPL

if defined OEMCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%OEMCP%%
copy "%COPY_FROM_FILE_PATH%" "%COPY_TO_FILE_PATH%" /B /Y
set LASTERROR=%ERRORLEVEL%
if defined OEMCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat"
exit /b %LASTERROR%

:XCOPY_FILE_LOG_IMPL
if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" -chcp "%%OEMCP%%" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
) else call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%~dp1" "%%~nx1" "%%~dp2" /Y /H >nul
exit /b

:PROCESS_MOVE
if not defined FROM_FILE_PATH exit /b 2
if not defined TO_FILE_PATH exit /b 3

set "FROM_FILE_PATH=%FROM_FILE_PATH:/=\%"
set "TO_FILE_PATH=%TO_FILE_PATH:/=\%"

for /F "eol= tokens=* delims=" %%i in ("%FROM_FILE_PATH%\.") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi\.") do ( set "FROM_FILE_PATH=%%~fi" & set "FROM_FILE_DIR=%%~fj" & set "FROM_FILE_NAME=%%~nxi" )

rem extract destination path components
for /F "eol= tokens=1,* delims=|" %%i in ("%TO_FILE_PATH%") do ( set "TO_FILE_DIR=%%i" & set "TO_FILE_NAME=%%j" )

rem concatenate and renormalize
set "TO_FILE_PATH=%TO_FILE_DIR%\%TO_FILE_NAME%"

for /F "eol= tokens=* delims=" %%i in ("%TO_FILE_PATH%") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi\.") do ( set "TO_FILE_PATH=%%~fi" & set "TO_FILE_DIR=%%~fj" & set "TO_FILE_NAME=%%~nxi" )

rem file being moved to itself
if /i "%FROM_FILE_PATH%" == "%TO_FILE_PATH%" exit /b 0

echo."%FROM_FILE_PATH%" -^> "%TO_FILE_PATH%"

if not exist "\\?\%FROM_FILE_PATH%" (
  echo.%?~n0%: error: FROM_FILE_PATH is not found: "%FROM_FILE_PATH%".
  exit /b 4
) >&2

if exist "\\?\%TO_FILE_PATH%" (
  echo.%?~n0%: error: TO_FILE_PATH already exists: "%TO_FILE_PATH%".
  exit /b 5
) >&2

rem check recursion only if FROM_FILE_PATH is a directory
set FROM_FILE_PATH_AS_DIR=0
if not exist "\\?\%FROM_FILE_PATH%\" goto IGNORE_TO_FILE_PATH_CHECK
set FROM_FILE_PATH_AS_DIR=1

call "%%CONTOOLS_ROOT%%/filesys/subtract_path.bat" "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" && (
  echo.%?~n0%: error: TO_FILE_PATH file path must not contain FROM_FILE_PATH file path: FROM_FILE_PATH="%FROM_FILE_PATH%" TO_FILE_PATH="%TO_FILE_PATH%".
  exit /b 6
) >&2

:IGNORE_TO_FILE_PATH_CHECK

set TO_FILE_PATH_EXISTS=0
if exist "\\?\%TO_FILE_PATH%" set TO_FILE_PATH_EXISTS=1

if not exist "\\?\%TO_FILE_DIR%\" (
  echo.^>mkdir "%TO_FILE_DIR%"
  if %FLAG_USE_SHELL_MSYS_MOVE%%FLAG_USE_SHELL_CYGWIN_MOVE% EQU 0 (
    mkdir "%TO_FILE_DIR%" 2>nul || if exist "%SystemRoot%\System32\robocopy.exe" ( "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%TO_FILE_DIR%" >nul ) else type 2>nul || (
      echo.%?~nx0%: error: could not create a target file directory: "%TO_FILE_DIR%".
      exit /b 10
    ) >&2
  ) else if %FLAG_USE_SHELL_MSYS_MOVE% NEQ 0 (
    "%MSYS_ROOT%/bin/mkdir.exe" -p "%TO_FILE_DIR%"
  ) else "%CYGWIN_ROOT%/bin/mkdir.exe" -p "%TO_FILE_DIR%"
)

rem check if path is under GIT version control

rem WORKAROUND:
rem  Git ignores absolute path as an command argument and anyway searches current working directory for the repository.
rem  Use `pushd` to set the current directory to parent directory of being processed item.
rem

call :CMD pushd "%%FROM_FILE_DIR%%" && (
  git ls-files --error-unmatch "%FROM_FILE_PATH%" >nul 2>nul || ( popd & goto SHELL_MOVE )
  call :CMD git mv "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || ( popd & goto SHELL_MOVE )
  popd
  exit /b 0
)

goto SHELL_MOVE

:CMD
echo.^>%*
(%*)
exit /b

:SHELL_MOVE
if %FROM_FILE_PATH_AS_DIR% NEQ 0 goto XMOVE_FROM_FILE_PATH_AS_DIR

if %FLAG_USE_SHELL_MSYS_MOVE% NEQ 0 (
  call :CMD "%%MSYS_ROOT%%/bin/mv.exe" "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || exit /b 40
  exit /b 0
)
if %FLAG_USE_SHELL_CYGWIN_MOVE% NEQ 0 (
  call :CMD "%%CYGWIN_ROOT%%/bin/mv.exe" "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || exit /b 41
  exit /b 0
)

if /i "%FROM_FILE_NAME%" == "%TO_FILE_NAME%" goto XMOVE_FILE_WO_RENAME

call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.xmove_file_with_rename.bat" || exit /b 42
exit /b 0

:CMD
echo.^>%*
(%*)
exit /b

:XMOVE_FILE_WO_RENAME
rem create an empty destination file if not exist yet to check a path limitation issue
( type nul >> "\\?\%TO_FILE_PATH%" ) 2>nul

if exist "%FROM_FILE_PATH%" if exist "%TO_FILE_PATH%" (
  if %TO_FILE_PATH_EXISTS% EQU 0 "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/shell/delete_file.vbs" "\\?\%TO_FILE_PATH%" 2>nul
  call :CMD move "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" || exit /b 50
  exit /b 0
)

(
  if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" -chcp "%%OEMCP%%" "%%FROM_FILE_DIR%%" "%%TO_FILE_NAME%%" "%%TO_FILE_DIR%%" /Y /H /MOV
  ) else call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" "%%FROM_FILE_DIR%%" "%%TO_FILE_NAME%%" "%%TO_FILE_DIR%%" /Y /H /MOV
) || exit /b 51
exit /b 0

:CMD
echo.^>%*
(%*)
exit /b

:XMOVE_FROM_FILE_PATH_AS_DIR
if %FLAG_USE_SHELL_MSYS_MOVE% NEQ 0 (
  call :CMD "%%MSYS_ROOT%%/bin/mv.exe" "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%/" || exit /b 60
  exit /b 0
)
if %FLAG_USE_SHELL_CYGWIN_MOVE% NEQ 0 (
  call :CMD "%%CYGWIN_ROOT%%/bin/mv.exe" "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%/" || exit /b 65
  exit /b 0
)

(
  if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat" -chcp "%%OEMCP%%" -copy_dir "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" /E /Y /DCOPY:T /MOVE
  ) else call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat" -copy_dir "%%FROM_FILE_PATH%%" "%%TO_FILE_PATH%%" /E /Y /DCOPY:T /MOVE
) || exit /b 70
exit /b 0

:CMD
echo.^>%*
(%*)
exit /b
