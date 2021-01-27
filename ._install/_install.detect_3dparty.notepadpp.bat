@echo off

setlocal

set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"

call "%%?~dp0%%__init__.bat" || exit /b

for %%i in (PROJECT_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

set "DETECTED_NPP_ROOT="
set "DETECTED_NPP_EDITOR="

echo.Searching Notepad++ installation...

rem 32-bit version at first
call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKLM\SOFTWARE\Wow6432Node\Notepad++" >nul 2>nul

if %ERRORLEVEL% NEQ 0 call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKLM\SOFTWARE\Notepad++" >nul 2>nul

if not defined REGQUERY_VALUE goto END_SEARCH_NPP_EDITOR

rem remove all quotes
set "REGQUERY_VALUE=%REGQUERY_VALUE:"=%"

call :CANONICAL_PATH DETECTED_NPP_ROOT "%%REGQUERY_VALUE%%"
call :CANONICAL_PATH DETECTED_NPP_EDITOR "%%DETECTED_NPP_ROOT%%/notepad++.exe"

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
  set "DETECTED_NPP_ROOT=%DETECTED_NPP_ROOT%"
  set "DETECTED_NPP_EDITOR=%DETECTED_NPP_EDITOR%"
)

exit /b 0

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "RETURN_VALUE=%%~fi"
rem set "RETURN_VALUE=%RETURN_VALUE:\=/%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
