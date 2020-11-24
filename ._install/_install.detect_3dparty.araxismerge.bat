@echo off

setlocal

set "DETECTED_ARAXIS_COMPARE_TOOL="

echo.Searching AraxisMerge installation...

rem Fast check at first
set "ARAXIS_MERGE_UNINSTALL_HKEY=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{E710B3E8-248F-4C36-AD17-E0B1A9AF10FA}"
call :PROCESS_ARAXIS_MERGE_UNINSTALL_HKEY && goto END_ENUM_ARAXIS_MERGE_UNINSTALL_HKEY

set "ARAXIS_MERGE_UNINSTALL_HKEY=HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{E710B3E8-248F-4C36-AD17-E0B1A9AF10FA}"
call :PROCESS_ARAXIS_MERGE_UNINSTALL_HKEY && goto END_ENUM_ARAXIS_MERGE_UNINSTALL_HKEY

set "ARAXIS_MERGE_UNINSTALL_HKEY=HKEY_LOCAL_MACHINE\SOFTWARE\System64\Microsoft\Windows\CurrentVersion\Uninstall\{E710B3E8-248F-4C36-AD17-E0B1A9AF10FA}"
call :PROCESS_ARAXIS_MERGE_UNINSTALL_HKEY && goto END_ENUM_ARAXIS_MERGE_UNINSTALL_HKEY

rem Slow full check
for /F "usebackq eol= tokens=* delims=" %%i in (`@call "%%CONTOOLS_ROOT%%/registry/regenum.bat" "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"`) do (
  set "ARAXIS_MERGE_UNINSTALL_HKEY=%%i"
  call :PROCESS_ARAXIS_MERGE_UNINSTALL_HKEY && goto END_ENUM_ARAXIS_MERGE_UNINSTALL_HKEY
)

goto END_SEARCH_ARAXIS_COMPARE_TOOL

:PROCESS_ARAXIS_MERGE_UNINSTALL_HKEY
call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "%%ARAXIS_MERGE_UNINSTALL_HKEY%%" DisplayName >nul 2>nul
if not defined REGQUERY_VALUE exit /b 255

rem remove all quotes
set "REGQUERY_VALUE=%REGQUERY_VALUE:"=%"
if /i not "%REGQUERY_VALUE:~0,7%" == "Araxis " exit /b 255

call "%%CONTOOLS_ROOT%%/registry/regquery.bat" "%%ARAXIS_MERGE_UNINSTALL_HKEY%%" InstallLocation >nul 2>nul
if not defined REGQUERY_VALUE exit /b 255

rem remove all quotes
set "REGQUERY_VALUE=%REGQUERY_VALUE:"=%"

call :CANONICAL_PATH DETECTED_ARAXIS_COMPARE_TOOL "%%REGQUERY_VALUE%%/Compare.exe"
exit /b 0

:END_ENUM_ARAXIS_MERGE_UNINSTALL_HKEY
:END_SEARCH_ARAXIS_COMPARE_TOOL
if defined DETECTED_ARAXIS_COMPARE_TOOL if not exist "%DETECTED_ARAXIS_COMPARE_TOOL%" set "DETECTED_ARAXIS_COMPARE_TOOL="
if defined DETECTED_ARAXIS_COMPARE_TOOL (
  echo. * ARAXIS_COMPARE_TOOL="%DETECTED_ARAXIS_COMPARE_TOOL%"
) else (
  echo.%?~nx0%: warning: Araxis Merge is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_ARAXIS_COMPARE_TOOL=%DETECTED_ARAXIS_COMPARE_TOOL%"
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
