@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_GITEXTENSIONS_ROOT="

echo.Searching GitExtensions installation...

call :DETECT %%*

echo. * GITEXTENSIONS_ROOT="%DETECTED_GITEXTENSIONS_ROOT%"

if not defined DETECTED_GITEXTENSIONS_ROOT (
  echo.%?~nx0%: warning: GitExtensions installation directory is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_GITEXTENSIONS_ROOT=%DETECTED_GITEXTENSIONS_ROOT%"
)

exit /b 0

:DETECT
rem drop last error level
call;

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

set "INSTALL_DIR="

for /F "usebackq eol= tokens=1,2,3 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param InstallDir ^
  "HKCU\SOFTWARE\GitExtensions" "HKCU\SOFTWARE\Wow6432Node\GitExtensions" ^
  "HKLM\SOFTWARE\GitExtensions" "HKLM\SOFTWARE\Wow6432Node\GitExtensions"`) do (
  if not defined INSTALL_DIR if not "%%j" == "." set "INSTALL_DIR=%%j"
)

if defined INSTALL_DIR if exist "%INSTALL_DIR%\*" (
  call :CANONICAL_PATH DETECTED_GITEXTENSIONS_ROOT "%%INSTALL_DIR%%"
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
