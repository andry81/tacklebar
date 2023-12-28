@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%* || exit /b

set DETECTED_ARAXIS_COMPARE_ACTIVATED=0
set "DETECTED_ARAXIS_MERGE_ROOT="
set "DETECTED_ARAXIS_COMPARE_TOOL="
set "DETECTED_ARAXIS_COMPARE_TOOL_X64_VER=0"

echo.Searching AraxisMerge installation...

call :DETECT %%*

echo. * ARAXIS_COMPARE_ACTIVATED="%DETECTED_ARAXIS_COMPARE_ACTIVATED%"
echo. * ARAXIS_MERGE_ROOT="%DETECTED_ARAXIS_MERGE_ROOT%"
echo. * ARAXIS_COMPARE_TOOL="%DETECTED_ARAXIS_COMPARE_TOOL%"
echo. * ARAXIS_COMPARE_TOOL_X64_VER="%DETECTED_ARAXIS_COMPARE_TOOL_X64_VER%"

if not defined DETECTED_ARAXIS_COMPARE_TOOL (
  echo.%?~nx0%: warning: Araxis Merge is not detected.
) >&2

if %DETECTED_ARAXIS_COMPARE_ACTIVATED% EQU 0 (
  echo.%?~nx0%: warning: Araxis Merge is not activated.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_ARAXIS_COMPARE_ACTIVATED=%DETECTED_ARAXIS_COMPARE_ACTIVATED%"
  set "DETECTED_ARAXIS_MERGE_ROOT=%DETECTED_ARAXIS_MERGE_ROOT%"
  set "DETECTED_ARAXIS_COMPARE_TOOL=%DETECTED_ARAXIS_COMPARE_TOOL%"
  set "DETECTED_ARAXIS_COMPARE_TOOL_X64_VER=%DETECTED_ARAXIS_COMPARE_TOOL_X64_VER%"
)

exit /b 0

:DETECT
rem drop last error level
call;

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

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

set "DISPLAY_NAME=%DISPLAY_NAME:"=%

if "%DISPLAY_NAME:Araxis Merge=%" == "%DISPLAY_NAME%" exit /b 1

if defined INSTALL_LOCATION if exist "%INSTALL_LOCATION%\*" (
  call :CANONICAL_PATH DETECTED_ARAXIS_MERGE_ROOT "%%INSTALL_LOCATION%%"
  call :CANONICAL_PATH DETECTED_ARAXIS_COMPARE_TOOL "%%DETECTED_ARAXIS_MERGE_ROOT%%/Compare.exe"
)

exit /b 0

:INSTALL_DIR_END

if not defined DETECTED_ARAXIS_COMPARE_TOOL goto END_SEARCH

call "%%CONTOOLS_ROOT%%/filesys/read_pe_header_bitness.bat" "%%DETECTED_ARAXIS_COMPARE_TOOL%%"

if "%RETURN_VALUE%" == "64" set "DETECTED_ARAXIS_COMPARE_TOOL_X64_VER=1"

:END_SEARCH

set "LICENSED_USER="
set "SERIAL_NUMBER="

for /F "usebackq eol= tokens=1,2,3 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/enum_reg_hkeys_as_list.vbs" -param LicensedUser -param SerialNumber ^
  "HKCU\SOFTWARE\Araxis\Merge" "HKCU\SOFTWARE\Wow6432Node\Araxis\Merge" ^
  "HKLM\SOFTWARE\Araxis\Merge" "HKLM\SOFTWARE\Wow6432Node\Araxis\Merge"`) do (
  if not defined LICENSED_USER if not "%%j" == "." set "LICENSED_USER=%%j"
  if not defined SERIAL_NUMBER if not "%%k" == "." set "SERIAL_NUMBER=%%k"
)

if defined LICENSED_USER if defined SERIAL_NUMBER (
  set DETECTED_ARAXIS_COMPARE_ACTIVATED=1
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
