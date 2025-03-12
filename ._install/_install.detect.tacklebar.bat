@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_TACKLEBAR_INSTALL_DIR="
set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE="

echo.Searching `Tacklebar` installation...
echo.

call :DETECT %%*

echo. * TACKLEBAR_INSTALL_DIR="%DETECTED_TACKLEBAR_INSTALL_DIR%"
echo. * TACKLEBAR_INSTALL_CHANGELOG_DATE="%DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE%"

echo.

if not defined DETECTED_TACKLEBAR_INSTALL_DIR (
  echo.%?~%: info: `Tacklebar` installation directory is not detected.
  echo.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_TACKLEBAR_INSTALL_DIR=%DETECTED_TACKLEBAR_INSTALL_DIR%"
  set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE=%DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE%"
  exit /b 0
)

:DETECT
rem drop last error level
call;

if not defined INSTALL_TO_DIR set "INSTALL_TO_DIR=%COMMANDER_SCRIPTS_ROOT%"

if not defined INSTALL_TO_DIR exit /b 1

if not exist "\\?\%INSTALL_TO_DIR%\tacklebar\*" exit /b 1

set "DETECTED_TACKLEBAR_INSTALL_DIR=%INSTALL_TO_DIR%\tacklebar"

if not exist "\\?\%DETECTED_TACKLEBAR_INSTALL_DIR%\changelog.txt" exit /b 1

set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE="
for /F "usebackq tokens=* delims="eol^= %%i in (`@type "\\?\%DETECTED_TACKLEBAR_INSTALL_DIR%\changelog.txt" ^| "%SystemRoot%\System32\findstr.exe" /R /B /C:"^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*:" /C:"^[0-9][0-9]*-[0-9][0-9]*-[0-9][0-9]*:"`) do (
  set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE=%%i"
  goto BREAK
)
:BREAK

set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE=%DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE:"=%"
set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE=%DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE::=%"
set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE=%DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE:.='%"
set "DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE=%DETECTED_TACKLEBAR_INSTALL_CHANGELOG_DATE:-='%"

if defined DETECTED_TACKLEBAR_INSTALL_DIR ^
call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" DETECTED_TACKLEBAR_INSTALL_DIR "%%DETECTED_TACKLEBAR_INSTALL_DIR%%"

exit /b 0
