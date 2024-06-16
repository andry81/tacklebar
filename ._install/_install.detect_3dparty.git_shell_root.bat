@echo off

setlocal DISABLEDELAYEDEXPANSION

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_GIT_SHELL_ROOT="

echo.Searching GIT_SHELL_ROOT variable...
echo.

call :DETECT %%*

echo. * GIT_SHELL_ROOT="%DETECTED_GIT_SHELL_ROOT%"

echo.

if not defined DETECTED_GIT_SHELL_ROOT (
  echo.%?~nx0%: warning: GIT_SHELL_ROOT environment variable is not detected.
  echo.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_GIT_SHELL_ROOT=%DETECTED_GIT_SHELL_ROOT%"
)

exit /b 0

:DETECT
rem drop last error level
call;

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

rem NOTE:
rem   GitForWindows has priority over already existed GIT_SHELL_ROOT variable,
rem   because GitForWindows has most Git compatible Bash shell version.

set "INSTALL_DIR="

for /F "usebackq eol= tokens=1,2,3 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param InstallPath ^
  "HKCU\SOFTWARE\GitForWindows" "HKCU\SOFTWARE\Wow6432Node\GitForWindows" ^
  "HKLM\SOFTWARE\GitForWindows" "HKLM\SOFTWARE\Wow6432Node\GitForWindows"`) do (
  if not defined INSTALL_DIR if not "%%j" == "." set "INSTALL_DIR=%%j"
)

rem NOTE: expand path value variable if begins by %-character

if defined INSTALL_DIR ^
if ^%INSTALL_DIR:~0,1%/ == ^%%/ setlocal ENABLEDELAYEDEXPANSION & for /F "eol= tokens=* delims=" %%i in ("!INSTALL_DIR!") do endlocal & call set "INSTALL_DIR=%%i"

if defined INSTALL_DIR if exist "%INSTALL_DIR%\*" (
  call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" DETECTED_GIT_SHELL_ROOT "%%INSTALL_DIR%%"
)

exit /b 0
