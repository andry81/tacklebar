@echo off

setlocal

if defined DETECT_GITEXTENSIONS_INSTALL_DIR_CHECK if %DETECT_GITEXTENSIONS_INSTALL_DIR_CHECK%0 NEQ 0 exit /b 0

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_GITEXTENSIONS_INSTALL_DIR="

echo.Searching GitExtensions installation...

call :DETECT %%*

echo. * GITEXTENSIONS_INSTALL_DIR="%DETECTED_GITEXTENSIONS_INSTALL_DIR%"

if not defined DETECTED_GITEXTENSIONS_INSTALL_DIR (
  echo.%?~nx0%: warning: GitExtensions installation directory is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_GITEXTENSIONS_INSTALL_DIR=%DETECTED_GITEXTENSIONS_INSTALL_DIR%"
)

set DETECT_GITEXTENSIONS_INSTALL_DIR_CHECK=1

exit /b 0

:DETECT
rem drop last error level
call;

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

for /F "usebackq eol= tokens=1,2,3 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param InstallDir ^
  "HKCU\SOFTWARE\GitExtensions" "HKCU\SOFTWARE\Wow6432Node\GitExtensions" ^
  "HKLM\SOFTWARE\GitExtensions" "HKLM\SOFTWARE\Wow6432Node\GitExtensions"`) do (
  set "INSTALL_DIR=%%j"
  call :FIND_INSTALL_DIR && goto INSTALL_DIR_END
)

goto INSTALL_DIR_END

:FIND_INSTALL_DIR
if not defined INSTALL_DIR exit /b 1

set "INSTALL_DIR=%INSTALL_DIR:"=%"

if "%INSTALL_DIR%" == "." set "INSTALL_DIR="

if not defined INSTALL_DIR exit /b 1

if not exist "%INSTALL_DIR%\*" exit /b 1

call :CANONICAL_PATH DETECTED_GITEXTENSIONS_INSTALL_DIR "%%INSTALL_DIR%%"

exit /b 0

:INSTALL_DIR_END

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
