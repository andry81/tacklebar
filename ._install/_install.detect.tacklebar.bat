@echo off

setlocal

if defined DETECT_TACKLEBAR_INSTALL_DIR_CHECK if %DETECT_TACKLEBAR_INSTALL_DIR_CHECK%0 NEQ 0 exit /b 0

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

set "DETECTED_TACKLEBAR_INSTALL_DIR="
set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE="

echo.Searching Tacklebar installation...

call :DETECT %%*

if defined DETECTED_TACKLEBAR_INSTALL_DIR (
  echo. * TACKLEBAR_INSTALL_DIR="%DETECTED_TACKLEBAR_INSTALL_DIR%"
  echo. * TACKLEBAR_INSTALL_CHANGELOG_DATE="%DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE%"
) else (
  echo.%?~nx0%: info: Tacklebar installation directory is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_TACKLEBAR_INSTALL_DIR=%DETECTED_TACKLEBAR_INSTALL_DIR%"
  set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE=%DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE%"
)

set DETECT_TACKLEBAR_INSTALL_DIR_CHECK=1

exit /b 0

:DETECT
rem drop last error level
type nul >nul

if not defined INSTALL_TO_DIR set "INSTALL_TO_DIR=%COMMANDER_SCRIPTS_ROOT%"

if not defined INSTALL_TO_DIR exit /b 1

if not exist "\\?\%INSTALL_TO_DIR%\tacklebar\changelog.txt" exit /b 1

set "DETECTED_TACKLEBAR_INSTALL_DIR=%INSTALL_TO_DIR%\tacklebar"

set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE="
for /F "usebackq eol= tokens=* delims=" %%i in (`@type "\\?\%DETECTED_TACKLEBAR_INSTALL_DIR%\changelog.txt" ^| "%SystemRoot%\System32\findstr.exe" /R /B /C:"^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*:" /C:"^[0-9][0-9]*-[0-9][0-9]*-[0-9][0-9]*:"`) do (
  set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE=%%i"
  goto BREAK
)
:BREAK

set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE=%DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE:"=%"
set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE=%DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE::=%"
set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE=%DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE:.='%"
set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE=%DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE:-='%"

if defined DETECTED_TACKLEBAR_INSTALL_DIR call :CANONICAL_PATH DETECTED_TACKLEBAR_INSTALL_DIR "%%DETECTED_TACKLEBAR_INSTALL_DIR%%"

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
