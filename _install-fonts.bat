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

echo.Request Administrative permissions to install...

set SCRIPT_START_FLAG=0
set "SCRIPT_START_FLAG_FILE=%PROJECT_LOG_DIR%\script_start_flag_file.txt"

type nul > "%SCRIPT_START_FLAG_FILE%"

"%SystemRoot%\System32\wscript.exe" //NOLOGO "%CONTOOLS_ROOT%/ToolAdaptors/vbs/winshell_call.vbs" -nowindow -verb runas -make_temp_dir_as_cwd "{{CWD}}" -wait_delete_cwd ^
  "%SystemRoot%\System32\wscript.exe" //NOLOGO "%CONTOOLS_ROOT%/ToolAdaptors/vbs/call.vbs" -D "{{CWD}}" -u -ra "%%" "%%?01%%" -v "?01" "%%" ^
    "%COMSPEC%" /C set "%%22TACKLEBAR_SCRIPTS_INSTALL=1%%22" ^& set "%%22IMPL_MODE=1%%22" ^& set "%%22INIT_VARS_FILE=%PROJECT_LOG_DIR%\init.vars%%22" ^& ^
      "@%%22%?~dp0%._install\_install.update.terminal_params.bat%%22" -update_screen_size -update_buffer_size -script_start_flag_file "%SCRIPT_START_FLAG_FILE%" ^& ^
      "@%%22%?~f0%%%22" %* 2^>^&1 ^| "%%22%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe%%22" /E "%%22%PROJECT_LOG_FILE:/=\%%%22"
set LASTERROR=%ERRORLEVEL%

set /P SCRIPT_START_FLAG=< "%SCRIPT_START_FLAG_FILE%"

rem set again to remove invalid characters including quote character
if defined SCRIPT_START_FLAG set "SCRIPT_START_FLAG=%SCRIPT_START_FLAG:"=%"

del /F /Q /A:-D "%SCRIPT_START_FLAG_FILE%" 2>nul

if defined SCRIPT_START_FLAG if %SCRIPT_START_FLAG%0 NEQ 0 goto IMPL_END

(
  echo.%?~nx0%: error: the script process is not properly elevated up to Administrator privileges.
  set LASTERROR=255
  goto EXIT
) >&2

:IMPL_END
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

:EXIT
if %NEST_LVL%0 EQU 0 if defined OEMCP ( call "%%CONTOOLS_ROOT%%/std/pause.bat" -chcp "%%OEMCP%%" ) else call "%%CONTOOLS_ROOT%%/std/pause.bat"

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
  call :CMD "%%CONTOOLS_UTILITIES_BIN_ROOT%%/sysinternals/movefile.exe" "%%PENDING_MOVE_ON_REBOOT_DIR_TMP%%" "" || (
    echo.%?~nx0%: error: could not register file for pending delete operation: "%PENDING_MOVE_ON_REBOOT_DIR_TMP%".
    exit /b 11
  )
)

call :CMD "%%CONTOOLS_UTILITIES_BIN_ROOT%%/sysinternals/movefile.exe" "%%SCRIPT_TEMP_CURRENT_DIR%%" "" || (
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

call :CMD "%%CONTOOLS_UTILITIES_BIN_ROOT%%/sysinternals/movefile.exe" "%%PENDING_MOVE_ON_REBOOT_DIR_TMP%%\%%~2" "%%~f3\%%~2" || (
  echo.%?~nx0%: error: could not register file for pending move operation: "%PENDING_MOVE_ON_REBOOT_DIR_TMP%\%~2" -^> "%~f3\%~2".
  exit /b 11
)

rem CAUTION:
rem   Need to remove the file if previous operation were ignored, otherwise the termporary directory won't be empty and so won't be deleted!
rem
call :CMD "%%CONTOOLS_UTILITIES_BIN_ROOT%%/sysinternals/movefile.exe" "%%PENDING_MOVE_ON_REBOOT_DIR_TMP%%\%%~2" "" || (
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

if exist "%SystemRoot%\System32\robocopy.exe" (
  mkdir "%FILE_PATH%" 2>nul || if exist "%SystemRoot%\System32\robocopy.exe" ( "%SystemRoot%\System32\robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%FILE_PATH%" >nul )
) else mkdir "%FILE_PATH%" 2>nul
exit /b

:CMD
echo.^>%*
(%*)
exit /b
