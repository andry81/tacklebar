@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

set "DETECTED_CONEMU_INSTALL_DIR="

echo.Searching ConEmu installation...

rem drop last error level
type nul >nul

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

set "REGQUERY_VALUE="
for /F "usebackq eol= tokens=1,2,3,4 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param InstallDir -param InstallDir_x64 -param InstallDir_x86 ^
  "HKCU\SOFTWARE\ConEmu" "HKCU\SOFTWARE\Wow6432Node\ConEmu" "HKLM\SOFTWARE\ConEmu" "HKLM\SOFTWARE\Wow6432Node\ConEmu"`) do (
  set "INSTALL_DIR=%%j"
  set "INSTALL_DIR_X64=%%k"
  set "INSTALL_DIR_X86=%%l"
  call :FIND_INSTALL_DIR INSTALL_DIR INSTALL_DIR_X64 INSTALL_DIR_X86 && goto INSTALL_DIR_END
)

goto INSTALL_DIR_END

:FIND_INSTALL_DIR
if "%~1" == "" exit /b 1
if not defined %~1 ( shift & goto FIND_INSTALL_DIR )

call set "VALUE=%%%~1:"=%%"
shift

if "%VALUE%" == "." set "VALUE="

if defined VALUE if exist "%VALUE%\" ( set "REGQUERY_VALUE=%VALUE%" & exit /b 0 )

if not "%~1" == "" goto FIND_INSTALL_DIR

exit /b 1

:INSTALL_DIR_END

if not defined REGQUERY_VALUE goto END_SEARCH_CONEMU_INSTALL_DIR

call :CANONICAL_PATH DETECTED_CONEMU_INSTALL_DIR "%%REGQUERY_VALUE%%"

:END_SEARCH_CONEMU_INSTALL_DIR
if defined DETECTED_CONEMU_INSTALL_DIR if not exist "%DETECTED_CONEMU_INSTALL_DIR%" set "DETECTED_CONEMU_INSTALL_DIR="
if defined DETECTED_CONEMU_INSTALL_DIR (
  echo. * CONEMU_INSTALL_DIR="%DETECTED_CONEMU_INSTALL_DIR%"
) else (
  echo.%?~nx0%: warning: ConEmu is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_CONEMU_INSTALL_DIR=%DETECTED_CONEMU_INSTALL_DIR%"
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
