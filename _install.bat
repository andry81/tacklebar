@echo off

setlocal

call "%%~dp0._install/script_init.bat" tacklebar install %%0 %%* || exit /b
if %IMPL_MODE%0 NEQ 0 goto IMPL

call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" COMMANDER_SCRIPTS_ROOT >nul 2>nul
if defined REGQUERY_VALUE set "COMMANDER_SCRIPTS_ROOT=%REGQUERY_VALUE%"

exit /b 0

:IMPL
rem where to install
call "%%CONTOOLS_ROOT%%/std/setshift.bat" %%FLAG_SHIFT%% INSTALL_TO_DIR %%* || exit /b

rem CAUTION:
rem   We have to change the codepage here because the change would be revoked upon the UAC promotion.
rem

if defined FLAG_CHCP ( call "%%CONTOOLS_ROOT%%/std/chcp.bat" -p %%FLAG_CHCP%%
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || ( set "LAST_ERROR=255" & goto FREE_TEMP_DIR )

set "XCOPY_FILE_CMD_BARE_FLAGS="
set "XCOPY_DIR_CMD_BARE_FLAGS="
set "XMOVE_FILE_CMD_BARE_FLAGS="
set "XMOVE_DIR_CMD_BARE_FLAGS="
if defined OEMCP (
  set XCOPY_FILE_CMD_BARE_FLAGS=%XCOPY_FILE_CMD_BARE_FLAGS% -chcp "%OEMCP%"
  set XCOPY_DIR_CMD_BARE_FLAGS=%XCOPY_DIR_CMD_BARE_FLAGS% -chcp "%OEMCP%"
  set XMOVE_FILE_CMD_BARE_FLAGS=%XMOVE_FILE_CMD_BARE_FLAGS% -chcp "%OEMCP%"
  set XMOVE_DIR_CMD_BARE_FLAGS=%XMOVE_DIR_CMD_BARE_FLAGS% -chcp "%OEMCP%"
)

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

:FREE_TEMP_DIR
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

:FREE_TEMP_DIR_END
rem restore locale
if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat" -p

set /A NEST_LVL-=1

echo.%?~nx0%: info: installation log directory: "%PROJECT_LOG_DIR%".
echo.

if %LAST_ERROR% EQU 0 (
  rem run the log directory copy loop
  start /B "" "%SystemRoot%\System32\cmd.exe" /c @"%%?~dp0%%._install\_install.xcopy_log_dir_task.bat" ^<nul
) else (
  echo.%?~nx0%: warning: installation log directory is not copied.
  echo.
) >&2

rem return registered variables outside to reuse them again from the same process
(
  endlocal
  if defined COMMANDER_SCRIPTS_ROOT set "COMMANDER_SCRIPTS_ROOT=%COMMANDER_SCRIPTS_ROOT%"
  exit /b %LAST_ERROR%
)

:MAIN
rem call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/callln.bat" "%%PYTHON_EXE_PATH%%" "%%TACKLEBAR_PROJECT_ROOT%%/_install.xsh"
rem exit /b

if not defined INSTALL_TO_DIR if not defined COMMANDER_SCRIPTS_ROOT goto SELECT_INSTALL_TO_DIR

if defined INSTALL_TO_DIR call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" INSTALL_TO_DIR "%%INSTALL_TO_DIR%%"
if defined COMMANDER_SCRIPTS_ROOT call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" COMMANDER_SCRIPTS_ROOT "%%COMMANDER_SCRIPTS_ROOT%%"

if defined INSTALL_TO_DIR (
  if not exist "\\?\%INSTALL_TO_DIR%\*" (
    echo.%?~nx0%: error: INSTALL_TO_DIR is not a directory: "%INSTALL_TO_DIR%"
    exit /b 10
  ) >&2
) else if not exist "\\?\%COMMANDER_SCRIPTS_ROOT%\*" (
  echo.%?~nx0%: warning: COMMANDER_SCRIPTS_ROOT is not a directory: "%COMMANDER_SCRIPTS_ROOT%"
  goto SELECT_INSTALL_TO_DIR
) >&2

if not defined INSTALL_TO_DIR goto CONTINUE_INSTALL_TO_INSTALL_TO_DIR
if not defined COMMANDER_SCRIPTS_ROOT goto CONTINUE_INSTALL_TO_INSTALL_TO_DIR

if /i not "%INSTALL_TO_DIR%" == "%COMMANDER_SCRIPTS_ROOT%" (
  echo.*         INSTALL_TO_DIR="%INSTALL_TO_DIR%"
  echo.* COMMANDER_SCRIPTS_ROOT="%COMMANDER_SCRIPTS_ROOT%"
  echo.
  echo.The `COMMANDER_SCRIPTS_ROOT` variable is defined and is different to the inputed `INSTALL_TO_DIR`.
) >&2 else goto CONTINUE_INSTALL_TO_INSTALL_TO_DIR

:REPEAT_INSTALL_TO_INSTALL_TO_DIR_ASK
set "CONTINUE_INSTALL_ASK="
echo.Do you want to install into different directory [y]es/[n]o?
set /P "CONTINUE_INSTALL_ASK="

if /i "%CONTINUE_INSTALL_ASK%" == "y" goto CONTINUE_INSTALL_TO_INSTALL_TO_DIR
if /i "%CONTINUE_INSTALL_ASK%" == "n" goto CANCEL_INSTALL

goto REPEAT_INSTALL_TO_INSTALL_TO_DIR_ASK

:CONTINUE_INSTALL_TO_INSTALL_TO_DIR

if defined INSTALL_TO_DIR goto IGNORE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK

echo.* COMMANDER_SCRIPTS_ROOT="%COMMANDER_SCRIPTS_ROOT%"
echo.
echo.The explicit installation directory is not defined, the installation will be proceed into directory from the `COMMANDER_SCRIPTS_ROOT` variable.
echo.Close all scripts has been running from the previous installation directory before continue (previous installation directory will be moved and renamed).
echo.

:REPEAT_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK
set "CONTINUE_INSTALL_ASK="
echo.Do you want to continue [y]es/[n]o/[s]elect another directory?
set /P "CONTINUE_INSTALL_ASK="

if /i "%CONTINUE_INSTALL_ASK%" == "y" goto CONTINUE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT
if /i "%CONTINUE_INSTALL_ASK%" == "n" goto CANCEL_INSTALL
if /i "%CONTINUE_INSTALL_ASK%" == "s" goto SELECT_INSTALL_TO_DIR

goto REPEAT_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK

:IGNORE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT_ASK
:CONTINUE_INSTALL_TO_COMMANDER_SCRIPTS_ROOT

call "%%CONTOOLS_ROOT%%/std/canonical_path_if_ndef.bat" INSTALL_TO_DIR "%%COMMANDER_SCRIPTS_ROOT%%"

goto SELECT_INSTALL_TO_DIR_END

:SELECT_INSTALL_TO_DIR

echo.Selecting INTALL_TO_DIR installation directory, where the Tacklebar subdirectory will be created...
echo.

if defined COMMANDER_SCRIPTS_ROOT if exist "\\?\%COMMANDER_SCRIPTS_ROOT%\*" (
  for /F "usebackq eol= tokens=* delims=" %%i in (`@"%%CONTOOLS_UTILITIES_BIN_ROOT%%/contools/wxFileDialog.exe" "" "%%COMMANDER_SCRIPTS_ROOT%%" "Select INSTALL_TO_DIR installation directory..." -d`) do set "INSTALL_TO_DIR=%%~fi"
  goto SELECT_INSTALL_TO_DIR_END
)

if defined COMMANDER_PATH call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" COMMANDER_PATH "%%COMMANDER_PATH%%"

if defined COMMANDER_PATH if exist "\\?\%COMMANDER_PATH%\*" (
  if exist "\\?\%COMMANDER_PATH%\plugins" (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%COMMANDER_PATH%%\plugins\UTIL" || goto CANCEL_INSTALL

    for /F "usebackq eol= tokens=* delims=" %%i in (`@"%%CONTOOLS_UTILITIES_BIN_ROOT%%/contools/wxFileDialog.exe" "" "%%COMMANDER_PATH%%\plugins\UTIL" "Select INSTALL_TO_DIR installation directory..." -d`) do set "INSTALL_TO_DIR=%%~fi"
  ) else (
    for /F "usebackq eol= tokens=* delims=" %%i in (`@"%%CONTOOLS_UTILITIES_BIN_ROOT%%/contools/wxFileDialog.exe" "" "%%COMMANDER_PATH%%" "Select INSTALL_TO_DIR installation directory..." -d`) do set "INSTALL_TO_DIR=%%~fi"
  )
  goto SELECT_INSTALL_TO_DIR_END
)

call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.detect.totalcmd.bat"

if defined DETECTED_TOTALCMD_INSTALL_DIR if exist "\\?\%DETECTED_TOTALCMD_INSTALL_DIR%\*" (
  for /F "usebackq eol= tokens=* delims=" %%i in (`@"%%CONTOOLS_UTILITIES_BIN_ROOT%%/contools/wxFileDialog.exe" "" "%%DETECTED_TOTALCMD_INSTALL_DIR%%" "Select INSTALL_TO_DIR installation directory..." -d`) do set "INSTALL_TO_DIR=%%~fi"
  goto SELECT_INSTALL_TO_DIR_END
)

for /F "usebackq eol= tokens=* delims=" %%i in (`@"%%CONTOOLS_UTILITIES_BIN_ROOT%%/contools/wxFileDialog.exe" "" "" "Select INSTALL_TO_DIR installation directory..." -d`) do set "INSTALL_TO_DIR=%%~fi"

:SELECT_INSTALL_TO_DIR_END

if not defined INSTALL_TO_DIR (
  echo.%?~nx0%: error: INSTALL_TO_DIR is not defined.
  goto CANCEL_INSTALL
) >&2

if not exist "\\?\%INSTALL_TO_DIR%\*" (
  echo.%?~nx0%: error: INSTALL_TO_DIR is not a directory: "%INSTALL_TO_DIR%"
  goto CANCEL_INSTALL
) >&2

echo.
echo.Install to: "%INSTALL_TO_DIR%"
echo.
echo.Required Windows version:         %WINDOWS_X64_MIN_VER_STR%+ OR %WINDOWS_X86_MIN_VER_STR%+
echo.Required Total Commander version: %TOTALCMD_MIN_VER_STR%+
echo.
echo.Required set of 3dparty software included into distribution
echo.(use `tacklebar--external_tools` to install):
echo. * Notepad++ (%NOTEPADPP_MIN_VER_STR%+)
echo.   https://notepad-plus-plus.org/downloads/
echo. * Notepad++ PythonScript plugin (%NOTEPADPP_PYTHON_SCRIPT_PLUGIN_MIN_VER_STR%+)
echo.   https://github.com/bruderstein/PythonScript
echo. * WinMerge (%WINMERGE_MIN_VER_STR%+)
echo.   https://winmerge.org/downloads
echo. * Visual C++ 2008 Redistributables (%VCREDIST_2008_MIN_VER_STR%+)
echo.   https://www.catalog.update.microsoft.com/Search.aspx?q=kb2538243
echo.
echo.Required set of 3dparty software not included into distribution:
echo. * Git (%GIT_MIN_VER_STR%+)
echo.   https://git-scm.com
echo. * Bash shell for Git (%GIT_SHELL_MIN_VER_STR%+)
echo.   https://git-scm.com (builtin package)
echo.   https://www.msys2.org/#installation (`Bash` package)
echo.   https://cygwin.com (`Bash` package)
echo. * GitExtensions (%GITEXTENSIONS_MIN_VER_STR%+)
echo.   https://github.com/gitextensions/gitextensions
echo. * TortoiseSVN (%TORTOISESVN_MIN_VER_STR%+)
echo.   https://tortoisesvn.net/
echo. * ffmpeg
echo.   https://ffmpeg.org/download.html#build-windows
echo.   https://github.com/BtbN/FFmpeg-Builds/releases
echo.   https://github.com/Reino17/ffmpeg-windows-build-helpers
echo.   https://rwijnsma.home.xs4all.nl/files/ffmpeg/?C=M;O=D
echo. * msys2
echo.   https://www.msys2.org/#installation (`coreutils` package)
echo. * cygwin
echo.   https://cygwin.com (`coreutils` package)
echo.
echo.Optional set of supported 3dparty software not included into distribution:
echo. * MinTTY
echo.   https://mintty.github.io, https://github.com/mintty/mintty
echo. * ConEmu (%CONEMU_MIN_VER_STR%+)
echo.   https://github.com/Maximus5/ConEmu
echo.   NOTE: Under the Windows XP x64 SP2 only x86 version does work.
echo. * Araxis Merge (%ARAXIS_MERGE_MIN_VER_STR%+)
echo.   https://www.araxis.com/merge/documentation-windows/release-notes.en
echo.

echo.===============================================================================
echo.CAUTION:
echo. You must install at least Notepad++ (with PythonScript plugin) and
echo. WinMerge (or Araxis Merge) to continue.
echo.===============================================================================
echo.

:INSTALL_SINGLE_BUTTON_MENU_ASK
set INSTALL_SINGLE_BUTTON_MENU=0
set "INSTALL_SINGLE_BUTTON_MENU_ASK="

echo.Do you want to intall single button menu instead of multiple buttons [y]es/[n]o?
echo.Type [y]es if you already have many buttons on the Total Commander buttons bar and don't want to overflow it with more buttons.
set /P "INSTALL_SINGLE_BUTTON_MENU_ASK="

if /i "%INSTALL_SINGLE_BUTTON_MENU_ASK%" == "y" ( set "INSTALL_SINGLE_BUTTON_MENU=1" & goto REPEAT_INSTALL_3DPARTY_ASK )
if /i "%INSTALL_SINGLE_BUTTON_MENU_ASK%" == "n" goto REPEAT_INSTALL_3DPARTY_ASK

goto INSTALL_SINGLE_BUTTON_MENU_ASK

:REPEAT_INSTALL_3DPARTY_ASK
set "CONTINUE_INSTALL_ASK="

echo.Ready to install, do you want to continue [y]es/[n]o?
set /P "CONTINUE_INSTALL_ASK="

if /i "%CONTINUE_INSTALL_ASK%" == "y" goto CONTINUE_INSTALL_3DPARTY_ASK
if /i "%CONTINUE_INSTALL_ASK%" == "n" goto CANCEL_INSTALL

goto REPEAT_INSTALL_3DPARTY_ASK

:CONTINUE_INSTALL_3DPARTY_ASK
echo.

set "COMMANDER_SCRIPTS_ROOT=%INSTALL_TO_DIR:/=\%"

echo.Updated COMMANDER_SCRIPTS_ROOT variable: "%COMMANDER_SCRIPTS_ROOT%"
echo.

rem CAUTION:
rem   Always detect all programs to print detected variable values

call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.detect_all.bat"

if defined DETECTED_TOTALCMD_INSTALL_DIR if exist "\\?\%DETECTED_TOTALCMD_INSTALL_DIR%\*" goto DETECTED_TOTALCMD_INSTALL_DIR_OK

(
  echo.%?~nx0%: error: Total Commander must be already installed before continue.
  echo.
  goto CANCEL_INSTALL
) >&2

:DETECTED_TOTALCMD_INSTALL_DIR_OK

set "TOTALCMD_MIN_MAJOR_VER=0"
set "TOTALCMD_MIN_MINOR_VER=0"
setlocal ENABLEDELAYEDEXPANSION & for /F "eol= tokens=1,2,3,* delims=." %%i in ("!TOTALCMD_MIN_VER_STR!") do endlocal & set "TOTALCMD_MIN_MAJOR_VER=%%i" & set "TOTALCMD_MIN_MINOR_VER=%%j"

set "TOTALCMD_PRODUCT_MAJOR_VER=0"
set "TOTALCMD_PRODUCT_MINOR_VER=0"
setlocal ENABLEDELAYEDEXPANSION & for /F "eol= tokens=1,2,3,* delims=." %%i in ("!DETECTED_TOTALCMD_PRODUCT_VERSION!") do endlocal & set "TOTALCMD_PRODUCT_MAJOR_VER=%%i" & set "TOTALCMD_PRODUCT_MINOR_VER=%%j"

if %TOTALCMD_PRODUCT_MAJOR_VER% GTR %TOTALCMD_MIN_MAJOR_VER% goto TOTALCMD_MIN_VER_OK
if %TOTALCMD_PRODUCT_MAJOR_VER% GEQ %TOTALCMD_MIN_MAJOR_VER% if %TOTALCMD_PRODUCT_MINOR_VER% GEQ %TOTALCMD_MIN_MINOR_VER% goto TOTALCMD_MIN_VER_OK

(
  echo.%?~nx0%: error: Total Commander minimum version requirement is not satisfied: `%DETECTED_TOTALCMD_PRODUCT_VERSION%` ^>= `%TOTALCMD_MIN_VER_STR%`
  echo.
  goto CANCEL_INSTALL
) >&2

:TOTALCMD_MIN_VER_OK

if defined DETECTED_NPP_EDITOR if exist "\\?\%DETECTED_NPP_EDITOR%" goto DETECTED_NPP_EDITOR_OK

(
  echo.%?~nx0%: error: Notepad++ must be already installed before continue.
  echo.
  goto CANCEL_INSTALL
) >&2

:DETECTED_NPP_EDITOR_OK

if %DETECTED_NPP_PYTHONSCRIPT_PLUGIN%0 NEQ 0 goto DETECTED_NPP_PYTHONSCRIPT_PLUGIN_OK

(
  echo.%?~nx0%: error: Notepad++ PythonScript plugin must be already installed before continue.
  echo.
  goto CANCEL_INSTALL
) >&2

:DETECTED_NPP_PYTHONSCRIPT_PLUGIN_OK

if defined DETECTED_WINMERGE_COMPARE_TOOL if exist "\\?\%DETECTED_WINMERGE_COMPARE_TOOL%" goto DETECTED_WINMERGE_COMPARE_TOOL_OK
if defined DETECTED_ARAXIS_COMPARE_TOOL if exist "\\?\%DETECTED_ARAXIS_COMPARE_TOOL%" if %DETECTED_ARAXIS_COMPARE_ACTIVATED%0 NEQ 0 goto DETECTED_ARAXIS_COMPARE_TOOL_OK

(
  echo.%?~nx0%: error: WinMerge or Araxis Merge must be already installed and activated (if shareware) before continue.
  echo.
  goto CANCEL_INSTALL
) >&2

:DETECTED_WINMERGE_COMPARE_TOOL_OK
:DETECTED_ARAXIS_COMPARE_TOOL_OK

if %SKIP_INSTALL%0 NEQ 0 goto CANCEL_INSTALL

rem installing...

rem CAUTION:
rem   The UAC promotion call must be BEFORE this point, because:
rem   1. The UAC promotion cancel equals to cancel the installation.
rem   2. The UAC promotion call must be BEFORE the backup below, otherwise the `tacklebar` directory would be already moved (backed up) after UAC promotion cancel.

echo.Registering COMMANDER_SCRIPTS_ROOT variable: "%COMMANDER_SCRIPTS_ROOT%"...
rem echo.

if exist "\\?\%SystemRoot%\System32\setx.exe" (
  "%SystemRoot%\System32\setx.exe" /M COMMANDER_SCRIPTS_ROOT "%COMMANDER_SCRIPTS_ROOT%" || (
    echo.%%?~nx0%%: error: could not register `COMMANDER_SCRIPTS_ROOT` variable.
    echo.
    goto CANCEL_INSTALL
  ) >&2
) else (
  "%SystemRoot%\System32\reg.exe" add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v COMMANDER_SCRIPTS_ROOT /t REG_SZ /d "%COMMANDER_SCRIPTS_ROOT%" /f || (
    echo.%%?~nx0%%: error: could not register `COMMANDER_SCRIPTS_ROOT` variable.
    echo.
    goto CANCEL_INSTALL
  ) >&2

  rem trigger WM_SETTINGCHANGE
  "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/post_wm_settingchange.vbs"
)

echo.

echo.Backuping Notepad++ PythonScript plugin Tacklebar extension...
echo.

set "PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR=%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\scripts"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%%" || goto CANCEL_INSTALL

for %%i in (tacklebar\ startup.py) do (
  if exist "\\?\%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%~i" goto NPP_PYTHON_SCRIPT_TACKLEBAR_EXTENSION_BACKUP
)

goto IGNORE_NPP_PYTHON_SCRIPT_TACKLEBAR_EXTENSION_BACKUP

:NPP_PYTHON_SCRIPT_TACKLEBAR_EXTENSION_BACKUP
set "NPP_PYTHON_SCRIPT_UNINSTALLED_ROOT=%INSTALL_TO_DIR%\.uninstalled\notepadpp_tacklebar"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%NPP_PYTHON_SCRIPT_UNINSTALLED_ROOT%%" || (
  echo.%?~nx0%: error: could not create a backup file directory: "%NPP_PYTHON_SCRIPT_UNINSTALLED_ROOT%".
  echo.
  goto CANCEL_INSTALL
) >&2

rem move previous uninstall paths if exists
if exist "\\?\%INSTALL_TO_DIR%\.notepadpp_tacklebar_prev_install\*" (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xmove_file.bat" "%%INSTALL_TO_DIR%%\.notepadpp_tacklebar_prev_install\" "*.*" "%%NPP_PYTHON_SCRIPT_UNINSTALLED_ROOT%%\" /E /Y || (
    echo.%?~nx0%: error: could not move previous installation directory: "%INSTALL_TO_DIR%\.notepadpp_tacklebar_prev_install\" -^> "%NPP_PYTHON_SCRIPT_UNINSTALLED_ROOT%\"
    echo.
    goto CANCEL_INSTALL
  ) >&2
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/rmdir.bat" "%%INSTALL_TO_DIR%%\.notepadpp_tacklebar_prev_install"
)

set "NPP_PYTHON_SCRIPT_UNINSTALLED_DIR=%NPP_PYTHON_SCRIPT_UNINSTALLED_ROOT%\notepadpp_tacklebar_%PROJECT_LOG_FILE_NAME_DATE_TIME%"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%NPP_PYTHON_SCRIPT_UNINSTALLED_DIR%%" || (
  echo.%?~nx0%: error: could not create a backup file directory: "%NPP_PYTHON_SCRIPT_UNINSTALLED_DIR%".
  echo.
  goto CANCEL_INSTALL
) >&2

for %%i in (tacklebar\ startup.py) do (
  if exist "\\?\%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%~i" (
    if not "%%~nxi" == "" (
      call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xmove_file.bat" "%%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%%" "%%i" "%%NPP_PYTHON_SCRIPT_UNINSTALLED_DIR%%"
      if not exist "\\?\%NPP_PYTHON_SCRIPT_UNINSTALLED_DIR%\%%i" (
        echo.%?~nx0%: error: could not move previous installation file: "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i" -^> "%NPP_PYTHON_SCRIPT_UNINSTALLED_DIR%"
        echo.
        goto CANCEL_INSTALL
      ) >&2
    ) else (
      call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xmove_dir.bat" "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i" "%NPP_PYTHON_SCRIPT_UNINSTALLED_DIR%\%%i"
      if not exist "\\?\%NPP_PYTHON_SCRIPT_UNINSTALLED_DIR%\%%i\*" (
        echo.%?~nx0%: error: could not move previous installation directory: "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i" -^> "%NPP_PYTHON_SCRIPT_UNINSTALLED_DIR%"
        echo.
        goto CANCEL_INSTALL
      ) >&2
    )
  )
)

:IGNORE_NPP_PYTHON_SCRIPT_TACKLEBAR_EXTENSION_BACKUP

echo.Backuping Tacklebar...
echo.

set "TACKLEBAR_UNINSTALLED_ROOT=%INSTALL_TO_DIR%\.uninstalled\tacklebar"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%TACKLEBAR_UNINSTALLED_ROOT%%" || (
  echo.%?~nx0%: error: could not create a backup file directory: "%TACKLEBAR_UNINSTALLED_ROOT%".
  echo.
  goto CANCEL_INSTALL
) >&2

rem move previous uninstall paths if exists
if exist "\\?\%INSTALL_TO_DIR%\.tacklebar_prev_install\*" (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xmove_file.bat" "%%INSTALL_TO_DIR%%\.tacklebar_prev_install\" "*.*" "%%TACKLEBAR_UNINSTALLED_ROOT%%\" /E /Y || (
    echo.%?~nx0%: error: could not move previous installation directory: "%INSTALL_TO_DIR%\.tacklebar_prev_install\" -^> "%TACKLEBAR_UNINSTALLED_ROOT%\"
    echo.
    goto CANCEL_INSTALL
  ) >&2
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/rmdir.bat" "%%INSTALL_TO_DIR%%\.tacklebar_prev_install"
)

if not defined DETECTED_TACKLEBAR_INSTALL_DIR goto IGNORE_PREV_INSTALLATION_DIR_MOVE
if not exist "\\?\%DETECTED_TACKLEBAR_INSTALL_DIR%\*" goto IGNORE_PREV_INSTALLATION_DIR_MOVE

set "TACKLEBAR_UNINSTALLED_DIR=%TACKLEBAR_UNINSTALLED_ROOT%\tacklebar_%PROJECT_LOG_FILE_NAME_DATE_TIME%"

rem NOTE:
rem   Move and rename already existed installation directory into a unique one using `changelog.txt` file in the previous installation project root directory.

if not defined DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE goto MOVE_RENAME_INSTALLATION_DIR_WITH_CURRENT_DATE

set "TACKLEBAR_UNINSTALLED_DIR=%TACKLEBAR_UNINSTALLED_ROOT%\tacklebar_%DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE%_%PROJECT_LOG_FILE_NAME_DATE_TIME%"

:MOVE_RENAME_INSTALLATION_DIR_WITH_CURRENT_DATE

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xmove_dir.bat" "%%DETECTED_TACKLEBAR_INSTALL_DIR%%" "%%TACKLEBAR_UNINSTALLED_DIR%%" || (
  echo.%?~nx0%: error: could not move previous installation directory: "%DETECTED_TACKLEBAR_INSTALL_DIR%" -^> "%TACKLEBAR_UNINSTALLED_DIR%"
  echo.
  goto CANCEL_INSTALL
) >&2

:IGNORE_PREV_INSTALLATION_DIR_MOVE

echo.Installing Notepad++ PythonScript extension...
echo.

call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.notepadpp.pythonscript_extension.bat" || goto CANCEL_INSTALL
echo.

echo.Installing Total Commander configuration files...
echo.

call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.totalcmd.tacklebar_config.bat" || goto CANCEL_INSTALL
echo.

call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.totalcmd.tacklebar_buttonbar.bat" || goto CANCEL_INSTALL
echo.

echo Installing Tacklebar...
echo.

rem exclude all version control system directories and output directories
set "XCOPY_EXCLUDE_DIRS_LIST=.git|.svn|.hg|.log|_out"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/deploy/.saveload" "%%INSTALL_TO_DIR%%/.saveload" /E /Y /D || goto CANCEL_INSTALL

rem basic initialization
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/__init__"         "%%INSTALL_TO_DIR%%/tacklebar/__init__" /E /Y /D || goto CANCEL_INSTALL

rem to be able to (re)install totalcmd configs under current (or different in case of runas) user profile
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%/._install"       __init__.bat                                               "%%INSTALL_TO_DIR%%/tacklebar/._install" /Y /D /H || goto CANCEL_INSTALL
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%/._install"       _install.detect.totalcmd.bat                               "%%INSTALL_TO_DIR%%/tacklebar/._install" /Y /D /H || goto CANCEL_INSTALL
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%/._install"       _install.detect_3dparty.notepadpp.bat                      "%%INSTALL_TO_DIR%%/tacklebar/._install" /Y /D /H || goto CANCEL_INSTALL
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%/._install"       _install.detect_3dparty.notepadpp.pythonscript_plugin.bat  "%%INSTALL_TO_DIR%%/tacklebar/._install" /Y /D /H || goto CANCEL_INSTALL
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%/._install"       _install.notepadpp.pythonscript_extension.bat              "%%INSTALL_TO_DIR%%/tacklebar/._install" /Y /D /H || goto CANCEL_INSTALL
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%/._install"       _install.totalcmd.tacklebar_config.bat                     "%%INSTALL_TO_DIR%%/tacklebar/._install" /Y /D /H || goto CANCEL_INSTALL
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%/._install"       _install.update.terminal_params.bat                        "%%INSTALL_TO_DIR%%/tacklebar/._install" /Y /D /H || goto CANCEL_INSTALL
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%/._install"       script_init.bat                                            "%%INSTALL_TO_DIR%%/tacklebar/._install" /Y /D /H || goto CANCEL_INSTALL

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/_config/_common"  "%%INSTALL_TO_DIR%%/tacklebar/_config" /E /Y /D || goto CANCEL_INSTALL

if %WINDOWS_MAJOR_VER% EQU 5 (
  rem rewrite files even if were newer
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/_config/winxp"  "%%INSTALL_TO_DIR%%/tacklebar/_config" /E /Y || goto CANCEL_INSTALL
)

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/_externals"       "%%INSTALL_TO_DIR%%/tacklebar/_externals" /E /Y /D || goto CANCEL_INSTALL

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/deploy/totalcmd/ButtonBars/_common" "%%INSTALL_TO_DIR%%/tacklebar/ButtonBars" /E /Y /D || goto CANCEL_INSTALL

if %WINDOWS_MAJOR_VER% EQU 5 (
  rem rewrite files even if were newer
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/deploy/totalcmd/ButtonBars/winxp" "%%INSTALL_TO_DIR%%/tacklebar/ButtonBars" /E /Y || goto CANCEL_INSTALL
)

rem to be able to (re)install Total Commander configuration files under current (or different in case of runas) user profile
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/deploy/totalcmd/Profile" "%%INSTALL_TO_DIR%%/tacklebar/deploy/totalcmd/Profile" /E /Y /D || goto CANCEL_INSTALL

rem to be able to (re)install Notepad++ PythonScript extension under current (or different in case of runas) user profile
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%/deploy/notepad++/plugins/PythonScript/Config" PythonScriptStartup.cnf "%%INSTALL_TO_DIR%%/tacklebar/deploy/notepad++/plugins/PythonScript/Config" /Y /D /H || goto CANCEL_INSTALL

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/res/images"       "%%INSTALL_TO_DIR%%/tacklebar/res/images" /E /Y /D || goto CANCEL_INSTALL
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/src"              "%%INSTALL_TO_DIR%%/tacklebar/src" /E /Y /D || goto CANCEL_INSTALL

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_dir.bat" "%%TACKLEBAR_PROJECT_ROOT%%/tools"            "%%INSTALL_TO_DIR%%/tacklebar/tools" /E /Y /D || goto CANCEL_INSTALL

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%"                 .externals    "%%INSTALL_TO_DIR%%/tacklebar" /Y /D /H || goto CANCEL_INSTALL

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%"                 changelog.txt "%%INSTALL_TO_DIR%%/tacklebar" /Y /D /H || goto CANCEL_INSTALL
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%"                 userlog.md    "%%INSTALL_TO_DIR%%/tacklebar" /Y /D /H || goto CANCEL_INSTALL
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" "%%TACKLEBAR_PROJECT_ROOT%%"                 README_EN.txt "%%INSTALL_TO_DIR%%/tacklebar" /Y /D /H || goto CANCEL_INSTALL

rem default values for optional 3dparty installation locations
if not defined DETECTED_CONEMU32_ROOT set "DETECTED_CONEMU32_ROOT=c:\Program Files (x86)\ConEmu"
if not defined DETECTED_CONEMU64_ROOT set "DETECTED_CONEMU64_ROOT=c:\Program Files\ConEmu"

if not defined DETECTED_MINTTY32_ROOT set "DETECTED_MINTTY32_ROOT=c:\Program Files (x86)\MinTTY"
if not defined DETECTED_MINTTY64_ROOT set "DETECTED_MINTTY64_ROOT=c:\Program Files\MinTTY"

if not defined DETECTED_MINTTY32_TERMINAL_PREFIX set "DETECTED_MINTTY32_TERMINAL_PREFIX=$/\x22%DETECTED_MINTTY32_ROOT%\mintty.exe$/\x22"
if not defined DETECTED_MINTTY64_TERMINAL_PREFIX set "DETECTED_MINTTY64_TERMINAL_PREFIX=$/\x22%DETECTED_MINTTY64_ROOT%\mintty.exe$/\x22"

if not defined DETECTED_CYGWIN32_ROOT set "DETECTED_CYGWIN32_ROOT=c:\cygwin"
if not defined DETECTED_CYGWIN64_ROOT set "DETECTED_CYGWIN64_ROOT=c:\cygwin64"

if not defined DETECTED_MSYS32_ROOT set "DETECTED_MSYS32_ROOT=c:\msys32"
if not defined DETECTED_MSYS64_ROOT set "DETECTED_MSYS64_ROOT=c:\msys64"

if not defined DETECTED_WINMERGE_ROOT if %WINDOWS_X64_VER% NEQ 0 (
  set "DETECTED_WINMERGE_ROOT=c:\Program Files (x86)\WinMerge"
) else set "DETECTED_WINMERGE_ROOT=c:\Program Files\WinMerge"

if not defined DETECTED_ARAXIS_MERGE_ROOT if %WINDOWS_X64_VER% NEQ 0 (
  set "DETECTED_ARAXIS_MERGE_ROOT=c:\Program Files (x86)\Araxis\Araxis Merge"
) else set "DETECTED_ARAXIS_MERGE_ROOT=c:\Program Files\Araxis\Araxis Merge"

rem directly generate configuration file to be merged
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%INSTALL_TO_DIR%%/tacklebar/_out/config/tacklebar" || goto CANCEL_INSTALL

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CONTOOLS_BUILD_TOOLS_ROOT%%/gen_config.bat" ^
  -r "{{CONEMU32_ROOT}}" "%%DETECTED_CONEMU32_ROOT%%" ^
  -r "{{CONEMU64_ROOT}}" "%%DETECTED_CONEMU64_ROOT%%" ^
  -r "{{MINTTY32_ROOT}}" "%%DETECTED_MINTTY32_ROOT%%" ^
  -r "{{MINTTY64_ROOT}}" "%%DETECTED_MINTTY64_ROOT%%" ^
  -r "{{MINTTY32_TERMINAL_PREFIX}}" "%%DETECTED_MINTTY32_TERMINAL_PREFIX%%" ^
  -r "{{MINTTY64_TERMINAL_PREFIX}}" "%%DETECTED_MINTTY64_TERMINAL_PREFIX%%" ^
  -r "{{CYGWIN32_ROOT}}" "%%DETECTED_CYGWIN32_ROOT%%" ^
  -r "{{CYGWIN32_DLL}}" "%%DETECTED_CYGWIN32_DLL%%" ^
  -r "{{CYGWIN64_ROOT}}" "%%DETECTED_CYGWIN64_ROOT%%" ^
  -r "{{CYGWIN64_DLL}}" "%%DETECTED_CYGWIN64_DLL%%" ^
  -r "{{MSYS32_ROOT}}" "%%DETECTED_MSYS32_ROOT%%" ^
  -r "{{MSYS32_DLL}}" "%%DETECTED_MSYS32_DLL%%" ^
  -r "{{MSYS64_ROOT}}" "%%DETECTED_MSYS64_ROOT%%" ^
  -r "{{MSYS64_DLL}}" "%%DETECTED_MSYS64_DLL%%" ^
  -r "{{NPP_EDITOR}}" "%%DETECTED_NPP_EDITOR%%" ^
  -r "{{WINMERGE_ROOT}}" "%%DETECTED_WINMERGE_ROOT%%" ^
  -r "{{ARAXIS_COMPARE_ENABLE}}" "%%DETECTED_ARAXIS_COMPARE_ACTIVATED%%" ^
  -r "{{ARAXIS_MERGE_ROOT}}" "%%DETECTED_ARAXIS_MERGE_ROOT%%" ^
  -r "{{GIT_SHELL_ROOT}}" "%%DETECTED_GIT_SHELL_ROOT%%" ^
  -r "{{GITEXTENSIONS_ROOT}}" "%%DETECTED_GITEXTENSIONS_ROOT%%" ^
  "%%INSTALL_TO_DIR%%/tacklebar/_config" "%%INSTALL_TO_DIR%%/tacklebar/_out/config/tacklebar" "config.0.vars" || (
  echo.%?~nx0%: error: could not generate configuration file in the installation directory: "%INSTALL_TO_DIR%/tacklebar/_config/config.0.vars.in" -^> "%INSTALL_TO_DIR%/tacklebar/_out/config/tacklebar/config.0.vars"
  goto CANCEL_INSTALL
) >&2

echo.

rem detect 3dparty applications to merge/edit the user configuration file (`config.0.vars`)

if not exist "\\?\%INSTALL_TO_DIR%\.uninstalled\tacklebar\*" (
  echo.%?~nx0%: note: previous installation directory is not found: "%INSTALL_TO_DIR%/tacklebar"
  echo.
  goto NOTEPAD_EDIT_USER_CONFIG
)

rem search first different config in previous installation directories
echo.Searching first difference in previous installation directories...
echo.

rem CAUTION:
rem   If a variable is empty, then it would not be expanded in the `cmd.exe` command line or in case of `for /F ...`!
rem   We must expand the command line into a variable.
rem
set CMD_LINE=@dir "%INSTALL_TO_DIR%\.uninstalled\tacklebar\tacklebar_*" /A:D /B /O:-N

for /F "usebackq eol= tokens=* delims=" %%i in (`%%CMD_LINE%%`) do (
  set "TACKLEBAR_PREV_INSTALL_DIR=%INSTALL_TO_DIR%\.uninstalled\tacklebar\%%i"
  call :SEARCH_PREV_INSTALL || goto MERGE_FROM_PREV_INSTALL
)

echo.

goto NOTEPAD_EDIT_USER_CONFIG

:SEARCH_PREV_INSTALL
echo.  - "%TACKLEBAR_PREV_INSTALL_DIR%"
if exist "\\?\%TACKLEBAR_PREV_INSTALL_DIR%\_out\config\tacklebar\config.0.vars" ^
for /F "eol= tokens=* delims=" %%i in ("\\?\%TACKLEBAR_PREV_INSTALL_DIR%/_out/config/tacklebar/config.0.vars") do if %%~zi NEQ 0 (
  call "%%SystemRoot%%\System32\fc.exe" "%%TACKLEBAR_PREV_INSTALL_DIR:/=\%%\_out\config\tacklebar\config.0.vars" "%%INSTALL_TO_DIR:/=\%%\tacklebar\_out\config\tacklebar\config.0.vars" >nul 2>nul || exit /b 1
)
exit /b 0

:MERGE_FROM_PREV_INSTALL
echo.

if defined DETECTED_ARAXIS_COMPARE_TOOL if %DETECTED_ARAXIS_COMPARE_ACTIVATED%0 NEQ 0 (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%DETECTED_ARAXIS_COMPARE_TOOL%%" /wait "%%TACKLEBAR_PREV_INSTALL_DIR%%/_out/config/tacklebar/config.0.vars" "%%INSTALL_TO_DIR%%/tacklebar/_out/config/tacklebar/config.0.vars"
  goto END_INSTALL
)

if defined DETECTED_WINMERGE_COMPARE_TOOL (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%DETECTED_WINMERGE_COMPARE_TOOL%%" "%%TACKLEBAR_PREV_INSTALL_DIR%%/_out/config/tacklebar/config.0.vars" "%%INSTALL_TO_DIR%%/tacklebar/_out/config/tacklebar/config.0.vars"
  goto END_INSTALL
)

(
  echo.%?~nx0%: error: No one text file merge application is detected.
  echo.
  goto NOTEPAD_EDIT_USER_CONFIG
) >&2

:NOTEPAD_EDIT_USER_CONFIG
if not defined DETECTED_NPP_EDITOR goto IGNORE_NOTEPAD_EDIT_USER_CONFIG
if not exist "\\?\%DETECTED_NPP_EDITOR%" goto IGNORE_NOTEPAD_EDIT_USER_CONFIG

set "NPP_EDITOR=%DETECTED_NPP_EDITOR%"
call "%%TACKLEBAR_PROJECT_ROOT%%/src/scripts/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst "%%INSTALL_TO_DIR%%" "%%INSTALL_TO_DIR%%/tacklebar/_out/config/tacklebar/config.0.vars"

goto END_INSTALL

:IGNORE_NOTEPAD_EDIT_USER_CONFIG
(
  echo.%?~nx0%: warning: Notepad++ is not detected, do edit configuration file manually: "%INSTALL_TO_DIR%/tacklebar/_out/config/tacklebar/config.0.vars"
  echo.
) >&2

:END_INSTALL

rem load merged configuration file
call "%%TACKLEBAR_PROJECT_ROOT%%/tools/load_config_dir.bat" -gen_system_config -load_user_output_config "%%INSTALL_TO_DIR%%/tacklebar/_config" "%%INSTALL_TO_DIR%%/tacklebar/_out/config/tacklebar" || (
  echo.%?~nx0%: error: could not generate and load configuration file in the installation directory: "%INSTALL_TO_DIR%/tacklebar/_config/config.0.vars.in" -^> "%INSTALL_TO_DIR%/tacklebar/_out/config/tacklebar/config.0.vars"
  echo.
  goto CANCEL_INSTALL
) >&2

echo.

if defined MINTTY32_ROOT if exist "\\?\%MINTTY32_ROOT%\*" goto MINTTY32_ROOT_OK

(
  echo.%?~nx0%: warning: config.0.vars: MinTTY 32-bit terminal location is not detected: MINTTY32_ROOT="%MINTTY32_ROOT%"
  echo.
) >&2

:MINTTY32_ROOT_OK

if defined MINTTY64_ROOT if exist "\\?\%MINTTY64_ROOT%\*" goto MINTTY64_ROOT_OK

(
  echo.%?~nx0%: warning: config.0.vars: MinTTY 64-bit terminal location is not detected: MINTTY64_ROOT="%MINTTY64_ROOT%"
  echo.
) >&2

:MINTTY64_ROOT_OK

if defined CONEMU32_ROOT if exist "\\?\%CONEMU32_ROOT%\*" goto CONEMU32_ROOT_OK

(
  echo.%?~nx0%: warning: config.0.vars: ConEmu 32-bit terminal location is not detected: CONEMU32_ROOT="%CONEMU32_ROOT%"
  echo.
) >&2

:CONEMU32_ROOT_OK

if defined CONEMU64_ROOT if exist "\\?\%CONEMU64_ROOT%\*" goto CONEMU64_ROOT_OK

(
  echo.%?~nx0%: warning: config.0.vars: ConEmu 64-bit terminal location is not detected: CONEMU64_ROOT="%CONEMU64_ROOT%"
  echo.
) >&2

:CONEMU64_ROOT_OK

if defined NPP_EDITOR if exist "\\?\%NPP_EDITOR%" goto NPP_EDITOR_OK

(
  echo.%?~nx0%: warning: config.0.vars: Notepad++ application location is not detected: NPP_EDITOR="%NPP_EDITOR%"
  echo.
) >&2

:NPP_EDITOR_OK

if defined WINMERGE_COMPARE_TOOL if exist "\\?\%WINMERGE_COMPARE_TOOL%" goto WINMERGE_COMPARE_TOOL_OK

(
  echo.%?~nx0%: warning: config.0.vars: WinMerge application location is not detected: WINMERGE_COMPARE_TOOL="%WINMERGE_COMPARE_TOOL%"
  echo.
) >&2

:WINMERGE_COMPARE_TOOL_OK

if %ARAXIS_COMPARE_ENABLE%0 NEQ 0 goto ARAXIS_COMPARE_ENABLE_OK

(
  echo.%?~nx0%: warning: config.0.vars: Araxis Merge application is disabled: ARAXIS_COMPARE_ENABLE="%ARAXIS_COMPARE_ENABLE%"
  echo.
) >&2

:ARAXIS_COMPARE_ENABLE_OK

if defined ARAXIS_COMPARE_TOOL if exist "\\?\%ARAXIS_COMPARE_TOOL%" goto ARAXIS_COMPARE_TOOL_OK

(
  echo.%?~nx0%: warning: config.0.vars: Araxis Merge application location is not detected: ARAXIS_COMPARE_TOOL="%ARAXIS_COMPARE_TOOL%"
  echo.
) >&2

:ARAXIS_COMPARE_TOOL_OK

if defined ARAXIS_CONSOLE_COMPARE_TOOL if exist "\\?\%ARAXIS_CONSOLE_COMPARE_TOOL%" goto ARAXIS_CONSOLE_COMPARE_TOOL_OK

(
  echo.%?~nx0%: warning: config.0.vars: Araxis Merge application location is not detected: ARAXIS_CONSOLE_COMPARE_TOOL="%ARAXIS_CONSOLE_COMPARE_TOOL%"
  echo.
) >&2

:ARAXIS_CONSOLE_COMPARE_TOOL_OK

if defined GIT_SHELL_ROOT if exist "\\?\%GIT_SHELL_ROOT%\*" goto GIT_SHELL_ROOT_OK

(
  echo.%?~nx0%: warning: config.0.vars: Bash shell for Git tool location is not detected: GIT_SHELL_ROOT="%GIT_SHELL_ROOT%"
) >&2

:GIT_SHELL_ROOT_OK

if defined GITEXTENSIONS_ROOT if exist "\\?\%GITEXTENSIONS_ROOT%\*" goto GITEXTENSIONS_ROOT_OK

(
  echo.%?~nx0%: warning: config.0.vars: GitExtensions application location is not detected: GITEXTENSIONS_ROOT="%GITEXTENSIONS_ROOT%"
) >&2

:GITEXTENSIONS_ROOT_OK

if defined FFMPEG_TOOL_EXE if exist "\\?\%FFMPEG_TOOL_EXE%" goto FFMPEG_TOOL_EXE_OK

(
  echo.%?~nx0%: warning: config.0.vars: FFmpeg tool location is not detected: FFMPEG_TOOL_EXE="%FFMPEG_TOOL_EXE%"
  echo.
) >&2

:FFMPEG_TOOL_EXE_OK

if defined MSYS32_ROOT if exist "\\?\%MSYS32_ROOT%\usr\bin\*" goto MSYS32_ROOT_OK

(
  echo.%?~nx0%: warning: config.0.vars: msys 32-bit utilities location is not detected: "%MSYS32_ROOT%\usr\bin"
  echo.
) >&2

:MSYS32_ROOT_OK

if defined MSYS64_ROOT if exist "\\?\%MSYS64_ROOT%\usr\bin\*" goto MSYS64_ROOT_OK

(
  echo.%?~nx0%: warning: config.0.vars: msys 64-bit utilities location is not detected: "%MSYS64_ROOT%\usr\bin"
  echo.
) >&2

:MSYS64_ROOT_OK

if defined CYGWIN32_ROOT if exist "\\?\%CYGWIN32_ROOT%\bin\*" goto CYGWIN32_ROOT_OK

(
  echo.%?~nx0%: warning: config.0.vars: cygwin 32-bit utilities location is not detected: "%CYGWIN32_ROOT%\bin"
  echo.
) >&2

:CYGWIN32_ROOT_OK

if defined CYGWIN64_ROOT if exist "\\?\%CYGWIN64_ROOT%\bin\*" goto CYGWIN64_ROOT_OK

(
  echo.%?~nx0%: warning: config.0.vars: cygwin 64-bit utilities location is not detected: "%CYGWIN64_ROOT%\bin"
  echo.
) >&2

:CYGWIN64_ROOT_OK

echo.%?~nx0%: info: installation is complete.
echo.

exit /b 0

:CANCEL_INSTALL
(
  echo.%?~nx0%: info: installation is canceled.
  echo.
  exit /b 127
) >&2
