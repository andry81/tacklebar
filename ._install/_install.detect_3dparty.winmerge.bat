@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_WINMERGE_ROOT="
set "DETECTED_WINMERGE_COMPARE_TOOL="
set "DETECTED_WINMERGE_COMPARE_TOOL_X64_VER=0"

echo.Searching WinMerge installation...
echo.

call :DETECT %%*

echo. * WINMERGE_ROOT="%DETECTED_WINMERGE_ROOT%"
echo. * WINMERGE_COMPARE_TOOL="%DETECTED_WINMERGE_COMPARE_TOOL%"
echo. * WINMERGE_COMPARE_TOOL_X64_VER="%DETECTED_WINMERGE_COMPARE_TOOL_X64_VER%"

echo.

if not defined DETECTED_WINMERGE_COMPARE_TOOL (
  echo.%?~nx0%: warning: WinMerge is not detected.
  echo.
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
  call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" DETECTED_WINMERGE_COMPARE_TOOL "%%INSTALL_FILE%%"
) else exit /b 0

call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" DETECTED_WINMERGE_ROOT "%%DETECTED_WINMERGE_COMPARE_TOOL%%\.."

call "%%CONTOOLS_ROOT%%/filesys/read_pe_header_bitness.bat" "%%DETECTED_WINMERGE_COMPARE_TOOL%%"

if "%RETURN_VALUE%" == "64" set "DETECTED_WINMERGE_COMPARE_TOOL_X64_VER=1"

exit /b 0
