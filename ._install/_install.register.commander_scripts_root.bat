@echo off

setlocal

rem Check for true elevated environment (required in case of Windows XP)
"%SystemRoot%\System32\net.exe" session >nul 2>nul || (
  echo.%~nx0: error: the script process is not properly elevated up to Administrator privileges.
  pause
  exit /b 255
) 2>nul

set "COMMANDER_SCRIPTS_ROOT=%~1"

if exist "%SystemRoot%\System32\setx.exe" (
  "%SystemRoot%\System32\setx.exe" /M COMMANDER_SCRIPTS_ROOT "%COMMANDER_SCRIPTS_ROOT%" || (
    echo.%~nx0: error: could not register `COMMANDER_SCRIPTS_ROOT` variable.
    pause
    exit /b 1
  ) 2>nul
) else (
  "%SystemRoot%\System32\reg.exe" add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v COMMANDER_SCRIPTS_ROOT /t REG_SZ /d "%COMMANDER_SCRIPTS_ROOT%" /f || (
    echo.%~nx0: error: could not register `COMMANDER_SCRIPTS_ROOT` variable.
    pause
    exit /b 2
  ) 2>nul

  rem trigger WM_SETTINGCHANGE
  "%SystemRoot%\System32\cscript.exe" //NOLOGO "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/post_wm_settingchange.vbs"
)

exit /b 0
