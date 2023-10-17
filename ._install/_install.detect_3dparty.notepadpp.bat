@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

set "DETECTED_NPP_ROOT="
set "DETECTED_NPP_EDITOR="

echo.Searching Notepad++ installation...

call :DETECT %%*

if defined DETECTED_NPP_EDITOR if not exist "%DETECTED_NPP_EDITOR%" set "DETECTED_NPP_EDITOR="
if defined DETECTED_NPP_EDITOR (
  echo. * NPP_EDITOR="%DETECTED_NPP_EDITOR%"
) else (
  echo.%?~nx0%: warning: Notepad++ is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_NPP_ROOT=%DETECTED_NPP_ROOT%"
  set "DETECTED_NPP_EDITOR=%DETECTED_NPP_EDITOR%"
)

exit /b 0

:DETECT
rem drop last error level
type nul >nul

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

set "REGQUERY_VALUE="
for /F "usebackq eol= tokens=1,2 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" ^
  "HKCU\SOFTWARE\Notepad++" "HKCU\SOFTWARE\Wow6432Node\Notepad++" ^
  "HKLM\SOFTWARE\Notepad++" "HKLM\SOFTWARE\Wow6432Node\Notepad++"`) do (
  set "INSTALL_DIR=%%j"
  call :FIND_INSTALL_DIR INSTALL_DIR && goto INSTALL_DIR_END
)

goto INSTALL_DIR_END

:FIND_INSTALL_DIR
if "%~1" == "" exit /b 1
if not defined %~1 ( shift & goto FIND_INSTALL_DIR )

call set "VALUE=%%%~1:"=%%"
shift

if "%VALUE%" == "." set "VALUE="

if defined VALUE if exist "%VALUE%\*" ( set "REGQUERY_VALUE=%VALUE%" & exit /b 0 )

if not "%~1" == "" goto FIND_INSTALL_DIR

exit /b 1

:INSTALL_DIR_END

if not defined REGQUERY_VALUE goto END_SEARCH_NPP_EDITOR

call :CANONICAL_PATH DETECTED_NPP_ROOT "%%REGQUERY_VALUE%%"
call :CANONICAL_PATH DETECTED_NPP_EDITOR "%%DETECTED_NPP_ROOT%%/notepad++.exe"

:END_SEARCH_NPP_EDITOR

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
