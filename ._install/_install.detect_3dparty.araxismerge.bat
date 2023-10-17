@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

set "DETECTED_ARAXIS_COMPARE_TOOL="

echo.Searching AraxisMerge installation...

rem drop last error level
type nul >nul

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

set "REGQUERY_VALUE="
for /F "usebackq eol= tokens=1,2,3 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
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

if defined INSTALL_LOCATION if exist "%INSTALL_LOCATION%\*" ( set "REGQUERY_VALUE=%INSTALL_LOCATION%" & exit /b 0 )

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

set DETECTED_ARAXIS_COMPARE_ACTIVATED=0
for /F "usebackq eol= tokens=1,2,3 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/enum_reg_hkeys_as_list.vbs" -param LicensedUser -param SerialNumber ^
  "HKCU\SOFTWARE\Araxis\Merge" "HKCU\SOFTWARE\Wow6432Node\Araxis\Merge" ^
  "HKLM\SOFTWARE\Araxis\Merge" "HKLM\SOFTWARE\Wow6432Node\Araxis\Merge"`) do (
  set "LICENSED_USER=%%j"
  set "SERIAL_NUMBER=%%k"
  call :FIND_ACTIVATED && goto ACTIVATED_END
)

goto ACTIVATED_END

:FIND_ACTIVATED
if not defined LICENSED_USER exit /b 1
if not defined SERIAL_NUMBER exit /b 1

set "LICENSED_USER=%LICENSED_USER:"=%"
set "SERIAL_NUMBER=%SERIAL_NUMBER:"=%"

if "%LICENSED_USER%" == "." set "LICENSED_USER="
if "%SERIAL_NUMBER%" == "." set "SERIAL_NUMBER="

if not defined LICENSED_USER exit /b 1
if not defined SERIAL_NUMBER exit /b 1

set DETECTED_ARAXIS_COMPARE_ACTIVATED=1

exit /b 0

:ACTIVATED_END

if %DETECTED_ARAXIS_COMPARE_ACTIVATED%0 NEQ 0 (
  echo. * ARAXIS_COMPARE_ACTIVATED="%DETECTED_ARAXIS_COMPARE_ACTIVATED%"
) else (
  echo.%?~nx0%: warning: Araxis Merge is not activated.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_ARAXIS_COMPARE_ACTIVATED=%DETECTED_ARAXIS_COMPARE_ACTIVATED%"
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
