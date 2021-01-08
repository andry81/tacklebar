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

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%/std/get_wmic_local_datetime.bat"
set "LOG_FILE_NAME_SUFFIX=%RETURN_VALUE:~0,4%'%RETURN_VALUE:~4,2%'%RETURN_VALUE:~6,2%_%RETURN_VALUE:~8,2%'%RETURN_VALUE:~10,2%'%RETURN_VALUE:~12,2%''%RETURN_VALUE:~15,3%"

set "PROJECT_LOG_DIR=%PROJECT_LOG_ROOT%/%LOG_FILE_NAME_SUFFIX%.%~n0"
set "PROJECT_LOG_FILE=%PROJECT_LOG_DIR%/%LOG_FILE_NAME_SUFFIX%.%~n0.log"

if not exist "%PROJECT_LOG_DIR%" ( mkdir "%PROJECT_LOG_DIR%" || exit /b )

set IMPL_MODE=1

rem CAUTION:
rem   In the Windows 7 if the elevated console window closes through the GUI close button, then the `chcp.com` becomes a zombie (paused) process.
rem   So we have to run `chcp.com` BEFORE the UAC promotion!
rem

call "%%CONTOOLS_ROOT%%/std/chcp.bat" 65001
set RESTORE_LOCALE=1

rem CAUTION:
rem   We should avoid use handles 3 and 4 while the redirection has take a place because handles does reuse
rem   internally from left to right when being redirected externally.
rem   Example: if `1` is redirected, then `3` is internally reused, then if `2` redirected, then `4` is internally reused and so on.
rem   The discussion of the logic:
rem   https://stackoverflow.com/questions/9878007/why-doesnt-my-stderr-redirection-end-after-command-finishes-and-how-do-i-fix-i/9880156#9880156
rem   A partial analisis:
rem   https://www.dostips.com/forum/viewtopic.php?p=14612#p14612
rem

"%CONTOOLS_ROOT%/ToolAdaptors/lnk/cmd_admin.lnk" /C set "IMPL_MODE=1" ^& call "%?~f0%" %* 2^>^&1 ^| "%CONTOOLS_UTILITIES_BIN_ROOT%/ritchielawrence/mtee.exe" /E "%PROJECT_LOG_FILE:/=\%"
set LASTERROR=%ERRORLEVEL%

rem restore locale
if %RESTORE_LOCALE% NEQ 0 call "%%CONTOOLS_ROOT%%/std/restorecp.bat"

exit /b %LASTERROR%

:IMPL
set /A NEST_LVL+=1

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%"

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

rem cleanup temporary files
rem call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

set /A NEST_LVL-=1

if %NEST_LVL%0 EQU 0 call "%%CONTOOLS_ROOT%%/std/pause.bat"

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

set "WINDOWS_FONTS_DIR=%SYSTEMROOT%\Fonts"
set "PENDING_MOVE_ON_REBOOT_DIR_TMP=%SCRIPT_TEMP_CURRENT_DIR%\pending_move_on_reboot"

set REBOOT_REQUIRED=0

rem register some values
"%SYSTEMROOT%\System32\reg.exe" add "HKCU\Software\Sysinternals\MoveFile" /v "EulaAccepted" /t REG_DWORD /d 0x00000001 /f

call :PENDING_XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%/deploy/fonts/TerminalVector" TerminalVector.ttf                          "%%WINDOWS_FONTS_DIR%%" /Y /D /H
call :PENDING_XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%/deploy/fonts/Terminus"       terminus.fon                                "%%WINDOWS_FONTS_DIR%%" /Y /D /H
call :PENDING_XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%/deploy/fonts/Terminus TTF"   "TerminusTTFWindows-4.47.0.ttf"             "%%WINDOWS_FONTS_DIR%%" /Y /D /H
call :PENDING_XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%/deploy/fonts/Terminus TTF"   "TerminusTTFWindows-Bold-4.47.0.ttf"        "%%WINDOWS_FONTS_DIR%%" /Y /D /H
call :PENDING_XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%/deploy/fonts/Terminus TTF"   "TerminusTTFWindows-Bold-Italic-4.47.0.ttf" "%%WINDOWS_FONTS_DIR%%" /Y /D /H
call :PENDING_XCOPY_FILE "%%TACKLEBAR_PROJECT_ROOT%%/deploy/fonts/Terminus TTF"   "TerminusTTFWindows-Italic-4.47.0.ttf"      "%%WINDOWS_FONTS_DIR%%" /Y /D /H

rem CAUTION
rem   Not empty directory can not be removed. You must process the whole directory tree from leafs to the root.
rem

call :CMD "%%CONTOOLS_UTILITIES_BIN_ROOT%%/sysinternals/movefile.exe" "%%PENDING_MOVE_ON_REBOOT_DIR_TMP%%" "" || (
  echo.%?~nx0%: error: could not register file for pending delete operation: "%PENDING_MOVE_ON_REBOOT_DIR_TMP%\".
  exit /b 11
)

call :CMD "%%CONTOOLS_UTILITIES_BIN_ROOT%%/sysinternals/movefile.exe" "%%SCRIPT_TEMP_CURRENT_DIR%%" "" || (
  echo.%?~nx0%: error: could not register file for pending delete operation: "%SCRIPT_TEMP_CURRENT_DIR%\".
  exit /b 11
)

echo.

call :CMD "%%SYSTEMROOT%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "TerminalVector (TrueType)"                          /t REG_SZ /d "TerminalVector.ttf" /f
call :CMD "%%SYSTEMROOT%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Terminus (TTF) for Windows (TrueType)"              /t REG_SZ /d "TerminusTTFWindows-4.47.0.ttf" /f
call :CMD "%%SYSTEMROOT%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Terminus (TTF) for Windows Bold (TrueType)"         /t REG_SZ /d "TerminusTTFWindows-Bold-4.47.0.ttf" /f
call :CMD "%%SYSTEMROOT%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Terminus (TTF) for Windows Bold Italic (TrueType)"  /t REG_SZ /d "TerminusTTFWindows-Bold-Italic-4.47.0.ttf" /f
call :CMD "%%SYSTEMROOT%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Terminus (TTF) for Windows Italic (TrueType)"       /t REG_SZ /d "TerminusTTFWindows-Italic-4.47.0.ttf" /f

echo.

call :CMD "%%SYSTEMROOT%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" /v "TerminalVector"              /t REG_SZ /d "TerminalVector" /f
call :CMD "%%SYSTEMROOT%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" /v "Terminus (TTF) for Windows"  /t REG_SZ /d "Terminus (TTF) for Windows" /f

echo.

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
exit /b 0

:XCOPY_FILE
if not exist "\\?\%~f3" (
  echo.^>mkdir "%~3"
  mkdir "%~3" 2>nul || "%WINDIR%/System32/robocopy.exe" /CREATE "%EMPTY_DIR_TMP%" "%~3" >nul || (
    echo.%?~nx0%: error: could not create a target file directory: "%~3".
    exit /b 255
  ) >&2
  echo.
)
call "%%CONTOOLS_ROOT%%/std/xcopy_file.bat" %%*
exit /b

:CMD
echo.^>%*
(%*)
exit /b
