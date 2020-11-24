@echo off

setlocal

set "DETECTED_WINMERGE_COMPARE_TOOL="

echo.Searching WinMerge installation...

rem 64-bit version at first
call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_LOCAL_MACHINE\SOFTWARE\Thingamahoochie\WinMerge" Executable >nul 2>nul

if %ERRORLEVEL% NEQ 0 call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Thingamahoochie\WinMerge" Executable >nul 2>nul

if %ERRORLEVEL% NEQ 0 call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "HKEY_LOCAL_MACHINE\SOFTWARE\System64\Thingamahoochie\WinMerge" Executable >nul 2>nul

if not defined REGQUERY_VALUE goto END_SEARCH_WINMERGE_COMPARE_TOOL

rem remove all quotes
set "REGQUERY_VALUE=%REGQUERY_VALUE:"=%"

call :CANONICAL_PATH DETECTED_WINMERGE_COMPARE_TOOL "%%REGQUERY_VALUE%%"

:END_SEARCH_WINMERGE_COMPARE_TOOL
if defined DETECTED_WINMERGE_COMPARE_TOOL if not exist "%DETECTED_WINMERGE_COMPARE_TOOL%" set "DETECTED_WINMERGE_COMPARE_TOOL="
if defined DETECTED_WINMERGE_COMPARE_TOOL (
  echo. * WINMERGE_COMPARE_TOOL="%DETECTED_WINMERGE_COMPARE_TOOL%"
) else (
  echo.%?~nx0%: warning: WinMerge is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_WINMERGE_COMPARE_TOOL=%DETECTED_WINMERGE_COMPARE_TOOL%"
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
