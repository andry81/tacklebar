@echo off

setlocal

if %IMPL_MODE%0 NEQ 0 goto IMPL

set TACKLEBAR_SCRIPTS_INSTALL=1

call "%%~dp0__init__/__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

for %%i in (CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

rem check WSH disable
set "HKEYPATH=HKEY_CURRENT_USER\Software\Microsoft\Windows Script Host\Settings"
call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "%%HKEYPATH%%" Enabled >nul 2>nul
if defined REGQUERY_VALUE if %REGQUERY_VALUE%0 EQU 0 goto WSH_DISABLED

set "HKEYPATH=HKEY_LOCAL_MACHINE\Software\Microsoft\Windows Script Host\Settings"
call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "%%HKEYPATH%%" Enabled >nul 2>nul
if defined REGQUERY_VALUE if %REGQUERY_VALUE%0 EQU 0 goto WSH_DISABLED

goto WSH_ENABLED

:WSH_DISABLED
(
  echo.%~nx0: error: Windows Script Host is disabled: "%HKEYPATH%\Enabled" = %REGQUERY_VALUE%
  exit /b 255
) >&2

:WSH_ENABLED

call "%%CONTOOLS_ROOT%%/build/init_project_log.bat" "%%?~n0%%" || exit /b

rem List of issues discovered in Windows XP/7:
rem 1. Run from shortcut file (`.lnk`) in the Windows XP (but not in the Windows 7) brings truncated command line down to ~260 characters.
rem 2. Run from shortcut file (`.lnk`) loads console windows parameters (font, windows size, buffer size, etc) from the shortcut at first and from the registry
rem    (HKCU\Console) at second. If try to change and save parameters, then saves ONLY into the shortcut, which brings the shortcut file overwrite.
rem 3. Run under UAC promotion in the Windows 7+ blocks environment inheritance, blocks stdout redirection into a pipe from non-elevated process into elevated one and
rem    blocks console screen buffer change (piping locks process (stdout) screen buffer sizes).
rem    To bypass that, for example, need to:
rem     a. Save environment variables to a file from non-elevated process and load them back in an elevated process.
rem     b. Use redirection only from an elevated process.
rem     c. Change console screen buffer sizes before stdout redirection into a pipe.
rem 4. Windows antivirus software in some cases reports a `.vbs` script as not safe or requests an explicit action on each `.vbs` script execution.
rem

rem To resolve all the issues we DO NOT USE shortcut files (`.lnk`) or Visual Basic scripts (`.vbs`) for UAC promotion. Instead we use as a replacement `callf.exe` utility.
rem
rem PROs:
rem   1. Implementation is the same and portable between all the Windows versions like Windows XP/7/8/10. No need to use different implementation for each Windows version.
rem   2. No need to change console windows parameters (font, windows sizes, buffer sizes, etc) each time the project is installed. The parameters loads/saves from/to the registry and so
rem      is shared between installations.
rem   3. Process inheritance tree is retained between non-elevated process and elevated process because parent non-elevated process (`callf.exe`) awaits child elevated process.
rem   4. A single console can be shared between non-elevated and elevated processes.
rem   5. A single log file can be shared between non-elevated and elevated processes.
rem   6. The `/pause-on-exit*` flags of the `callf.exe` does not block execution on detached console versus the `pause` command of the `cmd.exe` interpreter which does block.
rem   7. Because the console window is owned or attached by the most top parent `callf.exe` process with the `/pause-on-exit*` flag, then
rem      there is no chance to skip the pause or skip a print into the console window if someone of children processes got crash or console detach,
rem      even under elevated environment.
rem
rem CONs:
rem   1. The `callf.exe` still can not redirect stdin/stdout of a child `cmd.exe` process without losing the auto completion feature (in case of interactive input - `cmd.exe /k`).
rem

rem CAUTION:
rem   The `ConSetBuffer.exe` utility has issue when changes screen buffer size under elevated environment through the `callf.exe` utility.
rem   To workaround that we have to change screen buffer sizes before the elevation.
rem
call "%%?~dp0%%._install\_install.update.terminal_params.bat" -update_screen_size -update_buffer_size

echo.Request Administrative permissions to install...

call "%%CONTOOLS_ROOT%%/build/init_vars_file.bat" || exit /b

call "%%CONTOOLS_ROOT%%/exec/exec_callf_prefix.bat" -Y /pause-on-exit -elevate tacklebar_fonts_install -- %%*
set LASTERROR=%ERRORLEVEL%

rem ...

exit /b %LASTERROR%

:IMPL
rem check for true elevated environment (required in case of Windows XP)
"%SystemRoot%\System32\net.exe" session >nul 2>nul || (
  echo.%?~nx0%: error: the script process is not properly elevated up to Administrator privileges.
  exit /b 255
) >&2

rem load initialization environment variables
if defined INIT_VARS_FILE call "%%CONTOOLS_ROOT%%/std/set_vars_from_file.bat" "%%INIT_VARS_FILE%%"

if exist "%SystemRoot%\System64\*" goto IGNORE_MKLINK_SYSTEM64

call "%%CONTOOLS_ROOT%%/ToolAdaptors/lnk/install_system64_link.bat"

if not exist "%SystemRoot%\System64\*" (
  echo.%?~nx0%: error: could not create directory link: "%SystemRoot%\System64" -^> "%SystemRoot%\System32"
  exit /b 255
) >&2

echo.

:IGNORE_MKLINK_SYSTEM64

rem CAUTION: requires `"%SystemRoot%\System64` directory installation
call "%%?~dp0%%._install\_install.update.terminal_params.bat" -update_registry || exit /b 255

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
    exit /b 255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

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

rem CAUTION:
rem   DO NOT cleanup here because cleanup does rely on the pending rename on reboot feature
goto FREE_TEMP_DIR_END

:FREE_TEMP_DIR
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

:FREE_TEMP_DIR_END
set /A NEST_LVL-=1

exit /b %LASTERROR%

:MAIN
rem call :CMD "%%PYTHON_EXE_PATH%%" "%%TACKLEBAR_PROJECT_ROOT%%/_install-fonts.xsh"
rem exit /b
rem 
rem :CMD
rem echo.^>%*
rem echo.
rem (
rem   %*
rem )
rem exit /b

echo.
echo.Set of fonts going to be installed:
echo.
echo.  * `TerminalVector (TrueType)`                          (TerminalVector.ttf)
echo.  * `Terminus (TTF) for Windows (TrueType)`              (TerminusTTFWindows-4.47.0.ttf)
echo.  * `Terminus (TTF) for Windows Bold (TrueType)`         (TerminusTTFWindows-4.47.0.ttf)
echo.  * `Terminus (TTF) for Windows Bold Italic (TrueType)`  (TerminusTTFWindows-4.47.0.ttf)
echo.  * `Terminus (TTF) for Windows Italic (TrueType)`       (TerminusTTFWindows-4.47.0.ttf)
echo.  * `Terminus`                                           (terminus.fon)
echo.

:REPEAT_INSTALL_ASK
set "CONTINUE_INSTALL_ASK="
echo.Do you want to continue [y]es/[n]o?
set /P "CONTINUE_INSTALL_ASK="

if /i "%CONTINUE_INSTALL_ASK%" == "y" goto CONTINUE_INSTALL_ASK
if /i "%CONTINUE_INSTALL_ASK%" == "n" goto CANCEL_INSTALL

goto REPEAT_INSTALL_ASK

:CONTINUE_INSTALL_ASK
echo.

set "WINDOWS_FONTS_DIR=%SystemRoot%\Fonts"
set "PENDING_MOVE_ON_REBOOT_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\pending_move_on_reboot"

rem register some values
"%SystemRoot%\System32\reg.exe" add "HKCU\Software\Sysinternals\Movefile" /v "EulaAccepted" /t REG_DWORD /d 0x00000001 /f >nul

call :PENDING_XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%/deploy/fonts/TerminalVector" TerminalVector.ttf                          "%%WINDOWS_FONTS_DIR%%" /Y /D /H
call :PENDING_XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%/deploy/fonts/Terminus"       terminus.fon                                "%%WINDOWS_FONTS_DIR%%" /Y /D /H
call :PENDING_XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%/deploy/fonts/Terminus TTF"   "TerminusTTFWindows-4.47.0.ttf"             "%%WINDOWS_FONTS_DIR%%" /Y /D /H
call :PENDING_XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%/deploy/fonts/Terminus TTF"   "TerminusTTFWindows-Bold-4.47.0.ttf"        "%%WINDOWS_FONTS_DIR%%" /Y /D /H
call :PENDING_XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%/deploy/fonts/Terminus TTF"   "TerminusTTFWindows-Bold-Italic-4.47.0.ttf" "%%WINDOWS_FONTS_DIR%%" /Y /D /H
call :PENDING_XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%/deploy/fonts/Terminus TTF"   "TerminusTTFWindows-Italic-4.47.0.ttf"      "%%WINDOWS_FONTS_DIR%%" /Y /D /H

rem CAUTION
rem   Not empty directory can not be removed. You must process the whole directory tree from leafs to the root.
rem

if exist "%PENDING_MOVE_ON_REBOOT_DIR_TMP%" (
  call :CMD "%%CONTOOLS_SYSINTERNALS_ROOT%%/movefile.exe" "%%PENDING_MOVE_ON_REBOOT_DIR_TMP%%" "" || (
    echo.%?~nx0%: error: could not register file for pending delete operation: "%PENDING_MOVE_ON_REBOOT_DIR_TMP%".
    exit /b 11
  )
)

call :CMD "%%CONTOOLS_SYSINTERNALS_ROOT%%/movefile.exe" "%%SCRIPT_TEMP_CURRENT_DIR%%" "" || (
  echo.%?~nx0%: error: could not register file for pending delete operation: "%SCRIPT_TEMP_CURRENT_DIR%".
  exit /b 11
)

echo.

call :CMD "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "TerminalVector (TrueType)"                          /t REG_SZ /d "TerminalVector.ttf" /f
call :CMD "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Terminus (TTF) for Windows (TrueType)"              /t REG_SZ /d "TerminusTTFWindows-4.47.0.ttf" /f
call :CMD "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Terminus (TTF) for Windows Bold (TrueType)"         /t REG_SZ /d "TerminusTTFWindows-Bold-4.47.0.ttf" /f
call :CMD "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Terminus (TTF) for Windows Bold Italic (TrueType)"  /t REG_SZ /d "TerminusTTFWindows-Bold-Italic-4.47.0.ttf" /f
call :CMD "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Terminus (TTF) for Windows Italic (TrueType)"       /t REG_SZ /d "TerminusTTFWindows-Italic-4.47.0.ttf" /f

echo.

call :CMD "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" /v "TerminalVector"              /t REG_SZ /d "TerminalVector" /f
call :CMD "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" /v "Terminus (TTF) for Windows"  /t REG_SZ /d "Terminus (TTF) for Windows" /f

echo.

rem Detect the reboot requirement state
"%SystemRoot%\System32\reg.exe" query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "PendingFileRenameOperations" 2>&1 >nul && (
  echo.*******************************************************************************
  echo.%?~nx0%: warning: to complete the fonts installation you must reboot!
  echo.*******************************************************************************
)

echo.%?~nx0%: info: installation is complete.

exit /b 0

:PENDING_XCOPY_FILE
rem check file on writable access which indicates ready to copy without reboot
move /Y "%~f3\%~2" "%~f3\%~2" >nul 2>nul
if %ERRORLEVEL% EQU 0 goto XCOPY_FILE

call :XCOPY_FILE %%1 %%2 "%%PENDING_MOVE_ON_REBOOT_DIR_TMP%%" %4 %5 %6 %7 %8 %9 || (
  echo.%?~nx0%: error: could not copy file to temporary directory: "%~f1\%~2" -^> "%~f3\%~2".
  exit /b 10
)

call :CMD "%%CONTOOLS_SYSINTERNALS_ROOT%%/movefile.exe" "%%PENDING_MOVE_ON_REBOOT_DIR_TMP%%\%%~2" "%%~f3\%%~2" || (
  echo.%?~nx0%: error: could not register file for pending move operation: "%PENDING_MOVE_ON_REBOOT_DIR_TMP%\%~2" -^> "%~f3\%~2".
  exit /b 11
)

rem CAUTION:
rem   Need to remove the file if previous operation were ignored, otherwise the termporary directory won't be empty and so won't be deleted!
rem
call :CMD "%%CONTOOLS_SYSINTERNALS_ROOT%%/movefile.exe" "%%PENDING_MOVE_ON_REBOOT_DIR_TMP%%\%%~2" "" || (
  echo.%?~nx0%: error: could not register file for pending delete operation: "%PENDING_MOVE_ON_REBOOT_DIR_TMP%\%~2".
  exit /b 12
)

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

:MAKE_DIR
for /F "eol= tokens=* delims=" %%i in ("%~1\.") do set "FILE_PATH=%%~fi"

mkdir "%FILE_PATH%" 2>nul || if exist "%SystemRoot%\System32\robocopy.exe" ( "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%FILE_PATH%" >nul ) else type 2>nul || (
  echo.%?~nx0%: error: could not create a target file directory: "%FILE_PATH%".
  exit /b 1
) >&2
exit /b

:CMD
echo.^>%*
(
  %*
)
exit /b

:CANCEL_INSTALL
(
  echo.%?~nx0%: info: installation is canceled.
  exit /b 127
) >&2
