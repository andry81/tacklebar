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

set "DETECTED_ARAXIS_COMPARE_TOOL="

echo.Searching AraxisMerge installation...

rem drop last error level
type nul >nul

set "REGQUERY_VALUE="
for /F "usebackq eol= tokens=1,2,3 delims=|" %%i in (`@"%SystemRoot%\System32\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/enum_reg_hkeys_as_list.vbs" -param DisplayName -param InstallLocation ^
  "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" "HKCU\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" ^
  "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"`) do (
  set "DISPLAY_NAME=%%j"
  set "INSTALL_LOCATION=%%k"
  call :FIND_INSTALL_DIR && goto INSTALL_DIR_END
)

goto INSTALL_DIR_END

:FIND_INSTALL_DIR
if not defined DISPLAY_NAME exit /b 1
if not defined INSTALL_LOCATION exit /b 1

set "DISPLAY_NAME=%DISPLAY_NAME:"=%"
set "INSTALL_LOCATION=%INSTALL_LOCATION:"=%"

if "%DISPLAY_NAME%" == "." set "DISPLAY_NAME="
if "%INSTALL_LOCATION%" == "." set "INSTALL_LOCATION="

if not defined DISPLAY_NAME exit /b 1
if "%DISPLAY_NAME:Araxis Merge=%" == "%DISPLAY_NAME%" exit /b 1

if defined INSTALL_LOCATION if exist "%INSTALL_LOCATION%\" ( set "REGQUERY_VALUE=%INSTALL_LOCATION%" & exit /b 0 )

exit /b 1

:INSTALL_DIR_END

if not defined REGQUERY_VALUE goto END_SEARCH_ARAXIS_COMPARE_TOOL

call :CANONICAL_PATH DETECTED_ARAXIS_COMPARE_TOOL "%%REGQUERY_VALUE%%/Compare.exe"

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
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "RETURN_VALUE=%%~fi"
rem set "RETURN_VALUE=%RETURN_VALUE:\=/%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
