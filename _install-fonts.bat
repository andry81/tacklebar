@echo off

setlocal

call "%%~dp0._install/script_init.bat" tacklebar install-fonts %%0 %%* || exit /b
if %IMPL_MODE%0 NEQ 0 goto IMPL

rem ...

exit /b 0

:IMPL
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

rem CAUTION:
rem   DO NOT cleanup here because cleanup does rely on the pending rename on reboot feature
goto FREE_TEMP_DIR_END

:FREE_TEMP_DIR
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

:FREE_TEMP_DIR_END
rem restore locale
if defined FLAG_CHCP call "%%CONTOOLS_ROOT%%/std/restorecp.bat" -p

set /A NEST_LVL-=1

echo;%?~%: info: installation log directory: "%PROJECT_LOG_DIR%".
echo;

exit /b %LAST_ERROR%

:MAIN
rem call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/callln.bat" "%%PYTHON_EXE_PATH%%" "%%TACKLEBAR_PROJECT_ROOT%%/_install-fonts.xsh"
rem exit /b

echo;
echo;Set of fonts going to be installed:
echo;
echo;  * `TerminalVector (TrueType)`                          (TerminalVector.ttf)
echo;  * `Terminus (TTF) for Windows (TrueType)`              (TerminusTTFWindows-4.47.0.ttf)
echo;  * `Terminus (TTF) for Windows Bold (TrueType)`         (TerminusTTFWindows-4.47.0.ttf)
echo;  * `Terminus (TTF) for Windows Bold Italic (TrueType)`  (TerminusTTFWindows-4.47.0.ttf)
echo;  * `Terminus (TTF) for Windows Italic (TrueType)`       (TerminusTTFWindows-4.47.0.ttf)
echo;  * `Terminus`                                           (terminus.fon)
echo;

:REPEAT_INSTALL_ASK
set "CONTINUE_INSTALL_ASK="

echo;Ready to install, do you want to continue [y]es/[n]o?
set /P "CONTINUE_INSTALL_ASK="

if /i "%CONTINUE_INSTALL_ASK%" == "y" goto CONTINUE_INSTALL_ASK
if /i "%CONTINUE_INSTALL_ASK%" == "n" goto CANCEL_INSTALL

goto REPEAT_INSTALL_ASK

:CONTINUE_INSTALL_ASK
echo;

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
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CONTOOLS_SYSINTERNALS_ROOT%%/movefile.exe" "%%PENDING_MOVE_ON_REBOOT_DIR_TMP%%" "" || (
    echo;%?~%: error: could not register file for pending delete operation: "%PENDING_MOVE_ON_REBOOT_DIR_TMP%".
    echo;
    exit /b 11
  )
  echo;
)

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CONTOOLS_SYSINTERNALS_ROOT%%/movefile.exe" "%%SCRIPT_TEMP_CURRENT_DIR%%" "" || (
  echo;%?~%: error: could not register file for pending delete operation: "%SCRIPT_TEMP_CURRENT_DIR%".
  echo;
  exit /b 11
)

echo;

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "TerminalVector (TrueType)"                          /t REG_SZ /d "TerminalVector.ttf" /f
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Terminus (TTF) for Windows (TrueType)"              /t REG_SZ /d "TerminusTTFWindows-4.47.0.ttf" /f
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Terminus (TTF) for Windows Bold (TrueType)"         /t REG_SZ /d "TerminusTTFWindows-Bold-4.47.0.ttf" /f
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Terminus (TTF) for Windows Bold Italic (TrueType)"  /t REG_SZ /d "TerminusTTFWindows-Bold-Italic-4.47.0.ttf" /f
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Terminus (TTF) for Windows Italic (TrueType)"       /t REG_SZ /d "TerminusTTFWindows-Italic-4.47.0.ttf" /f

echo;

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" /v "TerminalVector"              /t REG_SZ /d "TerminalVector" /f
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%SystemRoot%%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" /v "Terminus (TTF) for Windows"  /t REG_SZ /d "Terminus (TTF) for Windows" /f

echo;

rem Detect the reboot requirement state
"%SystemRoot%\System32\reg.exe" query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "PendingFileRenameOperations" >nul 2>nul && (
  echo;*******************************************************************************
  echo;%?~%: warning: to complete the fonts installation you must reboot!
  echo;*******************************************************************************
)

echo;%?~%: info: installation is complete.
echo;

exit /b 0

:PENDING_XCOPY_FILE
rem check file on writable access which indicates ready to copy without reboot
call "%%CONTOOLS_ROOT%%/locks/wait_file_write_access.bat" "%%~f3\%%~2" -1 && (
  call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" %%*
  exit /b 0
)

call "%%CONTOOLS_ROOT%%/std/callshift.bat" -skip 3 3 "%%CONTOOLS_BUILD_TOOLS_ROOT%%/xcopy_file.bat" %%1 %%2 "%%PENDING_MOVE_ON_REBOOT_DIR_TMP%%" %%* || (
  echo;%?~%: error: could not copy file to temporary directory: "%~f1\%~2" -^> "%~f3\%~2".
  echo;
  exit /b 10
)

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CONTOOLS_SYSINTERNALS_ROOT%%/movefile.exe" "%%PENDING_MOVE_ON_REBOOT_DIR_TMP%%\%%~2" "%%~f3\%%~2" || (
  echo;%?~%: error: could not register file for pending move operation: "%PENDING_MOVE_ON_REBOOT_DIR_TMP%\%~2" -^> "%~f3\%~2".
  echo;
  exit /b 11
)

rem CAUTION:
rem   Need to remove the file if previous operation were ignored, otherwise the termporary directory won't be empty and so won't be deleted!
rem
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%CONTOOLS_SYSINTERNALS_ROOT%%/movefile.exe" "%%PENDING_MOVE_ON_REBOOT_DIR_TMP%%\%%~2" "" || (
  echo;%?~%: error: could not register file for pending delete operation: "%PENDING_MOVE_ON_REBOOT_DIR_TMP%\%~2".
  echo;
  exit /b 12
)

exit /b 0

:CANCEL_INSTALL
(
  echo;%?~%: info: installation is canceled.
  echo;
  exit /b 127
) >&2
