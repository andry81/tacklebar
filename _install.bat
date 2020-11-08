@echo off

setlocal

set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

set TACKLEBAR_SCRIPTS_INSTALL=1

call "%%~dp0__init__/__init__.bat" 0 || exit /b

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
set /A NEST_LVL+=1

call "%%CONTOOLS_ROOT%%/std/chcp.bat" 65001
set RESTORE_LOCALE=1

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

set /A NEST_LVL-=1

if %NEST_LVL%0 EQU 0 pause

exit /b %LASTERROR%

:MAIN
rem script flags
rem set FLAG_IGNORE_BUTTONBARS=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  rem if "%FLAG%" == "-ignore_buttonbars" (
  rem   set FLAG_IGNORE_BUTTONBARS=1
  rem ) else
  (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

rem there to install
set "INSTALL_TO_DIR=%~1"

if not defined INSTALL_TO_DIR if not defined COMMANDER_SCRIPTS_ROOT (
  echo.%?~nx0%: error: INSTALL_TO_DIR must be defined if COMMANDER_SCRIPTS_ROOT is not defined
  exit /b 1
) >&2

if defined INSTALL_TO_DIR (
  call :CANONICAL_PATH INSTALL_TO_DIR "%%INSTALL_TO_DIR%%"
) else (
  call :CANONICAL_PATH COMMANDER_SCRIPTS_ROOT "%%COMMANDER_SCRIPTS_ROOT%%"
)

if defined INSTALL_TO_DIR (
  if not exist "%INSTALL_TO_DIR%\" (
    echo.%?~nx0%: error: INSTALL_TO_DIR is not a directory: "%INSTALL_TO_DIR%"
    exit /b 10
  ) >&2
) else (
  if not exist "%COMMANDER_SCRIPTS_ROOT%\" (
    echo.%?~nx0%: error: COMMANDER_SCRIPTS_ROOT is not a directory: "%COMMANDER_SCRIPTS_ROOT%"
    exit /b 11
  ) >&2
)

if defined INSTALL_TO_DIR goto IGNORE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK

echo.* COMMANDER_SCRIPTS_ROOT="%COMMANDER_SCRIPTS_ROOT%"
echo.The explicit installation directory is not defined, the installation will be proceed into directory from the `COMMANDER_SCRIPTS_ROOT` variable.
echo.Close all scripts has been running from the previous installation directory before continue (previous installation directory will be renamed).

:REPEAT_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK
echo.Do you want to continue [y]es/[N]o?
set /P "INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK="

if /i "%INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK%" == "y" goto CONTINUE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT
if /i "%INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK%" == "n" goto CANCEL_INSTALL_TO_COMMANDER_SCRIPTS_ROOT

goto REPEAT_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK

:CANCEL_INSTALL_TO_COMMANDER_SCRIPTS_ROOT
(
    echo.%?~nx0%: info: installation is canceled.
    exit /b 20
) >&2

:IGNORE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK
:CONTINUE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT

if not defined INSTALL_TO_DIR (
  set "INSTALL_TO_DIR=%COMMANDER_SCRIPTS_ROOT%"
)

set "PREV_INSTALL_DIR="

if not exist "%INSTALL_TO_DIR%\tacklebar" goto IGNORE_INSTALLATION_DIR_RENAME

rem NOTE:
rem   Rename already existed installation directory into a unique one using `changelog.txt` file in the previous installation project root directory.

if not exist "%INSTALL_TO_DIR%\tacklebar\changelog.txt" goto RENAME_INSTALLATION_DIR_WITH_CURRENT_DATE

set "LAST_CHANGELOG_DATE="
for /F "usebackq eol= tokens=* delims=" %%i in (`@type "%INSTALL_TO_DIR%\tacklebar\changelog.txt" ^| findstr /R /B "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*:"`) do (
  set "LAST_CHANGELOG_DATE=%%i"
  goto CONTINUE_INSTALLATION_DIR_RENAME_1
)

:CONTINUE_INSTALLATION_DIR_RENAME_1
if not defined LAST_CHANGELOG_DATE goto RENAME_INSTALLATION_DIR_WITH_CURRENT_DATE

set "LAST_CHANGELOG_DATE=%LAST_CHANGELOG_DATE:"=%"
set "LAST_CHANGELOG_DATE=%LAST_CHANGELOG_DATE::=%"
set "LAST_CHANGELOG_DATE=%LAST_CHANGELOG_DATE:.='%"

set "PREV_INSTALL_DIR=tacklebar_old_%LAST_CHANGELOG_DATE%_%LOG_FILE_NAME_SUFFIX%"

rename "%INSTALL_TO_DIR%\tacklebar" "%PREV_INSTALL_DIR%" || (
  echo.%?~nx0%: error: could not rename previous installation directory: "%INSTALL_TO_DIR%\tacklebar" -^> "%PREV_INSTALL_DIR%"
  exit /b 30
) >&2

goto END_INSTALLATION_DIR_RENAME

:RENAME_INSTALLATION_DIR_WITH_CURRENT_DATE

set "PREV_INSTALL_DIR=tacklebar_old_%LOG_FILE_NAME_SUFFIX%"

rename "%INSTALL_TO_DIR%\tacklebar" "%PREV_INSTALL_DIR%" || (
  echo.%?~nx0%: error: could not rename previous installation directory: "%INSTALL_TO_DIR%\tacklebar" -^> "%PREV_INSTALL_DIR%"
  exit /b 31
) >&2

:END_INSTALLATION_DIR_RENAME
:IGNORE_INSTALLATION_DIR_RENAME

rem installing...

rem CAUTION:
rem   The `cmd_admin.lnk` call must be in any case, because a cancel is equal to cancel the installation

call :CMD "%%CONTOOLS_ROOT%%/ToolAdaptors/lnk/cmd_admin.lnk" /C @setx /M COMMANDER_SCRIPTS_ROOT "%%INSTALL_TO_DIR:/=\%%" || (
  echo.%?~nx0%: info: installation is canceled.
  exit /b 30
) >&2

rem exclude all version control system directories
set "XCOPY_EXCLUDE_DIRS_LIST=.svn|.git|.hg"

call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/deploy/.saveload" "%%INSTALL_TO_DIR%%/.saveload" /E /Y /D || exit /b

rem basic initialization
call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/__init__"         "%%INSTALL_TO_DIR%%/tacklebar/__init__" /E /Y /D || exit /b
call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/_config"          "%%INSTALL_TO_DIR%%/tacklebar/_config" /E /Y /D || exit /b
call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/_externals"       "%%INSTALL_TO_DIR%%/tacklebar/_externals" /E /Y /D || exit /b

call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/deploy/totalcmd/ButtonBars" "%%INSTALL_TO_DIR%%/tacklebar/ButtonBars" /E /Y /D || exit /b

call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/res/images"       "%%INSTALL_TO_DIR%%/tacklebar/res/images" /E /Y /D || exit /b
call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/src"              "%%INSTALL_TO_DIR%%/tacklebar/src" /E /Y /D || exit /b

call :XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%"                 changelog.txt "%%INSTALL_TO_DIR%%/tacklebar" /Y /D /H || exit /b
call :XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%"                 README_EN.txt "%%INSTALL_TO_DIR%%/tacklebar" /Y /D /H || exit /b

if not exist "%SYSTEMROOT%\System64\" (
  call :CMD "%%CONTOOLS_ROOT%%/ToolAdaptors/lnk/mklink_system64.bat"
  if exist "%SYSTEMROOT%\System64\" (
    echo."%SYSTEMROOT%\System64" -^> "%SYSTEMROOT%\System32"
  ) else (
    echo.%?~nx0%: error: could not create directory link: "%SYSTEMROOT%\System64" -^> "%SYSTEMROOT%\System32"
    exit /b 255
  ) >&2
)

rem drop project variables to reinitialize them in the inititialization script on demand
set "TACKLEBAR_SCRIPTS_INSTALL="
set "PROJECT_OUTPUT_ROOT="

rem run the inititialization script in an installation directory to generate configuration files
call "%%INSTALL_TO_DIR%%/tacklebar/__init__/__init__.bat" 0 || exit /b

rem detect 3dparty applications to merge/edit the user configuration file (`config.0.vars`)

if not defined PREV_INSTALL_DIR goto NOTEPAD_EDIT_USER_CONFIG

set "PREV_INSTALL_ROOT=%INSTALL_TO_DIR%/%PREV_INSTALL_DIR%"

if not exist "%PREV_INSTALL_ROOT%/_out/config/tacklebar/config.0.vars" goto NOTEPAD_EDIT_USER_CONFIG

if defined ARAXIS_COMPARE_TOOL if exist "%ARAXIS_COMPARE_TOOL%" goto ARAXIS_COMPARE_TOOL

echo.Searching AraxisMerge installation...

rem Fast check at first
set "ARAXIS_MERGE_UNINSTALL_HKEY=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{E710B3E8-248F-4C36-AD17-E0B1A9AF10FA}"
call :PROCESS_ARAXIS_MERGE_UNINSTALL_HKEY && goto END_ENUM_ARAXIS_MERGE_UNINSTALL_HKEY

set "ARAXIS_MERGE_UNINSTALL_HKEY=HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{E710B3E8-248F-4C36-AD17-E0B1A9AF10FA}"
call :PROCESS_ARAXIS_MERGE_UNINSTALL_HKEY && goto END_ENUM_ARAXIS_MERGE_UNINSTALL_HKEY

set "ARAXIS_MERGE_UNINSTALL_HKEY=HKEY_LOCAL_MACHINE\SOFTWARE\System64\Microsoft\Windows\CurrentVersion\Uninstall\{E710B3E8-248F-4C36-AD17-E0B1A9AF10FA}"
call :PROCESS_ARAXIS_MERGE_UNINSTALL_HKEY && goto END_ENUM_ARAXIS_MERGE_UNINSTALL_HKEY

rem Slow full check
for /F "usebackq eol= tokens=* delims=" %%i in (`@call "%%CONTOOLS_ROOT%%/registry/regenum.bat" "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"`) do (
  set "ARAXIS_MERGE_UNINSTALL_HKEY=%%i"
  call :PROCESS_ARAXIS_MERGE_UNINSTALL_HKEY && goto END_ENUM_ARAXIS_MERGE_UNINSTALL_HKEY
)

goto DETECT_WINMERGE_TOOL

:PROCESS_ARAXIS_MERGE_UNINSTALL_HKEY
call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "%%ARAXIS_MERGE_UNINSTALL_HKEY%%" DisplayName >nul 2>nul
if not defined REGQUERY_VALUE exit /b 255

rem remove all quotes
set "REGQUERY_VALUE=%REGQUERY_VALUE:"=%"
if /i not "%REGQUERY_VALUE:~0,7%" == "Araxis " exit /b 255

call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "%%ARAXIS_MERGE_UNINSTALL_HKEY%%" InstallLocation >nul 2>nul
if not defined REGQUERY_VALUE exit /b 255

rem remove all quotes
set "REGQUERY_VALUE=%REGQUERY_VALUE:"=%"

call :CANONICAL_PATH ARAXIS_COMPARE_TOOL "%REGQUERY_VALUE%/Compare.exe"

exit /b 0

:END_ENUM_ARAXIS_MERGE_UNINSTALL_HKEY

if not exist "%ARAXIS_COMPARE_TOOL%" goto DETECT_WINMERGE_TOOL

:ARAXIS_COMPARE_TOOL
"%ARAXIS_COMPARE_TOOL%" /wait "%PREV_INSTALL_ROOT%/_out/config/tacklebar/config.0.vars" "%INSTALL_TO_DIR%/tacklebar/_out/config/tacklebar/config.0.vars"

goto END_INSTALL

exit /b 0

:DETECT_WINMERGE_TOOL

(
  echo.%?~nx0%: warning: Araxis Merge is not detected.
) >&2

echo.Searching WinMerge installation...

rem 64-bit version at first
call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_LOCAL_MACHINE\SOFTWARE\Thingamahoochie\WinMerge" Executable >nul 2>nul

if %ERRORLEVEL% NEQ 0 call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Thingamahoochie\WinMerge" Executable >nul 2>nul

if %ERRORLEVEL% NEQ 0 call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_LOCAL_MACHINE\SOFTWARE\System64\Thingamahoochie\WinMerge" Executable >nul 2>nul

if not defined REGQUERY_VALUE goto NOTEPAD_EDIT_USER_CONFIG

rem remove all quotes
set "REGQUERY_VALUE=%REGQUERY_VALUE:"=%"

call :CANONICAL_PATH WINMERGE_COMPARE_TOOL "%REGQUERY_VALUE%"

echo WINMERGE_COMPARE_TOOL=%WINMERGE_COMPARE_TOOL%

if not exist "%WINMERGE_COMPARE_TOOL%" goto NOTEPAD_EDIT_USER_CONFIG

"%WINMERGE_COMPARE_TOOL%" "%PREV_INSTALL_ROOT%/_out/config/tacklebar/config.0.vars" "%INSTALL_TO_DIR%/tacklebar/_out/config/tacklebar/config.0.vars"

goto END_INSTALL

exit /b 0

:NOTEPAD_EDIT_USER_CONFIG

(
  echo.%?~nx0%: warning: WinMerge is not detected.
) >&2

echo.Searching Notepad++ installation...

rem 32-bit version at first
call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Notepad++" >nul 2>nul
if %ERRORLEVEL% NEQ 0 call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_LOCAL_MACHINE\SOFTWARE\Notepad++" >nul 2>nul

if not defined REGQUERY_VALUE (
  echo.%?~nx0%: error: Notepad++ is not detected, do edit configuration file manually: "%INSTALL_TO_DIR%/tacklebar/_out/config/tacklebar/config.0.vars"
) >&2

rem remove all quotes
set "REGQUERY_VALUE=%REGQUERY_VALUE:"=%"

call :CANONICAL_PATH NPP_EDITOR "%REGQUERY_VALUE%/notepad++.exe"

call "%%TACKLEBAR_PROJECT_ROOT%%/src/scripts/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst "%%INSTALL_TO_DIR%%/tacklebar/_out/config/tacklebar" config.0.vars

goto END_INSTALL

exit /b 0

:END_INSTALL

echo.%?~nx0%: info: installation is complete.

exit /b 0

:XCOPY_FILE
if not exist "%CONTOOLS_ROOT%/std/xcopy_file.bat" (
  echo.%?~nx0%: error: xcopy_file.bat is not found: "%CONTOOLS_ROOT%/std/xcopy_file.bat".
  exit /b 5
) >&2
if not exist "%~3" mkdir "%~3"
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" %%* || exit /b
exit /b 0

:XCOPY_DIR
if not exist "%CONTOOLS_ROOT%/std/xcopy_dir.bat" (
  echo.%?~nx0%: error: xcopy_dir.bat is not found: "%CONTOOLS_ROOT%/std/xcopy_dir.bat".
  exit /b 6
) >&2
if not exist "%~2" mkdir "%~2"
call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat" %%* || exit /b
exit /b 0

:COPY_FILE
echo."%~1" -^> "%~2"
copy "%~f1" "%~f2" /B /Y || exit /b
exit /b 0

:CMD
echo.^>%*
(%*)
exit /b

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
set "RETURN_VALUE=%~dpf2"
set "RETURN_VALUE=%RETURN_VALUE:\=/%"
if "%RETURN_VALUE:~-1%" == "/" set "RETURN_VALUE=%RETURN_VALUE:~0,-1%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
