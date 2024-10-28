@echo off

setlocal DISABLEDELAYEDEXPANSION

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_CONEMU32_ROOT="
set "DETECTED_CONEMU64_ROOT="

echo.Searching ConEmu installation...
echo.

call :DETECT %%*

echo. * CONEMU32_ROOT="%DETECTED_CONEMU32_ROOT%"
echo. * CONEMU64_ROOT="%DETECTED_CONEMU64_ROOT%"

echo.

if not defined DETECTED_CONEMU32_ROOT (
  echo.%?~nx0%: warning: ConEmu 32-bit is not detected.
  echo.
) >&2

if not defined DETECTED_CONEMU64_ROOT (
  echo.%?~nx0%: warning: ConEmu 64-bit is not detected.
  echo.
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

for /F "usebackq tokens=1,2,3,4 delims=|"eol^= %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param InstallDir -param InstallDir_x64 -param InstallDir_x86 ^
  "HKCU\SOFTWARE\ConEmu" "HKCU\SOFTWARE\Wow6432Node\ConEmu" "HKLM\SOFTWARE\ConEmu" "HKLM\SOFTWARE\Wow6432Node\ConEmu"`) do (
  if not defined INSTALL_DIR if not "%%j" == "." set "INSTALL_DIR=%%j"
  if not defined INSTALL_DIR_X64 if not "%%k" == "." set "INSTALL_DIR_X64=%%k"
  if not defined INSTALL_DIR_X86 if not "%%l" == "." set "INSTALL_DIR_X86=%%l"
)

rem NOTE: expand path value variable if begins by %-character

rem CAUTION:
rem   The `if %VAR:~0,1% ...` expression will fail and stop the script execution if `VAR` is not defined.
rem   We use `call if_.bat ...` expression instead to suppress `if ...` error on invalid `if` expression.

for %%i in (INSTALL_DIR_X64 INSTALL_DIR_X86 INSTALL_DIR) do ^
if defined %%i call "%%CONTOOLS_ROOT%%/std/if_.bat" ^%%%%i:~0,1%%/ == ^%%%%/ && call "%%CONTOOLS_ROOT%%/std/expand_vars.bat" %%i

if defined INSTALL_DIR_X64 (
  if exist "%INSTALL_DIR_X64%\ConEmu64.exe" (
    call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" DETECTED_CONEMU64_ROOT "%%INSTALL_DIR_X64%%"
  )
  if exist "%INSTALL_DIR_X64%\ConEmu.exe" (
    call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" DETECTED_CONEMU32_ROOT "%%INSTALL_DIR_X64%%"
  )
) else if defined INSTALL_DIR_X86 (
  if exist "%INSTALL_DIR_X86%\ConEmu.exe" (
    call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" DETECTED_CONEMU32_ROOT "%%INSTALL_DIR_X86%%"
  )
) else if defined INSTALL_DIR (
  if exist "%INSTALL_DIR%\ConEmu64.exe" (
    call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" DETECTED_CONEMU64_ROOT "%%INSTALL_DIR%%"
  )
  if exist "%INSTALL_DIR%\ConEmu.exe" (
    call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" DETECTED_CONEMU32_ROOT "%%INSTALL_DIR%%"
  )
)

exit /b 0
