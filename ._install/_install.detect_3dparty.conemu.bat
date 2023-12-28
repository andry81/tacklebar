@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

call "%%TACKLEBAR_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_CONEMU32_ROOT="
set "DETECTED_CONEMU64_ROOT="

echo.Searching ConEmu installation...

call :DETECT %%*

echo. * CONEMU32_ROOT="%DETECTED_CONEMU32_ROOT%"
echo. * CONEMU64_ROOT="%DETECTED_CONEMU64_ROOT%"

if not defined DETECTED_CONEMU32_ROOT (
  echo.%?~nx0%: warning: ConEmu 32-bit is not detected.
) >&2

if not defined DETECTED_CONEMU64_ROOT (
  echo.%?~nx0%: warning: ConEmu 64-bit is not detected.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_CONEMU32_ROOT=%DETECTED_CONEMU32_ROOT%"
  set "DETECTED_CONEMU64_ROOT=%DETECTED_CONEMU64_ROOT%"
)

exit /b 0

:DETECT
rem drop last error level
call;

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

set "INSTALL_DIR="
set "INSTALL_DIR_X64="
set "INSTALL_DIR_X86="

for /F "usebackq eol= tokens=1,2,3,4 delims=|" %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param InstallDir -param InstallDir_x64 -param InstallDir_x86 ^
  "HKCU\SOFTWARE\ConEmu" "HKCU\SOFTWARE\Wow6432Node\ConEmu" "HKLM\SOFTWARE\ConEmu" "HKLM\SOFTWARE\Wow6432Node\ConEmu"`) do (
  if not defined INSTALL_DIR if not "%%j" == "." set "INSTALL_DIR=%%j"
  if not defined INSTALL_DIR_X64 if not "%%k" == "." set "INSTALL_DIR_X64=%%k"
  if not defined INSTALL_DIR_X86 if not "%%l" == "." set "INSTALL_DIR_X86=%%l"
)

if defined INSTALL_DIR_X64 (
  if exist "%INSTALL_DIR_X64%\ConEmu64.exe" (
    call :CANONICAL_PATH DETECTED_CONEMU64_ROOT "%%INSTALL_DIR_X64%%"
  )
  if exist "%INSTALL_DIR_X64%\ConEmu.exe" (
    call :CANONICAL_PATH DETECTED_CONEMU32_ROOT "%%INSTALL_DIR_X64%%"
  )
) else if defined INSTALL_DIR_X86 (
  if exist "%INSTALL_DIR_X86%\ConEmu.exe" (
    call :CANONICAL_PATH DETECTED_CONEMU32_ROOT "%%INSTALL_DIR_X86%%"
  )
) else if defined INSTALL_DIR (
  if exist "%INSTALL_DIR%\ConEmu64.exe" (
    call :CANONICAL_PATH DETECTED_CONEMU64_ROOT "%%INSTALL_DIR%%"
  )
  if exist "%INSTALL_DIR%\ConEmu.exe" (
    call :CANONICAL_PATH DETECTED_CONEMU32_ROOT "%%INSTALL_DIR%%"
  )
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
