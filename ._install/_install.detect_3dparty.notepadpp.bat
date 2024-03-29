@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_NPP_ROOT="
set "DETECTED_NPP_EDITOR="
set "DETECTED_NPP_EDITOR_X64_VER=0"

echo.Searching Notepad++ installation...

call :DETECT %%*

echo. * NPP_ROOT="%DETECTED_NPP_ROOT%"
echo. * NPP_EDITOR="%DETECTED_NPP_EDITOR%"
echo. * NPP_EDITOR_X64_VER="%DETECTED_NPP_EDITOR_X64_VER%"

if not defined DETECTED_NPP_EDITOR (
  echo.%?~nx0%: warning: Notepad++ is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_NPP_ROOT=%DETECTED_NPP_ROOT%"
  set "DETECTED_NPP_EDITOR=%DETECTED_NPP_EDITOR%"
  set "DETECTED_NPP_EDITOR_X64_VER=%DETECTED_NPP_EDITOR_X64_VER%"
)

exit /b 0

:DETECT
rem drop last error level
call;

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

set "INSTALL_DIR="

for /F "usebackq eol= tokens=1,2 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" ^
  "HKCU\SOFTWARE\Notepad++" "HKCU\SOFTWARE\Wow6432Node\Notepad++" ^
  "HKLM\SOFTWARE\Notepad++" "HKLM\SOFTWARE\Wow6432Node\Notepad++"`) do (
  if not defined INSTALL_DIR if not "%%j" == "." set "INSTALL_DIR=%%j"
)

if defined INSTALL_DIR if exist "%INSTALL_DIR%\*" (
  call :CANONICAL_PATH DETECTED_NPP_ROOT "%%INSTALL_DIR%%"
) else exit /b 0

set "DETECTED_NPP_EDITOR=%INSTALL_DIR%\notepad++.exe"

call "%%CONTOOLS_ROOT%%/filesys/read_pe_header_bitness.bat" "%%DETECTED_NPP_EDITOR%%"

if "%RETURN_VALUE%" == "64" set "DETECTED_NPP_EDITOR_X64_VER=1"

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
