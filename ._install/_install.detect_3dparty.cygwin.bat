@echo off

setlocal DISABLEDELAYEDEXPANSION

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_CYGWIN32_ROOT="
set "DETECTED_CYGWIN32_DLL="
set "DETECTED_CYGWIN64_ROOT="
set "DETECTED_CYGWIN64_DLL="

echo.Searching Cygwin installation...
echo.

call :DETECT %%*

echo. * CYGWIN32_ROOT="%DETECTED_CYGWIN32_ROOT%"
echo. * CYGWIN32_DLL="%DETECTED_CYGWIN32_DLL%"
echo. * CYGWIN64_ROOT="%DETECTED_CYGWIN64_ROOT%"
echo. * CYGWIN64_DLL="%DETECTED_CYGWIN64_DLL%"

echo.

if not defined DETECTED_CYGWIN32_ROOT (
  echo.%?~nx0%: warning: Cygwin 32-bit is not detected.
  echo.
) >&2

if not defined DETECTED_CYGWIN64_ROOT (
  echo.%?~nx0%: warning: Cygwin 64-bit is not detected.
  echo.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_CYGWIN32_ROOT=%DETECTED_CYGWIN32_ROOT%"
  set "DETECTED_CYGWIN32_DLL=%DETECTED_CYGWIN32_DLL%"
  set "DETECTED_CYGWIN64_ROOT=%DETECTED_CYGWIN64_ROOT%"
  set "DETECTED_CYGWIN64_DLL=%DETECTED_CYGWIN64_DLL%"
)

exit /b 0

:DETECT
rem drop last error level
call;

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

set "INSTALL_DIR="

for /F "usebackq eol= tokens=1,2,3,4 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param rootdir ^
  "HKCU\SOFTWARE\Cygwin\setup" "HKCU\SOFTWARE\Wow6432Node\Cygwin\setup" "HKLM\SOFTWARE\Cygwin\setup" "HKLM\SOFTWARE\Wow6432Node\Cygwin\setup"`) do (
  if not defined INSTALL_DIR if not "%%j" == "." set "INSTALL_DIR=%%j"
)

set "CYGWIN_DLL="

rem NOTE: expand path value variable if begins by %-character

if defined INSTALL_DIR ^
if ^%INSTALL_DIR:~0,1%/ == ^%%/ setlocal ENABLEDELAYEDEXPANSION & for /F "eol= tokens=* delims=" %%i in ("!INSTALL_DIR!") do endlocal & call set "INSTALL_DIR=%%i"

rem CAUTION:
rem   If a variable is empty, then it would not be expanded in the `cmd.exe` command line or in case of `for /F ...`!
rem   We must expand the command line into a variable.
rem
set CMD_LINE=@dir "%INSTALL_DIR%\bin\cygwin?.dll" /A:-D /B /O:N

if defined INSTALL_DIR if exist "%INSTALL_DIR%\bin\cygwin?.dll" (
  for /F "usebackq eol= tokens=* delims=" %%i in (`%%CMD_LINE%%`) do (
    set "CYGWIN_DLL=%INSTALL_DIR%\bin\%%i"
    goto END_SEARCH
  )
)

:END_SEARCH

if not defined CYGWIN_DLL goto END_SEARCH

call "%%CONTOOLS_ROOT%%/filesys/read_pe_header_bitness.bat" "%%CYGWIN_DLL%%"

rem find first
if "%RETURN_VALUE%" == "64" (
  if not defined DETECTED_CYGWIN64_ROOT (
    set "DETECTED_CYGWIN64_ROOT=%INSTALL_DIR%"
    set "DETECTED_CYGWIN64_DLL=%CYGWIN_DLL%"
  )
) else (
  if not defined DETECTED_CYGWIN32_ROOT (
    set "DETECTED_CYGWIN32_ROOT=%INSTALL_DIR%"
    set "DETECTED_CYGWIN32_DLL=%CYGWIN_DLL%"
  )
)

:END_SEARCH

set "INSTALL_DIR="

for /F "usebackq eol= tokens=1,2,3,4 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param native ^
  "HKCU\SOFTWARE\Cygnus Solutions\Cygwin\mounts v2\/" "HKCU\SOFTWARE\Wow6432Node\Cygnus Solutions\Cygwin\mounts v2\/" ^
  "HKLM\SOFTWARE\Cygnus Solutions\Cygwin\mounts v2\/" "HKLM\SOFTWARE\Wow6432Node\Cygnus Solutions\Cygwin\mounts v2\/"`) do (
  if not defined INSTALL_DIR if not "%%j" == "." set "INSTALL_DIR=%%j"
)

set "CYGWIN_DLL="

rem CAUTION:
rem   If a variable is empty, then it would not be expanded in the `cmd.exe` command line or in case of `for /F ...`!
rem   We must expand the command line into a variable.
rem
set CMD_LINE=@dir "%INSTALL_DIR%\bin\cygwin?.dll" /A:-D /B /O:N

if defined INSTALL_DIR if exist "%INSTALL_DIR%\bin\cygwin?.dll" (
  for /F "usebackq eol= tokens=* delims=" %%i in (`%%CMD_LINE%%`) do (
    set "CYGWIN_DLL=%INSTALL_DIR%\bin\%%i"
    goto END_SEARCH
  )
)

:END_SEARCH

if not defined CYGWIN_DLL goto END_SEARCH

call "%%CONTOOLS_ROOT%%/filesys/read_pe_header_bitness.bat" "%%CYGWIN_DLL%%"

rem find first
if "%RETURN_VALUE%" == "64" (
  if not defined DETECTED_CYGWIN64_ROOT (
    set "DETECTED_CYGWIN64_ROOT=%INSTALL_DIR%"
    set "DETECTED_CYGWIN64_DLL=%CYGWIN_DLL%"
  )
) else (
  if not defined DETECTED_CYGWIN32_ROOT (
    set "DETECTED_CYGWIN32_ROOT=%INSTALL_DIR%"
    set "DETECTED_CYGWIN32_DLL=%CYGWIN_DLL%"
  )
)

:END_SEARCH

exit /b 0
