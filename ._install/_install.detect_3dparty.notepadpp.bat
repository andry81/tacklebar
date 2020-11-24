@echo off

setlocal

set "DETECTED_NPP_EDITOR="

echo.Searching Notepad++ installation...

rem 32-bit version at first
call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Notepad++" >nul 2>nul
if %ERRORLEVEL% NEQ 0 call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_LOCAL_MACHINE\SOFTWARE\Notepad++" >nul 2>nul

if not defined REGQUERY_VALUE goto END_SEARCH_NPP_EDITOR

rem remove all quotes
set "REGQUERY_VALUE=%REGQUERY_VALUE:"=%"

call :CANONICAL_PATH DETECTED_NPP_EDITOR "%%REGQUERY_VALUE%%/notepad++.exe"

:END_SEARCH_NPP_EDITOR
if defined DETECTED_NPP_EDITOR if not exist "%DETECTED_NPP_EDITOR%" set "DETECTED_NPP_EDITOR="
if defined DETECTED_NPP_EDITOR (
  echo. * NPP_EDITOR="%DETECTED_NPP_EDITOR%"
) else (
  echo.%?~nx0%: warning: Notepad++ is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_NPP_EDITOR=%DETECTED_NPP_EDITOR%"
)

exit /b 0

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
