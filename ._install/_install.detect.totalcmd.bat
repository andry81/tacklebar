@echo off

setlocal DISABLEDELAYEDEXPANSION

call "%%~dp0__init__.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

set "DETECTED_TOTALCMD_PRODUCT_VERSION="
set "DETECTED_TOTALCMD_INSTALL_DIR="
set "DETECTED_TOTALCMD_INI_FILE_DIR="

echo.Searching `Total Commander` installation...
echo.

call :DETECT %%*

echo. * TOTALCMD_PRODUCT_VERSION="%DETECTED_TOTALCMD_PRODUCT_VERSION%"
echo. * TOTALCMD_MIN_VERSION="%TOTALCMD_MIN_VER_STR%"
echo. * TOTALCMD_INSTALL_DIR="%DETECTED_TOTALCMD_INSTALL_DIR%"
echo. * TOTALCMD_INI_FILE_DIR="%DETECTED_TOTALCMD_INI_FILE_DIR%"

echo.

if not defined DETECTED_TOTALCMD_INSTALL_DIR (
  echo.%?~%: warning: `Total Commander` installation directory is not detected.
  echo.
) >&2

rem return variable
(
  endlocal
  set "DETECTED_TOTALCMD_PRODUCT_VERSION=%DETECTED_TOTALCMD_PRODUCT_VERSION%"
  set "DETECTED_TOTALCMD_INSTALL_DIR=%DETECTED_TOTALCMD_INSTALL_DIR%"
  set "DETECTED_TOTALCMD_INI_FILE_DIR=%DETECTED_TOTALCMD_INI_FILE_DIR%"
  exit /b 0
)

:DETECT
rem drop last error level
call;

if %WINDOWS_X64_VER%0 NEQ 0 (
  set "System6432=%SystemRoot%\System64"
) else set "System6432=%SystemRoot%\System32"

set "INSTALL_DIR="
set "INI_FILE_NAME="

for /F "usebackq tokens=1,2,3 delims=|"eol^= %%i in (`@"%System6432%\cscript.exe" //NOLOGO ^
  "%TACKLEBAR_PROJECT_EXTERNALS_ROOT%/tacklelib/vbs/tacklelib/tools/registry/read_reg_hkeys_as_list.vbs" -param InstallDir -param IniFileName ^
  "HKCU\SOFTWARE\Ghisler\Total Commander" "HKCU\SOFTWARE\Wow6432Node\Ghisler\Total Commander" ^
  "HKLM\SOFTWARE\Ghisler\Total Commander" "HKLM\SOFTWARE\Wow6432Node\Ghisler\Total Commander"`) do (
  if not defined INSTALL_DIR if not "%%j" == "." set "INSTALL_DIR=%%j"
  if not defined INI_FILE_NAME if not "%%k" == "." set "INI_FILE_NAME=%%k"
)

rem NOTE: expand path value variable if begins by %-character

rem CAUTION:
rem   The `if %VAR:~0,1% ...` expression will fail and stop the script execution if `VAR` is not defined.
rem   We use `call if_.bat ...` expression instead to suppress `if ...` error on invalid `if` expression.

for %%i in (INSTALL_DIR INI_FILE_NAME) do ^
if defined %%i call "%%CONTOOLS_ROOT%%/std/if_.bat" ^%%%%i:~0,1%%/ == ^%%%%/ && call "%%CONTOOLS_ROOT%%/std/expand_vars.bat" %%i

if defined INSTALL_DIR if exist "%INSTALL_DIR%\*" ^
call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" DETECTED_TOTALCMD_INSTALL_DIR "%%INSTALL_DIR%%"

if defined INI_FILE_NAME if exist "%INI_FILE_NAME%" ^
call "%%CONTOOLS_ROOT%%/std/canonical_path.bat" DETECTED_TOTALCMD_INI_FILE_DIR "%INI_FILE_NAME%\.."

set "RETURN_VALUE="
if exist "%DETECTED_TOTALCMD_INSTALL_DIR%\totalcmd64.exe" (
  call "%%CONTOOLS_ROOT%%/filesys/read_path_props" -v -x -lr ProductVersion "%DETECTED_TOTALCMD_INSTALL_DIR%\totalcmd64.exe"
) else if exist "%DETECTED_TOTALCMD_INSTALL_DIR%\totalcmd.exe" (
  call "%%CONTOOLS_ROOT%%/filesys/read_path_props" -v -x -lr ProductVersion "%DETECTED_TOTALCMD_INSTALL_DIR%\totalcmd.exe"
)

call "%%CONTOOLS_ROOT%%/std/set_var.bat" DETECTED_TOTALCMD_PRODUCT_VERSION RETURN_VALUE

exit /b 0

:INSTALL_DIR_AND_INI_PATH_END

exit /b 0
