@echo off

setlocal DISABLEDELAYEDEXPANSION

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_NPP_ROOT="
set "DETECTED_NPP_EDITOR="
set "DETECTED_NPP_EDITOR_X64_VER=0"

echo.Searching Notepad++ installation...
echo.

call :DETECT %%*

echo. * NPP_ROOT="%DETECTED_NPP_ROOT%"
echo. * NPP_EDITOR="%DETECTED_NPP_EDITOR%"
echo. * NPP_EDITOR_X64_VER="%DETECTED_NPP_EDITOR_X64_VER%"

echo.

if not defined DETECTED_NPP_EDITOR (
  echo.%?~nx0%: warning: Notepad++ is not detected.
  echo.
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

rem NOTE: expand path value variable if begins by %-character

if defined INSTALL_DIR ^
if ^%INSTALL_DIR:~0,1%/ == ^%%/ setlocal ENABLEDELAYEDEXPANSION & for /F "eol= tokens=* delims=" %%i in ("!INSTALL_DIR!") do endlocal & call set "INSTALL_DIR=%%i"

if defined INSTALL_DIR if exist "%INSTALL_DIR%\*" (
  call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" DETECTED_NPP_ROOT "%%INSTALL_DIR%%"
) else exit /b 0

set "DETECTED_NPP_EDITOR=%INSTALL_DIR%\notepad++.exe"

call "%%CONTOOLS_ROOT%%/filesys/read_pe_header_bitness.bat" "%%DETECTED_NPP_EDITOR%%"

if "%RETURN_VALUE%" == "64" set "DETECTED_NPP_EDITOR_X64_VER=1"

exit /b 0
