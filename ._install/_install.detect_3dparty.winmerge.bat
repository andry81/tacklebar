@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_WINMERGE_ROOT="
set "DETECTED_WINMERGE_COMPARE_TOOL="
set "DETECTED_WINMERGE_COMPARE_TOOL_X64_VER=0"

echo.Searching WinMerge installation...

call :DETECT %%*

echo. * WINMERGE_ROOT="%DETECTED_WINMERGE_ROOT%"
echo. * WINMERGE_COMPARE_TOOL="%DETECTED_WINMERGE_COMPARE_TOOL%"
echo. * WINMERGE_COMPARE_TOOL_X64_VER="%DETECTED_WINMERGE_COMPARE_TOOL_X64_VER%"

if not defined DETECTED_WINMERGE_COMPARE_TOOL (
  echo.%?~nx0%: warning: WinMerge is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_WINMERGE_ROOT=%DETECTED_WINMERGE_ROOT%"
  set "DETECTED_WINMERGE_COMPARE_TOOL=%DETECTED_WINMERGE_COMPARE_TOOL%"
  set "DETECTED_WINMERGE_COMPARE_TOOL_X64_VER=%DETECTED_WINMERGE_COMPARE_TOOL_X64_VER%"
)

exit /b 0

:DETECT
rem drop last error level
call;

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

set "REGQUERY_VALUE="
for /F "usebackq eol= tokens=1,2 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param "Executable" ^
  "HKCU\SOFTWARE\Thingamahoochie\WinMerge" "HKCU\SOFTWARE\Wow6432Node\Thingamahoochie\WinMerge" ^
  "HKLM\SOFTWARE\Thingamahoochie\WinMerge" "HKLM\SOFTWARE\Wow6432Node\Thingamahoochie\WinMerge"`) do (
  if not defined INSTALL_FILE if not "%%j" == "." set "INSTALL_FILE=%%j"
)

if defined INSTALL_FILE if exist "%INSTALL_FILE%" (
  call :CANONICAL_PATH DETECTED_WINMERGE_COMPARE_TOOL "%%INSTALL_FILE%%"
) else exit /b 0

call :CANONICAL_PATH DETECTED_WINMERGE_ROOT "%%DETECTED_WINMERGE_COMPARE_TOOL%%\.."

call "%%CONTOOLS_ROOT%%/filesys/read_pe_header_bitness.bat" "%%DETECTED_WINMERGE_COMPARE_TOOL%%"

if "%RETURN_VALUE%" == "64" set "DETECTED_WINMERGE_COMPARE_TOOL_X64_VER=1"

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
