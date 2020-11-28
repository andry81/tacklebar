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
set LASTERROR=%ERRORLEVEL%

call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" COMMANDER_SCRIPTS_ROOT >nul 2>nul
if defined REGQUERY_VALUE set "COMMANDER_SCRIPTS_ROOT=%REGQUERY_VALUE%"

rem return registered variables outside to reuse them again from the same process
(
  endlocal
  set "COMMANDER_SCRIPTS_ROOT=%COMMANDER_SCRIPTS_ROOT%"
  exit /b %LASTERROR%
)

:IMPL
set /A NEST_LVL+=1

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%"

call "%%CONTOOLS_ROOT%%/std/chcp.bat" 65001
set RESTORE_LOCALE=1

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

set /A NEST_LVL-=1

if %NEST_LVL%0 EQU 0 pause

exit /b %LASTERROR%

:MAIN
rem call :CMD "%%PYTHON_EXE_PATH%%" "%%TACKLEBAR_PROJECT_ROOT%%/_install.xsh"
rem exit /b
rem 
rem :CMD
rem echo.^>%*
rem echo.
rem (
rem   %*
rem )
rem exit /b

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

set "EMPTY_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\emptydir"

mkdir "%EMPTY_DIR_TMP%" || (
  echo.%?~n0%: error: could not create a directory: "%EMPTY_DIR_TMP%".
  exit /b 255
) >&2

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
  if not exist "\\?\%INSTALL_TO_DIR%\" (
    echo.%?~nx0%: error: INSTALL_TO_DIR is not a directory: "%INSTALL_TO_DIR%"
    exit /b 10
  ) >&2
) else (
  if not exist "\\?\%COMMANDER_SCRIPTS_ROOT%\" (
    echo.%?~nx0%: error: COMMANDER_SCRIPTS_ROOT is not a directory: "%COMMANDER_SCRIPTS_ROOT%"
    exit /b 11
  ) >&2
)

if defined INSTALL_TO_DIR goto IGNORE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK

echo.* COMMANDER_SCRIPTS_ROOT="%COMMANDER_SCRIPTS_ROOT%"
echo.The explicit installation directory is not defined, the installation will be proceed into directory from the `COMMANDER_SCRIPTS_ROOT` variable.
echo.Close all scripts has been running from the previous installation directory before continue (previous installation directory will be moved and renamed).

:REPEAT_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK
set "CONTINUE_INSTALL_ASK="
echo.Do you want to continue [y]es/[n]o?
set /P "CONTINUE_INSTALL_ASK="

if /i "%CONTINUE_INSTALL_ASK%" == "y" goto CONTINUE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT
if /i "%CONTINUE_INSTALL_ASK%" == "n" goto CANCEL_INSTALL_TO_COMMANDER_SCRIPTS_ROOT

goto REPEAT_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK

:CANCEL_INSTALL_TO_COMMANDER_SCRIPTS_ROOT
(
  echo.%?~nx0%: info: installation is canceled.
  exit /b 127
) >&2

:IGNORE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK
:CONTINUE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT

if not defined INSTALL_TO_DIR set "INSTALL_TO_DIR=%COMMANDER_SCRIPTS_ROOT%"

echo.
echo.Required set of 3dparty applications:
echo. * Notepad++ (7.9.1+, https://notepad-plus-plus.org/downloads/ )
echo. * Notepad++ PythonScript plugin (1.5.4+, https://github.com/bruderstein/PythonScript )
echo. * WinMerge (2.16.8+, https://winmerge.org/downloads )
echo.
echo.Optional set of 3dparty applications:
echo. * Araxis Merge (2017+, https://www.araxis.com/merge/documentation-windows/release-notes.en )
echo.
echo. CAUTION:
echo.   You must install at least Notepad++ (with PythonScript plugin) and WinMerge (or Araxis Merge) to continue.
echo.

:REPEAT_INSTALL_3DPARTY_ASK
set "CONTINUE_INSTALL_ASK="
echo.Do you want to continue [y]es/[n]o?
set /P "CONTINUE_INSTALL_ASK="

if /i "%CONTINUE_INSTALL_ASK%" == "y" goto CONTINUE_INSTALL_3DPARTY_ASK
if /i "%CONTINUE_INSTALL_ASK%" == "n" goto CANCEL_INSTALL_3DPARTY_ASK

goto REPEAT_INSTALL_3DPARTY_ASK

:CANCEL_INSTALL_3DPARTY_ASK
(
  echo.%?~nx0%: info: installation is canceled.
  exit /b 127
) >&2

:CONTINUE_INSTALL_3DPARTY_ASK

rem CAUTION:
rem   Always detect all programs to print detected variable values

call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.detect_3dparty.notepadpp.bat"
call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.detect_3dparty.notepadpp.pythonscript_plugin.tacklebar_extension.bat"
call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.detect_3dparty.winmerge.bat"
call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.detect_3dparty.araxismerge.bat"

echo.

if defined DETECTED_NPP_EDITOR if exist "%DETECTED_NPP_EDITOR%" goto DETECTED_NPP_EDITOR_OK

(
  echo.%?~nx0%: error: Notepad++ must be already installed before continue.
  echo.%?~nx0%: info: installation is canceled.
  exit /b 127
) >&2

:DETECTED_NPP_EDITOR_OK

if %DETECTED_NPP_PYTHONSCRIPT_PLUGIN_TKL_EXT%0 NEQ 0 goto DETECTED_NPP_PYTHONSCRIPT_PLUGIN_TKL_EXT_OK

(
  echo.%?~nx0%: error: Notepad++ PythonScript plugin tacklebar extension must be already installed before continue.
  echo.%?~nx0%: info: installation is canceled.
  exit /b 127
) >&2

:DETECTED_NPP_PYTHONSCRIPT_PLUGIN_TKL_EXT_OK

if defined DETECTED_WINMERGE_COMPARE_TOOL if exist "%DETECTED_WINMERGE_COMPARE_TOOL%" goto DETECTED_WINMERGE_COMPARE_TOOL_OK
if defined DETECTED_ARAXIS_COMPARE_TOOL if exist "%DETECTED_ARAXIS_COMPARE_TOOL%" goto DETECTED_ARAXIS_COMPARE_TOOL_OK

(
  echo.%?~nx0%: error: WinMerge or Araxis Merge must be already installed before continue.
  echo.%?~nx0%: info: installation is canceled.
  exit /b 127
) >&2

:DETECTED_WINMERGE_COMPARE_TOOL_OK
:DETECTED_ARAXIS_COMPARE_TOOL_OK

set "NEW_PREV_INSTALL_DIR=%INSTALL_TO_DIR%\.tacklebar_prev_install\tacklebar_prev_install_%LOG_FILE_NAME_SUFFIX%"

if not exist "\\?\%INSTALL_TO_DIR%\tacklebar" goto IGNORE_PREV_INSTALLATION_DIR_MOVE

rem NOTE:
rem   Move and rename already existed installation directory into a unique one using `changelog.txt` file in the previous installation project root directory.

if not exist "\\?\%INSTALL_TO_DIR%\tacklebar\changelog.txt" goto MOVE_RENAME_INSTALLATION_DIR_WITH_CURRENT_DATE

set "LAST_CHANGELOG_DATE="
for /F "usebackq eol= tokens=* delims=" %%i in (`@type "%INSTALL_TO_DIR%\tacklebar\changelog.txt" ^| "%WINDIR%/System32/findstr.exe" /R /B "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*:"`) do (
  set "LAST_CHANGELOG_DATE=%%i"
  goto CONTINUE_INSTALLATION_DIR_RENAME_1
)

:CONTINUE_INSTALLATION_DIR_RENAME_1
if not defined LAST_CHANGELOG_DATE goto MOVE_RENAME_INSTALLATION_DIR_WITH_CURRENT_DATE

set "LAST_CHANGELOG_DATE=%LAST_CHANGELOG_DATE:"=%"
set "LAST_CHANGELOG_DATE=%LAST_CHANGELOG_DATE::=%"
set "LAST_CHANGELOG_DATE=%LAST_CHANGELOG_DATE:.='%"

set "NEW_PREV_INSTALL_DIR=%INSTALL_TO_DIR%\.tacklebar_prev_install\tacklebar_prev_install_%LAST_CHANGELOG_DATE%_%LOG_FILE_NAME_SUFFIX%"

if not exist "\\?\%NEW_PREV_INSTALL_DIR%" (
  echo.^>mkdir "%NEW_PREV_INSTALL_DIR%"
  mkdir "%NEW_PREV_INSTALL_DIR%" 2>nul || "%WINDIR%/System32/robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%NEW_PREV_INSTALL_DIR%" >nul
  if not exist "\\?\%NEW_PREV_INSTALL_DIR%" (
    echo.%?~nx0%: error: could not create a backup file directory: "%NEW_PREV_INSTALL_DIR%".
    exit /b 20
  ) >&2
)

echo.^>move: "%INSTALL_TO_DIR%\tacklebar" -^> "%NEW_PREV_INSTALL_DIR%"
"%WINDIR%/System32/robocopy.exe" /MOVE /E "%INSTALL_TO_DIR%\tacklebar" "%NEW_PREV_INSTALL_DIR%" "*.*" >nul
if not exist "\\?\%NEW_PREV_INSTALL_DIR%" (
  echo.%?~nx0%: error: could not move previous installation directory: "%INSTALL_TO_DIR%\tacklebar" -^> "%NEW_PREV_INSTALL_DIR%"
  exit /b 21
) >&2

goto END_PREV_INSTALLATION_DIR_MOVE

:MOVE_RENAME_INSTALLATION_DIR_WITH_CURRENT_DATE

if not exist "\\?\%NEW_PREV_INSTALL_DIR%" (
  echo.^>mkdir "%NEW_PREV_INSTALL_DIR%"
  mkdir "%NEW_PREV_INSTALL_DIR%" 2>nul || "%WINDIR%/System32/robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%NEW_PREV_INSTALL_DIR%" >nul
  if not exist "\\?\%NEW_PREV_INSTALL_DIR%" (
    echo.%?~nx0%: error: could not create a backup file directory: "%NEW_PREV_INSTALL_DIR%".
    exit /b 30
  ) >&2
)

echo.^>move: "%INSTALL_TO_DIR%\tacklebar" -^> "%NEW_PREV_INSTALL_DIR%"
"%WINDIR%/System32/robocopy.exe" /MOVE /E "%INSTALL_TO_DIR%\tacklebar" "%NEW_PREV_INSTALL_DIR%" "*.*" >nul
if not exist "\\?\%NEW_PREV_INSTALL_DIR%" (
  echo.%?~nx0%: error: could not move previous installation directory: "%INSTALL_TO_DIR%\tacklebar" -^> "%NEW_PREV_INSTALL_DIR%"
  exit /b 31
) >&2

:END_PREV_INSTALLATION_DIR_MOVE
:IGNORE_PREV_INSTALLATION_DIR_MOVE

rem installing...

rem CAUTION:
rem   The `cmd_admin.lnk` call must be in any case, because a cancel is equal to cancel the installation

set "COMMANDER_SCRIPTS_ROOT=%INSTALL_TO_DIR:/=\%"

call :CMD "%%CONTOOLS_ROOT%%/ToolAdaptors/lnk/cmd_admin.lnk" /C @setx /M COMMANDER_SCRIPTS_ROOT "%%COMMANDER_SCRIPTS_ROOT%%" || (
  echo.%?~nx0%: info: installation is canceled.
  exit /b 127
) >&2

rem exclude all version control system directories
set "XCOPY_EXCLUDE_DIRS_LIST=.svn|.git|.hg"

call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/deploy/.saveload" "%%INSTALL_TO_DIR%%/.saveload" /E /Y /D || exit /b 126

rem basic initialization
call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/__init__"         "%%INSTALL_TO_DIR%%/tacklebar/__init__" /E /Y /D || exit /b 126
call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/_config"          "%%INSTALL_TO_DIR%%/tacklebar/_config" /E /Y /D || exit /b 126
call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/_externals"       "%%INSTALL_TO_DIR%%/tacklebar/_externals" /E /Y /D || exit /b 126

call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/deploy/totalcmd/ButtonBars" "%%INSTALL_TO_DIR%%/tacklebar/ButtonBars" /E /Y /D || exit /b 126

call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/res/images"       "%%INSTALL_TO_DIR%%/tacklebar/res/images" /E /Y /D || exit /b 126
call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/src"              "%%INSTALL_TO_DIR%%/tacklebar/src" /E /Y /D || exit /b 126

call :XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%"                 changelog.txt "%%INSTALL_TO_DIR%%/tacklebar" /Y /D /H || exit /b 126
call :XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%"                 README_EN.txt "%%INSTALL_TO_DIR%%/tacklebar" /Y /D /H || exit /b 126

if not exist "%SYSTEMROOT%\System64\" (
  call :CMD "%%CONTOOLS_ROOT%%/ToolAdaptors/lnk/mklink_system64.bat"
  if exist "%SYSTEMROOT%\System64\" (
    echo."%SYSTEMROOT%\System64" -^> "%SYSTEMROOT%\System32"
  ) else (
    echo.%?~nx0%: error: could not create directory link: "%SYSTEMROOT%\System64" -^> "%SYSTEMROOT%\System32"
    exit /b 126
  ) >&2
)

rem drop project variables to reinitialize them in the inititialization script on demand
set "TACKLEBAR_SCRIPTS_INSTALL="
set "PROJECT_OUTPUT_ROOT="

rem run the inititialization script in an installation directory to generate configuration files
call "%%INSTALL_TO_DIR%%/tacklebar/__init__/__init__.bat" 0 || exit /b

rem detect 3dparty applications to merge/edit the user configuration file (`config.0.vars`)

if exist "%INSTALL_TO_DIR%/tacklebar\" goto PREV_INSTALL_ROOT_EXIST

(
  echo.%?~nx0%: note: previous installation directory is not found: "%INSTALL_TO_DIR%/tacklebar"
)

:PREV_INSTALL_ROOT_EXIST

if not exist "\\?\%NEW_PREV_INSTALL_DIR%/_out/config/tacklebar/config.0.vars" goto NOTEPAD_EDIT_USER_CONFIG

echo DETECTED_ARAXIS_COMPARE_TOOL=%DETECTED_ARAXIS_COMPARE_TOOL%
if defined DETECTED_ARAXIS_COMPARE_TOOL (
  "%DETECTED_ARAXIS_COMPARE_TOOL%" /wait "%NEW_PREV_INSTALL_DIR%/_out/config/tacklebar/config.0.vars" "%INSTALL_TO_DIR%/tacklebar/_out/config/tacklebar/config.0.vars"
  goto END_INSTALL
) else if defined DETECTED_WINMERGE_COMPARE_TOOL (
  "%DETECTED_WINMERGE_COMPARE_TOOL%" "%NEW_PREV_INSTALL_DIR%/_out/config/tacklebar/config.0.vars" "%INSTALL_TO_DIR%/tacklebar/_out/config/tacklebar/config.0.vars"
  goto END_INSTALL
) else (
  echo.%?~nx0%: error: No one text file merge application is detected.
  goto NOTEPAD_EDIT_USER_CONFIG
) >&2

:NOTEPAD_EDIT_USER_CONFIG
if not defined DETECTED_NPP_EDITOR goto IGNORE_NOTEPAD_EDIT_USER_CONFIG
if not exist "%DETECTED_NPP_EDITOR%" goto IGNORE_NOTEPAD_EDIT_USER_CONFIG

set "NPP_EDITOR=%DETECTED_NPP_EDITOR%"
call "%%TACKLEBAR_PROJECT_ROOT%%/src/scripts/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst "%%INSTALL_TO_DIR%%" "%%INSTALL_TO_DIR%%/tacklebar/_out/config/tacklebar/config.0.vars"

goto END_INSTALL

:IGNORE_NOTEPAD_EDIT_USER_CONFIG
(
  echo.%?~nx0%: warning: Notepad++ is not detected, do edit configuration file manually: "%INSTALL_TO_DIR%/tacklebar/_out/config/tacklebar/config.0.vars"
) >&2

:END_INSTALL

echo.%?~nx0%: info: installation is complete.

exit /b 0

:XCOPY_FILE
if not exist "\\?\%~f3" (
  echo.^>mkdir "%~3"
  mkdir "%~3" 2>nul || "%WINDIR%/System32/robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%~3" >nul || (
    echo.%?~nx0%: error: could not create a target file directory: "%~3".
    exit /b 255
  ) >&2
)
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" %%*
exit /b

:XCOPY_DIR
if not exist "\\?\%~f2" (
  echo.^>mkdir "%~2"
  mkdir "%~2" 2>nul || "%WINDIR%/System32/robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%~2" >nul || (
    echo.%?~nx0%: error: could not create a target directory: "%~2".
    exit /b 255
  ) >&2
)
call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat" %%*
exit /b

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
