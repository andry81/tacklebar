@echo off

setlocal

set "?~0=%~0"
set "?~f0=%~f0"
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

call "%%~dp0._install\_install.update.terminal_params.bat" -update_screen_size -update_buffer_size

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%\wmi\get_wmic_local_datetime.bat"
set "LOG_FILE_NAME_SUFFIX=%RETURN_VALUE:~0,4%'%RETURN_VALUE:~4,2%'%RETURN_VALUE:~6,2%_%RETURN_VALUE:~8,2%'%RETURN_VALUE:~10,2%'%RETURN_VALUE:~12,2%''%RETURN_VALUE:~15,3%"

set "PROJECT_LOG_DIR=%PROJECT_LOG_ROOT%\%LOG_FILE_NAME_SUFFIX%.%~n0"
set "PROJECT_LOG_FILE=%PROJECT_LOG_DIR%\%LOG_FILE_NAME_SUFFIX%.%~n0.log"

if not exist "%PROJECT_LOG_DIR%" ( mkdir "%PROJECT_LOG_DIR%" || exit /b )

rem CAUTION:
rem   In Windowx XP an elevated call under data protection flag will block the wmic tool, so we have to use `ver` command instead!
rem
for /F "usebackq tokens=1,2,* delims=[]" %%i in (`ver`) do for /F "tokens=1,2,* delims= " %%l in ("%%j") do set "WINDOWS_VER_STR=%%m"

set WINDOWS_MAJOR_VER=0
set WINDOWS_MINOR_VER=0
for /F "eol= tokens=1,2,* delims=." %%i in ("%WINDOWS_VER_STR%") do ( set "WINDOWS_MAJOR_VER=%%i" & set "WINDOWS_MINOR_VER=%%j" )

if %WINDOWS_MAJOR_VER% GTR 5 goto WINDOWS_VER_OK
if %WINDOWS_MAJOR_VER% EQU 5 if %WINDOWS_MINOR_VER% GEQ 1 goto WINDOWS_VER_OK

(
  echo.%~nx0: error: unsupported version of Windows: "%WINDOWS_VER_STR%"
  set LASTERROR=255
  goto EXIT
) >&2

:WINDOWS_VER_OK

set WINDOWS_X64_VER=0
if defined PROCESSOR_ARCHITEW6432 ( set "WINDOWS_X64_VER=1" ) else if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" set WINDOWS_X64_VER=1

rem CAUTION:
rem   Specific case for Windows XP x64 SP2, where both PROCESSOR_ARCHITECTURE and PROCESSOR_ARCHITEW6432 are equal to AMD64 for 32-bit cmd.exe process!
rem
set PROC_X64_VER=0
if /i not "%PROCESSOR_ARCHITECTURE%" == "x86" if not defined PROCESSOR_ARCHITEW6432 set PROC_X64_VER=1

rem register initialization environment variables
(
for %%i in (TACKLEBAR_SCRIPTS_INSTALL LOG_FILE_NAME_SUFFIX PROJECT_LOG_DIR PROJECT_LOG_FILE COMMANDER_SCRIPTS_ROOT COMMANDER_PATH COMMANDER_INI ^
            WINDOWS_VER_STR WINDOWS_MAJOR_VER WINDOWS_MINOR_VER WINDOWS_X64_VER PROC_X64_VER COMSPEC COMSPECLNK ^
            TERMINAL_SCREEN_WIDTH TERMINAL_SCREEN_HEIGHT TERMINAL_SCREEN_BUFFER_HEIGHT) do ^
if defined %%i ( for /F "usebackq eol= tokens=1,* delims==" %%j in (`set %%i 2^>nul`) do if /i "%%i" == "%%j" echo.%%j=%%k) else echo.#%%i=
) > "%PROJECT_LOG_DIR%\init.vars"

rem List of issues discovered in Windows 7/XP:
rem 1. Run from shortcut file (`.lnk`) in the Windows XP (but not in the Windows 7) brings truncated command line down to ~260 characters.
rem 2. Run from shortcut file (`.lnk`) loads console windows parameters (font, windows size, buffer size, etc) from the shortcut at first and from the registry
rem    (HKCU\Console) at second. If try to change and save parameters, then saves ONLY into the shortcut, which brings the shortcut file overwrite.
rem 3. Run under UAC promotion in the Windows 7+ blocks environment inheritance, blocks stdout redirection into a pipe from non-elevated process into elevated one and
rem    blocks console screen buffer change (piping locks process (stdout) screen buffer sizes).
rem    To bypass that, for example, need to:
rem     a. Save environment variables to a file from non-elevated process and load them back in an elevated process.
rem     b. Use redirection only from an elevated process.
rem     c. Change console screen buffer sizes before stdout redirection into a pipe.
rem

rem To resolve all the issues we DO NOT USE shortcut files (.lnk) for UAC promotion. Instead we use as a replacement `winshell_call.vbs` + `call.vbs` scripts.
rem
rem The PROs:
rem   1. No need to change console windows parameters (font, windows sizes, buffer sizes, etc) each time the project is installed. The parameters loads/saves from/to the registry and so
rem      is shared between installations.
rem   2. Implementation is the same and portable between all the Windows versions like Windows XP/7. No need now to use different implementation for each Windows version.
rem   3. Process inheritance tree is retained between non-elevated process and elevated process because parent non-elevated process (`winchell_call.vbs`) awaits current directory
rem      release in the child elevated process (`call.vbs`) instead of awaits a child process exit and so independent to security permission from the Windows
rem      (in the Windows all elevated processes isolated from non-elevated processes and so can not be enumerated or can not be watched for exit by non-elevated processes).
rem
rem The CONs:
rem   1. To preserve the process inheritance tree between a non-elevated process and an elevated process, there is another process in the inheritance chain,
rem      compared to running a shortcut from a file with the UAC promotion flag raised.
rem   2. Implementation of the `winshell_call.vbs` script has race condition timeout because of the inner `ShellExecute` API call which does not support return code and
rem      does not have builtin child process exit await logic. So there is a chance that the parent non-elevated process will close before close the child elevated process.
rem

rem CAUTION:
rem   We should avoid use handles 3 and 4 while the redirection has take a place because handles does reuse
rem   internally from left to right when being redirected externally.
rem   Example: if `1` is redirected, then `3` is internally reused, then if `2` redirected, then `4` is internally reused and so on.
rem   The discussion of the logic:
rem   https://stackoverflow.com/questions/9878007/why-doesnt-my-stderr-redirection-end-after-command-finishes-and-how-do-i-fix-i/9880156#9880156
rem   A partial analisis:
rem   https://www.dostips.com/forum/viewtopic.php?p=14612#p14612
rem

"%SystemRoot%\System32\wscript.exe" //NOLOGO "%CONTOOLS_ROOT%/ToolAdaptors/vbs/winshell_call.vbs" -nowindow -verb runas -make_temp_dir_as_cwd "{{CWD}}" -wait_delete_cwd ^
  "%SystemRoot%\System32\wscript.exe" //NOLOGO "%CONTOOLS_ROOT%/ToolAdaptors/vbs/call.vbs" -D "{{CWD}}" -u -ra "%%" "%%?01%%" -v "?01" "%%" ^
    "%COMSPEC%" /C set "%%22TACKLEBAR_SCRIPTS_INSTALL=1%%22" ^& set "%%22IMPL_MODE=1%%22" ^& set "%%22INIT_VARS_FILE=%PROJECT_LOG_DIR%\init.vars%%22" ^& ^
      @"%%22%?~dp0%._install\_install.update.terminal_params.bat%%22" -update_screen_size -update_buffer_size -update_registry ^& ^
      @"%%22%?~f0%%%22" %* 2^>^&1 ^| "%%22%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe%%22" /E "%%22%PROJECT_LOG_FILE:/=\%%%22"
set LASTERROR=%ERRORLEVEL%

call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" COMMANDER_SCRIPTS_ROOT >nul 2>nul
if defined REGQUERY_VALUE set "COMMANDER_SCRIPTS_ROOT=%REGQUERY_VALUE%"
goto EXIT

:IMPL
rem check for true elevated environment (required in case of Windows XP)
"%SystemRoot%\System32\net.exe" session >nul 2>nul || (
  echo.%?~nx0%: error: the script process is not properly elevated up to Administrator privileges.
  set LASTERROR=255
  goto EXIT
) >&2

rem load initialization environment variables
for /F "usebackq eol=# tokens=* delims=" %%i in ("%INIT_VARS_FILE%") do set "%%i"

rem script flags
set "FLAG_CHCP="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-chcp" (
    set "FLAG_CHCP=%~2"
    shift
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

rem there to install
set "INSTALL_TO_DIR=%~1"

if not defined NEST_LVL set NEST_LVL=0

set /A NEST_LVL+=1

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || (
  echo.%?~nx0%: error: could not allocate temporary directory: "%SCRIPT_TEMP_CURRENT_DIR%"
  set LASTERROR=255
  goto FREE_TEMP_DIR
) >&2

rem CAUTION:
rem   We have to change the codepage here because the change would be revoked upon the UAC promotion.
rem

if defined FLAG_CHCP ( call "%%CONTOOLS_ROOT%%/std/chcp.bat" -p %%FLAG_CHCP%%
) else call "%%CONTOOLS_ROOT%%/std/getcp.bat"

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

rem restore locale
if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat" -p

:FREE_TEMP_DIR
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

:FREE_TEMP_DIR_END
set /A NEST_LVL-=1

:EXIT
if %NEST_LVL%0 EQU 0 if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/pause.bat" -chcp "%%OEMCP%%" ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"

rem return registered variables outside to reuse them again from the same process
(
  endlocal
  set "COMMANDER_SCRIPTS_ROOT=%COMMANDER_SCRIPTS_ROOT%"
  exit /b %LASTERROR%
)

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

set "EMPTY_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\emptydir"

mkdir "%EMPTY_DIR_TMP%" || (
  echo.%?~n0%: error: could not create a directory: "%EMPTY_DIR_TMP%".
  exit /b 255
) >&2

if not defined INSTALL_TO_DIR if not defined COMMANDER_SCRIPTS_ROOT goto SELECT_INSTALL_TO_DIR

if defined INSTALL_TO_DIR call :CANONICAL_PATH INSTALL_TO_DIR "%%INSTALL_TO_DIR%%"
if defined COMMANDER_SCRIPTS_ROOT call :CANONICAL_PATH COMMANDER_SCRIPTS_ROOT "%%COMMANDER_SCRIPTS_ROOT%%"

if defined INSTALL_TO_DIR (
  if not exist "\\?\%INSTALL_TO_DIR%\" (
    echo.%?~nx0%: error: INSTALL_TO_DIR is not a directory: "%INSTALL_TO_DIR%"
    exit /b 10
  ) >&2
) else if not exist "\\?\%COMMANDER_SCRIPTS_ROOT%\" (
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

if not defined INSTALL_TO_DIR set "INSTALL_TO_DIR=%COMMANDER_SCRIPTS_ROOT%"

goto SELECT_INSTALL_TO_DIR_END

:SELECT_INSTALL_TO_DIR

if defined COMMANDER_SCRIPTS_ROOT if exist "\\?\%COMMANDER_SCRIPTS_ROOT%\" (
  for /F "usebackq eol= tokens=* delims=" %%i in (`@"%CONTOOLS_UTILITIES_BIN_ROOT%/contools/wxFileDialog.exe" "" "%COMMANDER_SCRIPTS_ROOT%" "Select INSTALL_TO_DIR installation directory..." -d`) do set "INSTALL_TO_DIR=%%i"
  goto SELECT_INSTALL_TO_DIR_END
)

if defined COMMANDER_PATH call :CANONICAL_PATH COMMANDER_PATH "%%COMMANDER_PATH%%"

if defined COMMANDER_PATH if exist "\\?\%COMMANDER_PATH%\" (
  for /F "usebackq eol= tokens=* delims=" %%i in (`@"%CONTOOLS_UTILITIES_BIN_ROOT%/contools/wxFileDialog.exe" "" "%COMMANDER_PATH%" "Select INSTALL_TO_DIR installation directory..." -d`) do set "INSTALL_TO_DIR=%%i"
  goto SELECT_INSTALL_TO_DIR_END
)

for /F "usebackq eol= tokens=* delims=" %%i in (`@"%CONTOOLS_UTILITIES_BIN_ROOT%/contools/wxFileDialog.exe" "" "" "Select INSTALL_TO_DIR installation directory..." -d`) do set "INSTALL_TO_DIR=%%i"

:SELECT_INSTALL_TO_DIR_END

if not defined INSTALL_TO_DIR (
  echo.%?~nx0%: error: INSTALL_TO_DIR is not defined.
  goto CANCEL_INSTALL
) >&2

if not exist "\\?\%INSTALL_TO_DIR%\" (
  echo.%?~nx0%: error: INSTALL_TO_DIR is not a directory: "%INSTALL_TO_DIR%"
  goto CANCEL_INSTALL
) >&2

echo.
echo.Install to: "%INSTALL_TO_DIR%"
echo.
echo.Required Windows version:         %WINDOWS_X64_MIN_VER_STR%+ OR %WINDOWS_X86_MIN_VER_STR%+
echo.Required Total Commander version: %TOTALCMD_MIN_VER_STR%+
echo.
echo.Required set of 3dparty software included into install (use `tacklebar--external_tools` to install):
echo. * Notepad++ (%NOTEPADPP_MIN_VER_STR%+, https://notepad-plus-plus.org/downloads/ )
echo. * Notepad++ PythonScript plugin (%NOTEPADPP_PYTHON_SCRIPT_PLUGIN_MIN_VER_STR%+, https://github.com/bruderstein/PythonScript )
echo. * WinMerge (%WINMERGE_MIN_VER_STR%+, https://winmerge.org/downloads )
echo. * Visual C++ 2008 Redistributables (%VCREDIST_2008_MIN_VER_STR%+, https://www.catalog.update.microsoft.com/Search.aspx?q=kb2538243 )
echo.
echo.Required set of 3dparty software not included into install:
echo  * ffmpeg (ffmpeg module,
echo.           https://ffmpeg.org/download.html#build-windows, https://github.com/BtbN/FFmpeg-Builds/releases,
echo.           https://github.com/Reino17/ffmpeg-windows-build-helpers, https://rwijnsma.home.xs4all.nl/files/ffmpeg/?C=M;O=D )
echo. * msys2 (coreutils package, https://www.msys2.org/#installation )
echo. * cygwin (coreutils package, https://cygwin.com )
echo.
echo.Optional set of supported 3dparty software not included into install:
echo. * ConEmu (%CONEMU_MIN_VER_STR%+, https://github.com/Maximus5/ConEmu )
echo.   NOTE: Under the Windows XP x64 SP2 only x86 version does work.
echo. * Araxis Merge (%ARAXIS_MERGE_MIN_VER_STR%+, https://www.araxis.com/merge/documentation-windows/release-notes.en )
echo.
echo. CAUTION:
echo.   You must install at least Notepad++ (with PythonScript plugin) and WinMerge (or Araxis Merge) to continue.
echo.

:REPEAT_INSTALL_3DPARTY_ASK
set "CONTINUE_INSTALL_ASK="
echo.Do you want to continue [y]es/[n]o?
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

call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.detect.totalcmd.bat"
call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.detect_3dparty.conemu.bat"
call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.detect_3dparty.notepadpp.bat"
call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.detect_3dparty.notepadpp.pythonscript_plugin.bat"
call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.detect_3dparty.winmerge.bat"
call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.detect_3dparty.araxismerge.bat"

echo.

if defined DETECTED_TOTALCMD_INSTALL_DIR if exist "%DETECTED_TOTALCMD_INSTALL_DIR%" goto DETECTED_TOTALCMD_INSTALL_DIR_OK

(
  echo.%?~nx0%: error: Total Commander must be already installed before continue.
  goto CANCEL_INSTALL
) >&2

:DETECTED_TOTALCMD_INSTALL_DIR_OK

if defined DETECTED_NPP_EDITOR if exist "%DETECTED_NPP_EDITOR%" goto DETECTED_NPP_EDITOR_OK

(
  echo.%?~nx0%: error: Notepad++ must be already installed before continue.
  goto CANCEL_INSTALL
) >&2

:DETECTED_NPP_EDITOR_OK

if %DETECTED_NPP_PYTHONSCRIPT_PLUGIN%0 NEQ 0 goto DETECTED_NPP_PYTHONSCRIPT_PLUGIN_OK

(
  echo.%?~nx0%: error: Notepad++ PythonScript plugin must be already installed before continue.
  goto CANCEL_INSTALL
) >&2

:DETECTED_NPP_PYTHONSCRIPT_PLUGIN_OK

if defined DETECTED_WINMERGE_COMPARE_TOOL if exist "%DETECTED_WINMERGE_COMPARE_TOOL%" goto DETECTED_WINMERGE_COMPARE_TOOL_OK
if defined DETECTED_ARAXIS_COMPARE_TOOL if exist "%DETECTED_ARAXIS_COMPARE_TOOL%" if %DETECTED_ARAXIS_COMPARE_ACTIVATED%0 NEQ 0 goto DETECTED_ARAXIS_COMPARE_TOOL_OK

(
  echo.%?~nx0%: error: WinMerge or Araxis Merge must be already installed and activated (if shareware) before continue.
  goto CANCEL_INSTALL
) >&2

:DETECTED_WINMERGE_COMPARE_TOOL_OK
:DETECTED_ARAXIS_COMPARE_TOOL_OK

rem installing...

rem CAUTION:
rem   The UAC promotion call must be BEFORE this point, because:
rem   1. The UAC promotion cancel equals to cancel the installation.
rem   2. The UAC promotion call must be BEFORE the backup below, otherwise the `tacklebar` directory would be already moved (backed up) after UAC promotion cancel.

echo.Registering COMMANDER_SCRIPTS_ROOT variable: "%COMMANDER_SCRIPTS_ROOT%"...

if exist "%SystemRoot%\System32\setx.exe" (
  "%SystemRoot%\System32\setx.exe" /M COMMANDER_SCRIPTS_ROOT "%COMMANDER_SCRIPTS_ROOT%" || (
    echo.%%?~nx0%%: error: could not register `COMMANDER_SCRIPTS_ROOT` variable.
    goto CANCEL_INSTALL
  ) >&2
) else (
  "%SystemRoot%\System32\reg.exe" add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v COMMANDER_SCRIPTS_ROOT /t REG_SZ /d "%COMMANDER_SCRIPTS_ROOT%" /f || (
    echo.%%?~nx0%%: error: could not register `COMMANDER_SCRIPTS_ROOT` variable.
    goto CANCEL_INSTALL
  ) >&2

  rem trigger WM_SETTINGCHANGE
  "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/post_wm_settingchange.vbs"
)

echo.

echo.Backuping Notepad++ PythonScript plugin tacklebar extension...

set "PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR=%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\scripts"

if not exist "\\?\%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\" (
  echo.^>mkdir "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%"
  call :MAKE_DIR "%%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%%"
  echo.
)

for %%i in (tacklebar\ startup.py) do (
  if exist "\\?\%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%~i" goto NPP_PYTHON_SCRIPT_TACKLEBAR_EXTENSION_BACKUP
)

goto IGNORE_NPP_PYTHON_SCRIPT_TACKLEBAR_EXTENSION_BACKUP

:NPP_PYTHON_SCRIPT_TACKLEBAR_EXTENSION_BACKUP
set "NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_ROOT=%INSTALL_TO_DIR%\.notepadpp_tacklebar_prev_install"

if not exist "\\?\%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_ROOT%" (
  call :MAKE_DIR "%%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_ROOT%%"
  if not exist "\\?\%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_ROOT%" (
    echo.%?~nx0%: error: could not create a backup file directory: "%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_ROOT%".
    goto CANCEL_INSTALL
  ) >&2
  echo.
)

set "NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR=%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_ROOT%\notepadpp_tacklebar_prev_install_%LOG_FILE_NAME_SUFFIX%"

if not exist "\\?\%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%" (
  echo.^>mkdir "%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%"
  call :MAKE_DIR "%%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%%"
  if not exist "\\?\%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%" (
    echo.%?~nx0%: error: could not create a backup file directory: "%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%".
    goto CANCEL_INSTALL
  ) >&2
  echo.
)

if exist "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\startup.py" (
  echo.%?~nx0%: warning: Notepad++ PythonScript plugin startup script has been already existed, will be replaced.
  echo.
) >&2

for %%i in (tacklebar\ startup.py) do (
  if exist "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%~i" (
    echo.^>move: "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i" -^> "%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%\%%i"
    if not "%%~nxi" == "" (
      call :MOVE_FILE "%%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%%" "%%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%%" "%%i"
      if not exist "\\?\%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%\%%i" (
        echo.%?~nx0%: error: could not move previous installation file: "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i" -^> "%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%"
        goto CANCEL_INSTALL
      ) >&2
    ) else (
      call :MOVE_DIR "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i" "%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%\%%i"
      if not exist "\\?\%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%" (
        echo.%?~nx0%: error: could not move previous installation directory: "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\%%i" -^> "%NPP_PYTHON_SCRIPT_NEW_PREV_INSTALL_DIR%"
        goto CANCEL_INSTALL
      ) >&2
    )
    echo.
  )
)

:IGNORE_NPP_PYTHON_SCRIPT_TACKLEBAR_EXTENSION_BACKUP

echo.Backuping tacklebar...

set "TACKLEBAR_NEW_PREV_INSTALL_ROOT=%INSTALL_TO_DIR%\.tacklebar_prev_install"
set "TACKLEBAR_NEW_PREV_INSTALL_DIR=%TACKLEBAR_NEW_PREV_INSTALL_ROOT%\tacklebar_prev_install_%LOG_FILE_NAME_SUFFIX%"

if not exist "\\?\%INSTALL_TO_DIR%\tacklebar" goto IGNORE_PREV_INSTALLATION_DIR_MOVE

rem NOTE:
rem   Move and rename already existed installation directory into a unique one using `changelog.txt` file in the previous installation project root directory.

if not exist "\\?\%INSTALL_TO_DIR%\tacklebar\changelog.txt" goto MOVE_RENAME_INSTALLATION_DIR_WITH_CURRENT_DATE

set "LAST_CHANGELOG_DATE="
for /F "usebackq eol= tokens=* delims=" %%i in (`@type "%INSTALL_TO_DIR%\tacklebar\changelog.txt" ^| "%SystemRoot%\System32\findstr.exe" /R /B "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*:"`) do (
  set "LAST_CHANGELOG_DATE=%%i"
  goto CONTINUE_INSTALLATION_DIR_RENAME_1
)

:CONTINUE_INSTALLATION_DIR_RENAME_1
if not defined LAST_CHANGELOG_DATE goto MOVE_RENAME_INSTALLATION_DIR_WITH_CURRENT_DATE

set "LAST_CHANGELOG_DATE=%LAST_CHANGELOG_DATE:"=%"
set "LAST_CHANGELOG_DATE=%LAST_CHANGELOG_DATE::=%"
set "LAST_CHANGELOG_DATE=%LAST_CHANGELOG_DATE:.='%"

set "TACKLEBAR_NEW_PREV_INSTALL_DIR=%TACKLEBAR_NEW_PREV_INSTALL_ROOT%\tacklebar_prev_install_%LAST_CHANGELOG_DATE%_%LOG_FILE_NAME_SUFFIX%"

:MOVE_RENAME_INSTALLATION_DIR_WITH_CURRENT_DATE

if not exist "\\?\%TACKLEBAR_NEW_PREV_INSTALL_ROOT%" (
  echo.^>mkdir "%TACKLEBAR_NEW_PREV_INSTALL_ROOT%"
  call :MAKE_DIR "%%TACKLEBAR_NEW_PREV_INSTALL_ROOT%%"
  if not exist "\\?\%TACKLEBAR_NEW_PREV_INSTALL_ROOT%" (
    echo.%?~nx0%: error: could not create a backup file directory: "%TACKLEBAR_NEW_PREV_INSTALL_ROOT%".
    goto CANCEL_INSTALL
  ) >&2
  echo.
)

if not exist "\\?\%TACKLEBAR_NEW_PREV_INSTALL_DIR%" (
  echo.^>mkdir "%TACKLEBAR_NEW_PREV_INSTALL_DIR%"
  call :MAKE_DIR "%%TACKLEBAR_NEW_PREV_INSTALL_DIR%%"
  if not exist "\\?\%TACKLEBAR_NEW_PREV_INSTALL_DIR%" (
    echo.%?~nx0%: error: could not create a backup file directory: "%TACKLEBAR_NEW_PREV_INSTALL_DIR%".
    goto CANCEL_INSTALL
  ) >&2
  echo.
)

echo.^>move: "%INSTALL_TO_DIR%\tacklebar" -^> "%TACKLEBAR_NEW_PREV_INSTALL_DIR%"
call :MOVE_DIR "%%INSTALL_TO_DIR%%\tacklebar" "%%TACKLEBAR_NEW_PREV_INSTALL_DIR%%"
if not exist "\\?\%TACKLEBAR_NEW_PREV_INSTALL_DIR%" (
  echo.%?~nx0%: error: could not move previous installation directory: "%INSTALL_TO_DIR%\tacklebar" -^> "%TACKLEBAR_NEW_PREV_INSTALL_DIR%"
  goto CANCEL_INSTALL
) >&2

echo.

:IGNORE_PREV_INSTALLATION_DIR_MOVE

echo.Installing Notepad++ PythonScript tacklebar extension...

if not exist "%USERPROFILE%/Application Data/Notepad++\" (
  echo.%?~nx0%: error: Notepad++ user configuration directory is not found: "%USERPROFILE%/Application Data/Notepad++"
  goto INSTALL_WINMERGE
) >&2

echo.

echo.Updating "%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScriptStartup.cnf"...

if exist "%USERPROFILE%/Application Data/Notepad++/plugins/Config/PythonScriptStartup.cnf" (
  for /F "useback eol= tokens=* delims=" %%i in ("%TACKLEBAR_PROJECT_ROOT%/deploy/notepad++/plugins/PythonScript/Config/PythonScriptStartup.cnf") do (
    "%SystemRoot%\System32\findstr.exe" /R /C:"^%%i$" "%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScriptStartup.cnf" >nul || (
      echo.+%%i
      (echo.%%i) >> "%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScriptStartup.cnf"
    )
  )
) else (
  call :XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%/deploy/notepad++/plugins/PythonScript/Config" PythonScriptStartup.cnf "%%USERPROFILE%%/Application Data/Notepad++/plugins/Config" /Y /D /H
)

echo.

echo.Updating "%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\scripts\"...

set "PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR=%USERPROFILE%\Application Data\Notepad++\plugins\Config\PythonScript\scripts"

if not exist "\\?\%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%\" (
  echo.^>mkdir "%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%"
  call :MAKE_DIR "%%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%%"
  echo.
)

call :XCOPY_DIR "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%/contools/Scripts/Tools/ToolAdaptors/notepadplusplus/scripts/tacklebar" "%%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%%/tacklebar" /E /Y /D
call :XCOPY_FILE "%%TACKLEBAR_PROJECT_EXTERNALS_ROOT%%/contools/Scripts/Tools/ToolAdaptors/notepadplusplus/scripts" startup.py "%%PYTHON_SCRIPT_USER_SCRIPTS_INSTALL_DIR%%" /Y /D /H

echo.

echo.Installing tacklebar Total Commander extension...

call "%%?~dp0%%.%%?~n0%%/%%?~n0%%.totalcmd.tacklebar_config.bat" || goto CANCEL_INSTALL

echo.

echo Installing tacklebar...

rem exclude all version control system directories
set "XCOPY_EXCLUDE_DIRS_LIST=.svn|.git|.hg"

call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/deploy/.saveload" "%%INSTALL_TO_DIR%%/.saveload" /E /Y /D || goto CANCEL_INSTALL

rem basic initialization
call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/__init__"         "%%INSTALL_TO_DIR%%/tacklebar/__init__" /E /Y /D || goto CANCEL_INSTALL

call :XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%/_config"         config.system.vars.in "%%INSTALL_TO_DIR%%/tacklebar/_config" /Y /D /H || goto CANCEL_INSTALL

call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/_config/_common"  "%%INSTALL_TO_DIR%%/tacklebar/_config" /E /Y /D || goto CANCEL_INSTALL

if %WINDOWS_MAJOR_VER% EQU 5 (
  call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/_config/winxp"  "%%INSTALL_TO_DIR%%/tacklebar/_config" /E /Y /D || goto CANCEL_INSTALL
)

call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/_externals"       "%%INSTALL_TO_DIR%%/tacklebar/_externals" /E /Y /D || goto CANCEL_INSTALL

call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/deploy/totalcmd/ButtonBars/_common" "%%INSTALL_TO_DIR%%/tacklebar/ButtonBars" /E /Y /D || goto CANCEL_INSTALL

if %WINDOWS_MAJOR_VER% EQU 5 (
  call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/deploy/totalcmd/ButtonBars/winxp" "%%INSTALL_TO_DIR%%/tacklebar/ButtonBars" /E /Y /D || goto CANCEL_INSTALL
)

call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/res/images"       "%%INSTALL_TO_DIR%%/tacklebar/res/images" /E /Y /D || goto CANCEL_INSTALL
call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/src"              "%%INSTALL_TO_DIR%%/tacklebar/src" /E /Y /D || goto CANCEL_INSTALL

call :XCOPY_DIR "%%TACKLEBAR_PROJECT_ROOT%%/tools"            "%%INSTALL_TO_DIR%%/tacklebar/tools" /E /Y /D || goto CANCEL_INSTALL

call :XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%"                 changelog.txt "%%INSTALL_TO_DIR%%/tacklebar" /Y /D /H || goto CANCEL_INSTALL
call :XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%"                 README_EN.txt "%%INSTALL_TO_DIR%%/tacklebar" /Y /D /H || goto CANCEL_INSTALL

set "DETECTED_CONEMU_ROOT=
set "DETECTED_WINMERGE_ROOT="
set "DETECTED_ARAXIS_MERGE_ROOT="

if defined DETECTED_CONEMU_INSTALL_DIR for /F "eol= tokens=* delims=" %%i in ("%DETECTED_CONEMU_INSTALL_DIR%\.") do set "DETECTED_CONEMU_ROOT=%%~fi"
if defined DETECTED_WINMERGE_COMPARE_TOOL for /F "eol= tokens=* delims=" %%i in ("%DETECTED_WINMERGE_COMPARE_TOOL%") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi.") do set "DETECTED_WINMERGE_ROOT=%%~fj"
if defined DETECTED_ARAXIS_COMPARE_TOOL for /F "eol= tokens=* delims=" %%i in ("%DETECTED_ARAXIS_COMPARE_TOOL%") do for /F "eol= tokens=* delims=" %%j in ("%%~dpi.") do set "DETECTED_ARAXIS_MERGE_ROOT=%%~fj"

rem default value for optional 3dparty installation locations
if not defined DETECTED_CONEMU_ROOT if %WINDOWS_MAJOR_VER% GTR 5 (
  set "DETECTED_CONEMU_ROOT=c:\Program Files\ConEmu"
) else set "DETECTED_CONEMU_ROOT=c:\Program Files (x86)\ConEmu"

if not defined DETECTED_WINMERGE_ROOT if %WINDOWS_X64_VER% NEQ 0 (
  set "DETECTED_WINMERGE_ROOT=c:\Program Files (x86)\WinMerge"
) else set "DETECTED_WINMERGE_ROOT=c:\Program Files\WinMerge"

if not defined DETECTED_ARAXIS_MERGE_ROOT if %WINDOWS_X64_VER% NEQ 0 (
  set "DETECTED_ARAXIS_MERGE_ROOT=c:\Program Files (x86)\Araxis\Araxis Merge"
) else set "DETECTED_ARAXIS_MERGE_ROOT=c:\Program Files\Araxis\Araxis Merge"

rem directly generate  configuration file to be merged
if not exist "%INSTALL_TO_DIR%/tacklebar/_out/config/tacklebar\" mkdir "%INSTALL_TO_DIR%/tacklebar/_out/config/tacklebar"
call "%%TACKLEBAR_PROJECT_ROOT%%/tools/gen_user_config.bat" ^
  -conemu_root            "%%DETECTED_CONEMU_ROOT%%" ^
  -npp_editor             "%%DETECTED_NPP_EDITOR%%" ^
  -winmerge_root          "%%DETECTED_WINMERGE_ROOT%%" ^
  -enable_araxis_compare  "%%DETECTED_ARAXIS_COMPARE_ACTIVATED%%" ^
  -araxis_merge_root      "%%DETECTED_ARAXIS_MERGE_ROOT%%" ^
  "%%INSTALL_TO_DIR%%/tacklebar/_config" "%%INSTALL_TO_DIR%%/tacklebar/_out/config/tacklebar" "config.0.vars" || (
  echo.%?~nx0%: error: could not generate configuration file in the installation directory: "%INSTALL_TO_DIR%/tacklebar/_config/config.0.vars.in" -^> "%INSTALL_TO_DIR%/tacklebar/_out/config/tacklebar/config.0.vars"
  goto CANCEL_INSTALL
) >&2

echo.

rem detect 3dparty applications to merge/edit the user configuration file (`config.0.vars`)

if exist "%INSTALL_TO_DIR%/tacklebar\" goto PREV_INSTALL_ROOT_EXIST

(
  echo.%?~nx0%: note: previous installation directory is not found: "%INSTALL_TO_DIR%/tacklebar"
)

:PREV_INSTALL_ROOT_EXIST

set "TACKLEBAR_PREV_INSTALL_DIR=%TACKLEBAR_NEW_PREV_INSTALL_DIR%"

rem compare only if has a difference
if exist "\\?\%TACKLEBAR_PREV_INSTALL_DIR%/_out/config/tacklebar/config.0.vars" (
  "%SystemRoot%\System32\fc.exe" "%TACKLEBAR_PREV_INSTALL_DIR:/=\%\_out\config\tacklebar\config.0.vars" "%INSTALL_TO_DIR:/=\%\tacklebar\_out\config\tacklebar\config.0.vars" >nul 2>nul || goto MERGE_FROM_PREV_INSTALL
)

rem search in previous installation directories
echo.Searching in previous installation directories...

if exist "%INSTALL_TO_DIR%\.tacklebar_prev_install" ^
for /F "usebackq eol= tokens=* delims=" %%i in (`@dir /B /A:D /O:-N "%INSTALL_TO_DIR%\.tacklebar_prev_install\tacklebar_prev_install_*"`) do (
  set "TACKLEBAR_PREV_INSTALL_DIR=%INSTALL_TO_DIR%\.tacklebar_prev_install\%%i"
  call echo.- "%%TACKLEBAR_PREV_INSTALL_DIR%%"
  call "%%CONTOOLS_ROOT%%/std/if_.bat" exist "\\?\%%TACKLEBAR_PREV_INSTALL_DIR%%/_out/config/tacklebar/config.0.vars" && (
    call "%%SystemRoot%%\System32\fc.exe" "%%TACKLEBAR_PREV_INSTALL_DIR:/=\%%\_out\config\tacklebar\config.0.vars" "%%INSTALL_TO_DIR:/=\%%\tacklebar\_out\config\tacklebar\config.0.vars" >nul 2>nul || goto MERGE_FROM_PREV_INSTALL
  )
)

echo.

goto NOTEPAD_EDIT_USER_CONFIG

:MERGE_FROM_PREV_INSTALL
echo.

if defined DETECTED_ARAXIS_COMPARE_TOOL if %DETECTED_ARAXIS_COMPARE_ACTIVATED%0 NEQ 0 (
  call :CMD "%%DETECTED_ARAXIS_COMPARE_TOOL%%" /wait "%%TACKLEBAR_PREV_INSTALL_DIR%%/_out/config/tacklebar/config.0.vars" "%%INSTALL_TO_DIR%%/tacklebar/_out/config/tacklebar/config.0.vars"
  goto END_INSTALL
)

if defined DETECTED_WINMERGE_COMPARE_TOOL (
  call :CMD "%%DETECTED_WINMERGE_COMPARE_TOOL%%" "%%TACKLEBAR_PREV_INSTALL_DIR%%/_out/config/tacklebar/config.0.vars" "%%INSTALL_TO_DIR%%/tacklebar/_out/config/tacklebar/config.0.vars"
  goto END_INSTALL
)

(
  echo.%?~nx0%: error: No one text file merge application is detected.
  goto NOTEPAD_EDIT_USER_CONFIG
) >&2

:NOTEPAD_EDIT_USER_CONFIG
if not defined DETECTED_NPP_EDITOR goto IGNORE_NOTEPAD_EDIT_USER_CONFIG
if not exist "%DETECTED_NPP_EDITOR%" goto IGNORE_NOTEPAD_EDIT_USER_CONFIG

set "NPP_EDITOR=%DETECTED_NPP_EDITOR%"
call "%%TACKLEBAR_PROJECT_ROOT%%/src/scripts/notepad/notepad_edit_files.bat" -wait -npp -nosession -multiInst "%%INSTALL_TO_DIR%%" "%%INSTALL_TO_DIR%%/tacklebar/_out/config/tacklebar/config.0.vars"

goto END_INSTALL

echo.

:IGNORE_NOTEPAD_EDIT_USER_CONFIG
(
  echo.%?~nx0%: warning: Notepad++ is not detected, do edit configuration file manually: "%INSTALL_TO_DIR%/tacklebar/_out/config/tacklebar/config.0.vars"
) >&2

:END_INSTALL

echo.

rem load merged configuration file
call "%%TACKLEBAR_PROJECT_ROOT%%/tools/load_config.bat" "%%INSTALL_TO_DIR%%/tacklebar/_config" "%%INSTALL_TO_DIR%%/tacklebar/_out/config/tacklebar" "config.0.vars" || (
  echo.%?~nx0%: error: could not generate and load configuration file in the installation directory: "%INSTALL_TO_DIR%/tacklebar/_config/config.0.vars.in" -^> "%INSTALL_TO_DIR%/tacklebar/_out/config/tacklebar/config.0.vars"
  goto CANCEL_INSTALL
) >&2

if defined NPP_EDITOR if exist "%NPP_EDITOR%" goto NPP_EDITOR_OK

(
  echo.%?~nx0%: warning: config.0.vars: Notepad++ application location is not detected: NPP_EDITOR="%NPP_EDITOR%"
) >&2

:NPP_EDITOR_OK

if defined WINMERGE_COMPARE_TOOL if exist "%WINMERGE_COMPARE_TOOL%" goto WINMERGE_COMPARE_TOOL_OK

(
  echo.%?~nx0%: warning: config.0.vars: WinMerge application location is not detected: WINMERGE_COMPARE_TOOL="%WINMERGE_COMPARE_TOOL%"
) >&2

:WINMERGE_COMPARE_TOOL_OK

if %ARAXIS_COMPARE_ENABLE%0 NEQ 0 goto ARAXIS_COMPARE_ENABLE_OK

(
  echo.%?~nx0%: warning: config.0.vars: Araxis Merge application is disabled: ARAXIS_COMPARE_ENABLE="%ARAXIS_COMPARE_ENABLE%"
) >&2

:ARAXIS_COMPARE_ENABLE_OK

if defined ARAXIS_COMPARE_TOOL if exist "%ARAXIS_COMPARE_TOOL%" goto ARAXIS_COMPARE_TOOL_OK

(
  echo.%?~nx0%: warning: config.0.vars: Araxis Merge application location is not detected: ARAXIS_COMPARE_TOOL="%ARAXIS_COMPARE_TOOL%"
) >&2

:ARAXIS_COMPARE_TOOL_OK

if defined ARAXIS_CONSOLE_COMPARE_TOOL if exist "%ARAXIS_CONSOLE_COMPARE_TOOL%" goto ARAXIS_CONSOLE_COMPARE_TOOL_OK

(
  echo.%?~nx0%: warning: config.0.vars: Araxis Merge application location is not detected: ARAXIS_CONSOLE_COMPARE_TOOL="%ARAXIS_CONSOLE_COMPARE_TOOL%"
) >&2

:ARAXIS_CONSOLE_COMPARE_TOOL_OK

if defined FFMPEG_TOOL_EXE if exist "%FFMPEG_TOOL_EXE%" goto FFMPEG_TOOL_EXE_OK

(
  echo.%?~nx0%: warning: config.0.vars: FFmpeg tool location is not detected: FFMPEG_TOOL_EXE="%FFMPEG_TOOL_EXE%"
) >&2

:FFMPEG_TOOL_EXE_OK

if defined MSYS_ROOT if exist "%MSYS_ROOT%\bin\" goto MSYS_ROOT_OK

(
  echo.%?~nx0%: warning: config.0.vars: msys utilities location is not detected: MSYS_ROOT="%MSYS_ROOT%"
) >&2

:MSYS_ROOT_OK

if defined CYGWIN_ROOT if exist "%CYGWIN_ROOT%\bin\" goto CYGWIN_ROOT_OK

(
  echo.%?~nx0%: warning: config.0.vars: cygwin utilities location is not detected: CYGWIN_ROOT="%CYGWIN_ROOT%"
) >&2

:CYGWIN_ROOT_OK

echo.%?~nx0%: info: installation is complete.

exit /b 0

:XCOPY_FILE
if not exist "\\?\%~f3" (
  echo.^>mkdir "%~3"
  call :MAKE_DIR "%%~3" || (
    echo.%?~nx0%: error: could not create a target file directory: "%~3".
    exit /b 255
  ) >&2
  echo.
)
if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" -chcp "%%OEMCP%%" %%*
) else call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" %%*
exit /b

:XCOPY_DIR
if not exist "\\?\%~f2" (
  echo.^>mkdir "%~2"
  call :MAKE_DIR "%%~2" || (
    echo.%?~nx0%: error: could not create a target directory: "%~2".
    exit /b 255
  ) >&2
  echo.
)
if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat" -chcp "%%OEMCP%%" %%*
) else  call "%%CONTOOLS_ROOT%%/std/xcopy_dir.bat" %%*
exit /b

:MAKE_DIR
for /F "eol= tokens=* delims=" %%i in ("%~1\.") do set "FILE_PATH=%%~fi"

if exist "%SystemRoot%\System32\robocopy.exe" (
  mkdir "%FILE_PATH%" 2>nul || if exist "%SystemRoot%\System32\robocopy.exe" ( "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%FILE_PATH%" >nul )
) else mkdir "%FILE_PATH%" 2>nul
exit /b

:MOVE_FILE
for /F "eol= tokens=* delims=" %%i in ("%~1\.") do set "FROM_FILE_PATH=%%~fi"
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "TO_FILE_PATH=%%~fi"

if exist "%SystemRoot%\System32\robocopy.exe" (
  "%SystemRoot%\System32\robocopy.exe" /MOVE "%FROM_FILE_PATH%" "%TO_FILE_PATH%" "%~3" >nul
) else move "%FROM_FILE_PATH%\%~3" "%TO_FILE_PATH%\%~3" >nul
exit /b

:MOVE_DIR
for /F "eol= tokens=* delims=" %%i in ("%~1\.") do set "FROM_FILE_DIR=%%~fi"
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "TO_FILE_DIR=%%~fi"

if exist "%SystemRoot%\System32\robocopy.exe" (
  "%SystemRoot%\System32\robocopy.exe" /MOVE /E "%FROM_FILE_DIR%" "%TO_FILE_DIR%" "*.*" >nul
) else (
  if exist "\\?\%TO_FILE_DIR%\" rmdir /Q "%TO_FILE_DIR%"
  "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/shell/move_dir.vbs" "%FROM_FILE_DIR%" "%TO_FILE_DIR%"
)
exit /b

:CMD
echo.^>%*
(%*)
exit /b

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "RETURN_VALUE=%%~fi"
rem set "RETURN_VALUE=%RETURN_VALUE:\=/%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0

:CANCEL_INSTALL
(
  echo.%?~nx0%: info: installation is canceled.
  exit /b 127
) >&2
