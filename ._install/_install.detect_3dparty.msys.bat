@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_MSYS32_ROOT="
set "DETECTED_MSYS32_DLL="
set "DETECTED_MSYS64_ROOT="
set "DETECTED_MSYS64_DLL="

echo.Searching Msys installation...
echo.

call :DETECT %%*

echo. * MSYS32_ROOT="%DETECTED_MSYS32_ROOT%"
echo. * MSYS32_DLL="%DETECTED_MSYS32_DLL%"
echo. * MSYS64_ROOT="%DETECTED_MSYS64_ROOT%"
echo. * MSYS64_DLL="%DETECTED_MSYS64_DLL%"

echo.

if not defined DETECTED_MSYS32_ROOT (
  echo.%?~nx0%: warning: Msys 32-bit is not detected.
  echo.
) >&2

if not defined DETECTED_MSYS64_ROOT (
  echo.%?~nx0%: warning: Msys 64-bit is not detected.
  echo.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_MSYS32_ROOT=%DETECTED_MSYS32_ROOT%"
  set "DETECTED_MSYS32_DLL=%DETECTED_MSYS32_DLL%"
  set "DETECTED_MSYS64_ROOT=%DETECTED_MSYS64_ROOT%"
  set "DETECTED_MSYS64_DLL=%DETECTED_MSYS64_DLL%"
)

exit /b 0

:DETECT
rem drop last error level
call;

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

for /F "usebackq eol= tokens=1,2,3 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/enum_reg_hkeys_as_list.vbs" -param DisplayName -param InstallLocation ^
  "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" "HKCU\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" ^
  "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"`) do (
  set "DISPLAY_NAME=%%j"
  set "INSTALL_LOCATION=%%k"
  call :FIND_INSTALL_DIR
)

exit /b 0

:FIND_INSTALL_DIR

if not defined DISPLAY_NAME exit /b 1

set "DISPLAY_NAME=%DISPLAY_NAME:"=%

if /i not "%DISPLAY_NAME%" == "MSYS" ^
if /i not "%DISPLAY_NAME%" == "MSYS2" ^
if "%DISPLAY_NAME:MSYS =%" == "%DISPLAY_NAME%" ^
if "%DISPLAY_NAME:MSYS2 =%" == "%DISPLAY_NAME%" exit /b 1

set "MSYS_DLL="

if defined INSTALL_LOCATION if exist "%INSTALL_LOCATION%\usr\bin\msys-?.*.dll" (
  for /F "usebackq eol= tokens=* delims=" %%i in (`@dir "%%INSTALL_LOCATION%%\usr\bin\msys-?.*.dll" /A:-D /B /O:N`) do (
    set "MSYS_DLL=%INSTALL_LOCATION%\usr\bin\%%i"
    goto END_SEARCH
  )
)

:END_SEARCH

if not defined MSYS_DLL goto END_SEARCH

call "%%CONTOOLS_ROOT%%/filesys/read_pe_header_bitness.bat" "%%MSYS_DLL%%"

rem find first
if "%RETURN_VALUE%" == "64" (
  if not defined DETECTED_MSYS64_ROOT (
    set "DETECTED_MSYS64_ROOT=%INSTALL_LOCATION%"
    set "DETECTED_MSYS64_DLL=%MSYS_DLL%"
  )
) else (
  if not defined DETECTED_MSYS32_ROOT (
    set "DETECTED_MSYS32_ROOT=%INSTALL_LOCATION%"
    set "DETECTED_MSYS32_DLL=%MSYS_DLL%"
  )
)

:END_SEARCH

exit /b 0
